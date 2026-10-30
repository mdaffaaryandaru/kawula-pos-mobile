import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/outlet.dart';
import '../../domain/repositories/outlets_repository.dart';

sealed class OutletsState {
  const OutletsState();
}

final class OutletsLoading extends OutletsState {
  const OutletsLoading();
}

final class OutletsLoaded extends OutletsState {
  const OutletsLoaded({required this.outlets, this.errorMessage});

  final List<Outlet> outlets;
  final String? errorMessage;
}

final class OutletsFailure extends OutletsState {
  const OutletsFailure(this.message);

  final String message;
}

class OutletsCubit extends Cubit<OutletsState> {
  OutletsCubit(this._repository) : super(const OutletsLoading());

  final OutletsRepository _repository;

  Future<void> load() async {
    emit(const OutletsLoading());
    try {
      emit(OutletsLoaded(outlets: await _repository.getOutlets()));
    } catch (error) {
      emit(OutletsFailure(_messageFor(error)));
    }
  }

  Future<bool> saveOutlet({
    String? outletId,
    required String name,
    required String code,
    required String address,
    required String phone,
    required bool isActive,
  }) async {
    try {
      await _repository.saveOutlet(
        outletId: outletId,
        name: name,
        code: code,
        address: address,
        phone: phone,
        isActive: isActive,
      );
      await load();
      return state is OutletsLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> deleteOutlet(String outletId) async {
    try {
      await _repository.deleteOutlet(outletId);
      await load();
      return state is OutletsLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  void _emitOperationError(Object error) {
    final currentState = state;
    if (currentState is OutletsLoaded) {
      emit(
        OutletsLoaded(
          outlets: currentState.outlets,
          errorMessage: _messageFor(error),
        ),
      );
    } else {
      emit(OutletsFailure(_messageFor(error)));
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
