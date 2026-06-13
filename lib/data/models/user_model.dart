class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
    'created_at': createdAt,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'],
    name: map['name'],
    email: map['email'],
    password: map['password'],
    createdAt: map['created_at'],
  );

  UserModel copyWith({int? id, String? name, String? email,
    String? password, String? createdAt}) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}