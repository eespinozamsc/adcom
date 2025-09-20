import 'dart:convert';
import 'package:adcom/detalle_report_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:adcom/urlGlobal.dart';
import 'package:intl/intl.dart';

class ListReportesPage extends StatefulWidget {
  const ListReportesPage({super.key});

  @override
  State<ListReportesPage> createState() => _ListReportesPageState();
}

class _ListReportesPageState extends State<ListReportesPage> {
  List<Map<String, dynamic>> reportesData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportes();
  }

  Future<void> _loadReportes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idResidente = prefs.getInt('ID_RESIDENTE');

    String apiUrl = '${UrlGlobales.UrlBase}get-reportes';

    try {
      final response = await http.post(Uri.parse(apiUrl),
          body: {'idResidente': idResidente.toString()});
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          reportesData = List<Map<String, dynamic>>.from(responseBody['data']);
          reportesData.sort((a, b) {
            DateTime dateA = DateTime.parse(a['FECHA_REP']);
            DateTime dateB = DateTime.parse(b['FECHA_REP']);
            return dateB.compareTo(dateA);
          });
        } else {
          Fluttertoast.showToast(msg: 'Error al obtener los reportes');
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Error en el servidor ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error en la solicitud');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getColorForProgreso(String progreso) {
    switch (progreso) {
      case 'En Proceso':
        return Colors.orange;
      case 'Revision':
        return Colors.yellow;
      case 'Respuesta':
        return Colors.blue;
      case 'Finalizado':
        return Colors.green;
      default:
        return Colors.white;
    }
  }

  String formatFecha(String fecha) {
    DateTime dateTime = DateTime.parse(fecha);
    String formattedDate = DateFormat('d MMM, yyyy HH:mm').format(dateTime);

    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reportes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : reportesData.isEmpty
              ? Center(
                  child: Text('No hay reportes disponibles',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center))
              : ListView.builder(
                  itemCount: reportesData.length,
                  itemBuilder: (BuildContext context, int index) {
                    final reporte = reportesData[index];
                    final progreso = reporte['PROGRESO'] as List<dynamic>;

                    return Container(
                      margin: EdgeInsets.only(left: 10, right: 10, top: 20),
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 1,
                                offset: Offset(0, 0))
                          ]),
                      child: ListTile(
                        title: Text(reporte['DESC_CORTA'],
                            style: TextStyle(fontSize: 20)),
                        subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5),
                              Container(
                                padding: EdgeInsets.only(
                                    left: 4,
                                    right: 4,
                                    top: 2,
                                    bottom: 2), // Ajusta el espacio aquí
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                  color: getColorForProgreso(
                                    progreso.isNotEmpty
                                        ? progreso.last['PROGRESO']
                                        : "",
                                  ),
                                ),
                                child: Text(
                                  '${progreso.isNotEmpty ? progreso.last['PROGRESO'] : "Sin avance"}',
                                  style: TextStyle(
                                      color: Colors
                                          .black), // Agrega un color de texto
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                  'Fecha Generación: ${formatFecha(reporte['FECHA_REP'])}')
                            ]),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalleReportePage(
                                  historial: progreso,
                                  idReporte: reporte['ID_REPORTE'],
                                  reporteData: reporte),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
