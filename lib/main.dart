import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 231, 157, 66)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dashboard'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class Service {
  final String? id;
  final String? patient;
  final String? category;
  final String? createAt;
  final String? allocatedAgent;
  final String? requestTimestamp;
  final String? acceptTimestamp;
  final String? rating;
  final String? agentFeedback;

  Service({
    this.id,
    this.patient,
    this.category,
    this.createAt,
    this.allocatedAgent,
    this.requestTimestamp,
    this.acceptTimestamp,
    this.rating,
    this.agentFeedback,
  });
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    socket = IO.io('http://localhost:3010/HAC',
        IO.OptionBuilder().setTransports(['websocket']).build());

    socket.onConnect((_) {
      print('conectado no socket');
    });

    socket.on('services_list', (data) {
      if (data is List<dynamic>) {
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            if (item['acceptTimestamp'] == null) {
              print('Serviços recebidos: $item');
              addService(item);
            }
          }
        }
      }
    });

    socket.on('new_service', (data) {
      print('Serviço recebido: $data');
      addService(data);
    });

    socket.on('service_accepted', (data) {
      print('Serviço aceito: $data');
      services.removeWhere((service) {
        return service.id == data['id'] &&
            service.patient == data['patient'] &&
            service.category == data['category'] &&
            service.createAt == data['createAt'];
      });

      setState(() {});
    });
  }

  late final IO.Socket socket;

  List<Service> services = [];

  void addService(Map<String, dynamic> data) {
    Service service = Service(
        id: data['id'],
        patient: data['patient'],
        category: data['category'],
        createAt: data['createAt'],
        allocatedAgent: data['allocatedAgent'],
        requestTimestamp: data['requestTimestamp'],
        acceptTimestamp: data['acceptTimestamp'],
        rating: data['acceptTimestamp'],
        agentFeedback: data['acceptTimestamp']);
    services.add(service);
    setState(() {});
  }

  void removeAndEmitService(Service service) {
    services.remove(service);
    print('O serviço ${service.id} foi aceito');
    socket.emit('accept_service', service.id);
    setState(() {});
  }

  String formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  List<Widget> buildCardList(List<Service> services) {
    List<Widget> cardWidgets = [];
    for (Service service in services) {
      cardWidgets.add(
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                title: Text(service.id ?? ''),
                subtitle: Text(formatTimestamp(service.createAt ?? '')),
              ),
              Text(
                service.category ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                service.patient ?? '',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () {
                  removeAndEmitService(service);
                },
                child: const Text('Aceitar serviço'),
              ),
            ],
          ),
        ),
      );
    }
    return cardWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: ListView(
        children: buildCardList(services),
      ),
    );
  }
}
