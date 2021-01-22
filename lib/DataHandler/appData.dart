import 'package:flutter/cupertino.dart';
import 'package:ride_app/Models/address.dart';

class AppData extends ChangeNotifier{

  Address pickUpLocation, dropOfLocation;

  void updatePickUpLocationAddress(Address pickUpAddress){
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }

  void updateDropOfLocationAddress(Address dropOfAddress){
    dropOfLocation = dropOfAddress;
    notifyListeners();
  }

}