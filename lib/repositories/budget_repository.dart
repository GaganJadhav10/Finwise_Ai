import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;

  BudgetRepository({required this.uid});

  CollectionReference get _collection =>
      _firestore.collection('users').doc(uid).collection('budgets');

  Stream<List<BudgetModel>> watchBudgets(int month, int year) {
    return _collection
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                BudgetModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<void> setBudget(BudgetModel budget) async {
    if (budget.id.isEmpty) {
      await _collection.add(budget.toMap());
    } else {
      await _collection.doc(budget.id).set(budget.toMap());
    }
  }

  Future<void> deleteBudget(String id) async {
    await _collection.doc(id).delete();
  }
}
