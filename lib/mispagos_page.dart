import 'dart:convert';
import 'package:adcom/pagosdetalles_page.dart';
import 'package:adcom/view_pdf_pagos_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:adcom/urlGlobal.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class MisPagosPage extends StatefulWidget {
  const MisPagosPage({super.key});

  @override
  State<MisPagosPage> createState() => _MisPagosPageState();
}

class _MisPagosPageState extends State<MisPagosPage> {
  String? saldo;
  String? bandera;
  Color containerColor = Colors.green;
  String? _mesesAPagar;
  int? _cuota;
  int? _descuento;
  int? _totalAPagar;
  List<Map<String, dynamic>> _allAdeudos = [];
  List<Map<String, dynamic>> _filterPagosUno = [];
  List<Map<String, dynamic>> _filterPagosCero = [];
  bool _showFilteredDebts = false;
  double _sumAdeudosCero = 0;
  bool _isLoading = true;
  bool _isLoadingPdf = false;
  int _codi = 0;

  @override
  void initState() {
    super.initState();
    _loadAdeudos().then((_) {
      _toggleDebts();
    });
  }

  Future<void> _loadAdeudos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idResidente = prefs.getInt('ID_RESIDENTE');
    int? codi = prefs.getInt('CODI');

    setState(() {
      _isLoading = true;
      _codi = codi!;
    });

    String apiUrl = '${UrlGlobales.UrlBase}get-adeudos';
    final requestBody = {'usuarioId': idResidente};

    try {
      final response = await http
          .post(Uri.parse(apiUrl), body: {"params": jsonEncode(requestBody)});
      final responseBody = json.decode(response.body);

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
          _filterPagosCero = _allAdeudos
              .where((debt) => debt['PAGO'] == 0 || debt['PAGO'] == 4)
              .toList();

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
        _mesesAPagar = responseBody['pagoAnualORestante']['mesesAPagar'];
        _cuota = responseBody['pagoAnualORestante']['cuota'];
        _descuento = responseBody['pagoAnualORestante']['descuento'];
        _totalAPagar = responseBody['pagoAnualORestante']['totalAPagar'];
        if (bandera == "Rojo") {
          containerColor = Colors.red;
        } else if (bandera == "Amarillo") {
          containerColor = Colors.yellow;
        }
      });
    } catch (e) {
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

  Future<void> generarCobroCodi(int idAdeudo) async {
    String url = '${UrlGlobales.UrlBase}pagar-codi';

    try {
      final response =
          await http.post(Uri.parse(url), body: {'id': idAdeudo.toString()});
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          Fluttertoast.showToast(msg: 'Solicitud realizada con exito');
          Navigator.of(context)..pop();
        } else {
          Fluttertoast.showToast(msg: 'Error al generar el cobro.');
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Error en el servidor ${response.statusCode}.');
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: 'Error en la solicitud.');
    } finally {}
  }

  Future<void> _abrirPDF(idAdeudo, conceptoDesc, fecha) async {
    setState(() {
      _isLoadingPdf = true;
    });

    await initializeDateFormatting('es');

    DateTime fechaDateTime = DateTime.parse(fecha);
    String nombreMes = DateFormat('MMMM', 'es').format(fechaDateTime);
    String year = DateFormat('yyyy').format(fechaDateTime);
    String fechaFormateada = '$nombreMes-$year';

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
                      conceptoDesc: fechaFormateada)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20))),
                child: Column(
                  children: [
                    _buildPaymentInfo(context),
                    _isLoading
                        ? Text('')
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                  onPressed:
                                      _showFilteredDebts ? null : _toggleDebts,
                                  child: Text('Mis Pagos')),
                              SizedBox(width: 10),
                              ElevatedButton(
                                  onPressed:
                                      _showFilteredDebts ? _toggleDebts : null,
                                  child: Text('Pendientes')),
                            ],
                          ),
                    _buildDebtsList()
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
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
                          GestureDetector(
                            onTap: _isLoadingPdf
                                ? null
                                : () async {
                                    await _abrirPDF(
                                        debt['ID_ADEUDO'],
                                        debt['CONCEPTO_DESCRIPCION'],
                                        debt['FECHA_GENERACION']);
                                  },
                            child: Container(
                              // padding: EdgeInsets.all(5),
                              child: _isLoadingPdf
                                  ? CircularProgressIndicator()
                                  : Icon(
                                      Icons.download_outlined,
                                      color: Colors.blueGrey,
                                      size: 25,
                                    ),
                            ),
                          ),
                        if (debt['PAGO'] == 0 && _codi == 0)
                          Text('                     '),
                        if (debt['PAGO'] == 0 && _codi == 1)
                          GestureDetector(
                            onTap: _isLoadingPdf
                                ? null
                                : () {
                                    showModalBottomSheet<void>(
                                        backgroundColor: Colors.white,
                                        context: context,
                                        builder: (BuildContext context) {
                                          return SizedBox(
                                            height: 300,
                                            child: Center(
                                              child: Column(
                                                children: <Widget>[
                                                  SizedBox(height: 30),
                                                  Text('CODI'),
                                                  SizedBox(height: 15),
                                                  Text(
                                                      'Realizar pago usando servicio CODI'),
                                                  SizedBox(height: 30),
                                                  Text(
                                                      'Referencia: ${debt['REFERENCIA']}'),
                                                  SizedBox(height: 30),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          generarCobroCodi(debt[
                                                              'ID_ADEUDO']);
                                                        },
                                                        child: Text('Aceptar'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: Text('Cancelar'),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        });
                                  },
                            child: Container(child: Text('Pagar')),
                          )
                      ]),
                  Text(formattedDate),
                  if (debt['PAGO'] == 1)
                    Text('Ref. ${debt['REFERENCIA']}')
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
                            ? Text('Ref. ${debt['REFERENCAI_P']}')
                            : Text('Ref. ${debt['REFERENCIA']}'),
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

  Container _buildPaymentInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(color: Colors.grey, blurRadius: 3, offset: Offset(0, 0))
          ]),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                        child: Column(children: [
                      Text('Saldo a favor',
                          style: TextStyle(color: Colors.white, fontSize: 15)),
                      Text(saldo.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 15))
                    ])),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PagosDetallesPage(
                                    mesesAPagar: _mesesAPagar,
                                    cuota: _cuota,
                                    descuento: _descuento,
                                    totalAPagar: _totalAPagar,
                                    filterPagosCero: _filterPagosCero)));
                      },
                      child: Text('Detalles',
                          style: TextStyle(fontSize: 15, color: Colors.black)),
                    )
                  ],
                )
              ],
            ),
    );
  }

  Container _buildHeader(BuildContext context) {
    return Container(
      color: Colors.green,
      padding: EdgeInsets.only(left: 10, right: 10, top: 10),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back, color: Colors.white)),
          SizedBox(width: 10),
          Flexible(
              child: Text('Toma el control de tus pagos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
        SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
              child: Text(
                  'Mantente actualizado revisando tus estados de cuenta y adeudos pendientes.',
                  style: TextStyle(color: Colors.white, fontSize: 17))),
          Icon(Icons.show_chart_rounded, size: 80, color: Colors.white)
        ]),
        SizedBox(height: 10),
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
      return Text('Pagar antes del día: $dia/$mes/$year',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14));
    }
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
}

class BottomSheetExample extends StatelessWidget {
  const BottomSheetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        child: const Text('showModalBottomSheet'),
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('Modal BottomSheet'),
                      ElevatedButton(
                        child: const Text('Close BottomSheet'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
