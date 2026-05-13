import 'dart:io';
import 'package:flutter/services.dart';
import 'package:ekubee/models/report_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

import 'file_handle_api.dart';

class PdfInvoiceApi {
  static Future<File> generate(
    PdfColor color,
    pw.Font fontFamily,
    String type,
    String date,
    String result,
    String imagepath,
    ReportDataResponse reportDataResponse,
  ) async {
    final pdf = pw.Document();

    Future<Uint8List> loadNetworkImage(String url) async {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to load image');
      }
    }

    final iconImage =
        (await rootBundle.load("assets/splash.png")).buffer.asUint8List();

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            // Header Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                        textScaleFactor: 1.0,
                        'Hello Cloud',
                        style: pw.TextStyle(
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                            color: color,
                            font: fontFamily)),
                    pw.Text(
                        textScaleFactor: 1.0,
                        'Business Trading P.L.C',
                        style: pw.TextStyle(
                            fontSize: 15, color: color, font: fontFamily)),
                  ],
                ),
                pw.Image(pw.MemoryImage(iconImage), height: 60, width: 60),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                        textScaleFactor: 1.0,
                        'Statement Date: ${DateFormat("MMM dd, yyyy").format(DateTime.parse(date))}',
                        style: pw.TextStyle(
                            fontSize: 12, color: color, font: fontFamily)),
                    pw.Text(
                        textScaleFactor: 1.0,
                        'Hello Equb',
                        style: pw.TextStyle(
                            fontSize: 12, color: color, font: fontFamily)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),

            // Equb Info
            pw.Text(
                textScaleFactor: 1.0,
                'Equb Information',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: color,
                    font: fontFamily)),
            pw.SizedBox(height: 10),
            pw.Text(
                textScaleFactor: 1.0,
                'Equb Name: ${reportDataResponse.data?.equbName}',
                style:
                    pw.TextStyle(fontSize: 12, color: color, font: fontFamily)),
            pw.Text(
                textScaleFactor: 1.0,
                'Equb Type: ${reportDataResponse.data?.equbType?.name}',
                style:
                    pw.TextStyle(fontSize: 12, color: color, font: fontFamily)),
            pw.Text(
                textScaleFactor: 1.0,
                'Equb Description: ${reportDataResponse.data?.equbType?.description}',
                style:
                    pw.TextStyle(fontSize: 12, color: color, font: fontFamily)),

            pw.SizedBox(height: 15),

            // Statement Table Header
            pw.Text(
                textScaleFactor: 1.0,
                'Account Transactions',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: color,
                    font: fontFamily)),
            pw.SizedBox(height: 5),
            pw.Table.fromTextArray(
              headers: [
                'Lottery No.',
                'Total Paid',
                'Claim Amount',
                'Guarantee'
              ],
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              border: pw.TableBorder.all(width: 0.5),
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerLeft,
              },
              data: reportDataResponse.data!.equbers!.map((equber) {
                return [
                  equber.lotteryNumber,
                  equber.totalPaid.toString(),
                  equber.claimAmount.toString(),
                  equber.guarantee?.fullName ?? 'N/A',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),

            pw.Text(
                textScaleFactor: 1.0,
                'Payment Details',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: color,
                    font: fontFamily)),
            pw.SizedBox(height: 5),
            for (var equber in reportDataResponse.data!.equbers!)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                      textScaleFactor: 1.0,
                      'Lottery Number: ${equber.lotteryNumber}',
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: color,
                          font: fontFamily)),
                  pw.Table.fromTextArray(
                    headers: ['Payment ID', 'Amount', 'Date'],
                    cellAlignment: pw.Alignment.centerLeft,
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900),
                    headerDecoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    border: pw.TableBorder.all(width: 0.5),
                    cellHeight: 25,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerRight,
                      2: pw.Alignment.center,
                    },
                    data: equber.payments!.map((payment) {
                      return [
                        payment.paymentId,
                        payment.amount.toString(),
                        payment.createdAt!.toLocal().toString().split(' ')[0],
                      ];
                    }).toList(),
                  ),
                  pw.SizedBox(height: 10),
                ],
              ),
          ];
        },
        footer: (context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Divider(),
              pw.Text(
                  textScaleFactor: 1.0,
                  'Hello Cloud Business Trading P.L.C',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: color,
                      font: fontFamily)),
              pw.Text(
                  textScaleFactor: 1.0,
                  'Address: Addis Ababa, Ethiopia',
                  style: pw.TextStyle(color: color, font: fontFamily)),
              pw.Text(
                  textScaleFactor: 1.0,
                  'Email: helloapp@gmail.com',
                  style: pw.TextStyle(color: color, font: fontFamily)),
              pw.Text(
                  textScaleFactor: 1.0,
                  'Contact: +251-XXXXXXX',
                  style: pw.TextStyle(color: color, font: fontFamily)),
            ],
          );
        },
      ),
    );

    return FileHandleApi.saveDocument(name: 'Equb_Statement.pdf', pdf: pdf);
  }
}
