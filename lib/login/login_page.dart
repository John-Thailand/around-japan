import 'package:around_country/menu/menu_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_model.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mailController = TextEditingController();
    final passwordController = TextEditingController();

    return ChangeNotifierProvider<LoginModel>(
      create: (_) => LoginModel(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.withOpacity(0.7),
          title: Text('ログイン',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              )),
        ),
        body: Consumer<LoginModel>(
          builder: (context, model, child) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 35),
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'メールアドレス',
                        hintText: 'example@ex.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      controller: mailController,
                      onChanged: (text) {
                        model.mail = text;
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 35),
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'パスワード',
                        hintText: 'P@ssw0rd',
                        prefixIcon: Icon(Icons.password),
                      ),
                      obscureText: true,
                      controller: passwordController,
                      onChanged: (text) {
                        model.password = text;
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 45),
                    width: 190,
                    child: RaisedButton(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        'ログインする',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                        ),
                      ),
                      onPressed: () async {
                        try {
                          await model.Login();
                          _showDialog(context, 'ログインしました');
                        } catch (e) {
                          _showDialog(context, e.toString());
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Future _showDialog(BuildContext context, String title) async {
  showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              if (title == 'ログインしました') {
                // メニューページへ遷移
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MenuPage()),
                );
              }
            },
          ),
        ],
      );
    },
  );
}
