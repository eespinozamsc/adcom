import 'package:adcom/seguimiento_reporte_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DetalleReportePage extends StatefulWidget {
  final List<dynamic> historial;
  final dynamic idReporte;
  final Map<String, dynamic> reporteData;
  const DetalleReportePage(
      {super.key,
      required this.historial,
      required this.idReporte,
      required this.reporteData});

  @override
  State<DetalleReportePage> createState() => _DetalleReportePageState();
}

class _DetalleReportePageState extends State<DetalleReportePage> {
  int? _idPerfil;
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idPerfil = prefs.getInt('ID_PERFIL');
    setState(() {
      _idPerfil = idPerfil;
    });
  }

  Widget _botonSeguimiento() {
    return FloatingActionButton.extended(
      backgroundColor: Colors.blue,
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => SeguimientoReportePage(
                  idReporte: widget.idReporte,
                  idPerfil: _idPerfil,
                )));
      },
      icon: Icon(Icons.add),
      label: Text(''),
    );
  }

  String formatFecha(String fecha) {
    // Convierte la fecha de String a DateTime
    DateTime dateTime = DateTime.parse(fecha);

    // Formatea la fecha como 'yyyy-MM-dd HH:mm'
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);

    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historial de Seguimiento',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          padding: const EdgeInsets.all(5.0),
          decoration: BoxDecoration(
              color: Colors.white, // Color de fondo del elemento
              borderRadius: BorderRadius.circular(10.0), // Borde redondeado
              boxShadow: [
                BoxShadow(
                    color: Colors.grey, // Color de la sombra
                    blurRadius: 5.0, // Radio de desenfoque de la sombra
                    offset: Offset(0, 3))
              ]),
          child: ListTile(
            title: Text(widget.reporteData['DESC_CORTA']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descripción: ${widget.reporteData['DESC_DESPERFECTO']}'),
                SizedBox(height: 10),
                // Display images
                if (widget.reporteData['EVIDENCIA'] != null &&
                    widget.reporteData['EVIDENCIA'].isNotEmpty)
                  Container(
                    height: 200, // Adjust the height as needed
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.reporteData['EVIDENCIA'].length,
                      itemBuilder: (BuildContext context, int index) {
                        final imageUrl = widget.reporteData['EVIDENCIA'][index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(
                            imageUrl,
                            height: 80, // Adjust the height as needed
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
            height: 20.0,
            child: Center(
                child: Container(
                    margin: EdgeInsetsDirectional.only(start: 1.0, end: 1.0),
                    height: 5.0,
                    color: Colors.blue))),
        widget.historial.isNotEmpty
            ? Expanded(
                child: ListView.builder(
                  itemCount: widget.historial.length,
                  itemBuilder: (BuildContext context, int index) {
                    final progreso = widget.historial[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                          color: Colors.white, // Color de fondo del elemento
                          borderRadius:
                              BorderRadius.circular(10.0), // Borde redondeado
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey, // Color de la sombra
                                blurRadius:
                                    5.0, // Radio de desenfoque de la sombra
                                offset: Offset(0, 3))
                          ]),
                      child: ListTile(
                        title: Text(progreso['PROGRESO']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha: ${progreso['FECHA_SEG']}'),
                            Text('Comentario: ${progreso['COMENTARIO']}'),
                            if (progreso['EVIDENCIA'] != null &&
                                progreso['EVIDENCIA'].isNotEmpty)
                              Container(
                                height: 200, // Adjust the height as needed
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: progreso['EVIDENCIA'].length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final imageUrl =
                                        progreso['EVIDENCIA'][index];
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.network(
                                        imageUrl,
                                        height:
                                            80, // Adjust the height as needed
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            : Center(
                child: Column(children: [
                SizedBox(height: 50),
                Text('No hay progreso disponible.',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500))
              ]))
      ]),
      floatingActionButton: _idPerfil == 2 ? _botonSeguimiento() : Text(''),
    );
  }
}
