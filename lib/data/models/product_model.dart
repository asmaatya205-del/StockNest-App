class ProductModel {
  final int? id;
  final String name;
  final String? sku;
  final String? category;
  final String? unit;
  final int userId;
  final String createdAt;

  ProductModel({
    this.id,
    required this.name,
    this.sku,
    this.category,
    this.unit,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id':         id,
    'name':       name,
    'sku':        sku,
    'category':   category,
    'unit':       unit,
    'user_id':    userId,
    'created_at': createdAt,
  };

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
    id:        map['id'],
    name:      map['name'],
    sku:       map['sku'],
    category:  map['category'],
    unit:      map['unit'],
    userId:    map['user_id'],
    createdAt: map['created_at'],
  );

  ProductModel copyWith({
    int? id, String? name, String? sku, String? category,
    String? unit, int? userId, String? createdAt,
  }) {
    return ProductModel(
      id:        id        ?? this.id,
      name:      name      ?? this.name,
      sku:       sku       ?? this.sku,
      category:  category  ?? this.category,
      unit:      unit      ?? this.unit,
      userId:    userId    ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}