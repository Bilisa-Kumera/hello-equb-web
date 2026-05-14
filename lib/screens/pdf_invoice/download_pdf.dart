// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/models/report_model.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pdf/pdf.dart';
import '../../utils/secure_storage.dart';
import 'file_handle_api.dart';
import 'pdf_invoice_api.dart';
import 'package:pdf/widgets.dart' as pw;

class DownloadPdf extends StatefulWidget {
  final String type, date, result, image;
  const DownloadPdf(
      {Key? key,
      required this.type,
      required this.date,
      required this.result,
      required this.image})
      : super(key: key);

  @override
  State<DownloadPdf> createState() => _HomePageState();
}

class _HomePageState extends State<DownloadPdf> {
  PdfColor themeColor = PdfColors.black;
  pw.Font font = pw.Font.courier();
  String? type, date, result, image;

  @override
  void initState() {
    type = widget.type;
    date = widget.date;
    result = widget.result;
    image = widget.image;
    getReportData();
    super.initState();
  }

  bool clicked = false;
  ReportDataResponse? reportDataResponse;
  void getReportData() async {
    // Initialize Dio
    final Dio dio = Dio();

    try {
      // Set base options if needed
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);
      dio.options.responseType = ResponseType.plain; // Allow raw text response

      String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
      dio.options.headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };
      dio.options.responseType = ResponseType.json; 

      // Perform the GET request
      final response = await dio.get(getEqubReportUrl + widget.type);

      if (response.statusCode == 200) {
        if (response.data is String) {
          final decodedData = jsonDecode(response.data) as Map<String, dynamic>;
          reportDataResponse = ReportDataResponse.fromJson(decodedData);
        } else if (response.data is Map<String, dynamic>) {
          reportDataResponse = ReportDataResponse.fromJson(response.data);
        }
      }
    } on DioError catch (e) {
      // Handle Dio-specific errors
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppColors.green,
        title: const Text(
          textScaleFactor: 1.0,
          'Download PDF',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown for selecting text color
            const Text(
              textScaleFactor: 1.0,
              'Text Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8.0),
            DropdownButtonFormField(
              decoration: InputDecoration(
                hintText: 'Select text color (optional)',
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: PdfColors.black,
                  child: Text(textScaleFactor: 1.0, 'Black'),
                ),
                DropdownMenuItem(
                  value: PdfColors.grey900,
                  child: Text(textScaleFactor: 1.0, 'Dark Grey'),
                ),
                DropdownMenuItem(
                  value: PdfColors.green,
                  child: Text(textScaleFactor: 1.0, 'Green'),
                ),
                DropdownMenuItem(
                  value: PdfColors.blue,
                  child: Text(textScaleFactor: 1.0, 'Blue'),
                ),
                DropdownMenuItem(
                  value: PdfColors.orange,
                  child: Text(textScaleFactor: 1.0, 'Orange'),
                ),
                DropdownMenuItem(
                  value: PdfColors.cyan,
                  child: Text(textScaleFactor: 1.0, 'Cyan'),
                ),
                DropdownMenuItem(
                  value: PdfColors.red,
                  child: Text(textScaleFactor: 1.0, 'Red'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  themeColor = value as PdfColor;
                });
              },
            ),
            const SizedBox(height: 24.0),

            // Dropdown for selecting font type
            const Text(
              textScaleFactor: 1.0,
              'Font Style',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8.0),
            DropdownButtonFormField(
              decoration: InputDecoration(
                hintText: 'Select text font (optional)',
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: pw.Font.courier,
                  child: Text(textScaleFactor: 1.0, 'Courier'),
                ),
                DropdownMenuItem(
                  value: pw.Font.helvetica,
                  child: Text(textScaleFactor: 1.0, 'Helvetica'),
                ),
                DropdownMenuItem(
                  value: pw.Font.times,
                  child: Text(textScaleFactor: 1.0, 'Times'),
                ),
                DropdownMenuItem(
                  value: pw.Font.zapfDingbats,
                  child: Text(textScaleFactor: 1.0, 'ZapfDingbats'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    font = value();
                  });
                }
              },
            ),
            const Spacer(),

            // Download and open button
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: clicked
                    ? null
                    : () async {
                        if (type == null ||
                            date == null ||
                            result == null ||
                            image == null ||
                            reportDataResponse == null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text(AppKeys.errorTryAgain.tr(context))));
                          return; // Exit early to prevent calling the PDF generation function
                        }

                        setState(() {
                          clicked = true;
                        });

                        try {
                          // Generate PDF file
                          final pdfBytes = await PdfInvoiceApi.generateBytes(
                              themeColor,
                              pw.Font.courier(),
                              type!,
                              date!,
                              result!,
                              image!,
                              reportDataResponse! // This will no longer throw an error as we've ensured it's not null
                              );

                          await FileHandleApi.openPdfBytes(
                            bytes: pdfBytes,
                            name: 'Equb_Statement.pdf',
                          );
                        } catch (e) {
                          // Handle any errors during PDF generation or opening
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("An error occurred: $e")));
                        } finally {
                          setState(() {
                            clicked = false;
                          });
                        }
                      },
                icon: clicked
                    ? Center(
                        child: LoadingAnimationWidget.threeRotatingDots(
                          color: AppColors.vibrantGreen,
                          size: 30,
                        ),
                      )
                    : const Icon(Icons.download, color: AppColors.white),
                label: const Text(
                  textScaleFactor: 1.0,
                  'Download and Open',
                  style: TextStyle(
                      color: AppColors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
