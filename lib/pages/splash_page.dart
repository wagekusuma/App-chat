import 'dart:async';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:chatopia/services/app_state.dart';
import 'package:chatopia/utils/navigator.dart';
import 'package:chatopia/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/user_service.dart';
import '../utils/get.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  StreamSubscription<InternetStatus>? listen;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: AvatarGlow(
          endRadius: 120,
          glowColor: Colors.grey,
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Icon(
              Icons.message_rounded,
              size: 70,
              color: Colors.deepPurple,
            ),
          ),
        ),
      ),
    );
  }

  Future getData(String id) async {
    // get data from firebase return in map
    Map<String, dynamic> myData = await UserService().getUser(id);
    // set myData to modal local data
    await Get.setUserDataToLocal(myData);
  }

  @override
  void dispose() {
    super.dispose();
    listen?.cancel();
  }

  @override
  void initState() {
    Get.fToast.init(context);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Map<String, dynamic>? data =
          (ModalRoute.of(context)?.settings.arguments) as Map<String, dynamic>?;
      await Future.delayed(const Duration(seconds: 2));
      SharedPreferences.getInstance().then((value) async {
        if (value.getBool("isLogin") == true) {
          listen = InternetConnection().onStatusChange.listen((event) {
            if (event == InternetStatus.disconnected) {
              Get.fToastShow("No internet", gravity: ToastGravity.BOTTOM);
            } else {
              getData(value.getString("id").toString()).then((value) {
                context.read<AppState>().setIsOnline(isonline: true);
                if (data != null) {
                  Screen.pushReplacementNamed(
                    Routes.chats,
                    arguments: {
                      "name": data['name'],
                      "profile": data['profile'],
                      "room_id": data['room_id'],
                      "friend_id": data['friend_id'],
                      "push_token": data['push_token'],
                    },
                  );
                  return;
                }
                Screen.pushReplacementNamed(Routes.chats);
              });
            }
          });
        } else {
          Screen.pushReplacementNamed(Routes.auth);
        }
      });
    });
    super.initState();
  }
}
