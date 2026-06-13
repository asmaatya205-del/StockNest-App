class CategoryModel {
  final int?   id;
  final String name;
  final String icon;
  final bool   isDefault;
  final int?   userId;

  const CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    this.isDefault = false,
    this.userId,
  });

  Map<String, dynamic> toMap() => {
    'id':         id,
    'name':       name,
    'icon':       icon,
    'is_default': isDefault ? 1 : 0,
    'user_id':    userId,
  };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
    id:        map['id'],
    name:      map['name'],
    icon:      map['icon'] ?? '📦',
    isDefault: (map['is_default'] ?? 0) == 1,
    userId:    map['user_id'],
  );
}
 