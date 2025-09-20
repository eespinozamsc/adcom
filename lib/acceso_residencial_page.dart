import 'package:adcom/generar_qr_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adcom/urlGlobal.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AccesoResidencialPage extends StatefulWidget {
  const AccesoResidencialPage({super.key});

  @override
  State<AccesoResidencialPage> createState() => _AccesoResidencialPageState();
}

class _AccesoResidencialPageState extends State<AccesoResidencialPage> {
  bool _loadingAdeudos = false;
  bool _loadingAbrirPuerta = false;
  bool statusAdeudo = true;

  @override
  void initState() {
    super.initState();
    _loadAdeudos();
  }

  Future<void> _loadAdeudos() async {
    setState(() {
      _loadingAdeudos = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idResidente = prefs.getInt('ID_RESIDENTE');

    try {
      String apiUrl = '${UrlGlobales.UrlBase}get-adeudos';
      final requestBody = {'usuarioId': idResidente};
      final response = await http
          .post(Uri.parse(apiUrl), body: {"params": jsonEncode(requestBody)});
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseBody['value'] == 1 && responseBody['data'] != null) {
          List<dynamic> adeudosData = responseBody['data'];

          for (var i = 0; i < adeudosData.length; i++) {
            DateTime fechaLimite =
                DateTime.parse(adeudosData[i]['FECHA_LIMITE']);
            DateTime fechaNow = DateTime.now();

            if (adeudosData[i]['PAGO'] == 0 && fechaNow.isAfter(fechaLimite)) {
              statusAdeudo = false;
              break;
            }
          }
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud");
    } finally {
      setState(() {
        _loadingAdeudos = false;
      });
    }
  }

  Future<void> _loadAbrirPuerta() async {
    setState(() {
      _loadingAbrirPuerta = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('ID_RESIDENTE');
    int outPut = 1;
    try {
      String apiUrl = '${UrlGlobales.UrlBase}abrir-puerta';
      final response = await http.post(Uri.parse(apiUrl),
          body: {'idUsuarioApp': id.toString(), 'outPut': outPut.toString()});
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        print("******");
        if (responseBody['value'] == 1) {
          print("--------");
          Fluttertoast.showToast(msg: "Puerta Abierta");
        } else {
          Fluttertoast.showToast(msg: "Error ${responseBody['message']}");
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud");
    } finally {
      setState(() {
        _loadingAbrirPuerta = false;
      });
    }
  }

  Widget _buildAdeudos() {
    return Column(
      children: [
        SizedBox(height: 25),
        Center(
            child: Container(
          margin: EdgeInsets.only(left: 20, right: 20),
          padding: EdgeInsets.only(top: 25, bottom: 25, left: 35, right: 35),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3))
              ]),
          child: InkWell(
              splashColor: Colors.green,
              onTap: () {},
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Icon(Icons.no_encryption_gmailerrorred,
                        size: 100, color: Colors.red),
                    SizedBox(height: 30),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                              child: Text(
                                  "Usted cuenta con adeudos pendientes, por lo que no es posible hacer uso de estas funcionalidades. \n \n Para cualquier duda o aclaración favor de contactarse con su administrador.",
                                  style: TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center))
                        ])
                  ])),
        ))
      ],
    );
  }

  Widget _buildBotonApp() {
    return Center(
        child: _loadingAbrirPuerta
            ? Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 1,
                          offset: Offset(0, 0))
                    ]),
                margin: EdgeInsets.only(left: 20, right: 20),
                child: InkWell(
                    splashColor: Colors.green,
                    onTap: () {},
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Icon(Icons.door_sliding_outlined, size: 100),
                          Expanded(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                Text("Abriendo",
                                    style: TextStyle(fontSize: 20),
                                    textAlign: TextAlign.center),
                                Text("Puerta...",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold))
                              ]))
                        ])),
              )
            : Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 1,
                          offset: Offset(0, 0))
                    ]),
                margin: EdgeInsets.only(left: 20, right: 20),
                child: InkWell(
                    splashColor: Colors.green,
                    onTap: () {
                      _loadAbrirPuerta();
                    },
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Icon(Icons.door_sliding_outlined, size: 100),
                          Expanded(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                Text("Habilitar puerta de ",
                                    style: TextStyle(fontSize: 20),
                                    textAlign: TextAlign.center),
                                Text("Entrada...",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold))
                              ]))
                        ])),
              ));
  }

  Widget _buildBotonQr() {
    return Center(
        child: Container(
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
      margin: EdgeInsets.only(left: 20, right: 20),
      child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GenerarQrPage()),
            );
          },
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Icon(Icons.qr_code, size: 100),
                Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      Text("Generar ", style: TextStyle(fontSize: 20)),
                      Text("QR...",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold))
                    ]))
              ])),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              Text('Puerta Residencial', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white),
      body: Container(
          child: _loadingAdeudos
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : statusAdeudo
                  ? Column(
                      children: [
                        SizedBox(
                          height: 30,
                        ),
                        _buildBotonApp(),
                        SizedBox(
                          height: 30,
                        ),
                        _buildBotonQr()
                      ],
                    )
                  : _buildAdeudos()),
    );
  }
}
