import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ride_app/DataHandler/appData.dart';
import 'package:ride_app/Models/address.dart';
import 'package:ride_app/Models/allUsers.dart';
import 'package:ride_app/Models/directionDetails.dart';
import 'requestAssistant.dart';
import 'package:ride_app/configMaps.dart';
import 'package:http/http.dart' as http;

class AssistantMethods{
  static Future<String> searchCoordinateAddress(Position position,context) async{

    String placeAddress = "";
    String st1, st2, st3 , st4, st5;
    String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapkey";

    var response = await RequestAssistant.getRequest(url);

    if(response != "failed"){

      // placeAddress = response["results"][0]["formatted_address"];
      st1 = response["results"][0]["address_components"][0]["long_name"];
      st2 = response["results"][0]["address_components"][1]["long_name"];
      st3 = response["results"][0]["address_components"][2]["long_name"];
      st4 = response["results"][0]["address_components"][3]["long_name"];
      // st5 = response["results"][0]["address_components"][4]["long_name"];
      placeAddress = st1 + " " + st2 + " " + st3 + " " + st4;

      
      Address userPickUpAddress = new Address();
      userPickUpAddress.longitude = position.longitude;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.placeName = placeAddress;
      
      Provider.of<AppData>(context,listen: false).updatePickUpLocationAddress(userPickUpAddress);

    }

    return placeAddress;
  }

  static Future<DirectionDetails> obtainPlaceDirectionDetails(LatLng initialPosition , LatLng finalPosition) async{

    String directionUrl = "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapkey";

    var res = await RequestAssistant.getRequest(directionUrl);

    if(res == "failed"){
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails();

    directionDetails.encodedPoints = res["routes"][0]["overview_polyline"]["points"];
    directionDetails.distanceText = res["routes"][0]["legs"][0]["distance"]["text"];
    directionDetails.distanceValue = res["routes"][0]["legs"][0]["distance"]["value"];

    directionDetails.durationText = res["routes"][0]["legs"][0]["duration"]["text"];
    directionDetails.durationValue = res["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetails;
  }


  static int calculateFares(DirectionDetails directionDetails){

    double timeTraveledFare = (directionDetails.durationValue / 60) * 0.20;
    double distanceTraveledFare = (directionDetails.distanceValue / 1000) * 0.20;

    //In USD
    double totalFareAmount = timeTraveledFare + distanceTraveledFare;

    //In Ruppes
    double totalLocalFareAmount = totalFareAmount * 71;

    return totalLocalFareAmount.truncate();
  }


  static void getCurrentOnlineUsersInfo() async{
     firebaseUser = await FirebaseAuth.instance.currentUser;
     String userId = firebaseUser.uid;
     DatabaseReference reference = FirebaseDatabase.instance.reference().child("users").child(userId);

     reference.once().then((DataSnapshot dataSnapshot){
       if(dataSnapshot.value != null){
         userCurrentInfo = Users.fromSnapshot(dataSnapshot);
       }
     });
  }

  static double createRandomNumber(int num){
    var random = Random();
    int randomNumber = random.nextInt(num);
    return randomNumber.toDouble();
  }

  static sendNotificationToDrivers(String token, context ,String ride_request_id) async
  {

    var destination = Provider.of<AppData>(context, listen: false).dropOfLocation;

    Map<String,String> headersMap = {
      'Content-Type': 'application/json',
      'Authorization': serverToken,
    };

    Map  notificationMap = {
      'body': 'DropOff Address, ${destination.placeName}',
      'title': 'New Ride Request'
    };


    Map dataMap ={
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': '1',
      'status': 'done',
      'ride_request_id': ride_request_id,
    };

    Map sendNotificationMap = {
      "notification" : notificationMap,
      "data" : dataMap,
      "priority" : "high",
      "to" : token

    };
    
    var res = await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: headersMap,
      body: jsonEncode(sendNotificationMap),
    );
  }

}