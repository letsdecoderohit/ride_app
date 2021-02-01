import 'dart:async';
import 'dart:developer';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ride_app/AllScreens/loginScreen.dart';
import 'package:ride_app/AllScreens/searchScreen.dart';
import 'package:ride_app/Assistants/assistantMethods.dart';
import 'package:ride_app/Assistants/geoFireAssistant.dart';
import 'package:ride_app/DataHandler/appData.dart';
import 'package:ride_app/Models/directionDetails.dart';
import 'package:ride_app/Models/nearByAvailableDriver.dart';
import 'package:ride_app/Widgets/divider.dart';
import 'package:ride_app/Widgets/noDriverAvailableDialog.dart';
import 'package:ride_app/Widgets/progressDialog.dart';
import 'package:ride_app/configMaps.dart';
import 'package:ride_app/main.dart';

class MainScreen extends StatefulWidget {

  static const String idScreen = "mainScreen";


  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {

  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldkey = new GlobalKey<ScaffoldState>();
  DirectionDetails tripDirectionDetails;

  List<LatLng> pLineCoordinates =[];
  Set<Polyline> polyLineSet = {};

  Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingofmap = 0;

  Set<Marker> markersSet ={};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double searchContainerHeight = 300.0;
  double requestRideContainerHeight = 0.0;
  double driverDetailsContainerHeight = 0.0;

  bool drawerOpen = true;
  bool nearByAvailableDriversKeyLoaded = false;

  DatabaseReference rideRequestRef;

  BitmapDescriptor nearByIcon;

  List<NearByAvailableDrivers> availableDrivers;

  String state = "normal";

  StreamSubscription<Event> rideStreamSubscription;

  @override
  void initState() {
    super.initState();

    AssistantMethods.getCurrentOnlineUsersInfo();

  }

  void saveRideRequest(){

    rideRequestRef = FirebaseDatabase.instance.reference().child("Ride Requests").push();

    var pickUp = Provider.of<AppData>(context,listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context,listen: false).dropOfLocation;

    Map pickUpLocMap = {
      "latitude" : pickUp.latitude.toString(),
      "longitude" : pickUp.longitude.toString(),
    };

    Map dropOffLocMap = {
      "latitude" : dropOff.latitude.toString(),
      "longitude" : dropOff.longitude.toString(),
    };

    Map rideInfoMap = {
      "driver_id" : "waiting",
      "payment_method" : "cash",
      "pickup" : pickUpLocMap,
      "dropoff" : dropOffLocMap,
      "created_at" :  DateTime.now().toString(),
      "rider_name" : userCurrentInfo.name,
      "rider_phone" : userCurrentInfo.phone,
      "pickup_address" : pickUp.placeName,
      "drofoff_address" : dropOff.placeName,

    };

    rideRequestRef.set(rideInfoMap);

    rideStreamSubscription = rideRequestRef.onValue.listen((event) {
      if(event.snapshot.value == null){
        return;
      }

      if(event.snapshot.value["car_details"] != null){
        setState(() {
          carDetailsDriver = event.snapshot.value["car_details"].toString();
        });
      }

      if(event.snapshot.value["driver_name"] != null){
        setState(() {
          driverName = event.snapshot.value["driver_name"].toString();
        });
      }

      if(event.snapshot.value["driver_phone"] != null){
        setState(() {
          driverPhone = event.snapshot.value["driver_phone"].toString();
        });
      }




      if(event.snapshot.value["status"] != null){
        statusRide = event.snapshot.value["status"].toString();
      }

      if(statusRide == "accepted"){
        displayDriverDetailsContainer();
      }

    });

  }

  void cancelRideRequest(){
    rideRequestRef.remove();

    setState(() {
      state = "normal";
    });

  }

  void displayRequestRideCOntainer(){
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingofmap = 230.0;

      drawerOpen = true;
    });

