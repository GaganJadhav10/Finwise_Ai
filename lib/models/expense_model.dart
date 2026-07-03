import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String description;
  final String paymentMethod;
  final String? receiptUrl;
  final bool isIncome;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    required this.paymentMethod,
    this.receiptUrl,
    this.isIncome = false,
    required this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? 'Others',
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      description: map['description'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      receiptUrl: map['receiptUrl'],
      isIncome: map['isIncome'] ?? false,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'description': description,
      'paymentMethod': paymentMethod,
      'receiptUrl': receiptUrl,
      'isIncome': isIncome,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ExpenseModel copyWith({
    double? amount,
    String? category,
    DateTime? date,
    String? description,
    String? paymentMethod,
    String? receiptUrl,
    bool? isIncome,
  }) {
    return ExpenseModel(
      id: id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      isIncome: isIncome ?? this.isIncome,
      createdAt: createdAt,
    );
  }
}
