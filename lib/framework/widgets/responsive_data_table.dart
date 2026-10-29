import 'package:flutter/material.dart';

class ResponsiveDataTable extends StatelessWidget {
  const ResponsiveDataTable({
    super.key,
    required this.minWidth,
    required this.columns,
    required this.rows,
    this.headingRowColor,
    this.decoration,
    this.horizontalMargin,
    this.columnSpacing,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
    this.verticalScroll = false,
  });

  final double minWidth;
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final WidgetStateProperty<Color?>? headingRowColor;
  final Decoration? decoration;
  final double? horizontalMargin;
  final double? columnSpacing;
  final double? dataRowMinHeight;
  final double? dataRowMaxHeight;
  final bool verticalScroll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final table = DataTable(
      headingRowColor:
          headingRowColor ??
          WidgetStatePropertyAll(
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: .3),
          ),
      horizontalMargin: horizontalMargin,
      columnSpacing: columnSpacing,
      dataRowMinHeight: dataRowMinHeight,
      dataRowMaxHeight: dataRowMaxHeight,
      columns: columns,
      rows: rows,
    );
    final horizontalTable = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: table,
      ),
    );
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration:
          decoration ??
          BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(20),
          ),
      child: verticalScroll
          ? SingleChildScrollView(child: horizontalTable)
          : horizontalTable,
    );
  }
}
