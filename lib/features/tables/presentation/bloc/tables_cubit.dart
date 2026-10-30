import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../table_areas/domain/entities/table_area.dart';
import '../../../table_areas/domain/repositories/table_areas_repository.dart';
import '../../domain/entities/managed_table.dart';
import '../../domain/repositories/tables_repository.dart';

sealed class TablesState {
  const TablesState();
}

final class TablesLoading extends TablesState {
  const TablesLoading();
}

final class TablesLoaded extends TablesState {
  const TablesLoaded({
    required this.tables,
    required this.areas,
    this.errorMessage,
  });

  final List<ManagedTable> tables;
  final List<TableArea> areas;
  final String? errorMessage;
}

final class TablesFailure extends TablesState {
  const TablesFailure(this.message);

  final String message;
}

class TablesCubit extends Cubit<TablesState> {
  TablesCubit(this._repository, this._areasRepository)
    : super(const TablesLoading());

  final TablesRepository _repository;
  final TableAreasRepository _areasRepository;

  Future<void> load() async {
    emit(const TablesLoading());
    try {
      final tables = await _repository.getTables();
      final areas = await _areasRepository.getTableAreas();
      emit(TablesLoaded(tables: tables, areas: areas));
    } catch (error) {
      emit(TablesFailure(_messageFor(error)));
    }
  }

  Future<bool> saveTable({
    String? tableId,
    required String name,
    required String areaId,
    required int capacity,
    required String status,
    required bool isActive,
  }) async {
    try {
      await _repository.saveTable(
        tableId: tableId,
        name: name,
        areaId: areaId,
        capacity: capacity,
        status: status,
        isActive: isActive,
      );
      await load();
      return state is TablesLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> deleteTable(String tableId) async {
    try {
      await _repository.deleteTable(tableId);
      await load();
      return state is TablesLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  void _emitOperationError(Object error) {
    final currentState = state;
    if (currentState is TablesLoaded) {
      emit(
        TablesLoaded(
          tables: currentState.tables,
          areas: currentState.areas,
          errorMessage: _messageFor(error),
        ),
      );
    } else {
      emit(TablesFailure(_messageFor(error)));
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
