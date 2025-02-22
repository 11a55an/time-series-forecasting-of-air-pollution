import 'dart:ui';
import 'package:envirocast/screens/detail_screen.dart';
import 'package:kdgaugeview/kdgaugeview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class OutdoorScreen extends StatelessWidget {
  final Color colorUp;
  final Color colorDown;
  const OutdoorScreen({
    Key? key,
    required this.colorUp,
    required this.colorDown,
  }) : super(key: key);
  Future<Map<String, dynamic>> fetchAirData() async {
    Position position = await Geolocator.getCurrentPosition();
    final double lat = position.latitude;
    final double lon = position.longitude;
    final response = await http.get(Uri.parse(
        'https://api.weatherbit.io/v2.0/history/airquality?lat=$lat&lon=$lon&tz=local&key=4aa42fc9ef084abf8b9c0656acf29d38'));
    final responsePred = await http.post(Uri.parse(
        'http://ec2-16-16-98-137.eu-north-1.compute.amazonaws.com:8080/all'));

    // Get today's date
    DateTime startDate = DateTime.now();

    // Get yesterday's date
    DateTime endDate = startDate.add(const Duration(days: 1));

    // Format dates to 'YYYY-MM-DD'
    String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);
    String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);

    // Construct the URL with query parameters
    String url =
        'https://api.weatherbit.io/v2.0/history/hourly?lat=$lat&lon=$lon&tz=local&start_date=$formattedStartDate&end_date=$formattedEndDate&key=4aa42fc9ef084abf8b9c0656acf29d38';

    // Make the HTTP GET request
    final responseTemp = await http.get(Uri.parse(url));

    if (response.statusCode == 200 &&
        responseTemp.statusCode == 200 &&
        responsePred.statusCode == 200) {
      Map<String, dynamic> airData = jsonDecode(response.body);
      Map<String, dynamic> predData = jsonDecode(responsePred.body);
      Map<String, dynamic> weatherData = jsonDecode(responseTemp.body);

      return {
        'airData': SampleAirData.fromJson(airData),
        'weatherData': SampleWeatherData.fromJson(weatherData),
        'predData': SamplePredData.fromJson(predData),
      };
    } else if (response.statusCode != 200) {
      throw Exception('Failed to load air data');
    } else if (responseTemp.statusCode != 200) {
      throw Exception('Failed to load temp data');
    } else if (responsePred.statusCode != 200) {
      throw Exception('Failed to load pred data');
    } else {
      throw Exception('Failed to load air or weather data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
            future: fetchAirData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Unable to connect to Internet',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
                return const Center(
                  child: Text(
                    'No Internet Connection',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              } else {
                SampleAirData sampleAirData = snapshot.data!['airData'];
                SampleWeatherData sampleWeatherData =
                    snapshot.data!['weatherData'];
                SamplePredData samplePredData = snapshot.data!['predData'];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                      40, 1.2 * kToolbarHeight, 40, 20),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
                      children: [
                        Align(
                          alignment: const AlignmentDirectional(3, -0.3),
                          child: Container(
                            height: 300,
                            width: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorDown,
                            ),
                          ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(-3, -0.3),
                          child: Container(
                            height: 300,
                            width: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorDown,
                            ),
                          ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(0, -1.2),
                          child: Container(
                            height: 300,
                            width: 600,
                            decoration: BoxDecoration(
                              color: colorUp,
                            ),
                          ),
                        ),
                        BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0),
                          child: Container(
                            decoration:
                                const BoxDecoration(color: Colors.transparent),
                          ),
                        ),
                        SingleChildScrollView(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: 990,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: 8,
                                ),
                                const Center(
                                  child: Text(
                                    'Outdoor Air Data',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 35,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                ),
                                Center(
                                  child: SizedBox(
                                    width: 320,
                                    height: 300,
                                    child: Center(
                                      child: KdGaugeView(
                                        minSpeed: 0,
                                        maxSpeed: 500,
                                        speed: sampleAirData.aqi.toDouble(),
                                        animate: true,
                                        duration: const Duration(seconds: 5),
                                        alertSpeedArray: const [
                                          50,
                                          100,
                                          200,
                                          300
                                        ],
                                        alertColorArray: const [
                                          Colors.green,
                                          Colors.yellow,
                                          Colors.orange,
                                          Colors.red
                                        ],
                                        unitOfMeasurement: "AQI",
                                        gaugeWidth: 15,
                                        minMaxTextStyle: const TextStyle(
                                            color: Colors.white, fontSize: 20),
                                        unitOfMeasurementTextStyle:
                                            const TextStyle(
                                                color: Colors.white,
                                                fontSize: 30,
                                                fontWeight: FontWeight.w500),
                                        speedTextStyle: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 50,
                                            fontWeight: FontWeight.w600),
                                        //activeGaugeColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to detail screen
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailScreen(
                                                      parameterRange: const [
                                                        25,
                                                        30,
                                                        35,
                                                        40
                                                      ],
                                                      parameterName: 'Temp',
                                                      parameterData:
                                                          samplePredData.temp,
                                                      parameterValue:
                                                          sampleWeatherData.temp
                                                              .toDouble(),
                                                      predictedValue:
                                                          samplePredData
                                                              .temp[0],
                                                      speedValue:
                                                          sampleWeatherData.temp
                                                              .toDouble(),
                                                      colorUp: colorUp,
                                                      colorDown: colorDown,
                                                    )));

                                        // You can use Navigator.push or any other navigation method here
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.thermometer,
                                            color: Colors.white,
                                            size: 35,
                                          ),
                                          const SizedBox(width: 5),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Temp',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                '${sampleWeatherData.temp!.toStringAsFixed(0)}°C',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                'Exp_1h: ${samplePredData.temp[0]!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to detail screen
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailScreen(
                                                      parameterRange: const [
                                                        50,
                                                        100,
                                                        200,
                                                        300
                                                      ],
                                                      parameterName: 'AQI',
                                                      parameterData:
                                                          samplePredData.aqi,
                                                      parameterValue:
                                                          sampleAirData.aqi
                                                              .toDouble(),
                                                      predictedValue:
                                                          samplePredData.aqi[0],
                                                      speedValue: sampleAirData
                                                          .aqi
                                                          .toDouble(),
                                                      colorUp: colorUp,
                                                      colorDown: colorDown,
                                                    )));

                                        // You can use Navigator.push or any other navigation method here
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.wind,
                                            color: Colors.white,
                                            size: 35,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'AQI',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w300,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${sampleAirData.aqi!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              Text(
                                                'Exp_1h: ${samplePredData.aqi[0]!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14.0),
                                  child: Divider(
                                    color: Colors.grey,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to detail screen
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailScreen(
                                                      parameterRange: const [
                                                        50,
                                                        100,
                                                        150,
                                                        200
                                                      ],
                                                      parameterName: 'CO',
                                                      parameterData:
                                                          samplePredData.co,
                                                      parameterValue:
                                                          sampleAirData.co
                                                              .toDouble(),
                                                      predictedValue:
                                                          samplePredData.co[0],
                                                      speedValue: sampleAirData
                                                          .co
                                                          .toDouble(),
                                                      colorUp: colorUp,
                                                      colorDown: colorDown,
                                                    )));

                                        // You can use Navigator.push or any other navigation method here
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.science,
                                            color: Colors.white,
                                            size: 35,
                                          ),
                                          const SizedBox(width: 5),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'CO',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w300,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${sampleAirData.co!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                'Exp_1h: ${samplePredData.co[0]!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to detail screen
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailScreen(
                                                      parameterRange: const [
                                                        50,
                                                        100,
                                                        150,
                                                        200
                                                      ],
                                                      parameterName: 'NO2',
                                                      parameterData:
                                                          samplePredData.no2,
                                                      parameterValue:
                                                          sampleAirData.no2
                                                              .toDouble(),
                                                      predictedValue:
                                                          samplePredData.no2[0],
                                                      speedValue: sampleAirData
                                                          .no2
                                                          .toDouble(),
                                                      colorUp: colorUp,
                                                      colorDown: colorDown,
                                                    )));

                                        // You can use Navigator.push or any other navigation method here
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.gauge,
                                            color: Colors.white,
                                            size: 35,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'NO2',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w300,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${sampleAirData.no2!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              Text(
                                                'Exp_1h: ${samplePredData.no2[0]!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 15.0),
                                  child: Divider(
                                    color: Colors.grey,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Display max temperature
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to detail screen
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailScreen(
                                                      parameterRange: const [
                                                        80,
                                                        100,
                                                        120,
                                                        140
                                                      ],
                                                      parameterName: 'O3',
                                                      parameterData:
                                                          samplePredData.o3,
                                                      parameterValue:
                                                          sampleAirData.o3
                                                              .toDouble(),
                                                      predictedValue:
                                                          samplePredData.o3[0],
                                                      speedValue: sampleAirData
                                                          .o3
                                                          .toDouble(),
                                                      colorUp: colorUp,
                                                      colorDown: colorDown,
                                                    )));

                                        // You can use Navigator.push or any other navigation method here
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.cloud,
                                            color: Colors.white,
                                            size: 35,
                                          ),
                                          const SizedBox(width: 5),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'O3',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 20),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${sampleAirData.o3!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 20),
                                              ),
                                              Text(
                                                'Exp_1h: ${samplePredData.o3[0]!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 20),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Display min temperature
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to detail screen
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailScreen(
                                                      parameterRange: const [
                                                        50,
                                                        100,
                                                        200,
                                                        300
                                                      ],
                                                      parameterName: 'SO2',
                                                      parameterData:
                                                          samplePredData.so2,
                                                      parameterValue:
                                                          sampleAirData.so2
                                                              .toDouble(),
                                                      predictedValue:
                                                          samplePredData.so2[0],
                                                      speedValue: sampleAirData
                                                          .so2
                                                          .toDouble(),
                                                      colorUp: colorUp,
                                                      colorDown: colorDown,
                                                    )));

                                        // You can use Navigator.push or any other navigation method here
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.fire_extinguisher,
                                            color: Colors.white,
                                            size: 35,
                                          ),
                                          const SizedBox(width: 5),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'SO2',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 20),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${sampleAirData.so2!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 20),
                                              ),
                                              Text(
                                                'Exp_1h: ${samplePredData.so2[0]!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 20),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 15.0),
                                  child: Divider(
                                    color: Colors.grey,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Display max temperature
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to detail screen
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailScreen(
                                                      parameterRange: const [
                                                        25,
                                                        50,
                                                        100,
                                                        300
                                                      ],
                                                      parameterName: 'PM2.5',
                                                      parameterData:
                                                          samplePredData.pm25,
                                                      parameterValue:
                                                          sampleAirData.pm25
                                                              .toDouble(),
                                                      predictedValue:
                                                          samplePredData
                                                              .pm25[0],
                                                      speedValue: sampleAirData
                                                          .pm25
                                                          .toDouble(),
                                                      colorUp: colorUp,
                                                      colorDown: colorDown,
                                                    )));

                                        // You can use Navigator.push or any other navigation method here
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.flame_fill,
                                            color: Colors.white,
                                            size: 35,
                                          ),
                                          const SizedBox(width: 5),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'PM2',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 20),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${sampleAirData.pm25!}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 20),
                                              ),
                                              Text(
                                                'Exp_1h: ${samplePredData.pm25[0]!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 20),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Display min temperature
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to detail screen
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailScreen(
                                                      parameterRange: const [
                                                        50,
                                                        100,
                                                        200,
                                                        300
                                                      ],
                                                      parameterName: 'PM10',
                                                      parameterData:
                                                          samplePredData.pm10,
                                                      parameterValue:
                                                          sampleAirData.pm10
                                                              .toDouble(),
                                                      predictedValue:
                                                          samplePredData
                                                              .pm10[0],
                                                      speedValue: sampleAirData
                                                          .pm10
                                                          .toDouble(),
                                                      colorUp: colorUp,
                                                      colorDown: colorDown,
                                                    )));

                                        // You can use Navigator.push or any other navigation method here
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.waveform_path,
                                            color: Colors.white,
                                            size: 35,
                                          ),
                                          const SizedBox(width: 5),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'PM10',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 20),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${sampleAirData.pm10!}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 20),
                                              ),
                                              Text(
                                                'Exp_1h: ${samplePredData.pm10[0]!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 20),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }));
  }
}

