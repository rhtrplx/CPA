// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, avoid_print

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:file_upload/file_upload.dart';
import 'package:intl/intl.dart';
import 'dart:math';

void main() {
  runApp(const MainApp());
}

void calculateDistance() {
  var lat1 = 43.48964596660554;
  var lon1 = 6.354178996608254;
  var lat2 = 43.491856513149116;
  var lon2 = 6.368491263478705;

  var earthRadiusKm = 6371.0;

  var dLat = _degreesToRadians(lat2 - lat1);
  var dLon = _degreesToRadians(lon2 - lon1);

  lat1 = _degreesToRadians(lat1);
  lat2 = _degreesToRadians(lat2);

  var a = sin(dLat / 2) * sin(dLat / 2) +
      sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
  var c = 2 * atan2(sqrt(a), sqrt(1 - a));
  print(earthRadiusKm * c);
}

double _degreesToRadians(double degrees) {
  return degrees * pi / 180.0;
}

// Global variable for route coordinates
// Modify globalRouteFileCoordinates to a Map with waypoint name, long, lat, and threshold
Map<String, Map<String, dynamic>> globalRouteFileCoordinates = {};
List<Map<String, dynamic>> followDictionary = [];

// Assuming functions that utilize globalRouteFileCoordinates follow...

// Example modification in functions:
// Any function that iterates over globalRouteFileCoordinates or adds to it will need to be updated.
// For example, if there's a function that adds waypoints, it should now add a Map with long, lat, and threshold.

void addWaypoint(String name, double longitude, double latitude) {
  // Each waypoint has a threshold set to 100 by default
  globalRouteFileCoordinates[name] = {
    'longitude': longitude,
    'latitude': latitude,
    'threshold': 100,
  };
}

String _url = 'http://10.194.196.75';
FileUpload fileUpload = FileUpload();

// Global variable for waypoint validation
List<String> globalWaypointValidation = [];

Future<Map<String, Map<String, dynamic>>> ReadRouteFile() async {
  print("function: ReadRouteFile executed...");

  // Use FilePicker to select the file
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  if (result == null) {
    print("No file selected");
    return {};
  }

  String filePath = result.files.single.path!;
  String xmlString;
  try {
    xmlString = await File(filePath).readAsString();
    // print(xmlString);
  } catch (e) {
    print("Error reading file: $e");
    return {};
  }

  // Initialize the map to store waypoint details
  Map<String, Map<String, dynamic>> waypoints = {};

  try {
    final document = XmlDocument.parse(xmlString);
    // Directly extracting coordinates from all Point elements
    final coordinatesElements = document.findAllElements('coordinates');
    int waypointCounter = 1; // Used to name waypoints uniquely
    for (var coordinates in coordinatesElements) {
      List<String> coords = coordinates.innerText.trim().split(',');
      final longitude = double.parse(coords[0]);
      final latitude = double.parse(coords[1]);
      double altitude = coords.length > 2
          ? double.parse(coords[2])
          : 0.0; // Handle altitude if present

      // Constructing a waypoint name
      String waypointName = "Waypoint $waypointCounter";
      waypointCounter++;

      // Add waypoint details to the map, including a static threshold of 100
      waypoints[waypointName] = {
        'longitude': longitude,
        'latitude': latitude,
        'altitude': altitude, // Including altitude for completeness
        'threshold': 100,
      };
    }
  } catch (e) {
    print("Error parsing XML: $e");
    return {};
  }
  print(waypoints);
  return waypoints;
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: ChoseFilePage(),
    );
  }
}

class ChoseFilePage extends StatefulWidget {
  const ChoseFilePage({super.key});

  @override
  State<ChoseFilePage> createState() => ChoseRouteFilePage();
}

class ChoseRouteFilePage extends State<ChoseFilePage> {
  Future<void> selectAndReadFile() async {
    globalRouteFileCoordinates = await ReadRouteFile();
    if (globalRouteFileCoordinates.isNotEmpty) {
      print("Dans la condition...");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DisplayRouteFileContentPage(),
        ),
      );
    }
    print("Après la condition...");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text("CPA"),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: selectAndReadFile,
              child: const Text('Open route'),
            ),
            const ElevatedButton(
                onPressed: calculateDistance,
                child: Center(
                  child: Text("TEST"),
                ))
          ],
        ),
      ),
    );
  }
}

class DisplayRouteFileContentPage extends StatefulWidget {
  const DisplayRouteFileContentPage({super.key});

  @override
  State<DisplayRouteFileContentPage> createState() =>
      _DisplayRouteFileContentPageState();
}

