// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, avoid_print, prefer_const_constructors

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
import 'package:mysql_client/mysql_client.dart';

String username = "CPA3";
String password = "7891235";
String bdd = "parcours_aerien";
String ip_bdd = '10.194.196.26';
String port_bdd = '3306';
int id_concurrent = 0;
int id_competition = 0;
int id_course = 0;
int id_parcours = 0;
Map<String, Map<String, dynamic>> validWaypoints = {};
String nomConcurrent = "";

void main() {
  runApp(const MainApp());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  var dist = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  return dist / 100;
}

Future<void> init_files() async {
  Directory? directory = await getExternalStorageDirectory();

  // Supprimer les fichiers existants s'ils existent
  if (directory != null) {
    await _deleteFileIfExists("${directory.path}/follow_file.txt");
    await _deleteFileIfExists("${directory.path}/result_file.txt");
  }

  // Reconstruire les fichiers
  String followFilePath = "${directory?.path}/follow_file.txt";
  String resultFilePath = "${directory?.path}/result_file.txt";

  String string =
      "Competition: $id_competition\nCourse: $id_course\nConcurrent: $id_concurrent\n";

  final file = File(followFilePath);
  final file2 = File(resultFilePath);

  await file.writeAsString(string, mode: FileMode.append);
  await file2.writeAsString(string, mode: FileMode.append);
}

Future<void> _deleteFileIfExists(String filePath) async {
  final file = File(filePath);
  if (await file.exists()) {
    await file.delete();
  }
}

