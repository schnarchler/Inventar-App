class StorageLocation {
  final int? id;
  final String name;

  const StorageLocation({this.id, required this.name});

  StorageLocation copyWith({int? id, String? name}) =>
      StorageLocation(id: id ?? this.id, name: name ?? this.name);

  Map<String, Object?> toMap() => {'id': id, 'name': name};

  factory StorageLocation.fromMap(Map<String, Object?> map) =>
      StorageLocation(id: map['id'] as int?, name: map['name'] as String);
}