class _DisplayRouteFileContentPageState
    extends State<DisplayRouteFileContentPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Route Coordinates",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const <DataColumn>[
                  DataColumn(
                    label: Text('Nom Waypoint'),
                  ),
                  DataColumn(
                    label: Text('Longitude'),
                  ),
                  DataColumn(
                    label: Text('Latitude'),
                  ),
                  DataColumn(
                    label: Text('Threshold'), // Add column for threshold
                  ),
                ],
                rows: globalRouteFileCoordinates.entries.map<DataRow>((entry) {
                  String name = entry.key;
                  Map<String, dynamic> details = entry.value;
                  String longitude = details['longitude'].toStringAsFixed(2);
                  String latitude = details['latitude'].toStringAsFixed(2);
                  String threshold =
                      details['threshold'].toString(); // Access threshold
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(Text(name)),
                      DataCell(Text(longitude)),
                      DataCell(Text(latitude)),
                      DataCell(Text(threshold)), // Display threshold
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to the next page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DisplayRacePage(),
                ),
              );
            },
            child: const Center(
              child: Text("GO"),
            ),
          ),
        ],
      ),
    );
  }
}

class DisplayRacePage extends StatefulWidget {
  const DisplayRacePage({super.key});

  @override
  State<DisplayRacePage> createState() => _DisplayRacePageState();
}

void DisplayRaceFunc() {
  print("FUNCTION: DisplayRaceFunc executed...");
}

class _DisplayRacePageState extends State<DisplayRacePage> {
  List<String> liveCoordinates = ["N/A", "N/A"];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      _updateLiveCoordinates();
    });
  }

  // Fonction pour obtenir les coordonnées en temps réel
  Future<void> _updateLiveCoordinates() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      setState(() {
        // Mettre à jour liveCoordinates si nécessaire
        liveCoordinates = [
          position.longitude.toStringAsFixed(5),
          position.latitude.toStringAsFixed(5),
        ];
        // Ajouter une nouvelle entrée dans followDictionary avec les coordonnées actuelles et l'heure
        followDictionary.add({
          'longitude': position.longitude.toStringAsFixed(5),
          'latitude': position.latitude.toStringAsFixed(5),
          'heure': currentTime,
        });
      });
    } catch (e) {
      print("Error updating live coordinates: $e");
    }
  }

  @override
  void dispose() {
    // Arrêter le timer lorsqu'il n'est plus nécessaire
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Suivi de la course en temps réel ici...",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Dernières coordonnées en temps réel :",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text("Longitude : ${liveCoordinates[0]}"),
                  Text("Latitude : ${liveCoordinates[1]}"),
                  const SizedBox(height: 10),
                  Text(
                    "Heure actuelle : ${DateFormat('HH:mm:ss').format(DateTime.now())}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const ElevatedButton(
            onPressed: DisplayRaceFunc,
            child: Center(
              child: Text("FIN"),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DisplayRaceResultPage(),
                ),
              );
            },
            child: const Center(
              child: Text("NEXT"),
            ),
          ),
        ],
      ),
    );
  }
}

class DisplayRaceResultPage extends StatefulWidget {
  const DisplayRaceResultPage({super.key});

  @override
  State<DisplayRaceResultPage> createState() => _DisplayRaceResultPageState();
}

Future<void> upload_follow_file() async {
  print("Pretending to upload the follow file...");
  String url = '$_url/request1';
  /* 
   uploadTwoFiles()
    Params: 
      String url,
      String fileKey1,
      String filePath1,
      String fileType1,
      String fileKey2,
  */
  var path1 = "/sdcard/Download/suivi_Mark.txt";
  var response1 = await fileUpload.uploadFile(url, 'text', path1, 'txt');
  print(response1);
}

Future<void> upload_result_file() async {
  print("Pretending to upload the result file...");
  String url = '$_url/request1';
  /* 
   uploadTwoFiles()
    Params: 
      String url,
      String fileKey1,
      String filePath1,
      String fileType1,
      String fileKey2,
  */
  var path1 = "/sdcard/Download/resultat_Mark.txt";
  var response1 = await fileUpload.uploadFile(url, 'text', path1, 'txt');
  print(response1);
}

class _DisplayRaceResultPageState extends State<DisplayRaceResultPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          Expanded(
              child: Center(
            child: Text("Résultat de la course ici..."),
          )),
          Row(children: [
            ElevatedButton(
                onPressed: upload_follow_file,
                child: Center(
                  child: Text("Envoyez suivi"),
                )),
            Spacer(),
            ElevatedButton(
                onPressed: upload_result_file,
                child: Center(
                  child: Text("Envoyer résultats"),
                ))
          ])
        ],
      ),
    );
  }
}
