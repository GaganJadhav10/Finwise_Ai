class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String currency;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.currency = 'INR',
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      currency: map['currency'] ?? 'INR',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? currency,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      currency: currency ?? this.currency,
      createdAt: createdAt,
    );
  }
}
