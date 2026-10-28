import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../products/domain/entities/catalog_product.dart';
import '../../domain/entities/product_management.dart';
import '../../domain/repositories/product_management_repository.dart';
import '../../../variant_groups/domain/repositories/variant_groups_repository.dart';
import '../bloc/product_management_cubit.dart';
import '../dialogs/product_dialog.dart';
import '../dialogs/product_recipes_dialog.dart';
import '../widgets/product_management_widgets.dart';
import '../widgets/product_table.dart';
import '../../../variant_groups/presentation/pages/variant_groups_management_page.dart';

class ProductsManagementPage extends StatelessWidget {
  const ProductsManagementPage({
    super.key,
    required this.repository,
    required this.variantGroupsRepository,
  });

  final ProductManagementRepository repository;
  final VariantGroupsRepository variantGroupsRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductManagementCubit(repository)..load(),
      child: BlocBuilder<ProductManagementCubit, ProductManagementState>(
        builder: (context, state) => switch (state) {
          ProductManagementLoading() => const Scaffold(
            appBar: _ProductManagementAppBar(),
            body: Center(child: CircularProgressIndicator()),
          ),
          ProductManagementFailure() => Scaffold(
            appBar: const _ProductManagementAppBar(),
            body: _loadFailure(context, state.message),
          ),
          ProductManagementLoaded() => _ProductManagementTabs(
            state: state,
            repository: repository,
            variantGroupsRepository: variantGroupsRepository,
          ),
        },
      ),
    );
  }

  Widget _loadFailure(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Data belum dapat dimuat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: context.read<ProductManagementCubit>().load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductManagementAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ProductManagementAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AppBar(title: const Text('Pengelolaan produk'));
}

class _ProductManagementTabs extends StatelessWidget {
  const _ProductManagementTabs({
    required this.state,
    required this.repository,
    required this.variantGroupsRepository,
  });

