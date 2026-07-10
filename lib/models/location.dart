class StorageLocation {
  final int? id;
  final String name;

  /// Farbe als ARGB-Wert; null = keine Farbe zugeordnet.
  final int? color;

  const StorageLocation({this.id, required this.name, this.color});

  Map<String, Object?> toMap() => {'id': id, 'name': name, 'color': color};

  factory StorageLocation.fromMap(Map<String, Object?> map) => StorageLocation(
        id: map['id'] as int?,
        name: map['name'] as String,
        color: map['color'] as int?,
      );
}
