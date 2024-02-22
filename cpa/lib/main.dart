// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, avoid_print

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:file_upload/file_upload.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:path_provider/path_provider.dart'; // Add path_provider dependency

void main() {
  runApp(const MainApp());
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
  //     overlays: [SystemUiOverlay.top]);
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  // var lat1 = 43.48964596660554;
  // var lon1 = 6.354178996608254;
  // var lat2 = 43.491856513149116;
  // var lon2 = 6.368491263478705;

  var earthRadiusKm = 6371.0;

  var dLat = _degreesToRadians(lat2 - lat1);
  var dLon = _degreesToRadians(lon2 - lon1);

  lat1 = _degreesToRadians(lat1);
  lat2 = _degreesToRadians(lat2);

  var a = sin(dLat / 2) * sin(dLat / 2) +
      sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
  var c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

// New function to append coordinates to a file
Future<void> add_to_follow_file(
    String longitude, String latitude, String time) async {
  try {
    // Obtain the directory where the app can write data.
    final directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/follow_file.txt';
    print(filePath);
    final String content =
        '$time, Longitude: $longitude, Latitude: $latitude\n';
    final file = File(filePath);

    // Append the content to the file.
    await file.writeAsString(content, mode: FileMode.append);
  } on FileSystemException catch (e) {
    print('FileSystemException: Cannot write to file, ${e.message}');
  } catch (e) {
    // Handle any other exceptions
    print('An unexpected error occurred: $e');
  }
}

double _degreesToRadians(double degrees) {
  return degrees * pi / 180.0;
}

Map<String, Map<String, dynamic>> globalRouteFileCoordinates = {};
Map<String, Map<String, dynamic>> validWaypoints = {};

void validWaypoint(
    String name, double longitude, double latitude, String time) {}

void getCurrentWaypointName(
    double currentLat, double currentLon, String currentTime) {
  String waypointName = "";

  print('----');
  // Remplacement de forEach par une boucle for-in
  for (var entry in globalRouteFileCoordinates.entries) {
    String name = entry.key;
    Map<String, dynamic> details = entry.value;
    print("Verifying if you're in $name");
    double waypointLat = details['latitude'];
    double waypointLon = details['longitude'];
    double distance =
        calculateDistance(currentLat, currentLon, waypointLat, waypointLon);
    print(details);
    print(distance * 100);
    print(details["time"]);

    if (details["time"] == null) {
      waypointName = name;
      print('Checking $waypointName');
      print("$validWaypoints");
      if (distance * 100 <= details['threshold']) {
        // Each waypoint has a threshold set to 100 by default
        if (validWaypoints[waypointName]?["time"] == null) {
          validWaypoints[waypointName] = {
            'longitude': currentLon,
            'latitude': currentLat,
            'time': currentTime,
          };
          break; // Sort de la boucle une fois le waypoint trouvé
        } else {
          print("You're inside $waypointName, but you already passed it.");
        }
      }
    }
  }
  print(validWaypoints);
}

String _url = 'http://10.194.196.75';
FileUpload fileUpload = FileUpload();

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
        'threshold': 1,
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
            // const ElevatedButton(
            //     onPressed: calculateDistance,
            //     child: Center(
            //       child: Text("TEST"),
            //     ))
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
  String currentWaypoint = "";
  late double distance;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      _updateLiveCoordinates();
      distance = calculateDistance(liveCoordinates[1] as double,
          liveCoordinates[0] as double, 43.4224414, 6.3563667);
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
          position.longitude.toString(),
          position.latitude.toString(),
        ];
        // Logique supplémentaire ici, si nécessaire
      });
      getCurrentWaypointName(
          position.latitude, position.longitude, currentTime);
    } catch (e) {
      print("Error updating live coordinates: $e");
    }
  }

  void stopTimer() {
    if (_timer.isActive) {
      _timer.cancel();
    }
  }

  @override
  void dispose() {
    stopTimer(); // Utilisez la nouvelle fonction stopTimer pour arrêter le timer
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
                  const SizedBox(
                    height: 5,
                  ),
                  // Text(distance)
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              stopTimer(); // Arrête le timer lorsque ce bouton est appuyé
              // Logique supplémentaire si nécessaire, par exemple naviguer vers une autre page
            },
            child: const Center(
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
  String url = '$_url/reception_fichiers.php';
  /* 
   uploadTwoFiles()
    Params: 
      String url,
      String fileKey1,
      String filePath1,
      String fileType1,
      String fileKey2,
  */
  var path1 = "/data/user/0/com.example.cpa/app_flutter/follow_file.txt";
  var response1 = await fileUpload.uploadFile(url, 'text', path1, 'txt');
  print(response1);
}

Future<void> upload_result_file() async {
  print("Pretending to upload the result file...");
  String url = '$_url/reception_fichiers.php';
  /* 
   uploadTwoFiles()
    Params: 
      String url,
      String fileKey1,
      String filePath1,
      String fileType1,
      String fileKey2,
  */
  var path1 = "/data/user/0/com.example.cpa/app_flutter/follow_file.txt";
  var response1 = await fileUpload.uploadFile(url, 'text', path1, 'txt');
  print(response1);
}

class _DisplayRaceResultPageState extends State<DisplayRaceResultPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Route performance",
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
                  // DataColumn(
                  //   label: Text('Longitude'),
                  // ),
                  // DataColumn(
                  //   label: Text('Latitude'),
                  // ),
                  DataColumn(
                    label: Text('Time'), // Add column for threshold
                  ),
                ],
                rows: validWaypoints.entries.map<DataRow>((entry) {
                  String name = entry.key;
                  Map<String, dynamic> details = entry.value;
                  // String longitude = details['longitude'].toStringAsFixed(2);
                  // String latitude = details['latitude'].toStringAsFixed(2);
                  String time = details['time'];
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(Text(name)),
                      // DataCell(Text(longitude)),
                      // DataCell(Text(latitude)),
                      DataCell(Text(time)), // Display threshold
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
