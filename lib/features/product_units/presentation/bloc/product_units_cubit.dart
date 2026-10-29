import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product_unit.dart';
import '../../domain/repositories/product_units_repository.dart';

sealed class ProductUnitsState {
  const ProductUnitsState();
}

final class ProductUnitsLoading extends ProductUnitsState {
  const ProductUnitsLoading();
}

final class ProductUnitsLoaded extends ProductUnitsState {
  const ProductUnitsLoaded(this.units, {this.errorMessage});

  final List<ProductUnit> units;
  final String? errorMessage;
}

final class ProductUnitsFailure extends ProductUnitsState {
  const ProductUnitsFailure(this.message);

  final String message;
}

class ProductUnitsCubit extends Cubit<ProductUnitsState> {
  ProductUnitsCubit(this._repository) : super(const ProductUnitsLoading());

  final ProductUnitsRepository _repository;

  Future<void> load() async {
    emit(const ProductUnitsLoading());
    try {
      emit(ProductUnitsLoaded(await _repository.getProductUnits()));
    } catch (error) {
      emit(ProductUnitsFailure(_messageFor(error)));
    }
  }

  Future<bool> save({
    String? unitId,
    required String name,
    required String abbreviation,
    required String description,
    required bool isActive,
  }) async {
    final currentState = state;
    if (currentState is! ProductUnitsLoaded) return false;
    try {
      final saved = await _repository.saveProductUnit(
        unitId: unitId,
        name: name,
        abbreviation: abbreviation,
        description: description,
        isActive: isActive,
      );
      final units = unitId == null
          ? [...currentState.units, saved]
          : currentState.units
                .map((unit) => unit.id == unitId ? saved : unit)
                .toList(growable: false);
      emit(ProductUnitsLoaded(units));
      return true;
    } catch (error) {
      emit(
        ProductUnitsLoaded(
          currentState.units,
          errorMessage: _messageFor(error),
        ),
      );
      return false;
    }
  }

  Future<bool> delete(String unitId) async {
    final currentState = state;
    if (currentState is! ProductUnitsLoaded) return false;
    try {
      await _repository.deleteProductUnit(unitId);
      emit(
        ProductUnitsLoaded(
          currentState.units
              .where((unit) => unit.id != unitId)
              .toList(growable: false),
        ),
      );
      return true;
    } catch (error) {
      emit(
        ProductUnitsLoaded(
          currentState.units,
          errorMessage: _messageFor(error),
        ),
      );
      return false;
    }
  }

  String _messageFor(Object error) =>
      error is FormatException ? error.message : error.toString();
}
