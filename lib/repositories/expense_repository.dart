import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/expense_model.dart';

/// Repository pattern: abstracts Firestore + Hive so providers never talk
/// to the data sources directly. Handles offline-first sync.
class ExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;
  late final Box _localBox;

  ExpenseRepository({required this.uid}) {
    _localBox = Hive.box('expenses_$uid');
  }

  CollectionReference get _collection =>
      _firestore.collection('users').doc(uid).collection('expenses');

  Stream<List<ExpenseModel>> watchExpenses() {
    return _collection.orderBy('date', descending: true).snapshots().map(
        (snap) => snap.docs
            .map((d) =>
                ExpenseModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<List<ExpenseModel>> getExpensesForRange(
      DateTime start, DateTime end) async {
    final snap = await _collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();
    return snap.docs
        .map((d) => ExpenseModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  Future<String> addExpense(ExpenseModel expense) async {
    try {
      final doc = await _collection.add(expense.toMap());
      return doc.id;
    } catch (_) {
      // Offline fallback: queue locally for later sync.
      final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      await _localBox.put(localId, expense.toMap());
      return localId;
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _collection.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _collection.doc(id).delete();
  }

  /// Pushes any locally-queued offline expenses to Firestore once online.
  Future<void> syncPendingExpenses() async {
    final pending = _localBox.toMap();
    for (final entry in pending.entries) {
      await _collection.add(entry.value as Map<String, dynamic>);
      await _localBox.delete(entry.key);
    }
  }
}
