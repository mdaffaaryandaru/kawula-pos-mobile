import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../outlets/domain/entities/outlet.dart';
import '../../../outlets/domain/repositories/outlets_repository.dart';
import '../../domain/entities/table_area.dart';
import '../../domain/repositories/table_areas_repository.dart';

sealed class TableAreasState {
  const TableAreasState();
}

final class TableAreasLoading extends TableAreasState {
  const TableAreasLoading();
}

final class TableAreasLoaded extends TableAreasState {
  const TableAreasLoaded({
    required this.areas,
    required this.outlets,
    this.errorMessage,
  });

  final List<TableArea> areas;
  final List<Outlet> outlets;
  final String? errorMessage;
}

final class TableAreasFailure extends TableAreasState {
  const TableAreasFailure(this.message);

  final String message;
}

class TableAreasCubit extends Cubit<TableAreasState> {
  TableAreasCubit(this._repository, this._outletsRepository)
    : super(const TableAreasLoading());

  final TableAreasRepository _repository;
  final OutletsRepository _outletsRepository;

  Future<void> load() async {
    emit(const TableAreasLoading());
    try {
      final areas = await _repository.getTableAreas();
      final outlets = await _outletsRepository.getOutlets();
      emit(TableAreasLoaded(areas: areas, outlets: outlets));
    } catch (error) {
      emit(TableAreasFailure(_messageFor(error)));
    }
  }

  Future<bool> saveTableArea({
    String? areaId,
    required String name,
    required String outletId,
    required String description,
    required bool isActive,
  }) async {
    try {
      await _repository.saveTableArea(
        areaId: areaId,
        name: name,
        outletId: outletId,
        description: description,
        isActive: isActive,
      );
      await load();
      return state is TableAreasLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> deleteTableArea(String areaId) async {
    try {
      await _repository.deleteTableArea(areaId);
      await load();
      return state is TableAreasLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  void _emitOperationError(Object error) {
    final currentState = state;
    if (currentState is TableAreasLoaded) {
      emit(
        TableAreasLoaded(
          areas: currentState.areas,
          outlets: currentState.outlets,
          errorMessage: _messageFor(error),
        ),
      );
    } else {
      emit(TableAreasFailure(_messageFor(error)));
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
