import 'print_helper_stub.dart'
    if (dart.library.html) 'print_helper_web.dart' as printer;

class PrintHelper {
  static void printReceipt(Map<String, dynamic> sale) {
    printer.printReceiptHtml(sale);
  }

  static void printSalesReport(List<Map<String, dynamic>> sales, String dateRange) {
    printer.printSalesReportHtml(sales, dateRange);
  }

  static void printBatchQrSheet(List<Map<String, String>> items) {
    printer.printBatchQrSheetHtml(items);
  }
}
