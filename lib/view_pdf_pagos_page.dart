import 'dart:typed_data';

import 'package:esys_flutter_share_plus/esys_flutter_share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:io';

class ViewPdfPagosPage extends StatefulWidget {
  final dynamic urlPdf;
  final dynamic conceptoDesc;
  const ViewPdfPagosPage(
      {Key? key, required this.urlPdf, required this.conceptoDesc})
      : super(key: key);

  @override
  State<ViewPdfPagosPage> createState() => _ViewPdfPagosPageState();
}

class _ViewPdfPagosPageState extends State<ViewPdfPagosPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  Future<void> _downloadPdf() async {
    print(widget.urlPdf);
    final response = await http.get(Uri.parse(widget.urlPdf));
    final Uint8List bytes = response.bodyBytes;
    final fileName = widget.conceptoDesc + '.pdf';
    await Share.file(
      'Compartir archivo PDF',
      fileName,
      bytes.buffer.asUint8List(),
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recibo de pago')),
      body: SfPdfViewer.network('${widget.urlPdf}', key: _pdfViewerKey),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _downloadPdf,
        tooltip: 'Descargar PDF',
        child: Icon(Icons.download),
      ),
    );
  }
}
