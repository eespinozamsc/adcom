import 'dart:collection';
import 'package:adcom/reservaramenidad_page.dart';
import 'package:adcom/urlGlobal.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendarioAmenidadPage extends StatefulWidget {
  final dynamic idCom;
  final dynamic idAmenidad;
  final dynamic necReserva;
  const CalendarioAmenidadPage(
      {super.key, this.idAmenidad, this.necReserva, this.idCom});

  @override
  State<CalendarioAmenidadPage> createState() => _CalendarioAmenidadPageState();
}

class _CalendarioAmenidadPageState extends State<CalendarioAmenidadPage> {
  List<Map<String, dynamic>> reservas = [];
  late final ValueNotifier<List<Event>> _selectedEvents;
  final ValueNotifier<DateTime> _focusedDay = ValueNotifier(DateTime.now());
  final Set<DateTime> _selectedDays = LinkedHashSet<DateTime>(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  late PageController _pageController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isLoading = true;
  int? _idPerfil;
  bool _loadingReglamento = false;

  @override
  void initState() {
    super.initState();

    _selectedDays.add(_focusedDay.value);
    _selectedEvents = ValueNotifier(_getEventsForDay(_focusedDay.value));
    _loadPerfil();
    _loadReservasAmenidad();
  }

  Future<void> _loadPerfil() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _idPerfil = prefs.getInt('ID_PERFIL');
  }

