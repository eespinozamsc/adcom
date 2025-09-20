import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adcom/urlGlobal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeguimientoReportePage extends StatefulWidget {
  final dynamic idReporte;
  final dynamic idPerfil;
  const SeguimientoReportePage(
      {Key? key, required this.idReporte, required this.idPerfil})
      : super(key: key);

  @override
  State<SeguimientoReportePage> createState() => _SeguimientoReportePage();
}

class _SeguimientoReportePage extends State<SeguimientoReportePage> {
  int _currentStep = 0;
  late TextEditingController _nombreController;
  List<XFile?> _selectedImages = List.filled(3, null);
  bool _loadingSaveReport = false;
  List<Map<String, dynamic>> _opcionesSeguimiento = [];
  int? _idProgresoSeleccionado;
  bool hide = false;
  int _selectedOption = -1;

  @override
  void initState() {
    super.initState();
    _getStatusProgreso();
    _nombreController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _getStatusProgreso() async {
    String apiUrl = '${UrlGlobales.UrlBase}get-status-progreso';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          setState(() {
            _opcionesSeguimiento = List.from(responseBody['data']);
          });
        } else {
          Fluttertoast.showToast(msg: 'Error al cargar los estatus');
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error en la solicitud");
    }
  }

  Future<void> _getImage(int index) async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _selectedImages[index] = pickedFile;
    });
  }

  Widget _buildImagePicker(int index) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 100,
                width: double.infinity,
                color: Colors.white,
                child: _selectedImages[index] != null
                    ? Image.file(File(_selectedImages[index]!.path))
                    : Container(),
              ),
              if (_selectedImages[index] == null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.add_photo_alternate),
                    onPressed: () => _getImage(index),
                  ),
                )
              else
                Positioned(
                  top: 0,
                  right: 0,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteImage(index),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  void _deleteImage(int index) {
    setState(() {
      _selectedImages[index] = null;
    });
  }

  void _saveReport() async {
    setState(() {
      _loadingSaveReport = true;
    });

    String nombre = _nombreController.text;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('ID');

    var uri = Uri.parse(UrlGlobales.UrlBase + 'registrar-seguimiento');
    var request = http.MultipartRequest('POST', uri);

    for (int i = 0; i < _selectedImages.length; i++) {
      if (_selectedImages[i] != null) {
        var stream = http.ByteStream(_selectedImages[i]!.openRead());
        var length = await _selectedImages[i]!.length();
        var multipartFile = http.MultipartFile('archivos[]', stream, length,
            filename: 'image_$i.jpg');
        request.files.add(multipartFile);
      }
    }

    var params = {
      'IdCaso': widget.idReporte,
      'coment': nombre,
      'usuarioId': id,
      'idSeguimiento': _selectedOption,
    };

    request.fields['data'] = jsonEncode(params);

    try {
      final response = await request.send();
      final List<int> responseBodyBytes = await response.stream.toBytes();
      final responseBody = utf8.decode(responseBodyBytes);

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(responseBody);

        if (jsonResponse['value'] == 1) {
          Fluttertoast.showToast(
              msg: "Se ha registrado el seguimiento.",
              backgroundColor: Colors.red);
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        } else {
          Fluttertoast.showToast(msg: 'Error al guardar el seguimiento.');
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Error en el servidor ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error en la solicitud');
    } finally {
      setState(() {
        _loadingSaveReport = false;
      });
    }
  }

  Widget buildCheckBox(Map<String, dynamic> opcion) {
    return Row(
      children: [
        Radio<int>(
          value: opcion['ID_PROGRESO'] as int,
          groupValue: _selectedOption,
          onChanged: (int? value) {
            setState(() {
              _selectedOption = value ?? -1;
            });
            print(_selectedOption);
          },
        ),
        Text(
          opcion['DESC_PROGRESO'] as String,
          style: TextStyle(fontSize: 17),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Seguimiento reporte',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              if (_nombreController.text.isNotEmpty) {
                setState(() {
                  _currentStep += 1;
                });
              } else {
                Fluttertoast.showToast(msg: 'Por favor, ingresa una respuesta');
              }
            } else if (_currentStep == 1) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              if (_idProgresoSeleccionado != null) {
                setState(() {
                  _currentStep += 1;
                });
              } else {
                Fluttertoast.showToast(
                    msg: 'Por favor, selecciona una opción de seguimiento');
              }
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          steps: [
            Step(
                title: Text('Respuesta.'),
                content: Column(children: [
                  SizedBox(height: 8),
                  TextFormField(
                      controller: _nombreController,
                      cursorColor: Colors.blue,
                      decoration: InputDecoration(
                        labelText: 'Redactar respuesta',
                        labelStyle: TextStyle(color: Colors.blue),
                        prefixIcon:
                            Icon(Icons.draw_outlined, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          // borderSide: BorderSide(color: Colors.grey),
                          borderSide: BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      )),
                  SizedBox(height: 30)
                ])),
            Step(
                title: Text('Sube algunas fotos.'),
                content: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildImagePicker(0),
                        _buildImagePicker(1),
                        _buildImagePicker(2)
                      ]),
                  SizedBox(height: 16)
                ])),
            Step(
              title: Text('Estatus.'),
              content: Column(
                children: [
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 1,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _opcionesSeguimiento
                          .map<Widget>((opcion) => buildCheckBox(opcion))
                          .toList(),
                    ),
                  ),
                  SizedBox(height: 30)
                ],
              ),
            ),
          ],
          controlsBuilder: (BuildContext ctx, ControlsDetails dtl) {
            return _currentStep == 0
                ? Row(
                    children: [
                      ElevatedButton(
                        onPressed: dtl.onStepContinue,
                        style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.all(16.0),
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            )),
                        child: Text(hide == true ? '' : 'Continuar',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                : _currentStep == 2
                    ? Row(
                        children: [
                          ElevatedButton(
                              onPressed:
                                  _loadingSaveReport ? null : _saveReport,
                              style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.all(14.0),
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8.0))),
                              child: _loadingSaveReport
                                  ? CircularProgressIndicator()
                                  : Text('Guardar Seguimiento',
                                      style: TextStyle(color: Colors.white))),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: dtl.onStepCancel,
                            style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.all(16.0),
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
                                padding: EdgeInsets.all(16.0),
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
                                padding: EdgeInsets.all(16.0),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0))),
                            child: Text(hide == true ? '' : 'Cancelar',
                                style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      );
          }),
    );
  }
}
