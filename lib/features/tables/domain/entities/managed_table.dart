class ManagedTable {
  const ManagedTable({
    required this.id,
    required this.name,
    required this.areaId,
    required this.areaName,
    required this.capacity,
    required this.status,
    required this.isActive,
  });

  final String id;
  final String name;
  final String areaId;
  final String areaName;
  final int capacity;
  final String status;
  final bool isActive;
}