    saveRideRequest();
  }

  void displayDriverDetailsContainer(){
   setState(() {
     requestRideContainerHeight = 0.0;
     rideDetailsContainerHeight = 0.0;
     bottomPaddingofmap = 290.0;

     driverDetailsContainerHeight = 310.0;
   });
  }

  resetApp(){
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0.0;
      requestRideContainerHeight = 0.0;
      bottomPaddingofmap = 230.0;

      polyLineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });

    locatePosition();
  }

  void displayRideDetailContainer() async {

    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0.0;
      rideDetailsContainerHeight = 240.0;
      bottomPaddingofmap = 230.0;

      drawerOpen = false;
    });

  }


  //User current location
  void locatePosition() async{
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLatPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition = new CameraPosition(target: latLatPosition,zoom: 14);
    newGoogleMapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address = await AssistantMethods.searchCoordinateAddress(position,context);
    debugPrint("This is your Address" + address);
    log("This is your Address" + address);

    initGeoFireListner();



  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(

      key: scaffoldkey,
      appBar: AppBar(
        title: Text(
          "Main Screen"
        ),
      ),
      drawer: Drawer(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget> [
            UserAccountsDrawerHeader(
                accountName: Text("Profile Name"),
                accountEmail: Text("xyz@gmail.com"),
              currentAccountPicture: CircleAvatar(
                child: Image.asset("assets/images/user_icon.png"),
              ),
            ),

            ListTile(
              leading: Icon(Icons.history),
              title: Text(
                "History",
                style: TextStyle(fontSize: 15.0),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text(
                "Visit Profile",
                style: TextStyle(fontSize: 15.0),
              ),
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text(
                "About",
                style: TextStyle(fontSize: 15.0),
              ),
            ),
            GestureDetector(
              onTap: (){
                FirebaseAuth.instance.signOut();

                Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
              },
              child: ListTile(
                leading: Icon(FontAwesomeIcons.signOutAlt),
                title: Text(
                  "Sign Out",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingofmap),
            initialCameraPosition: _kGooglePlex,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polyLineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller)
            {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              setState(() {
                bottomPaddingofmap = 300.0;
              });

              locatePosition();
            },
          ),

          //HamburgerButton for Drawer
          Positioned(
            top: 38.0,
            left: 22.0,
            child: GestureDetector(
              onTap: (){

                if(drawerOpen){
                  scaffoldkey.currentState.openDrawer();
                }else{
                  resetApp();
                }

              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7,0.7),
                    )
                  ],
                ),

                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    (drawerOpen) ? Icons.menu : Icons.close,
                    color: Colors.black,
                  ),
                  radius: 20.0,
                ),

          ),
            ),
          ),

          //Google Maps and SEARCH pannel
          Positioned(
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: AnimatedSize(
                vsync: this,
                curve: Curves.bounceIn,
                duration: new Duration(milliseconds: 160),
                child: Container(
                  height: searchContainerHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(22.0),topRight: Radius.circular(22.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7,0.7),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0,vertical: 18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6.0,),
                        Text("Hi there ", style: TextStyle(fontSize: 15.0),),
                        Text("where to? ", style: TextStyle(fontSize: 20.0, fontFamily: "Brand-Bold"), ),
                        SizedBox(height: 20.0,),
                        GestureDetector(
                          onTap: () async{
                            var  res = await Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));

                            if(res == "obtain")
                            {
                              displayRideDetailContainer();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 6.0,
                                  spreadRadius: 0.5,
                                  offset: Offset(0.7,0.7),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Icon(Icons.search,color: Colors.blueAccent,),
                                  SizedBox(width: 10.0,),
                                  Text("Search Drop Off")
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24.0,),
                        Row(
                          children: [
                            Icon(Icons.home,color: Colors.grey,),
                            SizedBox(width: 12.0,),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Provider.of<AppData>(context).pickUpLocation != null
                                        ? Provider.of<AppData>(context).pickUpLocation.placeName
                                        : "Add Home ",
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                  SizedBox(height: 4.0,),
                                  Text("Your Living home address",style: TextStyle(color: Colors.black54,fontSize: 12.0),),

                                ],
                              ),
                            )
                          ],
                        ),

                        SizedBox(height: 16.0,),
                        DividerWidget(),
                        SizedBox(height: 10.0,),

                        Row(
                          children: [
                            Icon(Icons.home,color: Colors.grey,),
                            SizedBox(width: 12.0,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Add Work"),
                                SizedBox(height: 4.0,),
                                Text("Your Office address",style: TextStyle(color: Colors.black54,fontSize: 12.0),),
                              ],
                            )
                          ],
                        ),


                      ],
                    ),
                  ),



          ),
              )
          ),

          //Ride Details Pannel (Rs and Km)
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0),topRight: Radius.circular((16.0))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7,0.7),

                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 17.0,),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.tealAccent[100],
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Image.asset("assets/images/taxi.png",height: 70.0,width: 80.0,),
                              SizedBox(width: 16.0,),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Car",
                                    style: TextStyle(fontSize: 18.0,fontFamily: "Brand-Bold",),
                                  ),
                                  //Display Km
                                  Text(
                                    ((tripDirectionDetails != null) ? tripDirectionDetails.distanceText : '' ),
                                    style: TextStyle(fontSize: 18.0,color: Colors.grey[600],),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Container()),
                              Text(
                                ((tripDirectionDetails != null)
                                    ? '\₹${AssistantMethods.calculateFares(tripDirectionDetails)}'
                                    : '' ),
                                style: TextStyle(fontSize: 18.0,fontFamily: "Brand-Bold",),
                              ),
                            ],

                          ),
                        ),
                      ),
                      SizedBox(height: 20.0,),

                      Padding(padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.moneyCheckAlt,size: 18.0,color: Colors.black54,),
                            SizedBox(width: 16.0,),
                            Text("Cash"),
                            SizedBox(width: 6.0,),
                            Icon(Icons.keyboard_arrow_down,color: Colors.black54,size: 16.0,),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.0,),

                      Padding(padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: RaisedButton(
                          onPressed: (){

                            setState(() {
                              state = "requesting";
                            });

                            displayRequestRideCOntainer();
                            availableDrivers = GeoFireAssistant.nearByAvailableDriversList;
                            searchNearestDriver();
                          },
                          color: Theme.of(context).accentColor,
                          child: Padding(
                            padding: EdgeInsets.all(17.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Request",style: TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold,color: Colors.white),),
                                Icon(FontAwesomeIcons.taxi,color: Colors.white,size: 26.0,),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //request or cancel pannel
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0),topRight: Radius.circular(16.0),),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16.0,
                    spreadRadius: 0.5,
                    offset: Offset(0.7,0.7 ),
                  ),
                ],
              ),
              height: requestRideContainerHeight,
              child: Padding(
                padding:  EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    SizedBox(height: 12.0,),
                    SizedBox(
                    width: double.infinity,
                    child: ColorizeAnimatedTextKit(
                    onTap: () {
                      print("Tap Event");
                      },
                    text: [
                      "Requesting a Ride..",
                      "Please Wait",
                      "Finding A Driver..",
                    ],
                    textStyle: TextStyle(
                    fontSize: 55.0,
                    fontFamily: "Signatra"
                    ),
                    colors: [
                    Colors.black,
                    Colors.white,
                    ],
                    textAlign: TextAlign.center,
                    ),
                    ),
                    SizedBox(height: 22.0,),
                    GestureDetector(
                      onTap: (){
                        cancelRideRequest();

                        resetApp();
                      },
                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26.0),
                          color: Colors.white,
                          border: Border.all(width: 2.0 , color: Colors.grey[300]),
                        ),
                        child: Icon(Icons.close,size: 26.0,),
                      ),
                    ),
                    SizedBox(height: 10.0,),
                    Container(
                      width: double.infinity,
                      child: Text(
                        "Cancel Ride",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),
                      ),
                    )


                  ],
                ),
              ),
            ),
          ),

          //Display assign driver info
          Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0),topRight: Radius.circular(16.0),),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7,0.7 ),
                    ),
                  ],
                ),
                height: driverDetailsContainerHeight,
                child: Padding(
                  padding:  EdgeInsets.symmetric(horizontal: 24.0,vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.0,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(rideStatus, textAlign: TextAlign.center, style: TextStyle(fontSize: 20.0, fontFamily: "Brand-Bold"),),

                        ],


                      ),
                      SizedBox(height: 22.0,),
                      Divider(height: 2.0,thickness: 2.0,),
                      SizedBox(height: 22.0,),
                      Text(carDetailsDriver, style: TextStyle(color: Colors.grey),),
                      Text(driverName, style: TextStyle(fontSize: 20.0),),
                      SizedBox(height: 22.0,),
                      Divider(height: 2.0,thickness: 2.0,),
                      SizedBox(height: 22.0,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 55.0,
                                width: 55.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(26.0),),
                                  border: Border.all(width: 2.0, color: Colors.grey),
                                ),
                                child: Icon(
                                  Icons.call,
                                ),
                              ),
                              SizedBox(height: 10.0,),
                              Text("Call"),
                            ],
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 55.0,
                                width: 55.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(26.0),),
                                  border: Border.all(width: 2.0, color: Colors.grey),
                                ),
                                child: Icon(
                                  Icons.list,
                                ),
                              ),
                              SizedBox(height: 10.0,),
                              Text("Details"),
                            ],
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 55.0,
                                width: 55.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(26.0),),
                                  border: Border.all(width: 2.0, color: Colors.grey),
                                ),
                                child: Icon(
                                  Icons.close,
                                ),
                              ),
                              SizedBox(height: 10.0,),
                              Text("Cancel"),
                            ],
                          ),

                        ],
                      ),

                    ],
                  ),
                ),
              )
          ),

        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async{
    var initialPos = Provider.of<AppData>(context,listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context,listen: false).dropOfLocation;

    var pickUpLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOfLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(message: "Please wait..",)
    );

    var details = await AssistantMethods.obtainPlaceDirectionDetails(pickUpLatLng, dropOfLatLng);

    setState(() {
      tripDirectionDetails = details;
    });


    Navigator.pop(context);

    print("This is encoded points : : : : : : : ");
    print(details.encodedPoints);

   PolylinePoints polylinePoints = PolylinePoints();
   List<PointLatLng> decodePolyLinePointsResults = polylinePoints.decodePolyline(details.encodedPoints);

   pLineCoordinates.clear();

   if(decodePolyLinePointsResults.isNotEmpty)
   {
     decodePolyLinePointsResults.forEach((PointLatLng pointLatLng) {
       pLineCoordinates.add(LatLng(pointLatLng.latitude,pointLatLng.longitude));

     });
   }
   polyLineSet.clear();

   setState(() {
     Polyline polyline = Polyline(
       color: Colors.blue,
       polylineId: PolylineId("PolyLineID"),
       jointType: JointType.round,
       points: pLineCoordinates,
       width: 5,
       startCap: Cap.roundCap,
       endCap: Cap.roundCap,
       geodesic: true,

     );

     polyLineSet.add(polyline);

   });

     LatLngBounds latLngBounds;

     if(pickUpLatLng.latitude > dropOfLatLng.latitude && pickUpLatLng.longitude > dropOfLatLng.longitude)
     {
       latLngBounds = LatLngBounds(southwest: dropOfLatLng, northeast: pickUpLatLng);
     }
     else if(pickUpLatLng.longitude > dropOfLatLng.longitude)
     {
       latLngBounds = LatLngBounds(southwest: LatLng(pickUpLatLng.latitude,dropOfLatLng.longitude), northeast: LatLng(dropOfLatLng.latitude,pickUpLatLng.longitude));
     }
     else if(pickUpLatLng.latitude > dropOfLatLng.latitude)
     {
       latLngBounds = LatLngBounds(southwest: LatLng(dropOfLatLng.latitude,pickUpLatLng.longitude), northeast: LatLng(pickUpLatLng.latitude,dropOfLatLng.longitude));
     }else
       {
       latLngBounds = LatLngBounds(southwest: pickUpLatLng, northeast: dropOfLatLng);
     }

     newGoogleMapController.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));


     //Marker for pickup location
     Marker pickUpLocMarker = Marker(
       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
       infoWindow: InfoWindow(title: initialPos.placeName,snippet: "my Location"),
       position: pickUpLatLng,
       markerId: MarkerId("pickUpId"),
     );


    Marker dropOffLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: finalPos.placeName,snippet: "Drop Off Location"),
      position: dropOfLatLng,
      markerId: MarkerId("dropOffId"),
    );


    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
      fillColor: Colors.blueAccent,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.blueAccent,
      circleId: CircleId("pickUpId"),
    );

    Circle dropOffLocCircle = Circle(
      fillColor: Colors.deepPurple,
      center: dropOfLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.deepPurple,
      circleId: CircleId("dropOffId"),
    );


    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  void initGeoFireListner(){

    //geo fire default code

    Geofire.initialize("availableDrivers");

    Geofire.queryAtLocation(currentPosition.latitude, currentPosition.longitude, 5).listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearByAvailableDrivers nearByAvailableDrivers = NearByAvailableDrivers();
            nearByAvailableDrivers.key = map['key'];
            nearByAvailableDrivers.latitude = map['latitude'];
            nearByAvailableDrivers.longitude = map['longitude'];

            GeoFireAssistant.nearByAvailableDriversList.add(nearByAvailableDrivers);

            if(nearByAvailableDriversKeyLoaded == true){
              updateAvailableDriverOnMap();
            }

            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriverOnMap();
            break;

          case Geofire.onKeyMoved:
            NearByAvailableDrivers nearByAvailableDrivers = NearByAvailableDrivers();
            nearByAvailableDrivers.key = map['key'];
            nearByAvailableDrivers.latitude = map['latitude'];
            nearByAvailableDrivers.longitude = map['longitude'];

            GeoFireAssistant.updateDriverNearByLocation(nearByAvailableDrivers);
            updateAvailableDriverOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriverOnMap();
            break;
        }
      }

      setState(() {});

    });
    //comment

  }


  void updateAvailableDriverOnMap(){

    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMarkers = Set<Marker>();
    for(NearByAvailableDrivers driver in GeoFireAssistant.nearByAvailableDriversList){
      LatLng driverAvailablePosition = LatLng(driver.latitude,driver.longitude);

      Marker marker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverAvailablePosition,
        icon: nearByIcon,
        rotation: AssistantMethods.createRandomNumber(360),
      );

      tMarkers.add(marker);
    }

    setState(() {
      markersSet = tMarkers;
    });
  }

  void createIconMarker(){
    if(nearByIcon == null){
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context,size: Size(2,2,));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "assets/images/car_ios.png").then((value){
        nearByIcon = value;
      });
    }
  }


  void noDriverFound(){
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => NoDriverAvailableDialog()
    );
  }

  void searchNearestDriver(){
    if(availableDrivers.length == 0){
      cancelRideRequest();
      resetApp();
      noDriverFound();
      return;
    }

    var driver = availableDrivers[0];
    notifyDriver(driver);
    availableDrivers.removeAt(0);


  }

  void notifyDriver(NearByAvailableDrivers driver){

    driversRef.child(driver.key).child("newRide").set(rideRequestRef.key);

    driversRef.child(driver.key).child("token").once().then((DataSnapshot dataSnapshot)
    {
      if(dataSnapshot != null){
        String token = dataSnapshot.value.toString();
        AssistantMethods.sendNotificationToDrivers(token, context, rideRequestRef.key);
      }
      else {
        return;
      }

      const oneSecondPassed = Duration(seconds: 1);
      var timer = Timer.periodic(oneSecondPassed, (timer)
      {
        if(state != "requesting")
        {
            driversRef.child(driver.key).child("newRide").set("cancelled");
            driversRef.child(driver.key).child("newRide").onDisconnect();
            driverRequestTimeOut = 40;
            timer.cancel();

        }

        driverRequestTimeOut = driverRequestTimeOut - 1;

        //if trip is accepted
        driversRef.child(driver.key).child("newRide").onValue.listen((event) {
          if(event.snapshot.value.toString() == "accepted")
          {
            driversRef.child(driver.key).child("newRide").onDisconnect();
            driverRequestTimeOut = 40;
            timer.cancel();
          }
        });

        //if trip is timeout
        if(driverRequestTimeOut == 0){
          driversRef.child(driver.key).child("newRide").set("timeout");
          driversRef.child(driver.key).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();

          searchNearestDriver();
        }

      });

     });
  }

}
