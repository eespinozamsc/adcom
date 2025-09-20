import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ViewPdfArchivosPage extends StatefulWidget {
  final dynamic urlPdf;
  final dynamic nombrePdf;
  const ViewPdfArchivosPage(
      {super.key, required this.urlPdf, required this.nombrePdf});

  @override
  State<ViewPdfArchivosPage> createState() => _ViewPdfArchivosPageState();
}

class _ViewPdfArchivosPageState extends State<ViewPdfArchivosPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.nombrePdf)),
      body: SfPdfViewer.network('${widget.urlPdf}', key: _pdfViewerKey),
    );
  }
}
