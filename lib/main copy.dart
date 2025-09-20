import 'dart:async';

import 'package:adcom/acceso_residencial_page.dart';
import 'package:adcom/amenidades_page.dart';
import 'package:adcom/bitacora_accesos.dart';
import 'package:adcom/directorio_page.dart';
import 'package:adcom/home_page.dart';
import 'package:adcom/login_page.dart';
import 'package:adcom/mispagos_page.dart';
import 'package:adcom/mostrar_avisos_page.dart';
import 'package:adcom/reportes_page.dart';
import 'package:adcom/screensItems.dart';
import 'package:adcom/servicios_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:adcom/urlGlobal.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions(); // Solicitar permisos antes de iniciar la aplicación
  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  await Permission.camera.request();
  await Permission.storage.request();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adcom',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
      routes: {
        '/MisPagos': (context) => MisPagosPage(),
        '/Amenidades': (context) => AmenidadesPage(),
        '/Reportes': (context) => ReportesPage(),
        '/Avisos': (context) => MostrarAvisosPage(),
        '/Directorio': (context) => DirectorioPage(),
        '/Acceso': (context) => AccesoResidencialPage(),
        '/BitacoraAccesos': (context) => BitacoraAccesos(),
        '/LoginPage': (context) => LoginPage(
            onLogin:
                (int? perfil, String? especialidades, int? extComunidades) {}),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoggedIn = false;
  bool _statusVersion = false;
  int currentPageIndex = 0;
  String? usuarioM;
  String? passwordM;
  List<ScreensItems> myList = [];
  bool charger = true;
  int? _idPerfil;
  String? _especialidades = '0';
  int? _extComunidades;
  String? _currentVersion;

  @override
  void initState() {
    super.initState();
    _login();
    _initializeExtComunidades(); // Inicializar _extComunidades
    _validarVersion();
  }

  Future<void> _initializeExtComunidades() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _extComunidades = prefs.getInt('extComunidades');
  }

  int compararVersion(String currentVersion, String versionActual) {
    int currentVersionInt = int.parse(currentVersion.replaceAll('.', ''));
    int versionActualInt = int.parse(versionActual.replaceAll('.', ''));

    if (currentVersionInt >= versionActualInt) {
      return 1;
    }
    return 0;
  }

  Future<void> _validarVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;
    String apiUrl = '${UrlGlobales.UrlBase}version-app';
    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'Version': _currentVersion.toString(),
        'Dispositivo': 'Android'
      });
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseBody['Value'] == 1) {
          int respuesta =
              compararVersion(currentVersion, responseBody['Version']);
          if (respuesta == 1) {
            setState(() {
              _statusVersion = true;
            });
          } else {
            setState(() {
              _statusVersion = false;
            });
          }
        } else {
          setState(() {
            _statusVersion = false;
          });
        }
      } else {
        Fluttertoast.showToast(msg: "Error en el servidor.");
      }
    } on TimeoutException {
      Fluttertoast.showToast(msg: "Tiempo de espera agotado.");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud.");
    } finally {
      setState(() {
        charger = false;
      });
    }
  }

  Future<void> _login() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    usuarioM = prefs.getString('userM');
    passwordM = prefs.getString('passM');
    String apiUrl = '${UrlGlobales.UrlBase}login-app';
    final requestBody = {'username': usuarioM, 'password': passwordM};

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        "params": jsonEncode(requestBody)
      }).timeout(Duration(seconds: 10));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
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
          prefs.setString('userM', usuarioM!);
          prefs.setString('passM', passwordM!);
          prefs.setInt('extComunidades', responseBody['extComunidades']);

          int? extComunidades = prefs.getInt('extComunidades');
          int? idPerfil = prefs.getInt('ID_PERFIL');
          if (idPerfil != 2) {
            setState(() {
              _especialidades = responseBody['infoUsuario']['ESPECIALIDADES'];
            });
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

          setState(() {
            _isLoggedIn = true;
            _idPerfil = idPerfil;
            _extComunidades = extComunidades;
          });
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
    } on TimeoutException {
      Fluttertoast.showToast(msg: "Tiempo de espera agotado.");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud.");
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    if (charger) {
      return Scaffold(
          body: Center(
        child: CircularProgressIndicator(),
      ));
    } else if (!_statusVersion) {
      return Scaffold(
        body: _showUpdateDialog(),
      );
    } else {
      if (!_isLoggedIn) {
        return LoginPage(onLogin:
            (int? perfil, String? especialidades, int? extComunidades) {
          setState(() {
            _idPerfil = perfil;
            _especialidades = especialidades;
            _extComunidades = extComunidades;
            _isLoggedIn = true;
            currentPageIndex = 0;
          });
        });
      }

      if (_extComunidades == 1) {
        // Si extComunidades es igual a 1, entrar directamente al return
        return _idPerfil == 2 || _especialidades != '11'
            ? Scaffold(
                bottomNavigationBar: CurvedNavigationBar(
                  backgroundColor: Colors.white,
                  color: Colors.red,
                  buttonBackgroundColor: Colors.red,
                  height: 65,
                  animationCurve: Curves.easeInOut,
                  items: <Widget>[
                    Icon(Icons.home, size: 30, color: Colors.white),
                    Icon(Icons.home_repair_service,
                        size: 30, color: Colors.white),
                    Icon(Icons.exit_to_app, size: 30, color: Colors.white),
                  ],
                  onTap: (index) async {
                    if (index == 2) {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.clear();
                      setState(() {
                        _isLoggedIn = false;
                        currentPageIndex = index;
                      });
                    } else {
                      setState(() {
                        currentPageIndex = index;
                      });
                    }
                  },
                ),
                body: IndexedStack(
                  index: currentPageIndex,
                  children: <Widget>[
                    HomePage(),
                    ServiciosPage(),
                  ],
                ),
              )
            : Scaffold(
                bottomNavigationBar: CurvedNavigationBar(
                  backgroundColor: Colors.white,
                  color: Colors.red,
                  buttonBackgroundColor: Colors.red,
                  height: 65,
                  animationCurve: Curves.easeInOut,
                  items: <Widget>[
                    Icon(Icons.home, size: 30, color: Colors.white),
                    Icon(Icons.home_repair_service,
                        size: 30, color: Colors.white),
                    Icon(Icons.qr_code_2_outlined,
                        size: 30, color: Colors.white),
                    Icon(Icons.exit_to_app, size: 30, color: Colors.white),
                  ],
                  onTap: (index) async {
                    if (index == 3) {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.clear();
                      setState(() {
                        _isLoggedIn = false;
                        currentPageIndex = index;
                      });
                    } else {
                      setState(() {
                        currentPageIndex = index;
                      });
                    }
                  },
                ),
                body: IndexedStack(
                  index: currentPageIndex,
                  children: <Widget>[
                    HomePage(),
                    ServiciosPage(),
                    AccesoResidencialPage()
                  ],
                ),
              );
      } else {
        // Si extComunidades no es igual a 1, mostrar los botones para seleccionar
        return Scaffold(
          appBar: AppBar(
            title: Text('Seleccione una opción'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HelloWorldScreen()),
                    );
                  },
                  child: Text('Botón 1'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HelloWorldScreen()),
                    );
                  },
                  child: Text('Botón 2'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Widget _showUpdateDialog() {
    return AlertDialog(
      backgroundColor: Colors.white, // Fondo del diálogo
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0), // Bordes redondeados
      ),
      title: Text(
        'Actualización Requerida',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent, // Color de texto del título
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        'Por favor, actualiza la aplicación para continuar.',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700], // Color del texto del contenido
        ),
        textAlign: TextAlign.center,
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey[200], // Color de fondo del botón
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: Text(
            'Cerrar',
            style: TextStyle(
              color: Colors.black, // Color del texto del botón
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            Future.delayed(Duration(milliseconds: 100), () {
              SystemNavigator.pop();
            });
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.blueAccent, // Color de fondo del botón
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: Text(
            'Actualizar',
            style: TextStyle(
              color: Colors.white, // Color del texto del botón
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            _redirectToStoreAndExit();
          },
        ),
      ],
    );
  }
}

