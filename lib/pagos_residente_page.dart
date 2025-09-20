import 'dart:convert';
import 'package:adcom/view_pdf_pagos_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:adcom/urlGlobal.dart';

class PagosResidentePage extends StatefulWidget {
  final dynamic idResidente;
  const PagosResidentePage({Key? key, required this.idResidente})
      : super(key: key);

  @override
  _PagosResidentePageState createState() => _PagosResidentePageState();
}

class _PagosResidentePageState extends State<PagosResidentePage> {
  String? saldo;
  String? bandera;
  List<Map<String, dynamic>> _allAdeudos = [];
  List<Map<String, dynamic>> _filterPagosUno = [];
  List<Map<String, dynamic>> _filterPagosCero = [];
  bool _showFilteredDebts = false;
  double _sumAdeudosCero = 0;
  bool _isLoading = true;
  bool _isLoadingPdf = false;
  int? _idResidente;

  @override
  void initState() {
    super.initState();
    _loadAdeudos().then((_) {
      _toggleDebts();
    });
  }

  Future<void> _loadAdeudos() async {
    setState(() {
      _isLoading = true;
    });

    setState(() {
      _idResidente = widget.idResidente.toList()[0];
    });

    String apiUrl = '${UrlGlobales.UrlBase}get-adeudos';
    final requestBody = {'usuarioId': _idResidente};

    try {
      final response = await http
          .post(Uri.parse(apiUrl), body: {"params": jsonEncode(requestBody)});
      final responseBody = json.decode(response.body);
      print(responseBody);

      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          _allAdeudos = List<Map<String, dynamic>>.from(responseBody['data']);
          _allAdeudos.sort((a, b) {
            DateTime dateA = DateTime.parse(a['FECHA_GENERACION']);
            DateTime dateB = DateTime.parse(b['FECHA_GENERACION']);
            return dateB.compareTo(dateA);
          });

          _filterPagosUno =
              _allAdeudos.where((debt) => debt['PAGO'] == 1).toList();
          _filterPagosCero =
              _allAdeudos.where((debt) => debt['PAGO'] == 0).toList();

          _sumAdeudosCero = _filterPagosCero.fold(
              0, (sum, debt) => sum + debt['TOTAL_APAGAR']);
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
      setState(() {
        saldo = responseBody['data2']['SALDO'];
        bandera = responseBody['bandera'];
      });
    } catch (e) {
      print('Error $e');
      Fluttertoast.showToast(msg: "Error en la solicitud");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadAdeudos();
    setState(() {});
  }

  Future<void> _abrirPDF(idAdeudo) async {
    setState(() {
      _isLoadingPdf = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idResidente = prefs.getInt('ID_RESIDENTE');

    String url = '${UrlGlobales.UrlBase}generar-recibo-pdf';

    final requestBody = {
      'idAdeudo': idAdeudo,
      'idResidente': idResidente,
    };

    try {
      final response = await http
          .post(Uri.parse(url), body: {"params": jsonEncode(requestBody)});
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ViewPdfPagosPage(
                        urlPdf: responseBody['url'],
                        conceptoDesc: 'Test',
                      )));
        } else {
          Fluttertoast.showToast(msg: 'Error al generar el pdf.');
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Error en el servidor ${response.statusCode}.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error en la solicitud.');
    } finally {
      setState(() {
        _isLoadingPdf = false;
      });
    }
  }

  void _toggleDebts() {
    setState(() {
      _showFilteredDebts = !_showFilteredDebts;
    });
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.green,
      padding: EdgeInsets.only(left: 20, right: 20, top: 15),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Flexible(
              child: Text('Toma el control de tus pagos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
              child: Text(
                  'Mantente actualizado revisando tus estados de cuenta y adeudos pendientes.',
                  style: TextStyle(color: Colors.white, fontSize: 17))),
          Icon(Icons.show_chart_rounded, size: 90, color: Colors.white)
        ]),
        SizedBox(height: 15)
      ]),
    );
  }

  fechadepago() {
    DateTime fechaNow = DateTime.now();
    int? dia;
    int? mes;
    int? year;

    for (var i = 0; i < _allAdeudos.length; i++) {
      if (_allAdeudos[i]['PAGO'] == 0) {
        DateTime fechaLimite = DateTime.parse(
            _allAdeudos[i]['FECHA_LIMITE']); // Convertir a DateTime

        if (fechaNow
            .isAfter(DateTime.parse(_allAdeudos[i]['FECHA_GENERACION']!))) {
          dia = fechaLimite.day;
          mes = fechaLimite.month;
          year = fechaLimite.year;
        }
      }
    }

    if (dia == null) {
      return Text('');
    } else {
      return Text('Pagar antes del día: ${dia}/${mes}/${year}',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14));
    }
  }

  Widget _buildPaymentInfo() {
    Color containerColor = Colors.green;
    if (bandera == "Rojo") {
      containerColor = Colors.red;
    } else if (bandera == "Amarillo") {
      containerColor = Colors.yellow;
    }

    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(color: Colors.grey, blurRadius: 3, offset: Offset(0, 0))
          ]),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(children: [
              Text('Monto de cuota pendiente.',
                  style: TextStyle(color: Colors.white, fontSize: 17),
                  textAlign: TextAlign.center),
              SizedBox(height: 15),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Column(children: [
                  Text("\$ ${_sumAdeudosCero.toStringAsFixed(2)}",
                      style: TextStyle(color: Colors.white, fontSize: 17)),
                  // Text("Próximo pago antes del día: $nearestDueDate")
                  SizedBox(
                    height: 5,
                  ),
                  fechadepago()
                ])
              ]),
              SizedBox(height: 15),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                    child: Column(children: [
                  Text('Saldo a favor: ${saldo.toString()}',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ])),
              ])
            ]),
    );
  }

  Widget _buildButtons() {
    return _isLoading
        ? Text('')
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
                onPressed: _showFilteredDebts ? null : _toggleDebts,
                child: Text('Mis Pagos')),
            SizedBox(width: 10),
            ElevatedButton(
                onPressed: _showFilteredDebts ? _toggleDebts : null,
                child: Text('Pendientes')),
          ]);
  }

  Widget _buildDebtsList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_showFilteredDebts && _filterPagosUno.isEmpty ||
        !_showFilteredDebts && _filterPagosCero.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(height: 50),
          Text(
              _showFilteredDebts
                  ? 'No hay pagos disponibles.'
                  : 'No hay pagos pendientes.',
              style: TextStyle(fontSize: 20)),
        ])),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView.separated(
          padding: EdgeInsets.all(10.0),
          itemCount: _showFilteredDebts
              ? _filterPagosUno.length
              : _filterPagosCero.length,
          separatorBuilder: (context, index) => SizedBox(height: 10),
          itemBuilder: (context, index) {
            final debt = _showFilteredDebts
                ? _filterPagosUno[index]
                : _filterPagosCero[index];
            DateTime fechaGeneracion = DateTime.parse(debt['FECHA_GENERACION']);
            String formattedDate = _formatDate(fechaGeneracion);
            return Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey, blurRadius: 1, offset: Offset(0, 0))
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Concepto',
                        ),
                        Text(
                          'Monto',
                        ),
                        if (debt['PAGO'] == 1)
                          Icon(Icons.flag, color: Colors.green, size: 25)
                        else
                          Icon(Icons.flag, color: Colors.red, size: 25)
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${debt['CONCEPTO_DESCRIPCION']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '\$ ${debt['TOTAL_APAGAR']}',
                        ),
                        if (debt['PAGO'] == 1)
                          IconButton(
                            icon: _isLoadingPdf
                                ? CircularProgressIndicator()
                                : Icon(Icons.download_outlined,
                                    color: Colors.blueGrey, size: 25),
                            onPressed: _isLoadingPdf
                                ? null
                                : () async {
                                    await _abrirPDF(debt['ID_ADEUDO']);
                                  },
                          )
                        else
                          Text('')
                      ]),
                  Text(formattedDate),
                  if (debt['PAGO'] == 1)
                    Text('${debt['REFERENCIA']}')
                  else
                    GestureDetector(
                      onTap: () {
                        dynamic reference = '';
                        if (debt['CONCEPTO_DESCRIPCION'] == 'Pago anual') {
                          reference = debt['REFERENCAI_P'];
                        } else {
                          reference = debt['REFERENCIA'];
                        }
                        Clipboard.setData(ClipboardData(text: reference));
                        Fluttertoast.showToast(
                            msg: 'Número de referencia copiado: $reference');
                      },
                      child: Row(children: [
                        debt['CONCEPTO_DESCRIPCION'] == 'Pago anual'
                            ? Text('${debt['REFERENCAI_P']}')
                            : Text('${debt['REFERENCIA']}'),
                        SizedBox(width: 10),
                        Icon(Icons.auto_awesome_motion_outlined,
                            color: Colors.blueGrey, size: 25)
                      ]),
                    )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final List<String> monthNames = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    final String month = monthNames[date.month - 1];
    final String year = date.year.toString();
    return '$month $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Column(
        children: [
          SizedBox(height: 30),
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _buildPaymentInfo(),
                  _buildButtons(),
                  _buildDebtsList(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