  Future<void> _loadReservasAmenidad() async {
    String apiUrl = '${UrlGlobales.UrlBase}get-status-amenidades';

    try {
      final response = await http.post(Uri.parse(apiUrl),
          body: {'idAmenidad': widget.idAmenidad.toString()});
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          setState(() {
            reservas = List<Map<String, dynamic>>.from(responseBody['data']);
          });

          kEvents.clear();

          for (final reserva in reservas) {
            final fechaIni = DateTime.parse(reserva['fechaIniReserva']);
            final fechaFin = DateTime.parse(reserva['fechaFinReserva']);
            final DateFormat formatoDia = DateFormat('EEEE dd');
            final DateFormat formatoHora = DateFormat('HH:mm');
            final String fechaFormateada =
                '${formatoDia.format(fechaIni)}, ${formatoHora.format(fechaIni)}hrs - ${formatoHora.format(fechaFin)}hrs';
            final title = reserva['comentario'];
            final subtitle = fechaFormateada;

            for (var date = fechaIni;
                date.isBefore(fechaFin);
                date = date.add(Duration(days: 1))) {
              final events = kEvents[date] ?? [];
              events.add(Event(title, subtitle));
              kEvents[date] = events;
            }
          }
        } else {
          Fluttertoast.showToast(msg: 'Error al cargar las amenidades');
        }
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

  Future<void> _loadReglamento() async {
    setState(() {
      _loadingReglamento = true;
    });

    String apiUrl = '${UrlGlobales.UrlBase}get-relgamento-amenidad';
    final requestBody = {
      'idCom': widget.idCom,
      'idAmendiad': widget.idAmenidad
    };

    try {
      final response = await http
          .post(Uri.parse(apiUrl), body: {'params': jsonEncode(requestBody)});
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseBody['value'] == 1) {
          String reglamentoData = responseBody['data'] ?? '';
          _showReglamento(context, reglamentoData);
        } else {
          Fluttertoast.showToast(msg: 'Aun no hay reglamento');
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Error en el servidor ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error en la solicitud');
    } finally {
      setState(() {
        _loadingReglamento = false;
      });
    }
  }

  void _showReglamento(BuildContext context, String reglamentoData) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.all(15.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ListTile(title: Text('Reglamento', textAlign: TextAlign.center)),
              SizedBox(height: 10),
              Expanded(
                  child: SingleChildScrollView(child: Text(reglamentoData)))
            ]),
          );
        });
  }

  @override
  void dispose() {
    _focusedDay.dispose();
    _selectedEvents.dispose();
    super.dispose();
  }

  bool get canClearSelection =>
      _selectedDays.isNotEmpty || _rangeStart != null || _rangeEnd != null;

  List<Event> _getEventsForDay(DateTime day) {
    return kEvents[day] ?? [];
  }

  List<Event> _getEventsForDays(Iterable<DateTime> days) {
    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }

  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);
    return _getEventsForDays(days);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      if (_selectedDays.contains(selectedDay)) {
        _selectedDays.remove(selectedDay);
      } else {
        _selectedDays.add(selectedDay);
      }

      _focusedDay.value = focusedDay;
      _rangeStart = null;
      _rangeEnd = null;
      _rangeSelectionMode = RangeSelectionMode.toggledOff;
    });

    _selectedEvents.value = _getEventsForDays(_selectedDays);
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _focusedDay.value = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _selectedDays.clear();
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  Widget _buildMostrarCalendario() {
    return Column(
      children: [
        ValueListenableBuilder<DateTime>(
          valueListenable: _focusedDay,
          builder: (context, value, _) {
            return _CalendarHeader(
              focusedDay: value,
              clearButtonVisible: canClearSelection,
              onTodayButtonTap: () {
                setState(() => _focusedDay.value = DateTime.now());
              },
              onClearButtonTap: () {
                setState(() {
                  _rangeStart = null;
                  _rangeEnd = null;
                  _selectedDays.clear();
                  _selectedEvents.value = [];
                });
              },
              onLeftArrowTap: () {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              onRightArrowTap: () {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            );
          },
        ),
        _isLoading
            ? Column(
                children: [
                  SizedBox(height: 50),
                  Center(child: CircularProgressIndicator())
                ],
              )
            : Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white, // Color de fondo del elemento
                  borderRadius: BorderRadius.circular(10.0), // Borde redondeado
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey, // Color de la sombra
                      blurRadius: 5.0, // Radio de desenfoque de la sombra
                      offset: Offset(0,
                          3), // Desplazamiento de la sombra (horizontal, vertical)
                    ),
                  ],
                ),
                child: TableCalendar<Event>(
                  firstDay: kFirstDay,
                  lastDay: kLastDay,
                  focusedDay: _focusedDay.value,
                  headerVisible: false,
                  selectedDayPredicate: (day) => _selectedDays.contains(day),
                  rangeStartDay: _rangeStart,
                  rangeEndDay: _rangeEnd,
                  calendarFormat: _calendarFormat,
                  rangeSelectionMode: _rangeSelectionMode,
                  eventLoader: _getEventsForDay,
                  /* holidayPredicate: (day) {
                // Every 20th day of the month will be treated as a holiday
                return day.day == 20;
              }, */
                  onDaySelected: _onDaySelected,
                  onRangeSelected: _onRangeSelected,
                  onCalendarCreated: (controller) =>
                      _pageController = controller,
                  onPageChanged: (focusedDay) => _focusedDay.value = focusedDay,
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() => _calendarFormat = format);
                    }
                  },
                ),
              ),
        const SizedBox(height: 8.0),
        Expanded(
          child: ValueListenableBuilder<List<Event>>(
            valueListenable: _selectedEvents,
            builder: (context, value, _) {
              return ListView.builder(
                itemCount: value.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white, // Color de fondo del elemento
                      borderRadius:
                          BorderRadius.circular(10.0), // Borde redondeado
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey, // Color de la sombra
                          blurRadius: 5.0, // Radio de desenfoque de la sombra
                          offset: Offset(0,
                              3), // Desplazamiento de la sombra (horizontal, vertical)
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () => print('${value[index]}'),
                      title: Text(
                          '${value[index].title ?? 'Title not available'}'),
                      subtitle: Text(
                          '${value[index].subtitle ?? 'Subtitle not available'}'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSinReservar() {
    return Container(
        padding: EdgeInsets.only(left: 5, right: 5),
        child: Center(
          child: Text(
            'Esta amenidad no necesita reserva.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calendario de Reservas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: widget.necReserva.toString() == '0'
          ? _buildSinReservar()
          : _buildMostrarCalendario(),
      floatingActionButton: _idPerfil != 2 && widget.necReserva == 1
          ? FloatingActionButton.extended(
              backgroundColor: Colors.purple,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ReservarAmenidadPage(
                        reservas: reservas, idAmenidad: widget.idAmenidad)));
              },
              icon: Icon(Icons.add),
              label: Text("Nueva Reserva"))
          : _loadingReglamento
              ? CircularProgressIndicator()
              : FloatingActionButton.extended(
                  backgroundColor: Colors.purple,
                  onPressed: () {
                    _loadReglamento();
                  },
                  icon: Icon(Icons.rule_folder_outlined),
                  label: Text("Ver Reglamento")),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;
  final VoidCallback onTodayButtonTap;
  final VoidCallback onClearButtonTap;
  final bool clearButtonVisible;

  const _CalendarHeader({
    Key? key,
    required this.focusedDay,
    required this.onLeftArrowTap,
    required this.onRightArrowTap,
    required this.onTodayButtonTap,
    required this.onClearButtonTap,
    required this.clearButtonVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final headerText = DateFormat.yMMM().format(focusedDay);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 16.0),
          SizedBox(
            width: 150.0,
            child: Text(
              headerText,
              style: TextStyle(fontSize: 26.0),
            ),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today, size: 20.0),
            visualDensity: VisualDensity.compact,
            onPressed: onTodayButtonTap,
          ),
          if (clearButtonVisible)
            IconButton(
              icon: Icon(Icons.clear, size: 20.0),
              visualDensity: VisualDensity.compact,
              onPressed: onClearButtonTap,
            ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: onLeftArrowTap,
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: onRightArrowTap,
          ),
        ],
      ),
    );
  }
}
