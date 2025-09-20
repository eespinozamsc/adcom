import 'dart:io';
import 'dart:typed_data';

import 'package:adcom/urlGlobal.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:esys_flutter_share_plus/esys_flutter_share_plus.dart';
import 'package:intl/intl.dart';

class BitacoraAccesos extends StatefulWidget {
  const BitacoraAccesos({super.key});

  @override
  State<BitacoraAccesos> createState() => _BitacoraAccesosState();
}

class _BitacoraAccesosState extends State<BitacoraAccesos> {
  int idCom = 0;

  List<dynamic> comunidades = [];
  List<dynamic> accesosQr = [];
  List<dynamic> accesosTarjeta = [];
  List<dynamic> accesosApp = [];

  String? selectedCommunity;

  bool cargaAmenidades = true;
  bool _mostrarAccesoQr = false;
  bool _mostrarAccesoApp = false;
  bool _mostrarAccesoTarjeta = false;
  bool _crearExcel = false;
  bool _mostratBitacora = false;

  ScrollController _scrollControllerTarjeta = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadComunidades();
  }

  @override
  void dispose() {
    _scrollControllerTarjeta.dispose();
    super.dispose();
  }

  void _toggleMostrarAccesosQr() {
    setState(() {
      _mostrarAccesoQr = !_mostrarAccesoQr;
    });
  }

  void _toggleMostrarAccesosApp() {
    setState(() {
      _mostrarAccesoApp = !_mostrarAccesoApp;
    });
  }

  void _toggleMostrarAccesosTarjeta() {
    setState(() {
      _mostrarAccesoTarjeta = !_mostrarAccesoTarjeta;
      if (_mostrarAccesoTarjeta) {
        // Desplazar la pantalla hacia la posición del contenedor de la lista
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollControllerTarjeta.animateTo(
            _scrollControllerTarjeta.position.maxScrollExtent,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  // Declara un estado booleano para controlar la visibilidad de los botones B y C
  bool mostrarBotonesBC = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: cargaAmenidades
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      SizedBox(height: 20),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: Offset(0, 3),
                              ),
                            ],
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: SingleChildScrollView(
                            controller: _scrollControllerTarjeta,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 30,
                                ),
                                _dropDownComunidades(),
                                SizedBox(
                                  height: 25,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Accesos QR',
                                        style: TextStyle(fontSize: 18),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(_mostrarAccesoQr
                                          ? Icons.expand_less
                                          : Icons.expand_more),
                                      onPressed: _toggleMostrarAccesosQr,
                                    ),
                                  ],
                                ),
                                accesosQr.isEmpty
                                    ? _mostratBitacora
                                        ? CircularProgressIndicator()
                                        : Text("-----")
                                    : _mostrarAccesoQr
                                        ? _listAccesosQr()
                                        : Container(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Accesos App',
                                        style: TextStyle(fontSize: 18),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(_mostrarAccesoApp
                                          ? Icons.expand_less
                                          : Icons.expand_more),
                                      onPressed: _toggleMostrarAccesosApp,
                                    ),
                                  ],
                                ),
                                accesosApp.isEmpty
                                    ? _mostratBitacora
                                        ? CircularProgressIndicator()
                                        : Text("-----")
                                    : _mostrarAccesoApp
                                        ? _listAccesosApp()
                                        : Container(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Accesos Tarjeta',
                                        style: TextStyle(fontSize: 18),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(_mostrarAccesoTarjeta
                                          ? Icons.expand_less
                                          : Icons.expand_more),
                                      onPressed: _toggleMostrarAccesosTarjeta,
                                    ),
                                  ],
                                ),
                                accesosTarjeta.isEmpty
                                    ? _mostratBitacora
                                        ? CircularProgressIndicator()
                                        : Text("-----")
                                    : _mostrarAccesoTarjeta
                                        ? _listAccesosTarjeta()
                                        : Container(),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _crearExcel
                          ? CircularProgressIndicator()
                          : FloatingActionButton(
                              onPressed: () {
                                _loadArchivoExcel();
                              },
                              child: Icon(
                                Icons.add,
                                color: Colors.black,
                              ),
                              backgroundColor: Colors.white,
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Container _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(left: 10, right: 10, top: 10),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back, color: Colors.black)),
          SizedBox(width: 10),
          Flexible(
              child: Text('Bitacora Accesos',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
        SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Flexible(
            child: Column(children: [
              Text('Registro de accesos del día actual.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.black),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              SizedBox(height: 25),
            ]),
          ),
          SizedBox(
            width: 20,
          ),
          Icon(
            Icons.history_toggle_off,
            size: 90,
            color: Colors.black,
          ),
        ]),
        // SizedBox(height: 10),
      ]),
    );
  }

  Widget _dropDownComunidades() {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 5,
          blurRadius: 7,
          offset: Offset(0, 0),
        ),
      ], color: Colors.white),
      child: DropdownButton<String>(
        value: selectedCommunity,
        hint: Text('Seleccionar una comunidad'),
        items: comunidades.map((comunidad) {
          return DropdownMenuItem<String>(
            value: comunidad['ID_COM'].toString(),
            child: Text(comunidad['NOMBRE_COMU']),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedCommunity = newValue;
            idCom = int.parse(newValue!);
            _loadBitacoraAccesos();
          });
        },
        iconSize: 30,
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
        ),
        underline: Container(), // Oculta la línea subrayada
      ),
    );
  }

  Widget _listAccesosQr() {
    return Container(
      height: 250,
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: accesosQr.length,
        itemBuilder: (context, index) {
          var inquilino = accesosQr[index];

          DateTime fechaActivacion =
              DateTime.parse(inquilino['FECHA_ACTIVACION']);
          String formattedFechaActivacion =
              DateFormat('dd-MMM-yyyy HH:mm:ss').format(fechaActivacion);

          return Container(
            margin: EdgeInsets.only(bottom: 5),
            padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$formattedFechaActivacion'),
                    Text(
                      '${inquilino['DESCRIPCION']}',
                      style: TextStyle(
                        color: inquilino['STATUS'] == "2"
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${inquilino['NOMBRE_RESIDENTE'] != null ? (inquilino['NOMBRE_RESIDENTE'].length <= 20 ? inquilino['NOMBRE_RESIDENTE'] : inquilino['NOMBRE_RESIDENTE'].substring(0, 20) + '...') : '-----'}'),
                    Text('${inquilino['CADENA']}'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _listAccesosApp() {
    return Container(
      height: 250,
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: accesosApp.length,
        itemBuilder: (context, index) {
          var inquilino = accesosApp[index];
          DateTime fechaActivacion =
              DateTime.parse(inquilino['FECHA_ACTIVACION']);
          String formattedFechaActivacion =
              DateFormat('dd-MMM-yyyy HH:mm:ss').format(fechaActivacion);
          return Container(
            margin: EdgeInsets.only(bottom: 5),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$formattedFechaActivacion'),
                    Text(
                      '${inquilino['DESCRIPCION']}',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${inquilino['NOMBRE_RESIDENTE'] != null ? (inquilino['NOMBRE_RESIDENTE'].length <= 20 ? inquilino['NOMBRE_RESIDENTE'] : inquilino['NOMBRE_RESIDENTE'].substring(0, 20) + '...') : '-----'}'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _listAccesosTarjeta() {
    return Container(
      height: 250,
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: accesosTarjeta.length,
        itemBuilder: (context, index) {
          var inquilino = accesosTarjeta[index];
          DateTime fechaActivacion =
              DateTime.parse(inquilino['FECHA_ACTIVACION']);
          String formattedFechaActivacion =
              DateFormat('dd-MMM-yyyy HH:mm:ss').format(fechaActivacion);
          return Container(
            margin: EdgeInsets.only(bottom: 5),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$formattedFechaActivacion'),
                    Text(
                      '${inquilino['ACCION']}',
                    ),
                    Text(
                      '${inquilino['DESCRIPCION']}',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${inquilino['NOMBRE_RESIDENTE'] != null ? (inquilino['NOMBRE_RESIDENTE'].length <= 20 ? inquilino['NOMBRE_RESIDENTE'] : inquilino['NOMBRE_RESIDENTE'].substring(0, 20) + '...') : '-----'}'),
                    Text('${inquilino['CADENA']}'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadComunidades() async {
    String apiUrl = '${UrlGlobales.UrlBase}get-comunities';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          comunidades = responseBody['data'];
        });
      } else {
        Fluttertoast.showToast(
          msg: "Error en el servidor ${response.statusCode}",
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud $e");
    } finally {
      setState(() {
        cargaAmenidades = false;
      });
    }
  }

  Future<void> _loadBitacoraAccesos() async {
    setState(() {
      _mostratBitacora = true;
    });
    String apiUrl = '${UrlGlobales.UrlBase}bitacora-accesos-aplicacion';
    try {
      final response =
          await http.post(Uri.parse(apiUrl), body: {'idCom': idCom.toString()});
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          accesosQr = responseBody['historicoQr'];
          accesosApp = responseBody['historicoApp'];
          accesosTarjeta = responseBody['historicoTarjetas'];
        });
      } else {
        Fluttertoast.showToast(
          msg: "Error en el servidor ${response.statusCode}",
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud $e");
      print(e);
    } finally {
      setState(() {
        _mostratBitacora = false;
      });
    }
  }

  Future<void> _loadArchivoExcel() async {
    if (idCom == 0) {
      Fluttertoast.showToast(msg: "Debe seleccionar una comunidad");
      return;
    }
    setState(() {
      _crearExcel = true;
    });
    String apiUrl = '${UrlGlobales.UrlBase}reporte-accesos-app';
    try {
      final response =
          await http.post(Uri.parse(apiUrl), body: {'idCom': idCom.toString()});
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        print("**************");
        print(responseBody['file_url']);
        final response = await http.get(Uri.parse(responseBody['file_url']));
        final Uint8List bytes = response.bodyBytes;

        // Compartir el archivo Excel a través de WhatsApp
        String nameFile = responseBody['comunidad'] + '.xlsx';
        print("-----------------");
        print(nameFile);

        await Share.file(
          'Compartir archivo Excel',
          nameFile,
          bytes.buffer.asUint8List(),
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // Tipo MIME para Excel
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud $e");
    } finally {
      setState(() {
        _crearExcel = false;
      });
    }
  }
}
