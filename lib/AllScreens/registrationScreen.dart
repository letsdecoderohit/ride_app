import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ride_app/AllScreens/loginScreen.dart';
import 'package:ride_app/AllScreens/mainscreen.dart';
import 'package:ride_app/Widgets/progressDialog.dart';
import 'package:ride_app/main.dart';

class RegistrationScreen extends StatelessWidget {

  static const String idScreen = "regsiter";

  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding:  EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(height: 55.0,),
              Image(image: AssetImage("assets/images/logo.png"),
                width: 390.0,
                height: 250.0,
                alignment: Alignment.center,
              ),

              SizedBox(height: 1.0,),
              Text("Register as a Rider",
                style: TextStyle(
                    fontSize: 24.0,
                    fontFamily: "Brand Bold"
                ),
                textAlign: TextAlign.center,),

              Padding(padding:
              EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(height: 1.0,),
                    TextField(
                      controller: nameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          labelText: "Name",
                          labelStyle: TextStyle(
                            fontSize: 14.0,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.0,
                          )
                      ),
                      style: TextStyle(fontSize: 14.0,),
                    ),

                    SizedBox(height: 1.0,),
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(
                            fontSize: 14.0,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.0,
                          )
                      ),
                      style: TextStyle(fontSize: 14.0,),
                    ),

                    SizedBox(height: 1.0,),
                    TextField(
                      controller: phoneTextEditingController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: "Phone",
                          labelStyle: TextStyle(
                            fontSize: 14.0,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.0,
                          )
                      ),
                      style: TextStyle(fontSize: 14.0,),
                    ),

                    SizedBox(height: 1.0,),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(
                            fontSize: 14.0,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.0,
                          )
                      ),
                      style: TextStyle(fontSize: 14.0,),
                    ),

                    SizedBox(height: 20.0,),
                    RaisedButton(
                      onPressed: (){
                        if(nameTextEditingController.text.length < 4 ){
                          Fluttertoast.showToast(msg: "Name must be atleast 3 characters");
                        }else if(!emailTextEditingController.text.contains("@")){
                          Fluttertoast.showToast(msg: "Email inapropriate");
                        }else if(phoneTextEditingController.text.isEmpty){
                          Fluttertoast.showToast(msg: "Phone number is Mandatory");
                        }else if(passwordTextEditingController.text.length < 7){
                          Fluttertoast.showToast(msg: "Password must be atleast 6 characters");
                        }else{
                          registerNewUSer(context);
                        }
                      },
                      color: Colors.yellow,
                      textColor: Colors.white,
                      child: Container(
                        height: 50.0,
                        child: Center(
                          child: Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 18.0,
                              fontFamily: "Brand Bold",
                            ),
                          ),
                        ),
                      ),
                      shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(24.0),
                      ),
                    )
                  ],
                ),
              ),

              FlatButton(onPressed: (){
                Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);

              },
                  child: Text(
                    "Already have an account? Login here",
                  ))


            ],
          ),
        ),
      ),
    );
  }


  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  void registerNewUSer(BuildContext context) async {

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext){
          return ProgressDialog(message: "Regestering Please Wait...",);
        }
    );

    final User firebaseUser = (await firebaseAuth
        .createUserWithEmailAndPassword(
        email: emailTextEditingController.text,
        password: passwordTextEditingController.text
    ).catchError((errMsg){
      Navigator.pop(context);

      Fluttertoast.showToast(msg: "Error:"+errMsg.toString());

    })).user;



      if(firebaseUser != null ){
        Map userDataMap = {
          "name": nameTextEditingController.text.trim(),
          "email": emailTextEditingController.text.trim(),
          "phone": phoneTextEditingController.text.trim(),
        };

        userRef.child(firebaseUser.uid).set(userDataMap);
        Fluttertoast.showToast(msg: "Account has been created");

        Navigator.pushNamedAndRemoveUntil(context, MainScreen.idScreen, (route) => false);
      }else{
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "new user has not been created");
      }


  }
}


