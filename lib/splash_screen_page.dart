import 'package:adcom/main.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'urlGlobal.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    String? usuarioM = prefs.getString('userM');
    String? passwordM = prefs.getString('passM');
    String apiUrl = '${UrlGlobales.UrlBase}login-app';
    final requestBody = {'username': usuarioM, 'password': passwordM};

    try {
      final response = await http
          .post(Uri.parse(apiUrl), body: {"params": jsonEncode(requestBody)});

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseBody['value'] == 0) {
          await prefs.clear();
          prefs.setBool('isLoggedIn', false);
        } else {
          prefs.setInt('ID', responseBody['ID']);
          prefs.setInt('ID_COM', responseBody['ID_COM']);
          prefs.setInt('ID_PERFIL', responseBody['ID_PERFIL']);
          prefs.setInt('ID_RESIDENTE', responseBody['ID_RESIDENTE']);
          prefs.setString('USUARIO', responseBody['USUARIO']);
          prefs.setString('NombreResidente', responseBody['NombreResidente']);
          prefs.setString('email', responseBody['email']);
          prefs.setString('contrasenia', responseBody['contrasenia']);
          prefs.setBool('isLoggedIn', true);
          prefs.setString('userM', usuarioM!);
          prefs.setString('passM', passwordM!);

          int? idPerfil = prefs.getInt('ID_PERFIL');
          if (idPerfil != 2) {
            prefs.setString('ESPECIALIDADES',
                responseBody['infoUsuario']['ESPECIALIDADES']);
            prefs.setInt('CODI', responseBody['infoUsuario']['CODI']);
          }
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud");
    } finally {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      } else {
        /* Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );*/
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Puedes personalizar la pantalla de carga según tus necesidades.
        child: CircularProgressIndicator(),
      ),
    );
  }
}
