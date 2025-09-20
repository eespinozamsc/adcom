import 'package:adcom/view_pdf_archivos_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:adcom/urlGlobal.dart';
import 'package:intl/intl.dart';

class MostrarAvisosPage extends StatefulWidget {
  const MostrarAvisosPage({super.key});

  @override
  State<MostrarAvisosPage> createState() => _MostrarAvisosPageState();
}

class _MostrarAvisosPageState extends State<MostrarAvisosPage> {
  late List<Map<String, dynamic>> avisos;
  bool _loadingAvisos = true;

  @override
  void initState() {
    super.initState();
    _loadAvisos();
  }

  Future<void> _loadAvisos() async {
    String apiUrl = '${UrlGlobales.UrlBase}get-avisos-by-residente';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idCom = prefs.getInt('ID_COM');

    try {
      final response =
          await http.post(Uri.parse(apiUrl), body: {'idCom': idCom.toString()});
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> avisosData =
            List<Map<String, dynamic>>.from(responseBody['data']);

        // Ordenar la lista por fecha de forma descendente
        avisosData.sort((a, b) {
          DateTime dateA = DateTime.parse(a['FECHA_AVISO']);
          DateTime dateB = DateTime.parse(b['FECHA_AVISO']);
          return dateB.compareTo(dateA);
        });

        setState(() {
          avisos = avisosData;
        });
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud");
    } finally {
      setState(() {
        _loadingAvisos = false;
      });
    }
  }

  String _formatFecha(String fecha) {
    DateTime parsedDate = DateTime.parse(fecha);
    String formattedDate = DateFormat('dd/MMM/yyyy').format(parsedDate);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
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
                  child: _loadingAvisos
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : avisos.isEmpty
                          ? Center(
                              child: Text('No hay avisos disponibles'),
                            )
                          : _buildAvisosList()),
            )
          ],
        ),
      ),
    );
  }

  ListView _buildAvisosList() {
    return ListView.builder(
      itemCount: avisos.length,
      itemBuilder: (context, index) {
        final aviso = avisos[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
              color: Colors.white, // Color de fondo del elemento
              borderRadius: BorderRadius.circular(10.0), // Borde redondeado
              boxShadow: [
                BoxShadow(
                    color: Colors.grey, // Color de la sombra
                    blurRadius: 2, // Radio de desenfoque de la sombra
                    offset: Offset(0, 0))
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(
                  children: [
                    Image.asset('assets/images/logo.png', width: 35),
                    SizedBox(width: 20),
                    Text('Administrador'),
                  ],
                ),
                Row(
                  children: [Text(_formatFecha(aviso['FECHA_AVISO']))],
                )
              ]),
              Divider(),
              Text(aviso['AVISO'], style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return SizedBox(
                        height: 400,
                        child: Column(
                          children: [
                            ListTile(
                                title: const Text('Archivos Adjuntos',
                                    textAlign: TextAlign.center)),
                            Divider(),
                            Expanded(
                                child: ListView.builder(
                                    itemCount: aviso['ARCHIVOS'].length,
                                    itemBuilder: (context, index) {
                                      final archivo = aviso['ARCHIVOS'][index];
                                      return ListTile(
                                        title: Text(archivo['NOMBRE_ARCHIVO']),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ViewPdfArchivosPage(
                                                urlPdf: archivo[
                                                    'DIRECCION_ARCHIVO'],
                                                nombrePdf:
                                                    archivo['NOMBRE_ARCHIVO'],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    })),
                            TextButton(
                              child: const Text('Cerrar'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Text(
                  'Archivos Adjuntos',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Container _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10, top: 10),
      decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20))),
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
          SizedBox(width: 15),
          Flexible(
              child: Text('Comunicados de la comunidad.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis))
        ]),
        SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
              child: Text(
                  'Enterate de lo que sucede en tu comunidad! Desde recordatorios, alertas, novedades y más.',
                  style: TextStyle(color: Colors.white, fontSize: 17))),
          SizedBox(width: 10),
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.white)
        ]),
        SizedBox(height: 15),
      ]),
    );
  }
}
