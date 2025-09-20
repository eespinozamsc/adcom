import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adcom/urlGlobal.dart';

class SettingUserPage extends StatefulWidget {
  const SettingUserPage({super.key});

  @override
  State<SettingUserPage> createState() => _SettingUserPageState();
}

class _SettingUserPageState extends State<SettingUserPage> {
  String? _tipoUsuario;
  String? _nombreResidente;
  String? _nombreComunidad;
  int? _idPerfil;
  bool _loadingDatos = false;
  String? calle;
  String? noExterior;
  String? noInterior;
  String? codigoPostal;
  String? noCelular;
  String? correo;
  String? celular;
  late List<dynamic> _inquilinosJson;

  late TextEditingController _correoController;
  late TextEditingController _passwordController;
  late TextEditingController _celularController;

  bool _mostrarInquilinos = false;
  bool _showUpdateInfo = false;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _correoController = TextEditingController();
    _passwordController = TextEditingController();
    _celularController = TextEditingController();
    _cargarInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  void _toggleMostrarInquilinos() {
    setState(() {
      _mostrarInquilinos = !_mostrarInquilinos;
      if (_mostrarInquilinos) {
        // Desplazar la pantalla hacia la posición del contenedor de la lista
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  void _toggleShowUpdateInfo() {
    setState(() {
      _showUpdateInfo = !_showUpdateInfo;
    });
  }

  _cargarInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? tipoUsuario = prefs.getInt('ID_PERFIL');
    String? nombreResidente = prefs.getString('NombreResidente');
    String? comunidad = prefs.getString('COMUNIDAD');
    correo = prefs.getString('email');
    celular = prefs.getString('celular');
    String? password = prefs.getString('passM');

    String? inquilinosJson = prefs.getString('inquilinos');
    _inquilinosJson = jsonDecode(inquilinosJson!);
    setState(() {
      _idPerfil = prefs.getInt('ID_PERFIL');
      if (tipoUsuario == 1) {
        _tipoUsuario = 'Propietario';
        _nombreResidente = nombreResidente;
        _nombreComunidad = comunidad;
        // print("----");
        print(_inquilinosJson);
      } else if (tipoUsuario == 2) {
        _tipoUsuario = 'Administrador';
        _nombreResidente = 'Martha Falomir';
        _nombreComunidad = 'Administración';
      } else {
        _tipoUsuario = 'Inquilino';
        _nombreResidente = nombreResidente;
        _nombreComunidad = comunidad;
      }
      _correoController.text = correo!;
      _passwordController.text = password!;
      _celularController.text = celular!;

      if (tipoUsuario != 2) {
        calle = prefs.getString('CALLE');
        noExterior = prefs.getString('NO_EXTERNO');
        noInterior = prefs.getString('NO_INTERIOR');
        codigoPostal = prefs.getString('CP');
        noCelular = prefs.getString('celular');
        correo = prefs.getString('email');
      }
    });
  }

  Future<void> _guardarDatos() async {
    setState(() {
      _loadingDatos = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('ID');

    String apiUrl = '${UrlGlobales.UrlBase}actualizar-datos-usr';

    final requestBody = {
      'idUsuarioApp': id,
      'email': _correoController.text,
      'password': _passwordController.text,
    };

    try {
      final response = await http
          .post(Uri.parse(apiUrl), body: {"params": jsonEncode(requestBody)});

      final responseBody = jsonDecode(response.body);

      print('Response Body: $responseBody');

      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          Fluttertoast.showToast(msg: 'Se han guardado los cambios');
          _login(_passwordController.text);
        } else {
          Fluttertoast.showToast(msg: 'No se han podido guardar los cambios');
        }
      } else {
        Fluttertoast.showToast(msg: 'Error en el servidor');
      }
    } catch (e) {
      print('Error $e');
      Fluttertoast.showToast(msg: 'Error en la solicitud');
    }
  }

  Future<void> _login(password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('userM');

    String apiUrl = '${UrlGlobales.UrlBase}login-app';
    final requestBody = {'username': username, 'password': password};

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        "params": jsonEncode(requestBody)
      }).timeout(Duration(seconds: 10));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseBody['value'] == 0) {
          Fluttertoast.showToast(
            msg: "Usuario o contraseña incorrecto",
          );
        } else {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setInt('ID', responseBody['ID']);
          prefs.setInt('ID_COM', responseBody['ID_COM']);
          prefs.setInt('ID_PERFIL', responseBody['ID_PERFIL']);
          prefs.setInt('ID_RESIDENTE', responseBody['ID_RESIDENTE']);
          prefs.setString('USUARIO', responseBody['USUARIO']);
          prefs.setString('NombreResidente', responseBody['NombreResidente']);
          prefs.setString('email', responseBody['email']);
          prefs.setString('contrasenia', responseBody['contrasenia']);
          prefs.setBool('isLoggedIn', true);
          prefs.setString('userM', username!);
          prefs.setString('passM', password);
          prefs.setInt('extComunidades', responseBody['extComunidades']);

          int? idPerfil = prefs.getInt('ID_PERFIL');
          if (idPerfil != 2) {
            prefs.setString('ESPECIALIDADES',
                responseBody['infoUsuario']['ESPECIALIDADES']);
            prefs.setInt('CODI', responseBody['infoUsuario']['CODI']);
            prefs.setString(
                'NO_EXTERNO', responseBody['infoUsuario']['NO_EXTERNO']);
            prefs.setString(
                'NO_INTERIOR', responseBody['infoUsuario']['NO_INTERIOR']);
            prefs.setString(
                'COMUNIDAD', responseBody['infoUsuario']['COMUNIDAD']);
            prefs.setString('CP', responseBody['infoUsuario']['CP']);
            prefs.setString('CALLE', responseBody['infoUsuario']['CALLE']);

            // Guardar los inquilinos como lista de mapas
            List<dynamic> inquilinos = responseBody['Inquilinos'];
            List<Map<String, dynamic>> inquilinosList = [];

            for (var inquilino in inquilinos) {
              Map<String, dynamic> inquilinoData = {
                'Nombre': inquilino['Nombre'],
                'Telefono_Movil': inquilino['Telefono_Movil'],
                'Usuario': inquilino['Usuario'],
              };
              inquilinosList.add(inquilinoData);
            }

            // Convertir la lista de mapas a una cadena JSON
            String inquilinosJson = jsonEncode(inquilinosList);

            // Guardar la cadena JSON en SharedPreferences
            prefs.setString('inquilinos', inquilinosJson);
          }
          Navigator.pop(context);
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
    } on TimeoutException {
      Fluttertoast.showToast(msg: "Tiempo de espera agotado.");
    } catch (e) {
      print('Error $e');
      Fluttertoast.showToast(msg: "Error en la solicitud");
    } finally {
      setState(() {
        _loadingDatos = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                  height: 800,
                  padding: EdgeInsets.only(left: 20, right: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        SizedBox(height: 25),
                        Container(
                          margin: EdgeInsets.only(left: 10, right: 10),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 2,
                                    offset: Offset(0, 0))
                              ]),
                          child: Column(
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Calle: ',
                                        style: TextStyle(fontSize: 18)),
                                    Text('$calle',
                                        style: TextStyle(fontSize: 18)),
                                  ]),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Número: ',
                                        style: TextStyle(fontSize: 18)),
                                    Text('${noExterior?.trim()}',
                                        style: TextStyle(fontSize: 18))
                                  ]),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('No. Interior: ',
                                        style: TextStyle(fontSize: 18)),
                                    Text('${noInterior?.trim()}',
                                        style: TextStyle(fontSize: 18))
                                  ]),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Código Postal: ',
                                        style: TextStyle(fontSize: 18)),
                                    Text('${codigoPostal?.trim()}',
                                        style: TextStyle(fontSize: 18))
                                  ]),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Celular: ',
                                        style: TextStyle(fontSize: 18)),
                                    Text('$noCelular',
                                        style: TextStyle(fontSize: 18))
                                  ]),
                              _idPerfil == 1
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                          Text('Correo: ',
                                              style: TextStyle(fontSize: 18)),
                                          Text('$correo',
                                              style: TextStyle(fontSize: 18))
                                        ])
                                  : Container()
                            ],
                          ),
                        ),
                        SizedBox(height: 25),
                        /* _idPerfil == 1
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Actualizar Información',
                                      style: TextStyle(fontSize: 18),
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(_showUpdateInfo
                                        ? Icons.expand_less
                                        : Icons.expand_more),
                                    onPressed: _toggleShowUpdateInfo,
                                  ),
                                ],
                              )
                            : Container(), */
                        /* _showUpdateInfo
                            ? Container(
                                margin: EdgeInsets.only(left: 10, right: 10),
                                child: Column(
                                  children: [
                                    _textCorreo(),
                                    SizedBox(height: 30),
                                    _textCelular(),
                                    SizedBox(height: 30),
                                    _textPassword(),
                                    SizedBox(height: 30),
                                    _buildBotonCambios(),
                                    SizedBox(height: 30),
                                  ],
                                ),
                              )
                            : Container(), */
                        /* if (_idPerfil == 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Inquilinos',
                                  style: TextStyle(fontSize: 18),
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: Icon(_mostrarInquilinos
                                    ? Icons.expand_less
                                    : Icons.expand_more),
                                onPressed: _toggleMostrarInquilinos,
                              ),
                            ],
                          ),
                        SizedBox(height: 20),
                        if (_mostrarInquilinos && _inquilinosJson.isNotEmpty)
                          Container(
                            height: 250,
                            child: ListView.builder(
                              physics: BouncingScrollPhysics(),
                              itemCount: _inquilinosJson.length,
                              itemBuilder: (context, index) {
                                var inquilino = _inquilinosJson[index];
                                return Container(
                                  margin: EdgeInsets.only(
                                      bottom: 7.5,
                                      left: 10,
                                      right: 10,
                                      top: 7.5),
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 1,
                                          blurRadius: 2,
                                          offset: Offset(0, 0))
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Nombre: ${inquilino['Nombre']}'),
                                      Text('Usuario: ${inquilino['Usuario']}'),
                                      Text(
                                          'Teléfono: ${inquilino['Telefono_Movil']}'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        SizedBox(height: 30), */
                      ],
                    ),
                  )),
            )
          ],
        ),
      ),
    );
  }

  SizedBox _buildBotonCambios() {
    return SizedBox(
        width: double.infinity,
        child: TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  // Color cuando el botón está deshabilitado
                  return Colors.grey;
                }
                // Color cuando el botón está habilitado
                return Colors.blue;
              },
            ),
            shape: MaterialStateProperty.all<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          onPressed: _guardarDatos,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: _loadingDatos
                ? Center(child: CircularProgressIndicator())
                : Text(
                    'Guardar cambios',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
          ),
        ));
  }

  Container _textPassword() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(color: Colors.grey, blurRadius: 2, offset: Offset(0, 0))
          ]),
      child: TextField(
        controller: _passwordController,
        cursorColor: Colors.blue,
        decoration: InputDecoration(
          labelText: 'Contraseña',
          labelStyle: TextStyle(color: Colors.blue),
          prefixIcon: Icon(Icons.lock_clock_outlined, color: Colors.blue),
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
      ),
    );
  }

  Container _textCorreo() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(color: Colors.grey, blurRadius: 2, offset: Offset(0, 0))
          ]),
      child: TextField(
        controller: _correoController,
        cursorColor: Colors.blue,
        decoration: InputDecoration(
          labelText: 'Correo',
          labelStyle: TextStyle(color: Colors.blue),
          prefixIcon: Icon(Icons.email, color: Colors.blue),
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
      ),
    );
  }

  Container _textCelular() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(color: Colors.grey, blurRadius: 2, offset: Offset(0, 0))
          ]),
      child: TextField(
        controller: _celularController,
        cursorColor: Colors.blue,
        decoration: InputDecoration(
          labelText: 'Celular',
          labelStyle: TextStyle(color: Colors.blue),
          prefixIcon: Icon(Icons.email, color: Colors.blue),
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
      ),
    );
  }

  Container _buildHeader(BuildContext context) {
    return Container(
      color: Colors.blue,
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
              child: Text('Información $_tipoUsuario',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
        SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Flexible(
            child: Column(children: [
              Text(_nombreResidente.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              SizedBox(height: 15),
              Text(_nombreComunidad.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          Icon(
            Icons.people_alt_outlined,
            size: 90,
            color: Colors.white,
          ),
        ]),
        SizedBox(height: 10),
      ]),
    );
  }
}
