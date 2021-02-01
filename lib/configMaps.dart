import 'package:firebase_auth/firebase_auth.dart';
import 'package:ride_app/Models/allUsers.dart';

String mapkey = "AIzaSyCF_YpSfyAu2i62Tyb5iDw7SbeHxlETPuw";

User firebaseUser;

Users userCurrentInfo;

int driverRequestTimeOut = 40;

String statusRide = "";
String rideStatus = "Driver is on the way";
String carDetailsDriver = "";
String driverName = "";
String driverPhone = "";

String serverToken = "key=AAAAjZZTVXk:APA91bHTGd-SjYrOGCrxNrGoTRmimzwJeSfZB6Euw-Y0pmtU1SYOOpuc0Zw926kA2hhbpI6-PVXPaC14KcBzG10SANRtxt_CoHY23WzYk4xYTK78tu4ryEggFIYqcTzNfDmKRUAD6oAR";