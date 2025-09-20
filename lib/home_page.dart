import 'package:adcom/screensItems.dart';
import 'package:adcom/setting_user_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;
  bool showTemporaryText = true;

  String? _nombreResidente;
  int? _idPerfil;
  String? _especialidades;
  String? _nombreComunidad;
  String? _tipoUsuario;
  String? _noExterno;
  String? _noInterior;
  String? _calle;

  late ScreensItems misPagos;
  late ScreensItems amenidades;
  late ScreensItems reportes;
  late ScreensItems avisos;
  late ScreensItems directorio;
  late ScreensItems acceso;
  late ScreensItems bitacoraAcceso;

  late Map<int, List<ScreensItems>> pagesByProfile;
  late Map<int, List<ScreensItems>> pagesByEspecialidades;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(seconds: 5), () {
      setState(() {
        showTemporaryText = false;
      });
    });
    misPagos = ScreensItems(
        route: '/MisPagos',
        title: 'Mis Pagos',
        icon:
            Icon(Icons.show_chart_rounded, size: 60, color: Colors.lightGreen));
    amenidades = ScreensItems(
        route: '/Amenidades',
        title: 'Amenidades',
        icon: Icon(Icons.calendar_month_outlined,
            size: 60, color: Colors.purple));
    reportes = ScreensItems(
        route: '/Reportes',
        title: 'Reportes',
        icon: Icon(Icons.report_off_outlined, size: 60, color: Colors.blue));
    avisos = ScreensItems(
        route: '/Avisos',
        title: 'Avisos',
        icon: Icon(Icons.warning_amber_outlined, size: 60, color: Colors.grey));
    directorio = ScreensItems(
        route: '/Directorio',
        title: 'Directorio',
        icon: Icon(Icons.store_mall_directory_outlined,
            size: 60, color: Colors.green[600]));
    acceso = ScreensItems(
      route: '/Acceso',
      title: 'Acceso',
      icon: Icon(Icons.door_back_door_outlined, size: 60),
    );
    bitacoraAcceso = ScreensItems(
      route: '/BitacoraAccesos',
      title: 'Bitacora Accesos',
      icon: Icon(Icons.door_back_door_outlined, size: 60),
    );

    pagesByProfile = {
      1: [misPagos, amenidades, reportes, avisos],
      // 2: [directorio, reportes, amenidades, avisos],
      2: [directorio, reportes, amenidades, avisos, bitacoraAcceso],
      5: [amenidades, reportes, avisos],
    };

    pagesByEspecialidades = {
      11: [acceso]
    };

    checkPrefs();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> checkPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? nombreResidente = prefs.getString('NombreResidente');
    String? comunidad = prefs.getString('COMUNIDAD');
    int? idPerfil = prefs.getInt('ID_PERFIL');
    String? especialidades = prefs.getString('ESPECIALIDADES');
    String? noExterno = prefs.getString('NO_EXTERNO');
    String? noInterior = prefs.getString('NO_INTERIOR');
    String? calle = prefs.getString('CALLE');
    setState(() {
      if (idPerfil == 2) {
        _nombreResidente = 'Martha Falomir';
        _nombreComunidad = 'Administración';
      } else {
        _nombreResidente = nombreResidente;
        _nombreComunidad = comunidad;
        _noExterno = noExterno;
        _noInterior = noInterior;
        _calle = calle;
      }
      _idPerfil = idPerfil;
      _especialidades = especialidades;

      if (_idPerfil == 1) {
        _tipoUsuario = 'Propietario';
      } else if (_idPerfil == 2) {
        _tipoUsuario = 'Administrador';
      } else {
        _tipoUsuario = 'Inquilino';
      }
    });
  }

  List<ScreensItems> myList = [];

  String saludo() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos Dias';
    }
    if (hour < 19) {
      return 'Buenas Tardes';
    }
    return 'Buenas Noches';
  }

  @override
  Widget build(BuildContext context) {
    List<ScreensItems> profileItems = pagesByProfile[_idPerfil] ?? [];
    List<ScreensItems> especialidadesItems = pagesByEspecialidades[11] ?? [];
    List<ScreensItems> myList = (_especialidades == '11')
        ? (profileItems + especialidadesItems)
        : profileItems;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: 25),
            _buildListaOpciones(myList),
          ],
        ),
      ),
    );
  }

  Expanded _buildListaOpciones(List<ScreensItems> myList) {
    return Expanded(
      child: ListView.separated(
        itemCount: myList.length,
        separatorBuilder: (context, index) => SizedBox(height: 0),
        itemBuilder: (context, index) {
          if (index % 2 == 0) {
            int nextIndex = index + 1;
            if (nextIndex < myList.length) {
              return buildItemPairTile(myList[index], myList[nextIndex]);
            } else {
              return buildItemTile(myList[index]);
            }
          }
          return SizedBox.shrink();
        },
      ),
    );
  }

  Container _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10, top: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: Colors.grey, blurRadius: 3, offset: Offset(1, 0))
          ]),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text('¡${saludo()}!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            _idPerfil == 2
                ? Text('')
                : Row(
                    children: [
                      AnimatedOpacity(
                        opacity: showTemporaryText ? 1.0 : 0.0,
                        duration: Duration(seconds: 1),
                        child: Text(
                          '$_tipoUsuario',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SettingUserPage()));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Icon(Icons.people_alt_outlined, size: 30),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
        SizedBox(height: 15),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Flexible(
            child: Column(
              children: [
                Text(_nombreResidente.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 15),
                Text(_nombreComunidad.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 15),
                _idPerfil == 2
                    ? Text('')
                    : Text(
                        '${_calle != null ? (_calle!.length > 10 ? _calle!.substring(0, 10) + '...' : _calle) : ''} ${_noExterno.toString().trim()} - $_noInterior',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
          SizedBox(width: 5),
          Image.asset('assets/images/logo.png', width: 100)
        ]),
        SizedBox(height: 20),
      ]),
    );
  }

  Widget buildItemPairTile(ScreensItems item1, ScreensItems item2) {
    return Row(children: [
      Expanded(child: buildItemTile(item1)),
      Expanded(child: buildItemTile(item2)),
    ]);
  }

  Widget buildItemTile(ScreensItems item) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, item.route!);
      },
      child: Container(
        margin: EdgeInsets.only(left: 10, right: 10, bottom: 25),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.grey, blurRadius: 3, offset: Offset(0, 0))
            ]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(children: [
            SizedBox(height: 20),
            item.icon!,
            SizedBox(height: 10),
          ]),
          Text(item.title!, style: TextStyle(fontSize: 20)),
          SizedBox(height: 20),
        ]),
      ),
    );
  }
}
