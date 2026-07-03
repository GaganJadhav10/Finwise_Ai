import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/expense_model.dart';

class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  Future<File> generateExpenseReport({
    required List<ExpenseModel> expenses,
    required String periodLabel,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('FinWise AI - Expense Report',
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Period: $periodLabel'),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Income: Rs. ${totalIncome.toStringAsFixed(2)}'),
              pw.Text('Total Expense: Rs. ${totalExpense.toStringAsFixed(2)}'),
              pw.Text(
                  'Net: Rs. ${(totalIncome - totalExpense).toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Date', 'Category', 'Description', 'Method', 'Amount'],
            data: expenses
                .map((e) => [
                      '${e.date.day}/${e.date.month}/${e.date.year}',
                      e.category,
                      e.description,
                      e.paymentMethod,
                      '${e.isIncome ? '+' : '-'}Rs. ${e.amount.toStringAsFixed(2)}',
                    ])
                .toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/finwise_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<File> generateCsvReport(List<ExpenseModel> expenses) async {
    final rows = <List<dynamic>>[
      ['Date', 'Category', 'Description', 'Payment Method', 'Type', 'Amount'],
      ...expenses.map((e) => [
            '${e.date.day}/${e.date.month}/${e.date.year}',
            e.category,
            e.description,
            e.paymentMethod,
            e.isIncome ? 'Income' : 'Expense',
            e.amount,
          ]),
    ];
    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/finwise_report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);
    return file;
  }

  Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> printReport(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfFile.readAsBytes(),
    );
  }
}
