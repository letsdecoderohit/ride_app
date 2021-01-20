import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ride_app/AllScreens/registrationScreen.dart';
import 'package:ride_app/Widgets/progressDialog.dart';
import 'package:ride_app/main.dart';

import 'mainscreen.dart';

class LoginScreen extends StatelessWidget {

  static const String idScreen = "login";
  TextEditingController emailTextEditingController = TextEditingController();
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
              Text("Login as a Rider",
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

                      if(!emailTextEditingController.text.contains("@")){
                        Fluttertoast.showToast(msg: "Email Id is not valid");
                      }else if(passwordTextEditingController.text.length < 7){
                        Fluttertoast.showToast(msg: "Password is mandatory");
                      }else{
                        loginAndAuthenticateUser(context);
                      }

                    },
                    color: Colors.yellow,
                    textColor: Colors.white,
                    child: Container(
                      height: 50.0,
                      child: Center(
                        child: Text(
                          "Login",
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
                Navigator.pushNamedAndRemoveUntil(context, RegistrationScreen.idScreen, (route) => false);
              },
                  child: Text(
                    "Do not have an account? Register here",
                  ))


            ],
          ),
        ),
      ),
    );
  }


  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  void loginAndAuthenticateUser(BuildContext context) async {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext){
        return ProgressDialog(message: "Authenticating Please Wait...",);
      }
    );

    final User firebaseUser = (await firebaseAuth
        .signInWithEmailAndPassword(
        email: emailTextEditingController.text,
        password: passwordTextEditingController.text
    ).catchError((errMsg){
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Error:"+errMsg.toString());

    })).user;


    if(firebaseUser != null ){

      userRef.child(firebaseUser.uid).once().then((DataSnapshot snapshot){

        if(snapshot.value != null){
          Navigator.pushNamedAndRemoveUntil(context, MainScreen.idScreen, (route) => false);
          Fluttertoast.showToast(msg: "You are logged In");
        }else{
          Navigator.pop(context);
          firebaseAuth.signOut();
          Fluttertoast.showToast(msg: "No record exists  for this user. please create new account");
        }
      });

    }else{
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Error occured cannot sign in");
    }
  }
}
