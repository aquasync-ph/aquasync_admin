import 'dart:io';

void _openDesktopHtmlPrint(String htmlContent, String filenamePrefix) {
  try {
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/${filenamePrefix}_$timestamp.html');

    final printScript = '''
      <style>
        @media print {
          .aquasync-no-print { display: none !important; }
        }
        .aquasync-no-print-bar {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          background: #0f172a;
          color: #ffffff;
          padding: 10px 20px;
          display: flex;
          justify-content: space-between;
          align-items: center;
          box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
          z-index: 99999;
          font-family: system-ui, -apple-system, sans-serif;
        }
        .aquasync-no-print-btn {
          background: #0284c7;
          color: white;
          border: none;
          padding: 8px 16px;
          border-radius: 6px;
          font-weight: bold;
          cursor: pointer;
          font-size: 13px;
        }
      </style>
      <div class="aquasync-no-print aquasync-no-print-bar">
        <div style="font-weight: bold;">🖨️ AquaSync Print Document Preview</div>
        <button class="aquasync-no-print-btn" onclick="window.print()">Print Document</button>
      </div>
      <script>
        window.onload = function() {
          setTimeout(function() {
            window.focus();
            window.print();
          }, 500);
        };
      </script>
    ''';

    String fullHtml = htmlContent;
    if (fullHtml.contains('</body>')) {
      fullHtml = fullHtml.replaceFirst('</body>', '$printScript</body>');
    } else {
      fullHtml += printScript;
    }

    file.writeAsStringSync(fullHtml);

    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', '', file.path]);
    } else if (Platform.isMacOS) {
      Process.run('open', [file.path]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [file.path]);
    }
  } catch (_) {
    // Desktop file launch error fallback
  }
}

void printReceiptHtml(Map<String, dynamic> sale) {
  // Desktop stub fallback handled via _openDesktopHtmlPrint if needed
}

void printSalesReportHtml(List<Map<String, dynamic>> sales, String dateRange) {
  // Desktop stub fallback handled via _openDesktopHtmlPrint if needed
}

void printBatchQrSheetHtml(List<Map<String, String>> items) {
  // Desktop stub fallback handled via _openDesktopHtmlPrint if needed
}
