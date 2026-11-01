// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

String _determineClassification(Map<String, dynamic> item) {
  final invNum = (item['invoice_number'] ?? item['receipt_number'] ?? item['order_number'] ?? item['id'] ?? '').toString().toUpperCase();
  final orderType = (item['order_type'] ?? '').toString().trim().toLowerCase();
  final bool isWalkInFlag = item['is_walk_in'] == true;

  if (orderType == 'online' || orderType == 'app' || orderType == 'delivery' || invNum.contains('ORD-') || invNum.startsWith('ORD') || invNum.startsWith('APP-')) {
    return 'Online';
  }

  if (isWalkInFlag || orderType == 'pos' || orderType == 'walk_in' || orderType == 'walk-in' || invNum.contains('POS-') || invNum.startsWith('POS')) {
    return 'Walk-In';
  }

  final fulfillment = (item['fulfillment_type'] ?? item['notes'] ?? '').toString().toLowerCase();
  if (fulfillment.contains('delivery') || fulfillment.contains('online')) {
    return 'Online';
  }

  if (item['classification'] != null && item['classification'].toString().isNotEmpty) {
    final c = item['classification'].toString().trim().toLowerCase();
    if (c == 'online' || c == 'app' || c == 'delivery') return 'Online';
    if (c == 'walk-in' || c == 'walk_in' || c == 'pos') return 'Walk-In';
  }

  return item['is_online_order'] == true ? 'Online' : 'Walk-In';
}

void _printHtmlInIframe(String htmlContent) {
  final existingIframe = html.document.getElementById('aquasync_print_iframe');
  if (existingIframe != null) {
    existingIframe.remove();
  }

  final iframe = html.IFrameElement()
    ..id = 'aquasync_print_iframe'
    ..style.position = 'fixed'
    ..style.right = '0'
    ..style.bottom = '0'
    ..style.width = '0'
    ..style.height = '0'
    ..style.border = '0'
    ..style.visibility = 'hidden';

  html.document.body!.children.add(iframe);

  final dynamic win = iframe.contentWindow;
  if (win != null) {
    win.document.open();
    win.document.write(htmlContent);
    win.document.close();

    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        win.focus();
        win.print();
      } catch (_) {
        final popupWin = html.window.open('', '_blank', 'width=850,height=850');
        final dynamic pDoc = (popupWin as dynamic).document;
        pDoc.open();
        pDoc.write(htmlContent);
        pDoc.close();
        Future.delayed(const Duration(milliseconds: 300), () {
          (popupWin as dynamic).focus();
          (popupWin as dynamic).print();
        });
      }
    });
  }
}

