import 'dart:async';
import 'dart:developer';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ride_app/AllScreens/searchScreen.dart';
import 'package:ride_app/Assistants/assistantMethods.dart';
import 'package:ride_app/DataHandler/appData.dart';
import 'package:ride_app/Models/directionDetails.dart';
import 'package:ride_app/Widgets/divider.dart';
import 'package:ride_app/Widgets/progressDialog.dart';

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

  bool drawerOpen = true;


  void displayRequestRideCOntainer(){
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingofmap = 250.0;

      drawerOpen = true;
    });
  }

  resetApp(){
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0.0;
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



  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
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
                "Visit Ptofile",
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
              )),

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
                            displayRequestRideCOntainer();
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
                    Container(
                      height: 60.0,
                      width: 60.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26.0),
                        color: Colors.white,
                        border: Border.all(width: 2.0 , color: Colors.grey[300]),
                      ),
                      child: Icon(Icons.close,size: 26.0,),
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
}
