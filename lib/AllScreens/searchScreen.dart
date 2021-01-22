import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_app/Assistants/requestAssistant.dart';
import 'package:ride_app/DataHandler/appData.dart';
import 'package:ride_app/Models/address.dart';
import 'package:ride_app/Models/placePredictions.dart';
import 'package:ride_app/Widgets/divider.dart';
import 'package:ride_app/Widgets/progressDialog.dart';
import 'package:ride_app/configMaps.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  TextEditingController pickUptextEditingController = TextEditingController();
  TextEditingController dropOftextEditingController = TextEditingController();

  List<PlacePredictions> placePredictionList = [];

  @override
  Widget build(BuildContext context) {

    String placeAddress  = Provider.of<AppData>(context).pickUpLocation.placeName ?? "";
    pickUptextEditingController.text = placeAddress;

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Column(
        children: [
          Container(
            height: 210.0,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 6.0,
                  spreadRadius: 0.5,
                  offset: Offset(0.7,0.7 ),
                ),
              ],
            ),

            child: Padding(
              padding: EdgeInsets.only(left: 25.0,top: 30.0,right: 25.0,bottom: 20.0),
              child: Column(
                children: [
                  SizedBox(height: 10.0,),
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: (){
                          Navigator.pop(context);
                        },
                          child: Icon(
                              Icons.arrow_back,
                          ),
                      ),
                      Center(
                        child: Text("Set Drop Off",style: TextStyle(fontSize: 18.0,fontFamily: "Brand-Bold"),),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.0,),
                  Row(
                    children: [
                      Image.asset("assets/images/pickicon.png",height: 16.0,width: 16.0,),
                      SizedBox(width: 18.0,),

                      Expanded(child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(3.0),
                          child: TextField(
                            controller: pickUptextEditingController,
                            decoration: InputDecoration(
                              hintText: "PickUp location",
                              fillColor: Colors.grey[200],
                              filled: true,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.only(left: 11.0,top: 8.0,bottom: 8.0),

                            ),
                          ),
                        ),
                      ),
                      ),

                    ],
                  ),

                  SizedBox(height: 10.0,),
                  Row(
                    children: [
                      Image.asset("assets/images/desticon.png",height: 16.0,width: 16.0,),
                      SizedBox(width: 18.0,),

                      Expanded(child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(3.0),
                          child: TextField(
                            onChanged: (val){
                              findPlace(val);
                            },
                            controller: dropOftextEditingController,
                            decoration: InputDecoration(
                              hintText: "Where to?",
                              fillColor: Colors.grey[200],
                              filled: true,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.only(left: 11.0,top: 8.0,bottom: 8.0),

                            ),
                          ),
                        ),
                      ),
                      ),

                    ],
                  )
                ],
              ),
            ),
          ),

          //tile for predictions
          SizedBox(height: 10.0,),
          (placePredictionList.length > 0 )
              ? Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0,horizontal: 16.0),
            child: ListView.separated(
              padding: EdgeInsets.all(0.0),
              itemBuilder: (context, index){
                return PredictionTile(placePredictions: placePredictionList[index],);

              },
              separatorBuilder: (BuildContext context, int index) => DividerWidget(),
              itemCount: placePredictionList.length,
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
            ),

          )
              : Container(),


        ],
      ),
    );
  }

  void findPlace(String placeName) async{

    if(placeName.length > 1){
      String autoCompleteUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapkey&sessiontoken=1234567890&components=country:in";

      var res = await RequestAssistant.getRequest(autoCompleteUrl);

      if(res == "failed"){
        return;
      }

      if(res["status"] == "OK"){
        var predictions = res["predictions"];

        var placeList = (predictions as List).map((e) => PlacePredictions.fromJson(e)).toList();

        setState(() {
          placePredictionList = placeList;
        });
      }
    }

  }
}


class PredictionTile extends StatelessWidget {

  final PlacePredictions placePredictions;

  PredictionTile({Key key,this.placePredictions}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      padding: EdgeInsets.all(0.0),
      onPressed: () {
        getPlaceAddressDetails(placePredictions.place_id, context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(width: 10.0,),
            Row(
              children: [
                Icon(Icons.add_location),
                SizedBox(width: 14.0,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0,),
                      Text(placePredictions.main_text,overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16.0,),),
                      SizedBox(height: 2.0,),
                      Text(placePredictions.secondary_text,overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.0,color: Colors.grey),),
                      SizedBox(height: 8.0,),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(width: 10.0,),

          ],
        ),
      ),
    );
  }

  void getPlaceAddressDetails(String placeId, context) async {

    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(message: "Setting Dropoff , Please wait..",)
    );

    String placeDetailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapkey";

    var res = await RequestAssistant.getRequest(placeDetailsUrl);

    Navigator.pop(context);

    if(res == "failed"){
     return;
    }

    if(res["status"] == "OK"){
      Address address = Address();
      address.placeName = res["result"]["name"];
      address.placeId = placeId;
      address.latitude = res["result"]["geometry"]["location"]["lat"];
      address.longitude = res["result"]["geometry"]["location"]["lng"];

      Provider.of<AppData>(context,listen: false).updateDropOfLocationAddress(address);
      print("This is Drop Of Location");
      print(address.placeName);

      Navigator.pop(context, "obtain");
    }
  }

}
