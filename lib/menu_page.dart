import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/auth_page.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/bloc_provider.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/game_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/user_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/game_board.dart';
import 'package:flutter_firebase_tic_tac_toe/game_process_page.dart';
import 'package:flutter_firebase_tic_tac_toe/high_score_board.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game.dart';
import 'package:flutter_firebase_tic_tac_toe/users_board.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {


  UserBloc _userBloc;
  GameBloc  _gameBloc;
  FirebaseMessaging _messaging = new FirebaseMessaging();

  String username = '';

  @override
    void initState() {
      // TODO: implement initState
      super.initState();
      _delGetUserNamePref(); //TODO: to delete later

    _messaging.configure(onLaunch: (Map<String, dynamic> message) {
      print(message);
    }, onMessage: (Map<String, dynamic> message) {

      String notificationType = message['data']['notificationType'];

      switch(notificationType){
            case 'challenge':
                
                _showAcceptanceDialog(message);
                break;
              
            case 'started':
                  //TODO:gameBlocMessage that shows on the process page and allows button to display
                  _gameBloc.startServerGame(message['data']['player1Id'], message['data']['player2Id']);
                  break;
            case 'reject':
                  //GameBloc message too showing that game was declined ... and gives user option to go to menu.
                  break;
            case 'gameEnd':
                  _showGameEndDialog(message);
                  break;
            default:
                print('message');
                break;           
      }
     
    }, onResume: (Map<String, dynamic> message) {
     // _showAcceptanceDialog(message);
    });

    _messaging.getToken().then((token) {
      print('------------------');
      print(token);
      _userBloc.changeFcmToken(token);
    });



  }

  _delGetUserNamePref() async{

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String senderName = prefs.getString('user_name');

      setState(() {
              username = senderName ?? 'No name';
            });

  }

  _showGameEndDialog(Map<String, dynamic> message) async{

    //TODONOW: get message from notification;
    Future.delayed(
      Duration.zero, (){

        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => AlertDialog(

            title: Text('Game Endedn'),
            content: Text(message['notification']['body']), // get from server

            actions: <Widget>[
              FlatButton(
                child: Text('OK'),
                onPressed: () async{
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => MenuPage()));
                },
              ),
            ],

          ),
        );
      }
    );

  }


  _showAcceptanceDialog(Map<String, dynamic> message) async{

    String challengerId = message['data']['senderId'];
    String challengerName = message['data']['senderName'];
    String challengerFcmToken = message['data']['senderFcmToken'];


     SharedPreferences prefs = await SharedPreferences.getInstance();
     String senderFcmToken = prefs.getString('fcm_token');
    String senderId = prefs.getString('user_id');
    String senderName = prefs.getString('user_name');

    //TODO: remove This if not necessary .. The future dealyed
    Future.delayed(
      Duration.zero, (){

        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => AlertDialog(

            title: Text('Tic Tac Toe Challeenge'),
            content: Text(challengerName+' has Challenged you to a game of tic tac toe'),

            actions: <Widget>[
              FlatButton(
                child: Text('ACCEPT'),
                onPressed: () async{
                      _gameBloc.handleChallenge(senderId, senderName, senderFcmToken, challengerId, challengerName, challengerFcmToken, ChallengeHandleType.accept);
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => GameProcessPage()));
                },
              ),
              FlatButton(
                child: Text('DECLINE'),
                onPressed: (){
                       _gameBloc.handleChallenge(senderId, senderName, senderFcmToken, challengerId, challengerName, challengerFcmToken, ChallengeHandleType.reject);
                      Navigator.pop(context);
                },
              )
            ],

          ),
        );
      }
    );

  }


  @override
  Widget build(BuildContext context) {

    _userBloc = BlocProvider.of(context).userBloc;
    _gameBloc = BlocProvider.of(context).gameBloc;
    return Scaffold(
      backgroundColor: Color(0XFF212845),
      body: Stack(
        children: <Widget>[
          Positioned(
            left: -60.0,
            top: -75.0,
            child: _bigLetter('X'),
          ),
          Positioned(
            right: -100.0,
            bottom: -75.0,
            child: _bigLetter('O'),
          ),
         SingleChildScrollView(
           child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 40.0,
                ),
                Text(
                  'Tic Tac Toe',
                  style: TextStyle(
                    fontSize: 50.0,
                    fontWeight: FontWeight.bold,),
                ),
                SizedBox(
                  height: 40.0,
                ),
                Text('currentUser - '+username),
                SizedBox(
                  height: 40.0,
                ),

                _menuButton('PLAY WITH COMPUTER', (){
                  _gameBloc.startSingleDeviceGame(GameType.computer);
                  Navigator.of(context).push(MaterialPageRoute(builder:(index)=> GameBoard()));
                }),
                 _menuButton('PLAY WITH FRIEND', 
                  (){
                  _gameBloc.startSingleDeviceGame(GameType.multi_device);
                  Navigator.of(context).push(MaterialPageRoute(builder:(index)=> GameBoard()));
                }
                ),
                _menuButton('PLAY WITH USERS', 
                  (){
                  _userBloc.getUsers();
                  Navigator.of(context).push(MaterialPageRoute(builder:(index)=> UsersBoard()));
                }
                ),
                _menuButton('HIGH SCORE', (){
                  
                  _gameBloc.getHighScores();
                   Navigator.of(context).push(MaterialPageRoute(builder:(index)=> HighScoreBoard()));
                }),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                  Text('Play with Others?', style: TextStyle(
                    fontSize: 18.0
                  ),),
                  FlatButton(child: Text('Sign In', style:  TextStyle(
                    fontSize: 18.0,
                    color: Colors.blue
                  ),), onPressed: (){
                   Navigator.of(context).push(MaterialPageRoute(builder:(index)=> AuthPage(false)));
                },)
                ],)
              ],
            ),
        
         )
        ],
      ),
    );
  }
}

_menuButton(String text, onPressed) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 30.0),
    child: SizedBox(
      width: 300.0,
      child: RaisedButton(
          color: Color(0XFFF8D320),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(text, style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),
          ), onPressed: onPressed),
    ),
  );
}

_bigLetter(String letter) {
  return Text(
    letter,
    style: TextStyle(
      color: Colors.black,
      fontSize: 350.0,
    ),
  );
}
