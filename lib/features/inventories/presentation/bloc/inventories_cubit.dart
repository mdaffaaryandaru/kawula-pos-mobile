import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';

sealed class InventoriesState {
  const InventoriesState();
}

final class InventoriesLoading extends InventoriesState {
  const InventoriesLoading();
}

final class InventoriesLoaded extends InventoriesState {
  const InventoriesLoaded(this.items, {this.errorMessage});

  final List<InventoryItem> items;
  final String? errorMessage;
}

final class InventoriesFailure extends InventoriesState {
  const InventoriesFailure(this.message);

  final String message;
}

class InventoriesCubit extends Cubit<InventoriesState> {
  InventoriesCubit(this._repository) : super(const InventoriesLoading());

  final InventoryRepository _repository;

  Future<void> load() async {
    emit(const InventoriesLoading());
    try {
      emit(InventoriesLoaded(await _repository.getInventories()));
    } catch (error) {
      emit(InventoriesFailure(_messageFor(error)));
    }
  }

  Future<bool> save({
    String? inventoryId,
    required String name,
    required num? stock,
    required String unitId,
    required String category,
    required String description,
    required num buyPrice,
    required num minStock,
    required num? maxStock,
    required bool isActive,
  }) async {
    try {
      await _repository.saveInventory(
        inventoryId: inventoryId,
        name: name,
        stock: stock,
        unitId: unitId,
        category: category,
        description: description,
        buyPrice: buyPrice,
        minStock: minStock,
        maxStock: maxStock,
        isActive: isActive,
      );
      await load();
      return state is InventoriesLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> adjust({
    required String inventoryId,
    required String type,
    required num quantity,
    required String notes,
  }) async {
    try {
      await _repository.adjustStock(
        inventoryId: inventoryId,
        type: type,
        quantity: quantity,
        notes: notes,
      );
      await load();
      return state is InventoriesLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> delete(String inventoryId) async {
    try {
      await _repository.deleteInventory(inventoryId);
      await load();
      return state is InventoriesLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  void _emitOperationError(Object error) {
    final message = _messageFor(error);
    final currentState = state;
    if (currentState is InventoriesLoaded) {
      emit(InventoriesLoaded(currentState.items, errorMessage: message));
    } else {
      emit(InventoriesFailure(message));
    }
  }

  String _messageFor(Object error) =>
      error is FormatException ? error.message : error.toString();
}
