import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:adcom/urlGlobal.dart';

class PagosDetallesPage extends StatefulWidget {
  final dynamic mesesAPagar;
  final dynamic cuota;
  final dynamic descuento;
  final dynamic totalAPagar;
  final List<Map<String, dynamic>> filterPagosCero;
  const PagosDetallesPage(
      {Key? key,
      this.mesesAPagar,
      this.cuota,
      this.descuento,
      this.totalAPagar,
      required this.filterPagosCero})
      : super(key: key);

  @override
  State<PagosDetallesPage> createState() => _PagosDetallesPageState();
}

class _PagosDetallesPageState extends State<PagosDetallesPage> {
  bool isAnual = false;
  Set<int> selectedItems = {};
  bool _isLoagingGenerarRefencia = false;

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
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Elija su modo de pago',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                _buildPagoAnual(),
                !isAnual ? listaAdeudos() : datosPagoAnual(),
                _buildSelectedMontoText(),
                _referenciaBoton()
              ],
            ),
          ))
        ],
      )),
    );
  }

  void _mostrarNumeroReferencia(String numeroReferencia) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Número de Referencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      numeroReferencia,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: Tooltip(
                        message: 'Copiar en portapapeles',
                        child: Icon(Icons.content_copy),
                      ),
                      onPressed: () {
                        final String textoACopiar = numeroReferencia;
                        Clipboard.setData(ClipboardData(text: textoACopiar));
                        Fluttertoast.showToast(
                          msg:
                              'Número de referencia copiado: $numeroReferencia',
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    if (isAnual) {
                      Navigator.of(context)
                        ..pop()
                        ..pop()
                        ..pop()
                        ..pop();
                    } else {
                      Navigator.of(context)
                        ..pop()
                        ..pop()
                        ..pop();
                    }
                  },
                  child: Text(
                    'Cerrar',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  generarRefMaestra() async {
    setState(() {
      _isLoagingGenerarRefencia = true;
    });
    List<int> selectedIDs = selectedItems
        .map((index) =>
            widget.filterPagosCero[index]['ID_ADEUDO'] as int) // Cast to int
        .toList();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idResidente = prefs.getInt('ID_RESIDENTE');
    int? idCom = prefs.getInt('ID_COM');
    String apiUrl = '${UrlGlobales.UrlBase}generar-referencia-maestra';
    final requestBody = {
      "esAnual": isAnual,
      'idCom': idCom,
      'idResidente': idResidente,
      'idAdeudos': selectedIDs.toList()
    };

    try {
      final response = await http
          .post(Uri.parse(apiUrl), body: {"params": jsonEncode(requestBody)});
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          _mostrarNumeroReferencia(responseBody['REFERENCIA_P']);
        } else {
          Fluttertoast.showToast(msg: "Error al generar la referencia");
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error en la solicitud", backgroundColor: Colors.red);
    } finally {
      setState(() {
        _isLoagingGenerarRefencia = false;
      });
    }
  }

  Widget _referenciaBoton() {
    List<int> selectedIDs = selectedItems
        .map((index) =>
            widget.filterPagosCero[index]['ID_ADEUDO'] as int) // Cast to int
        .toList();
    return isAnual == true || selectedIDs.length >= 2
        ? Container(
            margin: EdgeInsets.all(20),
            width: 300,
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled)) {
                      // Color cuando el botón está deshabilitado
                      return Colors.grey;
                    }
                    // Color cuando el botón está habilitado
                    return Colors.green;
                  },
                ),
                shape: MaterialStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              onPressed: () {
                if (isAnual == true) {
                  _mostrarDialogoAtencionUsuario();
                } else {
                  generarRefMaestra();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _isLoagingGenerarRefencia
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text(
                        'Generar referencia de pago',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
              ),
            ),
          )
        : Text('');
  }

  void _mostrarDialogoAtencionUsuario() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Atención Usuario',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text(
                'Al generar una referencia por pago anual o pago restante ya no será posible pagar de manera individual los meses pendientes del año actual. ¿Desea continuar?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'Cancelar'),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  TextButton(
                    onPressed:
                        _isLoagingGenerarRefencia ? null : generarRefMaestra,
                    child: _isLoagingGenerarRefencia
                        ? CircularProgressIndicator()
                        : Text(
                            'Continuar',
                            style: TextStyle(color: Colors.green),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Text _buildSelectedMontoText() {
    double totalMonto = 0.0;

    for (int index in selectedItems) {
      String montoAsString =
          widget.filterPagosCero[index]['TOTAL_APAGAR'].toString();
      double monto = double.tryParse(montoAsString) ?? 0.0;
      totalMonto += monto;
    }

    return isAnual
        ? Text('')
        : Text(
            'Total a Pagar: ${totalMonto.toStringAsFixed(2)} MXN',
            style: TextStyle(fontWeight: FontWeight.bold),
          );
  }

  Container datosPagoAnual() {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15, top: 20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Meses a pagar:',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          Flexible(
              child: Text(widget.mesesAPagar,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, color: Colors.black),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Cuota:',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          Text(widget.cuota.toString(), style: TextStyle(fontSize: 17))
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Descuento:',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          Text(widget.descuento.toString(), style: TextStyle(fontSize: 17))
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total a pagar:',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          Text(widget.totalAPagar.toString(), style: TextStyle(fontSize: 17))
        ]),
      ]),
    );
  }

  Expanded listaAdeudos() {
    return Expanded(
      child: ListView.builder(
        itemCount: widget.filterPagosCero.length,
        itemBuilder: (context, index) {
          final paymentDetails = widget.filterPagosCero[index];
          final isSelected = selectedItems.contains(index);
          final concepto = paymentDetails['CONCEPTO_DESCRIPCION'];
          DateTime fechaGeneracion =
              DateTime.parse(paymentDetails['FECHA_GENERACION']);
          String formattedDate = _formatDate(fechaGeneracion);

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            padding: EdgeInsets.all(5.0),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey, blurRadius: 1, offset: Offset(0, 0))
                ]),
            child: ListTile(
              title: Text('$concepto'),
              subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5),
                    Text('Fecha: $formattedDate'),
                    SizedBox(height: 5),
                    Text('Monto: \$${paymentDetails['TOTAL_APAGAR']}'),
                  ]),
              trailing: Checkbox(
                value: isSelected,
                activeColor: Colors.green,
                onChanged: (bool? value) {
                  setState(() {
                    if (concepto == 'Pago anual') {
                      Fluttertoast.showToast(
                          msg: 'No se pueden seleccionar pagos anuales');
                    } else {
                      if (value == true) {
                        selectedItems.add(index);
                      } else {
                        selectedItems.remove(index);
                      }
                    }
                  });
                },
              ),
            ),
          );
        },
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
                  'Elije lo que decidas pagar y genera tu referencia maestra.',
                  style: TextStyle(color: Colors.white, fontSize: 17))),
          SizedBox(width: 10),
          Icon(Icons.show_chart_rounded, size: 80, color: Colors.white)
        ]),
        SizedBox(height: 10),
      ]),
    );
  }

  Widget _buildPagoAnual() {
    bool mesesAPagar;
    if (widget.mesesAPagar == "") {
      mesesAPagar = false;
    } else {
      mesesAPagar = true;
    }

    return Container(
        child: mesesAPagar
            ? Container(
                margin: EdgeInsets.only(left: 13, right: 13),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                          child: Text('Pago anual o pago restante.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 17, color: Colors.black),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      Checkbox(
                        checkColor: Colors.white,
                        activeColor: Colors.green,
                        value: isAnual,
                        onChanged: (bool? value) {
                          setState(() {
                            isAnual = value!;
                          });
                        },
                      )
                    ]))
            : Container(
                margin: EdgeInsets.all(10),
                child: Text(
                    'Por el momento no es posible generar una referencia anual o pago restante debido a que ya existe una referencia activa o, no cuenta con adeudos pendientes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17)),
              ));
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
