import 'dart:async';
import 'dart:typed_data';

import 'package:adcom/urlGlobal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:esys_flutter_share_plus/esys_flutter_share_plus.dart';

class GenerarQrPage extends StatefulWidget {
  const GenerarQrPage({super.key});

  @override
  State<GenerarQrPage> createState() => _GenerarQrPageState();
}

class _GenerarQrPageState extends State<GenerarQrPage> {
  bool _loadingGenerarQr = false;
  bool _loadingGenerarQrUnico = false;
  bool _mostrarBotonQr = false;
  DateTime fechaIni = DateTime.now();
  DateTime fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    _mostrarQrApp();
    fechaFin = fechaIni.add(Duration(hours: 1));
  }

  Future<void> _mostrarQrApp() async {
    String apiUrl = '${UrlGlobales.UrlBase}mostrar-qr-app';
    try {
      final response = await http.post(Uri.parse(apiUrl));
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          setState(() {
            _mostrarBotonQr = true;
          });
        } else {
          setState(() {
            _mostrarBotonQr = false;
          });
        }
      } else {
        Fluttertoast.showToast(msg: "Error en el servidor.");
      }
    } on TimeoutException {
      Fluttertoast.showToast(msg: "Tiempo de espera agotado.");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud.");
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Acceso QR',
              style: TextStyle(fontSize: 18, color: Colors.white),
            )
          ],
        ),
        SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
              child: Text('Genera un nuevo acceso para todas tus reuniones.',
                  style: TextStyle(color: Colors.white, fontSize: 17),
                  textAlign: TextAlign.center)),
          Icon(Icons.qr_code_2_outlined, size: 90, color: Colors.white)
        ]),
        SizedBox(height: 10)
      ]),
    );
  }

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => Container(
            height: 216,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(top: false, child: child)));
  }

  void _validarTiempo() {
    final validarHrs = fechaIni.add(const Duration(days: 1));
    final difference = fechaFin.difference(fechaIni);
    if (difference.inMinutes >= 59) {
      if (fechaFin.isBefore(validarHrs)) {
        _loadGenerarQr();
      } else {
        Fluttertoast.showToast(msg: 'Seleccionar rango mayor a una hora');
      }
    } else if (difference.inMinutes <= 58 && difference.inMinutes >= 1) {
      Fluttertoast.showToast(msg: 'Seleccionar rango mayor a una hora');
    } else {
      Fluttertoast.showToast(
          msg: 'Fecha inicial no puede ser mayor a fecha final');
    }
  }

  Future<void> _loadGenerarQr() async {
    setState(() {
      _loadingGenerarQr = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? _idResidente = prefs.getInt('ID_RESIDENTE');
    int? _idCom = prefs.getInt('ID_COM');
    int? _idUsuario = prefs.getInt('ID');
    int? _idPerfil = prefs.getInt('ID_PERFIL');

    String? fechaInicial = DateFormat("yyyy-MM-dd HH:mm:ss").format(fechaIni);
    String? fechaFinal = DateFormat("yyyy-MM-dd HH:mm:ss").format(fechaFin);

    String apiUrl = '${UrlGlobales.UrlBase}generar-acceso-qr';

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'idResidente': _idResidente.toString(),
        'idCom': _idCom.toString(),
        'fechaIni': fechaInicial,
        'fechaFin': fechaFinal,
        'idUsuario': _idUsuario.toString(),
        'idPerfil': _idPerfil.toString(),
        'tipoAcceso': "1"
      });
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          mostrarImage(responseBody['urlQr']);
        } else {
          Fluttertoast.showToast(msg: "Error al generar QR");
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud");
    } finally {
      setState(() {
        _loadingGenerarQr = false;
      });
    }
  }

  Future<void> _loadGenerarQrUnico() async {
    setState(() {
      _loadingGenerarQrUnico = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? _idResidente = prefs.getInt('ID_RESIDENTE');
    int? _idCom = prefs.getInt('ID_COM');
    int? _idUsuario = prefs.getInt('ID');
    int? _idPerfil = prefs.getInt('ID_PERFIL');

    String? fechaInicial = DateFormat("yyyy-MM-dd HH:mm:ss").format(fechaIni);
    String? fechaFinal = DateFormat("yyyy-MM-dd HH:mm:ss").format(fechaFin);

    String apiUrl = '${UrlGlobales.UrlBase}generar-acceso-qr';

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'idResidente': _idResidente.toString(),
        'idCom': _idCom.toString(),
        'fechaIni': fechaInicial,
        'fechaFin': fechaFinal,
        'idUsuario': _idUsuario.toString(),
        'idPerfil': _idPerfil.toString(),
        'tipoAcceso': "2"
      });
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          mostrarImage(responseBody['urlQr']);
        } else {
          Fluttertoast.showToast(msg: "Error al generar QR");
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud");
    } finally {
      setState(() {
        _loadingGenerarQrUnico = false;
      });
    }
  }

  mostrarImage(urlQr) async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('QR Generado con éxito', textAlign: TextAlign.center),
        content: Image.network(urlQr, height: 250, width: 250),
        actions: <Widget>[
          TextButton(
            child: const Text('Compartir QR', style: TextStyle(fontSize: 18)),
            onPressed: () async {
              // Descargar la imagen desde la URL
              final response = await http.get(Uri.parse(urlQr));
              final Uint8List bytes = response.bodyBytes;

              // Compartir la imagen a través de WhatsApp
              await Share.file(
                'Compartir imagen',
                'imagen.jpg',
                bytes.buffer.asUint8List(),
                'image/jpeg',
              );

              /* final uri = Uri.parse(urlQr);
              final response = await http.get(uri);
              final bytes = response.bodyBytes;

              final tempDir = await getTemporaryDirectory();
              final file = File('${tempDir.path}/QR.jpg');
              await file.writeAsBytes(bytes);

              await Share.share(
                'Acceso QR.\n \n $urlQr \n \n Fecha Inicial. \n ${fechaIni.day}-${fechaIni.month}-${fechaIni.year}    ${fechaIni.hour}:${fechaIni.minute} hrs. \n \n Fecha Final. \n ${fechaFin.day}-${fechaFin.month}-${fechaFin.year}     ${fechaFin.hour}:${fechaFin.minute} hrs.',
              ); */

              /* final uri = Uri.parse(urlQr);
              final response = await http.get(uri);
              final bytes = response.bodyBytes;
              final temp = await getTemporaryDirectory();
              final path = '${temp.path}/QR.jpg';
              File(path).writeAsBytesSync(bytes);

              await Share.shareFiles(
                [path],
                text:
                    'Acceso QR.\n \n Fecha Inicial. \n ${fechaIni.day}-${fechaIni.month}-${fechaIni.year}    ${fechaIni.hour}:${fechaIni.minute} hrs. \n \n Fecha Final. \n ${fechaFin.day}-${fechaFin.month}-${fechaFin.year}     ${fechaFin.hour}:${fechaFin.minute} hrs.',
              ); */
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blue,
        body: Column(children: [
          SizedBox(height: 30),
          _buildHeader(),
          SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20))),
              child: Column(
                children: [
                  SizedBox(height: 40),
                  Text("Fecha y Hora Inicial", style: TextStyle(fontSize: 20)),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CupertinoButton(
                        onPressed: () => _showDialog(CupertinoDatePicker(
                            initialDateTime: fechaIni,
                            mode: CupertinoDatePickerMode.date,
                            use24hFormat: false,
                            onDateTimeChanged: (DateTime newFechaIni) {
                              setState(() => fechaIni = newFechaIni);
                            })),
                        child: Text(
                            '${fechaIni.month}-${fechaIni.day}-${fechaIni.year}',
                            style: const TextStyle(
                                fontSize: 26.0, color: Colors.blue))),
                    CupertinoButton(
                        onPressed: () => _showDialog(CupertinoDatePicker(
                            initialDateTime: fechaIni,
                            mode: CupertinoDatePickerMode.time,
                            use24hFormat: true,
                            onDateTimeChanged: (DateTime newFechaIni) {
                              setState(() => fechaIni = newFechaIni);
                            })),
                        child: Text('${fechaIni.hour}:${fechaIni.minute}',
                            style: const TextStyle(
                                fontSize: 26.0, color: Colors.blue)))
                  ]),
                  SizedBox(height: 20),
                  Text("Fecha y Hora Final", style: TextStyle(fontSize: 20)),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CupertinoButton(
                        onPressed: () => _showDialog(CupertinoDatePicker(
                            initialDateTime: fechaFin,
                            mode: CupertinoDatePickerMode.date,
                            use24hFormat: false,
                            onDateTimeChanged: (DateTime newFechaFin) {
                              setState(() => fechaFin = newFechaFin);
                            })),
                        child: Text(
                            '${fechaFin.month}-${fechaFin.day}-${fechaFin.year}',
                            style: const TextStyle(
                                fontSize: 26.0, color: Colors.blue))),
                    CupertinoButton(
                        onPressed: () => _showDialog(CupertinoDatePicker(
                            initialDateTime: fechaFin,
                            mode: CupertinoDatePickerMode.time,
                            use24hFormat: true,
                            onDateTimeChanged: (DateTime newTime) {
                              setState(() => fechaFin = newTime);
                            })),
                        child: Text('${fechaFin.hour}:${fechaFin.minute}',
                            style: const TextStyle(
                                fontSize: 26.0, color: Colors.blue)))
                  ]),
                  SizedBox(height: 50),
                  _loadingGenerarQr
                      ? CircularProgressIndicator()
                      : Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.only(left: 50, right: 50),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.blue.withOpacity(0.5),
                                    spreadRadius: 3,
                                    blurRadius: 1,
                                    offset: Offset(0, 0))
                              ]),
                          child: InkWell(
                            onTap: () {
                              _validarTiempo();
                            },
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Icon(Icons.qr_code_2, size: 50),
                                  Expanded(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                        Text("Generar Nuevo QR",
                                            style: TextStyle(fontSize: 20),
                                            textAlign: TextAlign.center)
                                      ]))
                                ]),
                          ),
                        ),
                  SizedBox(height: 25),
                  _mostrarBotonQr
                      ? _loadingGenerarQrUnico
                          ? CircularProgressIndicator()
                          : Container(
                              padding: EdgeInsets.all(10),
                              margin: EdgeInsets.only(left: 50, right: 50),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.blue.withOpacity(0.5),
                                        spreadRadius: 3,
                                        blurRadius: 1,
                                        offset: Offset(0, 0))
                                  ]),
                              child: InkWell(
                                onTap: () {
                                  _loadGenerarQrUnico();
                                },
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Icon(Icons.qr_code_outlined, size: 50),
                                      Expanded(
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                            Text("Generar QR de Acceso Unico",
                                                style: TextStyle(fontSize: 20),
                                                textAlign: TextAlign.center)
                                          ]))
                                    ]),
                              ),
                            )
                      : Container(),
                ],
              ),
            ),
          )
        ]));
  }
}