void printReceiptHtml(Map<String, dynamic> sale) {
  final idStr = sale['id']?.toString() ?? '';
  final shortId = idStr.length >= 8 ? idStr.substring(0, 8).toUpperCase() : '001';
  final invoiceNum = sale['invoice_number']?.toString() ?? 'INV-$shortId';
  final receiptNum = sale['receipt_number']?.toString() ?? 'RCP-$shortId';
  final custStr = sale['customer_name']?.toString() ?? sale['notes']?.toString() ?? 'Customer';
  final payMethod = (sale['payment_method']?.toString() ?? 'Cash').toUpperCase();
  final classification = _determineClassification(sale);
  final totalAmt = (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
  final cashReceived = (sale['cash_received'] as num?)?.toDouble() ?? totalAmt;
  final changeAmount = (sale['change_amount'] as num?)?.toDouble() ?? 0.0;
  final timeStr = sale['created_at']?.toString().replaceAll('T', ' ').split('.').first ?? 'Today';
  final items = (sale['sale_items'] as List<dynamic>?) ?? (sale['order_items'] as List<dynamic>?) ?? [];

  String cashierName = sale['cashier_name']?.toString() ?? 'Admin / Cashier';
  if (sale['cashier'] != null && sale['cashier']['full_name'] != null) {
    cashierName = sale['cashier']['full_name'].toString();
  }

  final itemsHtml = items.map((item) {
    final pName = item['product_name']?.toString() ?? item['name']?.toString() ?? 'Product Item';
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final price = (item['unit_price'] as num?)?.toDouble() ?? (item['price'] as num?)?.toDouble() ?? 0.0;
    final sub = (item['subtotal'] as num?)?.toDouble() ?? (qty * price);
    return '''
      <tr>
        <td style="padding: 8px; border-bottom: 1px solid #e2e8f0;">$pName</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e2e8f0;">$qty</td>
        <td style="padding: 8px; text-align: right; border-bottom: 1px solid #e2e8f0;">₱${price.toStringAsFixed(2)}</td>
        <td style="padding: 8px; text-align: right; border-bottom: 1px solid #e2e8f0; font-weight: bold;">₱${sub.toStringAsFixed(2)}</td>
      </tr>
    ''';
  }).join('');

  final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Invoice - $invoiceNum</title>
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; color: #1e293b; background: #fff; }
        .receipt-card { max-width: 480px; margin: 0 auto; border: 1px solid #cbd5e1; padding: 24px; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); }
        .header { text-align: center; border-bottom: 2px dashed #0284c7; padding-bottom: 16px; margin-bottom: 16px; }
        .header h2 { margin: 0; color: #0284c7; font-size: 24px; font-weight: 800; letter-spacing: -0.5px; }
        .header p { margin: 4px 0 0 0; color: #64748b; font-size: 13px; }
        .badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: bold; background: #e0f2fe; color: #0369a1; text-transform: uppercase; letter-spacing: 0.5px; }
        .info-table { width: 100%; margin-bottom: 16px; font-size: 13px; border-collapse: collapse; }
        .info-table td { padding: 5px 0; }
        .items-table { width: 100%; border-collapse: collapse; margin-bottom: 16px; font-size: 13px; }
        .items-table th { background: #f1f5f9; padding: 8px; text-align: left; color: #475569; font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; }
        .total-section { border-top: 2px solid #0284c7; padding-top: 12px; font-size: 14px; }
        .total-row { display: flex; justify-content: space-between; font-weight: bold; font-size: 18px; color: #0284c7; margin-top: 6px; }
        .footer { text-align: center; margin-top: 24px; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; padding-top: 16px; }
        @media print {
          body { margin: 0; }
          .receipt-card { border: none; box-shadow: none; width: 100%; max-width: 100%; }
        }
      </style>
    </head>
    <body>
      <div class="receipt-card">
        <div class="header">
          <h2>AquaSync</h2>
          <p>Official Sales & Revenue Receipt</p>
          <div style="margin-top: 8px;">
            <span class="badge" style="${classification == 'Online' ? 'background: #e0e7ff; color: #3730a3;' : ''}">$classification</span>
          </div>
        </div>
        
        <table class="info-table">
          <tr><td><strong>Invoice #:</strong> $invoiceNum</td><td style="text-align: right;"><strong>Date:</strong> $timeStr</td></tr>
          <tr><td><strong>Receipt #:</strong> $receiptNum</td><td style="text-align: right;"><strong>Payment:</strong> $payMethod</td></tr>
          <tr><td><strong>Customer:</strong> $custStr</td><td style="text-align: right;"><strong>Staff:</strong> $cashierName</td></tr>
        </table>
        
        <table class="items-table">
          <thead>
            <tr>
              <th>Item</th>
              <th style="text-align: center;">Qty</th>
              <th style="text-align: right;">Price</th>
              <th style="text-align: right;">Total</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml.isNotEmpty ? itemsHtml : '<tr><td colspan="4" style="text-align:center; padding:12px; color:#94a3b8;">General Water Refill / Product Purchase</td></tr>'}
          </tbody>
        </table>
        
        <div class="total-section">
          <div style="display: flex; justify-content: space-between;">
            <span>Subtotal:</span>
            <span>₱${totalAmt.toStringAsFixed(2)}</span>
          </div>
          <div class="total-row">
            <span>TOTAL AMOUNT:</span>
            <span>₱${totalAmt.toStringAsFixed(2)}</span>
          </div>
          ${payMethod == 'CASH' ? '''
          <div style="display: flex; justify-content: space-between; font-size: 12px; margin-top: 6px; color: #64748b;">
            <span>Cash Received: ₱${cashReceived.toStringAsFixed(2)}</span>
            <span>Change: ₱${changeAmount.toStringAsFixed(2)}</span>
          </div>
          ''' : ''}
        </div>
        
        <div class="footer">
          <p><strong>Thank you for choosing AquaSync!</strong></p>
          <p>This document serves as an official proof of sales transaction.</p>
        </div>
      </div>
    </body>
    </html>
  ''';

  _printHtmlInIframe(htmlContent);
}

void printSalesReportHtml(List<Map<String, dynamic>> sales, String dateRange) {
  final nowStr = DateTime.now().toString().replaceAll('T', ' ').split('.').first;
  
  double totalRevenue = 0.0;
  double cashRevenue = 0.0;
  double gcashRevenue = 0.0;
  int walkInCount = 0;
  int onlineCount = 0;

  final rowsHtml = sales.map((sale) {
    final idStr = sale['id']?.toString() ?? '';
    final shortId = idStr.length >= 8 ? idStr.substring(0, 8).toUpperCase() : '001';
    final invoiceNum = sale['invoice_number']?.toString() ?? 'INV-$shortId';
    final receiptNum = sale['receipt_number']?.toString() ?? 'RCP-$shortId';
    final custStr = sale['customer_name']?.toString() ?? sale['notes']?.toString() ?? 'Customer';
    final payMethod = (sale['payment_method']?.toString() ?? 'Cash').toUpperCase();
    final classification = _determineClassification(sale);
    final totalAmt = (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
    final timeStr = sale['created_at']?.toString().replaceAll('T', ' ').split('.').first ?? 'Today';

    totalRevenue += totalAmt;
    if (payMethod.contains('GCASH') || payMethod.contains('ONLINE') || payMethod.contains('PAYMONGO')) {
      gcashRevenue += totalAmt;
    } else {
      cashRevenue += totalAmt;
    }

    if (classification == 'Online') {
      onlineCount++;
    } else {
      walkInCount++;
    }

    final classBadgeStyle = classification == 'Online'
        ? 'background: #e0e7ff; color: #3730a3;'
        : 'background: #e0f2fe; color: #0369a1;';

    return '''
      <tr>
        <td style="padding: 10px 8px; border-bottom: 1px solid #e2e8f0; font-weight: bold; color: #0284c7;">
          $invoiceNum<br><span style="font-size: 11px; font-weight: normal; color: #64748b;">$receiptNum</span>
        </td>
        <td style="padding: 10px 8px; border-bottom: 1px solid #e2e8f0; font-weight: 600;">$custStr</td>
        <td style="padding: 10px 8px; border-bottom: 1px solid #e2e8f0; text-align: center;">
          <span style="display: inline-block; padding: 4px 8px; border-radius: 12px; font-size: 11px; font-weight: bold; $classBadgeStyle">$classification</span>
        </td>
        <td style="padding: 10px 8px; border-bottom: 1px solid #e2e8f0; text-align: center;">$payMethod</td>
        <td style="padding: 10px 8px; border-bottom: 1px solid #e2e8f0; text-align: right; font-weight: bold;">₱${totalAmt.toStringAsFixed(2)}</td>
        <td style="padding: 10px 8px; border-bottom: 1px solid #e2e8f0; text-align: right; color: #64748b; font-size: 12px;">$timeStr</td>
      </tr>
    ''';
  }).join('');

  final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Sales & Revenue Report - ${dateRange.toUpperCase()}</title>
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 30px; color: #0f172a; background: #fff; }
        .report-header { display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #0284c7; padding-bottom: 16px; margin-bottom: 24px; }
        .report-title { color: #0284c7; font-size: 26px; font-weight: 800; margin: 0; }
        .report-subtitle { color: #64748b; font-size: 13px; margin-top: 4px; }
        .meta-box { text-align: right; font-size: 12px; color: #64748b; }
        .kpi-container { display: flex; gap: 16px; margin-bottom: 24px; }
        .kpi-card { flex: 1; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 14px; text-align: center; }
        .kpi-label { font-size: 11px; font-weight: bold; color: #64748b; text-transform: uppercase; }
        .kpi-val { font-size: 20px; font-weight: 800; color: #0284c7; margin-top: 4px; }
        .kpi-sub { font-size: 11px; color: #475569; margin-top: 2px; }
        .report-table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; }
        .report-table th { background: #0284c7; color: #fff; padding: 10px 8px; text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; }
        .footer { margin-top: 32px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; padding-top: 16px; }
        @media print {
          body { margin: 15px; }
        }
      </style>
    </head>
    <body>
      <div class="report-header">
        <div>
          <h1 class="report-title">AquaSync</h1>
          <div class="report-subtitle">Sales & Revenue Analytics Report (${dateRange.toUpperCase()})</div>
        </div>
        <div class="meta-box">
          <div><strong>Generated:</strong> $nowStr</div>
          <div><strong>Total Transactions:</strong> ${sales.length}</div>
        </div>
      </div>

      <div class="kpi-container">
        <div class="kpi-card">
          <div class="kpi-label">Total Revenue</div>
          <div class="kpi-val">₱${totalRevenue.toStringAsFixed(2)}</div>
          <div class="kpi-sub">All completed sales</div>
        </div>
        <div class="kpi-card">
          <div class="kpi-label">Cash Receipts</div>
          <div class="kpi-val">₱${cashRevenue.toStringAsFixed(2)}</div>
          <div class="kpi-sub">${totalRevenue > 0 ? ((cashRevenue / totalRevenue) * 100).toStringAsFixed(1) : 0}% of total</div>
        </div>
        <div class="kpi-card">
          <div class="kpi-label">GCash Digital</div>
          <div class="kpi-val">₱${gcashRevenue.toStringAsFixed(2)}</div>
          <div class="kpi-sub">${totalRevenue > 0 ? ((gcashRevenue / totalRevenue) * 100).toStringAsFixed(1) : 0}% of total</div>
        </div>
        <div class="kpi-card">
          <div class="kpi-label">Classifications</div>
          <div class="kpi-val" style="color: #0f172a; font-size: 16px; margin-top: 8px;">$walkInCount Walk-In • $onlineCount Online</div>
          <div class="kpi-sub">Record distribution</div>
        </div>
      </div>

      <table class="report-table">
        <thead>
          <tr>
            <th>Invoice / Receipt #</th>
            <th>Customer / Note</th>
            <th style="text-align: center;">Classification</th>
            <th style="text-align: center;">Payment Method</th>
            <th style="text-align: right;">Total Amount</th>
            <th style="text-align: right;">Timestamp</th>
          </tr>
        </thead>
        <tbody>
          ${rowsHtml.isNotEmpty ? rowsHtml : '<tr><td colspan="6" style="text-align:center; padding:20px; color:#94a3b8;">No sales records found for this period.</td></tr>'}
        </tbody>
      </table>

      <div class="footer">
        <p>AquaSync Admin Control Center — System Generated Sales & Revenue Analytics Report</p>
      </div>
    </body>
    </html>
  ''';

  _printHtmlInIframe(htmlContent);
}

void printBatchQrSheetHtml(List<Map<String, String>> items) {
  final cardsHtml = items.map((item) {
    final code = item['code'] ?? '';
    final customer = item['customer'] ?? 'AQUAZONE STOCK';
    final type = item['type'] ?? 'Standard 5-Gallon';
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${Uri.encodeComponent(code)}';

    return '''
      <div class="qr-card">
        <div class="header">
          <div class="title">AQUAZONE</div>
          <div class="subtitle">WATER REFILL STATION</div>
        </div>
        <div class="qr-img-wrapper">
          <img src="$qrUrl" alt="QR Code" width="120" height="120"/>
        </div>
        <div class="code">$code</div>
        <div class="tag-box">
          <div class="tag-label">CONTAINER OWNER / LAST NAME</div>
          <div class="tag-value">$customer</div>
        </div>
        <div class="type-text">$type</div>
        <div class="footer">PROPERTY OF AQUAZONE • DO NOT SWAP</div>
      </div>
    ''';
  }).join('');

  final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <title>AQUAZONE Batch QR Code Sticker Sheet</title>
      <style>
        @page { size: A4; margin: 10mm; }
        body {
          font-family: Arial, sans-serif;
          margin: 0;
          padding: 10px;
          background: #ffffff;
          color: #0f172a;
        }
        .page-title {
          text-align: center;
          font-size: 18px;
          font-weight: bold;
          color: #0284c7;
          margin-bottom: 4px;
        }
        .page-subtitle {
          text-align: center;
          font-size: 11px;
          color: #64748b;
          margin-bottom: 18px;
        }
        .grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 12px;
        }
        .qr-card {
          border: 2px solid #0284c7;
          border-radius: 12px;
          padding: 10px;
          text-align: center;
          background: #ffffff;
          box-shadow: 0 2px 4px rgba(0,0,0,0.05);
          page-break-inside: avoid;
        }
        .header .title {
          font-size: 13px;
          font-weight: 900;
          color: #0284c7;
          letter-spacing: 1px;
        }
        .header .subtitle {
          font-size: 7px;
          font-weight: bold;
          color: #64748b;
          letter-spacing: 0.8px;
        }
        .qr-img-wrapper {
          margin: 6px 0;
        }
        .code {
          font-size: 11px;
          font-weight: 800;
          color: #0f172a;
          letter-spacing: 0.8px;
        }
        .tag-box {
          background: #e0f2fe;
          border: 1px solid #0284c7;
          border-radius: 6px;
          padding: 3px;
          margin: 5px 0;
        }
        .tag-label {
          font-size: 6.5px;
          font-weight: bold;
          color: #0369a1;
        }
        .tag-value {
          font-size: 12px;
          font-weight: 900;
          color: #075985;
        }
        .type-text {
          font-size: 7.5px;
          color: #475569;
          font-weight: 600;
        }
        .footer {
          font-size: 6px;
          font-weight: bold;
          color: #94a3b8;
          margin-top: 3px;
        }
      </style>
    </head>
    <body>
      <div class="page-title">AQUAZONE GALLON CONTAINER QR STICKER SHEET</div>
      <div class="page-subtitle">Generated Batch • Total Stickers: ${items.length} • 1-to-1 Container Identity</div>
      <div class="grid">
        $cardsHtml
      </div>
    </body>
    </html>
  ''';

  _printHtmlInIframe(htmlContent);
}
