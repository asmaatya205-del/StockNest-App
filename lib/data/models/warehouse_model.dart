class WarehouseModel {
  final int? id;
  final String name;
  final String? location;
  final String? description;
  final double? capacity;
  final int? parentId;
  final int userId;
  final String createdAt;

  WarehouseModel({
    this.id,
    required this.name,
    this.location,
    this.description,
    this.capacity,
    this.parentId,
    required this.userId,
    required this.createdAt,
  });

  bool get isRoot => parentId == null;

  @override
  bool operator ==(Object other) => other is WarehouseModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'location': location,
    'description': description,
    'capacity': capacity,
    'parent_id': parentId,
    'user_id': userId,
    'created_at': createdAt,
  };

  factory WarehouseModel.fromMap(Map<String, dynamic> map) => WarehouseModel(
    id: map['id'],
    name: map['name'],
    location: map['location'],
    description: map['description'],
    capacity: map['capacity'],
    parentId: map['parent_id'],
    userId: map['user_id'],
    createdAt: map['created_at'],
  );

  WarehouseModel copyWith({
    int? id,
    String? name,
    String? location,
    String? description,
    double? capacity,
    Object? parentId = _sentinel,
    int? userId,
    String? createdAt,
  }) {
    return WarehouseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
      capacity: capacity ?? this.capacity,
      parentId: parentId == _sentinel ? this.parentId : parentId as int?,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const Object _sentinel = Object();
  }
