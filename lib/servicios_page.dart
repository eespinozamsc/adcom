import 'package:adcom/solicitar_servicio_page.dart';
import 'package:adcom/urlGlobal.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ServiciosPage extends StatefulWidget {
  const ServiciosPage({super.key});

  @override
  State<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends State<ServiciosPage> {
  List<Map<String, dynamic>> _listServicios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServicios();
  }

  Future<void> _loadServicios() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idCom = prefs.getInt('ID_COM');

    String apiUrl = '${UrlGlobales.UrlBase}get-datos-provedores-by-com';

    try {
      final response =
          await http.post(Uri.parse(apiUrl), body: {'idCom': idCom.toString()});

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _listServicios =
              List<Map<String, dynamic>>.from(responseBody['data']);
        });
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Servicios', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : _listServicios.isEmpty
              ? Center(
                  child: Flexible(
                      child: Text('Tu comunidad no cuenta con servicios.',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w500))))
              : ListView.builder(
                  itemCount: _listServicios.length,
                  itemBuilder: (context, index) {
                    final servicio = _listServicios[index];

                    final horaInicio =
                        servicio['HORA_INIT_ATEN'].substring(0, 5);
                    final horaFin = servicio['HORA_FIN_ATEN'].substring(0, 5);

                    return Container(
                      margin: EdgeInsets.all(10),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SolicitarServicioPage(
                                idProveedor: servicio['ID_PROV'],
                                rutaLogo: servicio['RUTA_LOGO'],
                                diaAtencion: servicio['DIA_ATENCION'],
                                horaInicioAtencion: servicio['HORA_INIT_ATEN'],
                                horaFinAtencion: servicio['HORA_FIN_ATEN'],
                                compania: servicio['COMPANIA'],
                                productos: List<Map<String, dynamic>>.from(
                                    servicio['PRODUCTOS']),
                                paymentOptions: [
                                  servicio['FORMA_PAGO_2'],
                                  servicio['FORMA_PAGO_3'],
                                ],
                              ),
                            ),
                          );
                        },
                        leading: Image.network(
                          servicio['RUTA_LOGO'],
                          height: 120,
                          width: 100,
                          fit: BoxFit.contain,
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${servicio['COMPANIA'].trim()}',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text('${servicio['DIA_ATENCION']}'),
                            Text('$horaInicio - $horaFin'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
