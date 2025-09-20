import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:adcom/urlGlobal.dart';

class LoginPage extends StatefulWidget {
  final void Function(int? perfil, String? especialidades, int? extComunidades)
      onLogin;

  const LoginPage({Key? key, required this.onLogin}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  final FocusNode myfocusNode = FocusNode();
  bool _passwordVisible = false;
  bool _loading = false;
  bool _loadingPolitica = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loading = true;
      });
      final username = _usernameController.text;
      final password = _passwordController.text;

      String apiUrl = '${UrlGlobales.UrlBase}login-app';
      final requestBody = {'username': username, 'password': password};

      try {
        final response = await http.post(Uri.parse(apiUrl), body: {
          "params": jsonEncode(requestBody)
        }).timeout(Duration(seconds: 10));

        final responseBody = json.decode(response.body);

        if (response.statusCode == 200) {
          if (responseBody['value'] == 0) {
            _usernameController.clear();
            _passwordController.clear();
            Fluttertoast.showToast(
              msg: "Usuario o contraseña incorrecto",
              backgroundColor: Colors.red,
              textColor: Colors.red,
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
            prefs.setString('celular', responseBody['celular']);
            prefs.setString('contrasenia', responseBody['contrasenia']);
            prefs.setBool('isLoggedIn', true);
            prefs.setString('userM', username);
            prefs.setString('passM', password);
            prefs.setInt('extComunidades', responseBody['extComunidades']);

            int? idPerfil = prefs.getInt('ID_PERFIL');
            String especialidades = '0';
            int? extComunidades = prefs.getInt('extComunidades');
            print(idPerfil);
            if (idPerfil != 2) {
              especialidades = responseBody['infoUsuario']['ESPECIALIDADES'];
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

              // prefs.setString('', value)

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
            widget.onLogin(idPerfil, especialidades, extComunidades);
          }
        } else {
          Fluttertoast.showToast(
              msg: "Error en el servidor ${response.statusCode}");
        }
      } on TimeoutException {
        Fluttertoast.showToast(msg: "Tiempo de espera agotado.");
      } catch (e) {
        print('Error $e');
        Fluttertoast.showToast(msg: "Error en la solicitud \n$e");
      } finally {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadPolitica() async {
    String apiUrl = '${UrlGlobales.UrlBase}get-politica';
    setState(() {
      _loadingPolitica = true;
    });
    try {
      final response = await http.get(Uri.parse(apiUrl));
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        String politicaData = responseBody['data'] ?? '';
        _showPrivacyPolicy(context, politicaData);
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud");
    } finally {
      setState(() {
        _loadingPolitica = false;
      });
    }
  }

  void _showPrivacyPolicy(BuildContext context, String politicaData) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                  title:
                      Text('Aviso de privacidad', textAlign: TextAlign.center)),
              SizedBox(height: 10),
              Expanded(
                  child: SingleChildScrollView(
                      child: Text(politicaData,
                          style: TextStyle(fontSize: 16.0)))),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Column(children: [
          SizedBox(height: 100),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image.asset('assets/images/logo.png', width: 200)]),
          SizedBox(height: 50),
          Container(
              margin: EdgeInsets.all(30),
              child: Form(
                  key: _formKey,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
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
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon:
                                  Icon(Icons.email, color: Color(0xFFDA1616)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                // borderSide: BorderSide(color: Colors.grey),
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFDA1616)),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa un usuario.';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Container(
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
                              controller: _passwordController,
                              textInputAction: TextInputAction.done,
                              focusNode: myfocusNode,
                              obscureText: !_passwordVisible,
                              autofocus: false,
                              decoration: InputDecoration(
                                  labelText: "Contraseña",
                                  prefixIcon: Icon(Icons.password,
                                      color: Color(0xFFDA1616)),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFFDA1616)),
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _passwordVisible = !_passwordVisible;
                                          FocusScope.of(context)
                                              .requestFocus(myfocusNode);
                                        });
                                      },
                                      icon: Icon(
                                          _passwordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.black,
                                          size: 20.0))),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa una contraseña.';
                                }
                                return null;
                              }),
                        ),
                        SizedBox(height: 24.0),
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
                                  return Color(0xFFDA1616);
                                },
                              ),
                              shape: MaterialStateProperty.all<OutlinedBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                            onPressed: _loading ? null : _login,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: _loading
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    )
                                  : Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ]))),
          SizedBox(height: 16.0),
          TextButton(
            onPressed: _loadingPolitica
                ? null
                : _loadPolitica, // Deshabilitar el botón cuando se está cargando
            child: _loadingPolitica
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ) // Mostrar indicador de progreso
                : Text(
                    'Aviso de privacidad',
                    style: TextStyle(color: Colors.red),
                  ),
          ),
          Text('3.0.8')
        ]))));
  }
}