// New function to append coordinates to a file
Future<void> add_to_follow_file(
    double longitude, double latitude, String time) async {
  try {
    // Obtain the directory where the app can write data.
    // final directory = await getApplicationDocumentsDirectory();
    // final String filePath = '${directory.path}/follow_file.txt';
    Directory? directory =
        await getExternalStorageDirectory(); // Obtient le répertoire de stockage externe, mais peut être null

    String filePath =
        "${directory?.path}/follow_file.txt"; // Construit le chemin du fichier

    print(filePath);
    final String content =
        'Heure: $time, Longitude: $longitude, Latitude: $latitude\n';
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

// New function to append coordinates to a file
Future<void> add_to_result_file(
    double longitude, double latitude, String time, String waypointName) async {
  try {
    // Obtain the directory where the app can write data.
    // final directory = await getApplicationDocumentsDirectory();
    // final String filePath = '${directory.path}/result_file.txt';
    Directory? directory =
        await getExternalStorageDirectory(); // Obtient le répertoire de stockage externe, mais peut être null

    String filePath =
        "${directory?.path}/result_file.txt"; // Construit le chemin du fichier

    print(filePath);
    final String content =
        'Nom waypoint: $waypointName, Heure: $time, Longitude: $longitude, Latitude: $latitude\n';
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

Map<String, Map<String, dynamic>> getCurrentWaypointName(
    double currentLat, double currentLon, String currentTime) {
  // Iterate through each waypoint to check proximity and update validation time if necessary
  for (var entry in validWaypoints.entries) {
    String name = entry.key;
    Map<String, dynamic> details = entry.value;
    double waypointLat = details['latitude'];
    double waypointLon = details['longitude'];
    double distance =
        calculateDistance(currentLat, currentLon, waypointLat, waypointLon) *
            100;

    // Update or add new waypoint details based on distance and existing validation
    if (distance <= details['threshold'] &&
        validWaypoints[name]?["validationTime"] == null) {
      validWaypoints[name] = {
        'longitude': waypointLon,
        'latitude': waypointLat,
        'altitude': details['altitude'],
        'validationTime': currentTime,
        'validationDistance': distance,
        'validationLongitude': currentLon,
        'validationLatitude': currentLat,
        'liveDistance': distance,
        'threshold': details['threshold'],
      };
      add_to_result_file(currentLon, currentLat, currentTime, name);
    } else {
      // Update liveDistance for all waypoints regardless of validation
      validWaypoints[name]?['liveDistance'] = distance;
    }
  }
  print(validWaypoints);
  return validWaypoints;
}

Future<Map<String, Map<String, dynamic>>> ReadRouteFile(
    int idConcurrent, int idCourse) async {
  Map<String, Map<String, dynamic>> waypoints = {};
  String? kmlContent = '';

  // Step 2: Fetch KML data from the database
  String query = "SELECT parcours FROM course WHERE idCourse = $idCourse";

  print(query);

  print("Connecting to mysql server...");

  // create connection
  final conn = await MySQLConnection.createConnection(
      host: ip_bdd,
      port: 3306,
      userName: username,
      password: password,
      databaseName: bdd, // optional
      secure: false);

  await conn.connect();

  print("Connected");

  var result = await conn.execute(query);

  // print query result
  for (final row in result.rows) {
    var parcours = row.assoc()['parcours'];
    print(parcours); // Print the parcours content

    // If you want to store the KML content for later processing
    kmlContent = parcours; // Assuming kmlContent is declared earlier
    break; // Remove this if you expect multiple rows and want to handle them all
  }

  // close all connections
  // await conn.close();
  // Step 3: Parse the KML content to extract waypoints
  try {
    final document = XmlDocument.parse(kmlContent!);
    final coordinatesElements = document.findAllElements('coordinates');
    int waypointCounter = 1;
    for (var coordinates in coordinatesElements) {
      List<String> coords = coordinates.text.trim().split(',');
      double longitude = double.parse(coords[0]);
      double latitude = double.parse(coords[1]);
      double altitude = coords.length > 2 ? double.parse(coords[2]) : 0.0;

      String waypointName = "Waypoint $waypointCounter";
      waypointCounter++;

      waypoints[waypointName] = {
        'longitude': longitude,
        'latitude': latitude,
        'altitude': altitude,
        'validationTime': null,
        'validationDistance': null,
        'validationLongitude': null,
        'validationLatitude': null,
        'liveDistance': null,
        'threshold': 10,
      };
    }
  } catch (e) {
    print("Error parsing XML: $e");
  }
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
    validWaypoints = await ReadRouteFile(id_concurrent, id_course);
    init_files();
    if (validWaypoints.isNotEmpty) {
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

  TextEditingController idConcurrentController = TextEditingController();
  TextEditingController idCourseController = TextEditingController();

  void updateIds() async {
    selectAndReadFile();
    int? newIdConcurrent = int.tryParse(idConcurrentController.text);
    if (newIdConcurrent == null) {
      // Handle invalid input for id_concurrent
      print("Invalid input for ID Concurrent");
      idConcurrentController.clear(); // Optional: Clear the input field
      return; // Exit the function to prevent further execution
    }

    int? newIdCourse = int.tryParse(idCourseController.text);
    if (newIdCourse == null) {
      // Handle invalid input for id_course
      print("Invalid input for ID Course");
      idCourseController.clear(); // Optional: Clear the input field
      return; // Exit the function to prevent further execution
    }

    // Update the global variables if both inputs are valid
    id_concurrent = newIdConcurrent;
    id_course = newIdCourse;
    String query =
        "SELECT Nom FROM `Concurrents` WHERE IDConcurrents = $id_concurrent";

    // create connection
    final conn = await MySQLConnection.createConnection(
        host: ip_bdd,
        port: 3306,
        userName: username,
        password: password,
        databaseName: bdd, // optional
        secure: false);

    await conn.connect();

    print("Connected");

    var result = await conn.execute(query);

    // print query result
    for (final row in result.rows) {
      nomConcurrent = row.assoc()['Nom']!;
      break; // Remove this if you expect multiple rows and want to handle them all
    }
    print("Here is $id_concurrent $nomConcurrent for the race id: $id_course");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CPA"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Center(child: Text("Coucou 👋")),
            const Center(child: Text("Bienvenue sur l'application CPA 🪂")),
            SizedBox(height: 50),
            Image.network(
                'https://thumbs.dreamstime.com/b/parachute-icon-vector-sports-icon-parachute-icon-106170386.jpg',
                width: 100,
                height: 100),
            const SizedBox(height: 150),
            const Center(child: Text("Qui est-ce ? 🙋‍♂️ 🙋‍♀️")),
            const SizedBox(height: 25),
            TextField(
              controller: idConcurrentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Votre numéro 🔢",
                border: OutlineInputBorder(
                  // Utilisation d'une bordure arrondie
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide(
                      color: const Color.fromARGB(255, 219, 33, 243),
                      width: 1.0),
                ),
                filled: true, // Ajout d'un fond de couleur
                fillColor: Color.fromARGB(255, 253, 237, 255),
                focusedBorder: OutlineInputBorder(
                  // Bordure plus prononcée lors de la sélection
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide(
                      color: const Color.fromARGB(255, 219, 33, 243),
                      width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: idCourseController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Numéro de la course 🏁",
                border: OutlineInputBorder(
                  // Utilisation d'une bordure arrondie
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide(
                      color: const Color.fromARGB(255, 219, 33, 243),
                      width: 1.0),
                ),
                filled: true, // Ajout d'un fond de couleur
                fillColor: Color.fromARGB(255, 253, 237, 255),
                focusedBorder: OutlineInputBorder(
                  // Bordure plus prononcée lors de la sélection
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide(
                      color: const Color.fromARGB(255, 219, 33, 243),
                      width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: updateIds,
              child: const Text('Valider ✅'),
            ),
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
        appBar: AppBar(
          title: const Text("CPA"),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            children: [
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
                        label: Text(
                            'Distance De Validation'), // Add column for threshold
                      ),
                    ],
                    rows: validWaypoints.entries.map<DataRow>((entry) {
                      String name = entry.key;
                      Map<String, dynamic> details = entry.value;
                      String longitude =
                          details['longitude'].toStringAsFixed(2);
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
              Text("Bonne chance $nomConcurrent ! 💪"),
              SizedBox(
                height: 25,
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
                  child: Text("GO 🏁"),
                ),
              ),
            ],
          ),
        ));
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
  List<double> liveCoordinates = [0, 0];
  late Timer _timer;
  String currentWaypoint = "";
  late double distance = 0;

  @override
  void initState() {
    _updateLiveCoordinates();
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      await _updateLiveCoordinates();
      setState(
          () {}); // Trigger UI update after liveCoordinates and validWaypoints are updated
    });
  }

  // Fonction pour obtenir les coordonnées en temps réel
  Future<void> _updateLiveCoordinates() async {
    try {
      print("Lecture de GPS...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      setState(() {
        // Mettre à jour liveCoordinates si nécessaire
        liveCoordinates = [
          position.latitude,
          position.longitude,
        ];
        // Logique supplémentaire ici, si nécessaire
      });
      getCurrentWaypointName(
          position.latitude, position.longitude, currentTime);
      add_to_follow_file(position.longitude, position.latitude, currentTime);
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
      appBar: AppBar(
        title: const Text("CPA"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const <DataColumn>[
                  DataColumn(
                    label: Text('Nom Waypoint'),
                  ),
                  DataColumn(
                    label: Text('validationTime'), // Add column for threshold
                  ),
                  DataColumn(
                    label: Text('liveDistance'), // Add column for threshold
                  ),
                ],
                rows: validWaypoints.entries.map<DataRow>((entry) {
                  String name = entry.key;
                  Map<String, dynamic> details = entry.value;
                  String validationTime = details['validationTime'].toString();
                  if (validationTime == "null") {
                    validationTime = "N/A";
                  }
                  String liveDistance =
                      details['liveDistance'].toString(); // Access threshold
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(Text(name)),
                      DataCell(Text(validationTime)),
                      DataCell(Text(liveDistance)), // Display threshold
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          Text(
            "Heure actuelle : ${DateFormat('HH:mm:ss').format(DateTime.now())}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(liveCoordinates.toString()),
          ElevatedButton(
            onPressed: () {
              stopTimer(); // Arrête le timer lorsque ce bouton est appuyé
            },
            child: const Center(
              child: Text("STOP ✋"),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              stopTimer();
              uploadDataToDatabase(id_course, id_concurrent);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DisplayRaceResultPage(),
                ),
              );
            },
            child: const Center(
              child: Text("Upload files to server 📨"),
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

Future<void> uploadDataToDatabase(int idCourse, int idConcurrent) async {
  // Read file contents
  // Read file content
  Directory? directory =
      await getExternalStorageDirectory(); // Obtient le répertoire de stockage externe, mais peut être null

  String followFilePath =
      "${directory?.path}/follow_file.txt"; // Construit le chemin du fichier
  print("Path to the file: $followFilePath");
  String resultFilePath =
      "${directory?.path}/result_file.txt"; // Construit le chemin du fichier
  print("Path to the file: $resultFilePath");

  String followContent = await File(followFilePath).readAsString();
  String resultContent = await File(resultFilePath).readAsString();

  // Database connection configuration
  final conn = await MySQLConnection.createConnection(
      host: ip_bdd,
      port: 3306,
      userName: username,
      password: password,
      databaseName: bdd,
      secure: false);

  await conn.connect();

  // Insert or update the database
  // String query = """
  //   INSERT INTO resultats (idCourse, idConcurrent, suivi, performance)
  //   VALUES ($idCourse, $idConcurrent, '$followContent', '$resultContent')
  //   ON DUPLICATE KEY UPDATE suivi = VALUES(suivi), performance = VALUES(performance);
  // """;

  // ALTER TABLE resultats ADD UNIQUE INDEX idx_unique_course_concurrent (idCourse, idConcurrent);
  // execute this command to update instead of inserting every time

  String query = """
    INSERT INTO resultats (idCourse, idConcurrent, suivi, performance)
    VALUES ($idCourse, $idConcurrent, '$followContent', '$resultContent')
    ON DUPLICATE KEY UPDATE suivi = '$followContent', performance = '$resultContent';
  """;

  await conn.execute(query);

  print("Data successfully updated or inserted.");

  await conn.close();
}

class _DisplayRaceResultPageState extends State<DisplayRaceResultPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CPA"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(
                  label: Text('Nom Waypoint'),
                ),
                DataColumn(
                  label: Text('Validation Time'), // Add column for threshold
                ),
                DataColumn(label: Text('Validation Distance')),
              ],
              rows: validWaypoints.entries.map<DataRow>((entry) {
                String name = entry.key;
                Map<String, dynamic> details = entry.value;
                String validationTime = details['validationTime'].toString();
                if (validationTime == "null") {
                  validationTime = "N/A";
                }
                String validationDistance =
                    details['validationDistance'].toString();
                return DataRow(
                  cells: <DataCell>[
                    DataCell(Text(name)),
                    DataCell(Text(validationTime)),
                    DataCell(Text(validationDistance)),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          Text("Bravo $nomConcurrent 💪🔥",
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 250),
          Text("Prenez un moment pour jetter un"),
          Text("rapide coup d'oeil sur vos performances 📊")
        ],
      ),
    );
  }
}
