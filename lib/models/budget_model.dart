class BudgetModel {
  final String id;
  final String category;
  final double limit;
  final int month;
  final int year;

  BudgetModel({
    required this.id,
    required this.category,
    required this.limit,
    required this.month,
    required this.year,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    return BudgetModel(
      id: id,
      category: map['category'] ?? 'Others',
      limit: (map['limit'] ?? 0).toDouble(),
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limit': limit,
      'month': month,
      'year': year,
    };
  }
}