void _redirectToStoreAndExit() async {
  Uri url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.soluciones.adcom&pcampaignid=web_share');

  // Intenta lanzar la URL
  if (await launchUrl(url)) {
    // Si se lanza correctamente, espera un breve momento y cierra la app
    Future.delayed(Duration(milliseconds: 500), () {
      SystemNavigator.pop();
    });
  } else {
    print('No se pudo abrir la URL: $url');
  }
}

class HelloWorldScreen extends StatefulWidget {
  HelloWorldScreen({super.key});

  @override
  _HelloWorldScreenState createState() => _HelloWorldScreenState();
}

class _HelloWorldScreenState extends State<HelloWorldScreen> {
  int? currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: Colors.red,
        buttonBackgroundColor: Colors.red,
        height: 65,
        animationCurve: Curves.easeInOut,
        items: <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.home_repair_service, size: 30, color: Colors.white),
          Icon(Icons.qr_code_2_outlined, size: 30, color: Colors.white),
          Icon(Icons.exit_to_app, size: 30, color: Colors.white),
        ],
        onTap: (index) async {
          if (index == 3) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HelloWorldScreenDos()),
              (route) => false,
            );
          } else {
            setState(() {
              currentPageIndex = index;
            });
          }
        },
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: <Widget>[
          HomePage(),
          ServiciosPage(),
          AccesoResidencialPage()
        ],
      ),
    );
  }
}

class HelloWorldScreenDos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello World'),
      ),
      body: Center(
        child: Text(
          'Hello World!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
