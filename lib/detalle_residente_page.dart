import 'package:adcom/pagos_residente_page.dart';
import 'package:flutter/material.dart';

class DetalleResidentePage extends StatefulWidget {
  final Map<String, dynamic> residente;
  const DetalleResidentePage({Key? key, required this.residente})
      : super(key: key);

  @override
  State<DetalleResidentePage> createState() => _DetalleResidentePageState();
}

class _DetalleResidentePageState extends State<DetalleResidentePage> {
  Widget buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 17,
          ),
        ),
        Flexible(
            child: Text('${value.trim()}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Column(
        children: [
          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20),
            height: 160,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
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
                      child: Text(
                        'Directorio',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  '${widget.residente['NOMBRE_RESIDENTE']}',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  '${widget.residente['COM_NOMBRE']}',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 30, top: 30, right: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  buildRow('Calle', '${widget.residente['CALLE']}'),
                  buildRow('Número', '${widget.residente['NUMERO']}'),
                  buildRow('No. Interior', '${widget.residente['INTERIOR']}'),
                  buildRow('Código postal', '${widget.residente['CP']}'),
                  buildRow('Celular', '${widget.residente['TELEFONO_CEL']}'),
                  buildRow('Email', '${widget.residente['EMAIL']}'),
                  SizedBox(
                    height: 30,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.only(
                        left: 50,
                        right: 50,
                        top: 15,
                        bottom: 15,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PagosResidentePage(
                            idResidente: {widget.residente['ID_RESIDENTE']},
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Ver historial de pagos',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
