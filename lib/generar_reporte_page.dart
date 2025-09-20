import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adcom/urlGlobal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GenerarReportePage extends StatefulWidget {
  const GenerarReportePage({Key? key}) : super(key: key);

  @override
  State<GenerarReportePage> createState() => _GenerarReportePageState();
}

class _GenerarReportePageState extends State<GenerarReportePage> {
  int _currentStep = 0;
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  List<XFile?> _selectedImages = List.filled(3, null);
  bool _loadingSaveReport = false;
  bool hide = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _descripcionController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
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
    String descripcion = _descripcionController.text;
    int? idCom;
    int? idResidente;

    var uri = Uri.parse(UrlGlobales.UrlBase + 'reportes');
    var request = http.MultipartRequest('POST', uri);

    for (int i = 0; i < _selectedImages.length; i++) {
      if (_selectedImages[i] != null) {
        var stream = http.ByteStream(_selectedImages[i]!.openRead());
        var length = await _selectedImages[i]!.length();
        var multipartFile = http.MultipartFile('img[]', stream, length,
            filename: 'image_$i.jpg');
        request.files.add(multipartFile);
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    idCom = prefs.getInt('ID_COM');
    idResidente = prefs.getInt('ID_RESIDENTE');

    var params = {
      'idCom': idCom,
      'descripcionLarga': descripcion,
      'idUsusarioResidente': idResidente,
      'descripcionCorta': nombre,
    };

    request.fields['params'] = jsonEncode(params);

    try {
      final response = await request.send();
      final List<int> responseBodyBytes = await response.stream.toBytes();
      final responseBody = utf8.decode(responseBodyBytes);

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(responseBody);
        print(jsonResponse);

        if (jsonResponse['value'] == 1) {
          Fluttertoast.showToast(
              msg: "Se ha generado el reporte.", backgroundColor: Colors.red);
          Navigator.of(context).pop();
        } else {
          Fluttertoast.showToast(
              msg: "Error al generar el reporte.", backgroundColor: Colors.red);
        }
      } else {
        Fluttertoast.showToast(
            msg: "Error en el servidor ${response.statusCode}",
            backgroundColor: Colors.red);
      }
    } catch (error) {
      Fluttertoast.showToast(
          msg: "Error en la solicitud", backgroundColor: Colors.red);
    } finally {
      setState(() {
        _loadingSaveReport = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reportes', style: TextStyle(color: Colors.white)),
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
                Fluttertoast.showToast(msg: 'Por favor, ingrese un nombre.');
              }
            } else if (_currentStep == 1) {
              if (_descripcionController.text.isNotEmpty) {
                setState(() {
                  _currentStep += 1;
                });
              } else {
                Fluttertoast.showToast(
                    msg: 'Por favor, ingrese una descripción.');
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
              title: Text('Nombre del reporte.'),
              content: Column(children: [
                SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey,
                            blurRadius: 2,
                            offset: Offset(0, 0))
                      ]),
                  child: TextFormField(
                    controller: _nombreController,
                    cursorColor: Colors.blue,
                    decoration: InputDecoration(
                      labelText: 'Nombre del reporte',
                      labelStyle: TextStyle(color: Colors.blue),
                      prefixIcon: Icon(Icons.report_problem_outlined,
                          color: Colors.blue),
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
                    ),
                  ),
                ),
                SizedBox(height: 30)
              ]),
              state: _nombreController.text.isNotEmpty
                  ? StepState.complete
                  : StepState.indexed,
            ),
            Step(
              title: Text('Descripción del incidente.'),
              content: Column(children: [
                SizedBox(height: 5),
                TextFormField(
                    controller: _descripcionController,
                    cursorColor: Colors.blue,
                    decoration: InputDecoration(
                      labelText: 'Descripción del incidente',
                      labelStyle: TextStyle(color: Colors.blue),
                      prefixIcon:
                          Icon(Icons.description_outlined, color: Colors.blue),
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
              ]),
              state: _descripcionController.text.isNotEmpty
                  ? StepState.complete
                  : StepState.indexed,
            ),
            Step(
              title: Text('Sube algunas fotos.'),
              content: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildImagePicker(0),
                      _buildImagePicker(1),
                      _buildImagePicker(2),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
          controlsBuilder: (BuildContext ctx, ControlsDetails dtl) {
            return _currentStep == 0
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: dtl.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(10.0),
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          hide == true ? '' : 'Continuar',
                          style: TextStyle(color: Colors.white),
                        ),
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
                                  padding: EdgeInsets.all(10.0),
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8.0))),
                              child: _loadingSaveReport
                                  ? CircularProgressIndicator()
                                  : Text('Generar Reporte',
                                      style: TextStyle(color: Colors.white))),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: dtl.onStepCancel,
                            style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.all(10.0),
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
                                padding: EdgeInsets.all(10.0),
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
                                padding: EdgeInsets.all(10.0),
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
