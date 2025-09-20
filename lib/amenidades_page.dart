import 'dart:convert';
import 'package:adcom/calendarioamenidad_page.dart';
import 'package:adcom/urlGlobal.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AmenidadesPage extends StatefulWidget {
  const AmenidadesPage({super.key});

  @override
  State<AmenidadesPage> createState() => _AmenidadesPageState();
}

class _AmenidadesPageState extends State<AmenidadesPage> {
  List<Map<String, dynamic>> _amenidades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAmenidades();
  }

  Future<void> _loadAmenidades() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('ID');

    String apiUrl = '${UrlGlobales.UrlBase}get-amenidades';
    final requestBody = {'usuarioId': id};

    try {
      final response = await http
          .post(Uri.parse(apiUrl), body: {"params": jsonEncode(requestBody)});
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _amenidades = List<Map<String, dynamic>>.from(responseBody['data']);
        });
      } else {
        Fluttertoast.showToast(
            msg: 'Error en el servidor ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error en la solicitud');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      body: SafeArea(
        child: Column(
          children: [
            _builHeader(context),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20))),
                child: Column(
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _amenidades.isEmpty
                            ? Container(
                                margin: EdgeInsets.only(
                                    top: 50, left: 25, right: 25),
                                child: Text(
                                    "Tu comunidad no cuenta con amenidades.",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center))
                            : Column(
                                children: _amenidades.map((amenidad) {
                                  return InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  CalendarioAmenidadPage(
                                                      idCom: amenidad['ID_COM'],
                                                      idAmenidad: amenidad[
                                                          'ID_AMENIDAD'],
                                                      necReserva: amenidad[
                                                          'NEC_RESERVA'])));
                                    },
                                    child: Column(
                                      children: <Widget>[
                                        SizedBox(height: 25.0),
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 20),
                                          // padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.grey,
                                                    blurRadius: 1,
                                                    offset: Offset(0, 0))
                                              ]),
                                          child: ListTile(
                                            leading: Icon(
                                                Icons.event_available_outlined,
                                                color: Colors.purple,
                                                size: 40.0),
                                            title:
                                                Text(amenidad['AMENIDAD_DESC']),
                                            subtitle:
                                                Text(amenidad['COMUNIDAD']),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Container _builHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10, top: 10),
      decoration: BoxDecoration(
          color: Colors.purple,
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
              child: Text('Ventajas de tu comunidad.',
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
                  'Enterate de las disponibilidad de tus areas recreativas o aparta con tiempo para tus eventos.',
                  style: TextStyle(color: Colors.white, fontSize: 17))),
          SizedBox(width: 10),
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.white)
        ]),
        SizedBox(height: 10),
      ]),
    );
  }
}
