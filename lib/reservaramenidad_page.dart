import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adcom/urlGlobal.dart';

class ReservarAmenidadPage extends StatefulWidget {
  final List<Map<String, dynamic>> reservas;
  final dynamic idAmenidad;
  const ReservarAmenidadPage(
      {Key? key, required this.reservas, required this.idAmenidad})
      : super(key: key);

  @override
  State<ReservarAmenidadPage> createState() => _ReservarAmenidadPageState();
}

class _ReservarAmenidadPageState extends State<ReservarAmenidadPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _eventNameController = TextEditingController();
  bool _acceptRules = false;
  DateTime fechaIni = DateTime.now();
  DateTime fechaFin = DateTime.now();
  bool _loadingReglamento = false;
  bool _loadingReserva = false;

  Future<void> _showDialog(Widget picker) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 300,
          child: picker,
        );
      },
    );
  }

  void _saveEvent() {
    if (_eventNameController.text.isNotEmpty) {
      if (_acceptRules) {
        if (fechaIni.isBefore(fechaFin)) {
          // Validación 2: La fecha y hora deben tener una diferencia de 30 minutos.
          if (fechaFin.difference(fechaIni).inMinutes >= 30) {
            bool canSave = true;

            for (var reserva in widget.reservas) {
              DateTime reservaIni = DateTime.parse(reserva['fechaIniReserva']);
              DateTime reservaFin = DateTime.parse(reserva['fechaFinReserva']);

              if ((fechaIni.isAfter(reservaIni) &&
                      fechaIni.isBefore(reservaFin)) ||
                  (fechaFin.isAfter(reservaIni) &&
                      fechaFin.isBefore(reservaFin)) ||
                  (fechaIni.isBefore(reservaIni) &&
                      fechaFin.isAfter(reservaIni)) ||
                  (fechaIni.isBefore(reservaFin) &&
                      fechaFin.isAfter(reservaFin))) {
                canSave = false;
                break;
              }
            }

            if (canSave) {
              DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              String formattedFechaIni = formatter.format(fechaIni);
              String formattedFechaFin = formatter.format(fechaFin);

              _reservarAmenidad(_eventNameController.text, formattedFechaIni,
                  formattedFechaFin);
            } else {
              Fluttertoast.showToast(
                  msg: 'La fecha y hora chocan con otras reservas.');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Padding(
                  padding: EdgeInsets.only(bottom: 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 50),
                      SizedBox(width: 15),
                      Flexible(
                        child: Text(
                          'Dif. entre fecha y hora inicial y final debe ser al menos 30 min.',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      )
                    ],
                  ),
                ),
                duration: Duration(seconds: 10),
                backgroundColor: Colors.white, // Elimina el color de fondo
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.red), // Color del contorno
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        } else {
          Fluttertoast.showToast(
              msg: 'La fecha y hora final no puede ser menor a la inicial.');
        }
      } else {
        Fluttertoast.showToast(msg: 'Debe aceptar el reglamento.');
      }
    } else {
      Fluttertoast.showToast(msg: 'Nombre del evento no puede estar vacio.');
    }
  }

  Future<void> _loadReglamento() async {
    setState(() {
      _loadingReglamento = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idCom = prefs.getInt('ID_COM');

    String apiUrl = '${UrlGlobales.UrlBase}get-relgamento-amenidad';
    final requestBody = {'idCom': idCom, 'idAmendiad': widget.idAmenidad};

    try {
      final response = await http
          .post(Uri.parse(apiUrl), body: {'params': jsonEncode(requestBody)});
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          String reglamentoData = responseBody['data'] ?? '';
          _showReglamento(context, reglamentoData);
        } else {
          Fluttertoast.showToast(msg: 'Aun no hay reglamento');
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Error en el servidor ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error en la solicitud');
    } finally {
      setState(() {
        _loadingReglamento = false;
      });
    }
  }

  void _showReglamento(BuildContext context, String reglamentoData) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    'Atención',
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Expanded(
                    child: SingleChildScrollView(
                  child: Text(reglamentoData),
                ))
              ],
            ),
          );
        });
  }

  Future<void> _reservarAmenidad(
      String comentario, String fechaIni, String fechaFin) async {
    setState(() {
      _loadingReserva = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idCom = prefs.getInt('ID_COM');
    int? idResidente = prefs.getInt('ID_RESIDENTE');
    String apiUrl = '${UrlGlobales.UrlBase}reserva-amenidad';
    final requestBody = {
      'idCom': idCom,
      'idAmenidad': widget.idAmenidad,
      'idResidente': idResidente,
      'fechaIni': fechaIni,
      'fechaFin': fechaFin,
      'comentario': comentario,
    };

    try {
      final response = await http
          .post(Uri.parse(apiUrl), body: {"params": jsonEncode(requestBody)});

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          Fluttertoast.showToast(msg: "Se ha registrado su reserva.");
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        } else {
          Fluttertoast.showToast(msg: 'Error al intertar hacer la reserva');
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Error en el servidor ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error en la solicitud');
    } finally {
      setState(() {
        _loadingReserva = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            'Reservar Amenidad',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.purple,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey,
                            blurRadius: 2,
                            offset: Offset(0, 0))
                      ]),
                  child: TextField(
                    controller: _eventNameController,
                    cursorColor: Colors.purple,
                    decoration: InputDecoration(
                      labelText: 'Nombre del evento',
                      labelStyle: TextStyle(color: Colors.purple),
                      prefixIcon: Icon(Icons.email, color: Colors.purple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        // borderSide: BorderSide(color: Colors.grey),
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 36),
                Text("Fecha y Hora Inicial"),
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
                              fontSize: 22.0, color: Colors.purple))),
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
                              fontSize: 22.0, color: Colors.purple)))
                ]),
                SizedBox(height: 20),
                Text("Fecha y Hora Final"),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CupertinoButton(
                    onPressed: () => _showDialog(
                      CupertinoDatePicker(
                        initialDateTime: fechaFin,
                        mode: CupertinoDatePickerMode.date,
                        use24hFormat: false,
                        onDateTimeChanged: (DateTime newFechaFin) {
                          setState(() => fechaFin = newFechaFin);
                        },
                      ),
                    ),
                    child: Text(
                      '${fechaFin.month}-${fechaFin.day}-${fechaFin.year}',
                      style:
                          const TextStyle(fontSize: 22.0, color: Colors.purple),
                    ),
                  ),
                  CupertinoButton(
                      onPressed: () => _showDialog(
                            CupertinoDatePicker(
                              initialDateTime: fechaFin,
                              mode: CupertinoDatePickerMode.time,
                              use24hFormat: true,
                              onDateTimeChanged: (DateTime newTime) {
                                setState(() => fechaFin = newTime);
                              },
                            ),
                          ),
                      child: Text('${fechaFin.hour}:${fechaFin.minute}',
                          style: const TextStyle(
                              fontSize: 22.0, color: Colors.purple)))
                ]),
                SizedBox(height: 30),
                Row(children: [
                  Checkbox(
                      value: _acceptRules,
                      activeColor: Colors.purple,
                      onChanged: (value) {
                        setState(() {
                          _acceptRules = value!;
                        });
                      }),
                  TextButton(
                      onPressed: _loadingReglamento ? null : _loadReglamento,
                      child: _loadingReglamento
                          ? CircularProgressIndicator()
                          : Text('Reglamento',
                              style: TextStyle(color: Colors.purple)))
                ]),
                SizedBox(height: 32),
                Container(
                    width: double.infinity,
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.disabled)) {
                              // Color cuando el botón está deshabilitado
                              return Colors.grey;
                            }
                            // Color cuando el botón está habilitado
                            return Colors.purple;
                          },
                        ),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      onPressed: _saveEvent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: _loadingReserva
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                'Guardar evento',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                ),
                              ),
                      ),
                    )),
              ],
            ),
          ),
        ));
  }
}
