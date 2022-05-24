import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as url;
import 'package:intl/intl.dart';

void main(List<String> args) {
  runApp(WeatherApp());
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({Key? key}) : super(key: key);

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int? temprature;
  String location = 'jakarta';
  String weather = 'clear';
  int woeid = 1047378;
  String abbrevation = 'c';

  String erroemessage = '';

  // buat var untuk list temprature nya
  var minTempratureForecase = List.filled(7, 0);
  var maxTempratureForecase = List.filled(7, 0);
  var abbrevationForecase = List.filled(7, '');

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';

  String locationApiUrl = 'https://www.metaweather.com/api/location/';

  @override
  void initState() {
    super.initState();
    onTxtFieldSumbitted(location);
  }

  Future<void> fetchSearch(String input) async {
    try {
      var searchResult = await url.get(Uri.parse(searchApiUrl + input));
      var result = json.decode(searchResult.body)[0];

      setState(() {
        location = result['title'];
        woeid = result['woeid'];
        erroemessage = '';
      });
    } catch (error) {
      erroemessage =
          "Maaf kita tidak ada data untuk kota itu, coba kota yang lain";
    }
  }

  Future<void> fetchLocation() async {
    var locationResult =
        await url.get(Uri.parse(locationApiUrl + woeid.toString()));
    var result = json.decode(locationResult.body);
    var consolidated_weather = result['consolidated_weather'];
    var data = consolidated_weather[0]; // array dimulai dari 0

    setState(() {
      temprature = data['the_temp'].round();
      weather = data['weather_state_name'].replaceAll(' ', '').toLowerCase();
      abbrevation = data['weather_state_abbr'];
    });
  }

  Future<void> fetchLocationDay() async {
    var today = DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await url.get(Uri.parse(locationApiUrl +
          woeid.toString() +
          '/' +
          DateFormat('y/M/d')
              .format(today.add(Duration(days: i + 1)))
              .toString()));
      var result = jsonDecode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTempratureForecase[i] = data['min_temp'].round();
        maxTempratureForecase[i] = data['max_temp'].round();
        abbrevationForecase[i] = data['weather_state_abbr'];
      });
    }
  }

  void onTxtFieldSumbitted(String input) async{
    await fetchLocation();
    await fetchSearch(input);
    await fetchLocationDay();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('images/$weather.png'), fit: BoxFit.cover)),
        child: temprature == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Center(
                          child: Image.network(
                            'https://www.metaweather.com/static/img/weather/png/' +
                                abbrevation +
                                '.png',
                            width: 100,
                          ),
                        ),
                        Center(
                          child: Text(
                            temprature.toString() + '°c',
                            style: TextStyle(color: Colors.white, fontSize: 60),
                          ),
                        ),
                        Center(
                          child: Text(
                            location,
                            style: TextStyle(color: Colors.white, fontSize: 40),
                          ),
                        )
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for(var i=0; i<7; i++)
                            forecastElement(
                              i+1, 
                              abbrevationForecase[i],
                              maxTempratureForecase[i],
                              minTempratureForecase[i]
                              )
                          ],
                        ),
                      ),
                      ),
                    Column(
                      children: [
                        Container(
                          width: 300,
                          child: TextField(
                            onSubmitted: (String input) {
                              onTxtFieldSumbitted(input);
                            },
                            style: TextStyle(color: Colors.white, fontSize: 25),
                            decoration: InputDecoration(
                                hintText: 'Search another location...',
                                hintStyle: TextStyle(
                                    color: Colors.white, fontSize: 18),
                                prefixIcon: Icon(Icons.search)),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            erroemessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: Platform.isAndroid ? 15 : 20),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
      ),
    );
  }
}

Widget forecastElement(
    dasyFromNow, abbreviation, maxTemprature, minTemprature) {
  var now = DateTime.now();
  var oneDaysFromNow = now.add(Duration(days: dasyFromNow));
  return Padding(
    padding: EdgeInsets.only(
      left: 16,
    ),
    child: Container(
      decoration: BoxDecoration(
          color: Color.fromRGBO(205, 212, 228, 0.2),
          borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              DateFormat.E().format(oneDaysFromNow),
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            Text(
              DateFormat.MMMd().format(oneDaysFromNow),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 16,
              ),
              child: Image.network(
                'https://www.metaweather.com/static/img/weather/png/' +
                    abbreviation +
                    '.png',
                width: 50,
              ),
            ),
            Text(
              'Hight ' + maxTemprature.toString() + '°c',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              'Low ' + minTemprature.toString() + '°c',
              style: TextStyle(color: Colors.white, fontSize: 20),
            )
          ],
        ),
      ),
    ),
  );
}

//nama-weather-flutter