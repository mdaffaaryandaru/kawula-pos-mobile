import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/discount_definition.dart';
import '../../domain/repositories/discounts_repository.dart';

sealed class DiscountsState {
  const DiscountsState();
}

final class DiscountsLoading extends DiscountsState {
  const DiscountsLoading();
}

final class DiscountsLoaded extends DiscountsState {
  const DiscountsLoaded({required this.discounts, this.errorMessage});

  final List<DiscountDefinition> discounts;
  final String? errorMessage;
}

final class DiscountsFailure extends DiscountsState {
  const DiscountsFailure(this.message);

  final String message;
}

class DiscountsCubit extends Cubit<DiscountsState> {
  DiscountsCubit(this._repository) : super(const DiscountsLoading());

  final DiscountsRepository _repository;

  Future<void> load() async {
    emit(const DiscountsLoading());
    try {
      emit(DiscountsLoaded(discounts: await _repository.getDiscounts()));
    } catch (error) {
      emit(DiscountsFailure(_messageFor(error)));
    }
  }

  Future<bool> save({
    String? discountId,
    required String name,
    required DiscountType type,
    required num value,
    required String description,
    required bool isActive,
  }) async {
    try {
      await _repository.saveDiscount(
        discountId: discountId,
        name: name,
        type: type,
        value: value,
        description: description,
        isActive: isActive,
      );
      await load();
      return state is DiscountsLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> delete(String discountId) async {
    try {
      await _repository.deleteDiscount(discountId);
      await load();
      return state is DiscountsLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  void _emitOperationError(Object error) {
    final currentState = state;
    if (currentState is DiscountsLoaded) {
      emit(
        DiscountsLoaded(
          discounts: currentState.discounts,
          errorMessage: _messageFor(error),
        ),
      );
    } else {
      emit(DiscountsFailure(_messageFor(error)));
    }
  }

  String _messageFor(Object error) =>
      error is FormatException ? error.message : error.toString();
}
