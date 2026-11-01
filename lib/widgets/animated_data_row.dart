import 'package:flutter/material.dart';

DataRow animatedDataRow({
  required List<DataCell> cells,
  bool isHighlighted = false,
  Color? color,
  void Function(bool?)? onSelectChanged,
  bool selected = false,
  LocalKey? key,
}) {
  return DataRow(
    key: key,
    selected: selected,
    onSelectChanged: onSelectChanged,
    color: isHighlighted
        ? WidgetStateProperty.all(const Color(0xFF0C3860))
        : (color != null ? WidgetStateProperty.all(color) : null),
    cells: cells,
  );
}
