import 'package:adcom/urlGlobal.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SolicitarServicioPage extends StatefulWidget {
  final String idProveedor;
  final String rutaLogo;
  final String diaAtencion;
  final String horaInicioAtencion;
  final String horaFinAtencion;
  final String compania;
  final List<Map<String, dynamic>> productos;
  final List<String> paymentOptions;

  SolicitarServicioPage({
    required this.idProveedor,
    required this.rutaLogo,
    required this.diaAtencion,
    required this.horaInicioAtencion,
    required this.horaFinAtencion,
    required this.compania,
    required this.productos,
    required this.paymentOptions,
  });

  @override
  State<SolicitarServicioPage> createState() => _SolicitarServicioPageState();
}

class _SolicitarServicioPageState extends State<SolicitarServicioPage> {
  int _currentStep = 0;
  String? selectedProduct;
  String? costoProducto;
  String? selectedPaymentOption;
  TextEditingController monto = TextEditingController();
  TextEditingController comentario = TextEditingController();
  String? cantidadARecargar;
  DateTime selectedDate = DateTime.now();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool hide = false;
  bool _loadingSolicitarServicio = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime pickedDate = (await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    ))!;
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime:
          isStartTime ? TimeOfDay(hour: 0, minute: 0) : TimeOfDay.now(),
    );

    if (pickedTime != null &&
        pickedTime != (isStartTime ? startTime : endTime)) {
      setState(() {
        if (isStartTime) {
          startTime = pickedTime;
        } else {
          endTime = pickedTime;
        }
      });
    }
  }

  Future<void> _solicitarServicio() async {
    setState(() {
      _loadingSolicitarServicio = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? _idResidente = prefs.getInt('ID_RESIDENTE');

    String apiUrl = '${UrlGlobales.UrlBase}envio-correo-servicio';

    if (costoProducto != null) {
      monto.text = costoProducto!;
    }

    final requestBody = {
      'idResidente': _idResidente,
      'idProveedor': widget.idProveedor,
      'medidasTanque': selectedProduct,
      'formaPago': selectedPaymentOption,
      'cantidadARecargar': monto.text,
      'horarioDePreferencia':
          construirFecha(selectedDate, startTime!, endTime!),
      'comentarios': comentario.text
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {"params": jsonEncode(requestBody)},
      ).timeout(Duration(seconds: 10));

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          Fluttertoast.showToast(msg: 'Solicitud realizada con exito.');
          Navigator.of(context).pop();
        } else {
          Fluttertoast.showToast(
              msg: 'Hubo un problema al hacer la solicitud.');
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor: ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud");
    } finally {
      setState(() {
        _loadingSolicitarServicio = false;
      });
    }
  }

  String construirFecha(DateTime fecha, TimeOfDay inicio, TimeOfDay fin) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(fecha);
    String formattedInicio =
        '${inicio.hour}:${inicio.minute.toString().padLeft(2, '0')}';
    String formattedFin =
        '${fin.hour}:${fin.minute.toString().padLeft(2, '0')}';

    return 'Fecha: $formattedDate Hora: $formattedInicio - $formattedFin';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              Text('Solicitar servicio', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && selectedProduct == null) {
            Fluttertoast.showToast(msg: 'Favor de seleccionar un producto.');
            return;
          }
          if (_currentStep == 1 && selectedPaymentOption == null) {
            Fluttertoast.showToast(msg: 'Favor de seleccionar forma de pago.');
            return;
          }
          if (costoProducto == null) {
            if (_currentStep == 1 && monto.text.isEmpty) {
              Fluttertoast.showToast(msg: 'Favor de ingresar un monto.');
              return;
            }
          }
          if (_currentStep == 2 && startTime == null) {
            Fluttertoast.showToast(msg: 'Favor de ingresar un horario.');
            return;
          }
          if (_currentStep == 2 && endTime == null) {
            Fluttertoast.showToast(msg: 'Favor de ingresar un horario.');
            return;
          }
          if (_currentStep == 3 && comentario.text.isEmpty) {
            Fluttertoast.showToast(msg: 'Favor de agregar un comentario');
            return;
          }
          setState(() {
            if (_currentStep < 3) {
              _currentStep += 1;
            }
          });
        },
        onStepCancel: () {
          setState(() {
            if (_currentStep > 0) {
              _currentStep -= 1;
            }
          });
        },
        steps: [
          Step(
              title: Text('Seleccionar producto.'),
              content: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: widget.productos.map((producto) {
                        return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedProduct = producto['DESCRIPCION'];
                                costoProducto = producto['COSTO'];
                              });
                            },
                            child: Column(children: [
                              Image.network(producto['PRES_LOGO_RUTA'],
                                  width: 80, height: 80, fit: BoxFit.cover),
                            ]));
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    if (selectedProduct != null)
                      Text('Producto seleccionado: $selectedProduct'),
                    SizedBox(height: 30)
                  ])),
          Step(
              title: Text('Seleccionar forma de pago.'),
              content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: widget.paymentOptions.map((option) {
                            return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ChoiceChip(
                                    label: Text(option,
                                        style: TextStyle(
                                            color:
                                                selectedPaymentOption == option
                                                    ? Colors.white
                                                    : Colors.black)),
                                    selected: selectedPaymentOption == option,
                                    selectedColor: Colors.blue,
                                    onSelected: (bool selected) {
                                      setState(() {
                                        selectedPaymentOption =
                                            selected ? option : null;
                                      });
                                    }));
                          }).toList(),
                        )),
                    SizedBox(height: 15),
                    costoProducto == null
                        ? Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.grey,
                                      blurRadius: 2,
                                      offset: Offset(0, 0))
                                ]),
                            child: TextFormField(
                              controller: monto,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Ingrese el monto',
                                labelStyle: TextStyle(color: Colors.blue),
                                prefixIcon: Icon(Icons.attach_money_outlined,
                                    color: Colors.blue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  // borderSide: BorderSide(color: Colors.grey),
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ))
                        : Text('Costo: $costoProducto'),
                    SizedBox(height: 30)
                  ])),
          Step(
              title: Text('Seleccionar horario.'),
              content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 8),
                      ElevatedButton(
                          onPressed: () => _selectDate(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0))),
                          child: Tooltip(
                              message: 'Seleccionar fecha',
                              child: Text(
                                  DateFormat('yyyy-MM-dd').format(selectedDate),
                                  style: TextStyle(color: Colors.black))))
                    ]),
                    Row(children: [
                      Icon(Icons.access_time),
                      SizedBox(width: 8),
                      ElevatedButton(
                          onPressed: () => _selectTime(context, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0))),
                          child: Tooltip(
                              message: 'Seleccionar hora de inicio',
                              child: Text(startTime?.format(context) ?? '00:00',
                                  style: TextStyle(color: Colors.black)))),
                      SizedBox(width: 4),
                      Text('--'),
                      SizedBox(width: 4),
                      ElevatedButton(
                          onPressed: () => _selectTime(context, false),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0))),
                          child: Tooltip(
                              message: 'Seleccionar hora de fin',
                              child: Text(endTime?.format(context) ?? '00:00',
                                  style: TextStyle(color: Colors.black))))
                    ]),
                    SizedBox(height: 30)
                  ])),
          Step(
              title: Text('Agregar comentario.'),
              content: Column(children: [
                SizedBox(height: 5),
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
                    child: TextFormField(
                        controller: comentario,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'Ingrese un comentario',
                          labelStyle: TextStyle(color: Colors.blue),
                          prefixIcon:
                              Icon(Icons.draw_outlined, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            // borderSide: BorderSide(color: Colors.grey),
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ))),
                SizedBox(height: 30)
              ]))
        ],
        controlsBuilder: (BuildContext ctx, ControlsDetails dtl) {
          return _currentStep == 0
              ? Row(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: dtl.onStepContinue,
                      style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(10.0),
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          )),
                      child: Text(
                        hide == true ? '' : 'Continuar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )
              : _currentStep == 3
                  ? Row(
                      children: [
                        ElevatedButton(
                            onPressed: _loadingSolicitarServicio
                                ? null
                                : _solicitarServicio,
                            style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.all(10.0),
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0))),
                            child: _loadingSolicitarServicio
                                ? CircularProgressIndicator()
                                : Text('Solicitar servicio',
                                    style: TextStyle(color: Colors.white))),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: dtl.onStepCancel,
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(10.0),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0))),
                          child: Text(hide == true ? '' : 'Cancelar',
                              style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: dtl.onStepContinue,
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(10.0),
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              )),
                          child: Text(hide == true ? '' : 'Continuar',
                              style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: dtl.onStepCancel,
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(10.0),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0))),
                          child: Text(hide == true ? '' : 'Cancelar',
                              style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    );
        },
      ),
    );
  }
}
