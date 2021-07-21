import 'package:around_country/menu/menu_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main_page.dart';

class SettingPage extends StatefulWidget {
  @override
  State<SettingPage> createState() => SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  // ダークモードを設定するための変数
  bool isDarkMode = false;
  ThemeData _dark = ThemeData(brightness: Brightness.dark);
  ThemeData _light = ThemeData(brightness: Brightness.light);

  bool valNotify2 = false;
  bool valNotify3 = false;

  // サインアウト用のFirebase_Authのインスタンス
  final _auth = FirebaseAuth.instance;

  // ユーザーのメールアドレスを取得する
  String _getUserEmail() {
    String userEmail = '';
    User? user = FirebaseAuth.instance.currentUser;
    userEmail = user!.email!;
    return userEmail;
  }

  String sendPasswordResetEmail() {
    String email = _getUserEmail();
    try {
      _auth.sendPasswordResetEmail(email: email);
      return 'success';
    } catch (error) {
      return error.toString();
    }
  }

  onChangeDarkMode(bool newIsDarkMode) {
    setState(() {
      isDarkMode = newIsDarkMode;
    });
  }

  onChangeFunction2(bool newValue2) {
    setState(() {
      valNotify2 = newValue2;
    });
  }

  onChangeFunction3(bool newValue3) {
    setState(() {
      valNotify3 = newValue3;
    });
  }

  // サインアウト
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> _okDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    showDialog<void>(
      context: context,
      // 背景を押した時に、ダイアログは閉じない設定
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? _dark : _light,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.withOpacity(0.7),
          title: Text('設定',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              )),
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(10),
          child: ListView(
            children: [
              SizedBox(height: 40),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 10),
                  Text('アカウント',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                ],
              ),
              Divider(height: 20, thickness: 1),
              SizedBox(height: 10),
              buildAccountOption(context, 'パスワード変更', '確認', 'パスワード変更しますか？',
                  sendPasswordResetEmail),
              buildAccountOption(context, 'Content Settings', '確認',
                  'パスワード変更しますか？', sendPasswordResetEmail),
              buildAccountOption(context, 'Social', '確認', 'パスワード変更しますか？',
                  sendPasswordResetEmail),
              buildAccountOption(context, 'Language', '確認', 'パスワード変更しますか？',
                  sendPasswordResetEmail),
              buildAccountOption(context, 'Privacy and Security', '確認',
                  'パスワード変更しますか？', sendPasswordResetEmail),
              SizedBox(height: 40),
              Row(
                children: [
                  Icon(Icons.volume_up_outlined, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('詳細設定',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ))
                ],
              ),
              Divider(height: 20, thickness: 1),
              SizedBox(height: 10),
              buildNotificationOption('ダークモード', isDarkMode, onChangeDarkMode),
              buildNotificationOption(
                  'Account Active', valNotify2, onChangeFunction2),
              buildNotificationOption(
                  'Opportunity', valNotify3, onChangeFunction3),
              SizedBox(height: 50),
              Center(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    await _auth.signOut().then((result) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainPage(),
                        ),
                      );
                    });
                  },
                  child: Text(
                    'サインアウト',
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Padding buildNotificationOption(
      String title, bool value, Function onChangeMethod) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              )),
          Transform.scale(
            scale: 0.7,
            child: CupertinoSwitch(
              activeColor: Colors.blue,
              trackColor: Colors.grey,
              value: value,
              onChanged: (bool newValue) {
                onChangeMethod(newValue);
              },
            ),
          )
        ],
      ),
    );
  }

  GestureDetector buildAccountOption(BuildContext context, String uiTitle,
      String title, String content, Function function) {
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(title),
                content: Text(content),
                actions: [
                  FlatButton(
                    child: Text('はい'),
                    onPressed: () {
                      String result = function();
                      Navigator.of(context).pop();
                      if (result == 'success') {
                        if (function == sendPasswordResetEmail) {
                          _okDialog(context, '完了', 'パスワード変更のためにメールを送信しました。');
                        }
                      } else {
                        _okDialog(context, 'エラー',
                            '内部エラーが発生しました。\nある程度の時間が経過した後に、再度実行してください。');
                      }
                    },
                  ),
                  FlatButton(
                    child: Text('いいえ'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(uiTitle,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600])),
            Icon(Icons.arrow_forward_ios, color: Colors.grey)
          ],
        ),
      ),
    );
  }
}
