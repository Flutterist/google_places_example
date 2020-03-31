import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter/material.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as LocationManager;
import 'place.dart';

//TODO: Consider Chnaging your API Key after configuring Google Place API
const kGoogleApiKey = "AIzaSyAQEQwwQo6OcYbU2tsIWjmTrMyB9GGJkN4";
GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

void main() {
  runApp(MaterialApp(
    title: "PlaceR Example",
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  List<PlacesSearchResult> places = [];
  bool isLoading = false;
  String errorMessage;

  @override
  void initState() {
    refresh();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget expandedChild;
    if (isLoading) {
      expandedChild = Center(child: CircularProgressIndicator(value: null));
    } else if (errorMessage != null) {
      expandedChild = Center(
        child: Text(errorMessage),
      );
    } else {
      expandedChild = buildPlacesList();
    }

    return Scaffold(
        key: homeScaffoldKey,
        appBar: AppBar(
          title: const Text("PlaceR Example"),
          actions: <Widget>[
            isLoading
                ? IconButton(
                    icon: Icon(Icons.timer),
                    onPressed: () {},
                  )
                : IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () {
                      refresh();
                    },
                  ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                _searchButtonPresses();
              },
            ),
          ],
        ),
        body: Column(
          children: <Widget>[Expanded(child: expandedChild)],
        ));
  }

  void refresh() async {
    final center = await getUserLocation();
    getNearbyPlaces(center);
  }

  Future<LatLng> getUserLocation() async {
    LocationManager.LocationData currentLocation;
    final location = LocationManager.Location();
    try {
      currentLocation = await location.getLocation();
      final lat = currentLocation.latitude;
      final lng = currentLocation.longitude;
      final center = LatLng(lat, lng);
      return center;
    } on Exception {
      currentLocation = null;
      return null;
    }
  }

  void getNearbyPlaces(LatLng center) async {
    setState(() {
      this.isLoading = true;
      this.errorMessage = null;
    });

    final location = Location(center.latitude, center.longitude);

//TODO: Using Type you can select the type of features you want try query, for further types,
//Please Refer to the following Link:
//https://developers.google.com/places/web-service/supported_types
    final result = await _places.searchNearbyWithRadius(location, 250,
        type:
            'food'); //|meal_delivery|meal_takeaway|shopping_mall|grocery_or_supermarket');
    setState(() {
      this.isLoading = false;
      if (result.status == "OK") {
        //TODO combine the Google Places API results
        //with results returned from your query.
        this.places = result.results;
      } else {
        this.errorMessage = result.errorMessage;
      }
    });
  }

  void onError(PlacesAutocompleteResponse response) {
    homeScaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }

  Future<void> _searchButtonPresses() async {
    try {
      final center = await getUserLocation();
      Prediction p = await PlacesAutocomplete.show(
          context: context,
          strictbounds: center == null ? false : true,
          apiKey: kGoogleApiKey,
          onError: onError,
          mode: Mode.fullscreen,
          language: "en",
          location: center == null
              ? null
              : Location(center.latitude, center.longitude),
          radius: center == null ? null : 10000);

      showDetailPlace(p.placeId);
    } catch (e) {
      return;
    }
  }

  Future<Null> showDetailPlace(String placeId) async {
    if (placeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PlaceDetailWidget(placeId)),
      );
    }
  }

  ListView buildPlacesList() {
    return ListView.builder(
      itemBuilder: (context, index) {
        return Card(
          child: InkWell(
            highlightColor: Colors.lightGreenAccent,
            splashColor: Colors.redAccent,
            onTap: () {
              showDetailPlace(places[index].placeId);
            },
            child: ListTile(
              title: Padding(
                padding: EdgeInsets.only(bottom: 2.0),
                child: Text(
                  places[index].name ?? "",
                  style: Theme.of(context).textTheme.subtitle,
                ),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(bottom: 2.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      places[index].vicinity ?? "",
                      style: Theme.of(context).textTheme.subtitle,
                    ),
                    Text(
                      places[index].types.first,
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      itemCount: places.length,
    );
  }
}
