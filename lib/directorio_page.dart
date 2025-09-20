import 'package:adcom/detalle_residente_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adcom/urlGlobal.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectorioPage extends StatefulWidget {
  const DirectorioPage({super.key});

  @override
  State<DirectorioPage> createState() => _DirectorioPageState();
}

class _DirectorioPageState extends State<DirectorioPage> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _directorio = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> _directorioOriginal = [];

  @override
  void initState() {
    super.initState();
    _loadDirectorio();
  }

  Future<void> _loadDirectorio() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('ID');

    String apiUrl = '${UrlGlobales.UrlBase}get-directorio';
    final requestBody = {'usuarioId': id};

    try {
      final response = await http
          .post(Uri.parse(apiUrl), body: {'params': jsonEncode(requestBody)});
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _directorioOriginal =
              List<Map<String, dynamic>>.from(responseBody['residente']);
          _directorio =
              List<Map<String, dynamic>>.from(responseBody['residente']);
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

  void _filterDirectorio(String query) {
    setState(() {
      _directorio = _directorioOriginal
          .where((residente) => residente['NOMBRE_RESIDENTE']
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

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
                      topRight: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    _buildSearch(),
                    SizedBox(height: 8),
                    Expanded(
                        child: _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : _directorio.isEmpty
                                ? Center(child: Text('Sin residentes'))
                                : _buildDirectorioList())
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  ListView _buildDirectorioList() {
    return ListView.builder(
      itemCount: _directorio.length,
      itemBuilder: (context, index) {
        final _direc = _directorio[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        DetalleResidentePage(residente: _direc)));
          },
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey, blurRadius: 1, offset: Offset(0, 0))
                ]),
            child: Column(
              children: [
                Text(_direc['NOMBRE_RESIDENTE']),
                Text(_direc['COM_NOMBRE'])
              ],
            ),
          ),
        );
      },
    );
  }

  Container _buildSearch() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(color: Colors.grey, blurRadius: 2, offset: Offset(0, 0))
          ]),
      margin: EdgeInsets.only(left: 20, right: 20),
      child: TextField(
        controller: _searchController,
        cursorColor: Colors.green,
        decoration: InputDecoration(
          labelText: 'Buscar por nombre',
          labelStyle: TextStyle(color: Colors.green),
          prefixIcon: Icon(Icons.search_outlined, color: Colors.green),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: OutlineInputBorder(
            // borderSide: BorderSide(color: Colors.grey),
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onChanged: (value) {
          // Lógica para realizar la búsqueda al cambiar el texto
          _filterDirectorio(value);
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
              child: Text('Directorio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
        SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
              child: Text(
                  'Mantente conectado con tu comunidad o asesores de tu comunidad.',
                  style: TextStyle(color: Colors.white, fontSize: 17))),
          Icon(Icons.show_chart_rounded, size: 80, color: Colors.white)
        ]),
        SizedBox(height: 10),
      ]),
    );
  }
}
