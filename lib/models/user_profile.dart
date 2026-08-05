class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.monthlyIncome,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final double monthlyIncome;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    int? id,
    String? name,
    double? monthlyIncome,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'monthly_income': monthlyIncome,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, Object?> map) {
    return UserProfile(
      id: map['id'] as int,
      name: map['name'] as String,
      monthlyIncome: (map['monthly_income'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