  final ProductManagementLoaded state;
  final ProductManagementRepository repository;
  final VariantGroupsRepository variantGroupsRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        actions: [
          IconButton(
            tooltip: 'Kelola grup varian',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VariantGroupsManagementPage(
                  repository: variantGroupsRepository,
                  productsRepository: repository,
                ),
              ),
            ),
            icon: const Icon(Icons.tune_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.errorMessage != null)
            MaterialBanner(
              content: Text(state.errorMessage!),
              actions: [
                TextButton(
                  onPressed: context.read<ProductManagementCubit>().load,
                  child: const Text('Muat ulang'),
                ),
              ],
            ),
          Expanded(child: _ProductsTab(state: state)),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatefulWidget {
  const _ProductsTab({required this.state});

  final ProductManagementLoaded state;

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductManagementCubit>();
    final filteredProducts = widget.state.products
        .where((item) {
          final query = _searchController.text.trim().toLowerCase();
          final product = item.product;
          final matchesQuery =
              query.isEmpty ||
              product.name.toLowerCase().contains(query) ||
              (product.category?.name.toLowerCase().contains(query) ?? false);
          final matchesCategory =
              _selectedCategoryId == null ||
              product.category?.id == _selectedCategoryId;
          return matchesQuery && matchesCategory;
        })
        .toList(growable: false);
    return RefreshIndicator(
      onRefresh: cubit.load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth >= 900 ? 28 : 16,
              16,
              constraints.maxWidth >= 900 ? 28 : 16,
              28,
            ),
            children: [
              ProductPageHeader(
                count: widget.state.products.length,
                onRefresh: cubit.load,
                onAdd: widget.state.categories.isEmpty
                    ? null
                    : () => _editProduct(context, widget.state),
              ),
              const SizedBox(height: 16),
              ProductFilterBar(
                controller: _searchController,
                categories: widget.state.categories,
                selectedCategoryId: _selectedCategoryId,
                onChanged: (_) => setState(() {}),
                onCategoryChanged: (value) =>
                    setState(() => _selectedCategoryId = value),
              ),
              const SizedBox(height: 16),
              if (filteredProducts.isEmpty)
                ProductEmptyState(hasProducts: widget.state.products.isNotEmpty)
              else if (isWide)
                ProductsTable(
                  products: filteredProducts,
                  onEdit: (item) => _editProduct(context, widget.state, item),
                  onDelete: (item) => _deleteProduct(context, item),
                  onRecipes: (item) => _manageRecipes(context, item),
                )
              else
                ...filteredProducts.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProductCard(
                      item: item,
                      onEdit: () => _editProduct(context, widget.state, item),
                      onDelete: () => _deleteProduct(context, item),
                      onRecipes: () => _manageRecipes(context, item),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _manageRecipes(BuildContext context, ManagedProduct item) async {
    final cubit = context.read<ProductManagementCubit>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ProductRecipesDialog(
        item: item,
        inventories: widget.state.inventories,
        productUnits: widget.state.productUnits
            .where((unit) => unit.isActive)
            .toList(growable: false),
        onAdd:
            ({
              required inventoryId,
              required quantity,
              required unitId,
              required conversionFactor,
            }) => cubit.addRecipe(
              productId: item.product.id,
              inventoryId: inventoryId,
              quantity: quantity,
              unitId: unitId,
              conversionFactor: conversionFactor,
            ),
        onRemove: (index) =>
            cubit.removeRecipe(productId: item.product.id, recipeIndex: index),
      ),
    );
    if (context.mounted) setState(() {});
  }
}

Future<void> _editProduct(
  BuildContext context,
  ProductManagementLoaded state, [
  ManagedProduct? item,
]) async {
  final draft = await showDialog<ProductDraft>(
    context: context,
    builder: (_) => ProductDialog(
      categories: state.categories,
      variantGroups: state.variantGroups,
      product: item,
    ),
  );
  if (draft == null || !context.mounted) return;
  final cubit = context.read<ProductManagementCubit>();
  final uploadedUrls = await cubit.uploadProductImages(
    draft.images
        .where((image) => image.file != null)
        .map((image) => image.file!)
        .toList(growable: false),
  );
  if (uploadedUrls == null || !context.mounted) {
    if (context.mounted) _showResult(context, false, '');
    return;
  }
  var uploadedIndex = 0;
  final images = draft.images
      .map((image) {
        final url = image.file == null
            ? image.url!
            : uploadedUrls[uploadedIndex++];
        return ProductImage(url: url, isMain: image.isMain);
      })
      .toList(growable: false);
  final success = await context.read<ProductManagementCubit>().saveProduct(
    productId: item?.product.id,
    name: draft.name,
    price: draft.price,
    stock: draft.stock,
    categoryId: draft.categoryId,
    variantGroupIds: draft.variantGroupIds,
    images: images,
    isActive: draft.isActive,
  );
  if (!context.mounted) return;
  _showResult(context, success, 'Produk berhasil disimpan.');
}

Future<void> _deleteProduct(BuildContext context, ManagedProduct item) async {
  final confirmed = await _confirmDelete(
    context,
    title: 'Hapus produk?',
    message: 'Produk "${item.product.name}" akan dihapus.',
  );
  if (!confirmed || !context.mounted) return;
  final success = await context.read<ProductManagementCubit>().deleteProduct(
    item.product.id,
  );
  if (!context.mounted) return;
  _showResult(context, success, 'Produk berhasil dihapus.');
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ) ??
      false;
}

void _showResult(BuildContext context, bool success, String successMessage) {
  var message = successMessage;
  if (!success) {
    final state = context.read<ProductManagementCubit>().state;
    message = switch (state) {
      ProductManagementLoaded(errorMessage: final errorMessage) =>
        errorMessage ?? 'Operasi tidak berhasil.',
      ProductManagementFailure(message: final errorMessage) => errorMessage,
      _ => 'Operasi tidak berhasil.',
    };
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