class SampleAirData {
  final dynamic aqi;
  final dynamic co;
  final dynamic no2;
  final dynamic o3;
  final dynamic so2;
  final dynamic pm25;
  final dynamic pm10;

  SampleAirData({
    this.aqi,
    this.co,
    this.no2,
    this.o3,
    this.so2,
    this.pm25,
    this.pm10,
  });

  factory SampleAirData.fromJson(Map<String, dynamic> json) {
    return SampleAirData(
      aqi: json['data'][0]['aqi'],
      co: json['data'][0]['co'],
      no2: json['data'][0]['no2'],
      o3: json['data'][0]['o3'],
      so2: json['data'][0]['so2'],
      pm25: json['data'][0]['pm25'],
      pm10: json['data'][0]['pm10'],
    );
  }
}

class SampleWeatherData {
  final dynamic temp;

  SampleWeatherData({this.temp});

  factory SampleWeatherData.fromJson(Map<String, dynamic> json) {
    // Get the last non-null temperature value
    List<dynamic> weatherDataList = json['data'];
    double temp1 = 0;
    for (var item in weatherDataList.reversed) {
      if (item['temp'] != null) {
        temp1 = item['temp'];
        break;
      }
    }
    return SampleWeatherData(temp: temp1);
  }
}

class SamplePredData {
  final dynamic temp;
  final dynamic aqi;
  final dynamic co;
  final dynamic no2;
  final dynamic o3;
  final dynamic so2;
  final dynamic pm25;
  final dynamic pm10;

  SamplePredData({
    this.temp,
    this.aqi,
    this.co,
    this.no2,
    this.o3,
    this.so2,
    this.pm25,
    this.pm10,
  });

  factory SamplePredData.fromJson(Map<String, dynamic> json) {
    return SamplePredData(
      temp: json['temp'],
      aqi: json['aqi'],
      co: json['co'],
      no2: json['no2'],
      o3: json['o3'],
      so2: json['so2'],
      pm25: json['pm25'],
      pm10: json['pm10'],
    );
  }
}
