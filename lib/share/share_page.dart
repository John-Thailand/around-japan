import 'package:flutter/material.dart';
import 'package:share/share.dart';

class SharePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.withOpacity(0.7),
        title: Text('共有',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            )),
      ),
      body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('img/background-share.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: RaisedButton(
              color: Colors.white.withOpacity(0.75),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                width: (MediaQuery.of(context).size.width - 100),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '共有する',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onPressed: () async {
                // メッセージをSNSに共有する
                await share();
              },
            ),
          )),
    );
  }
}

Future share() async {
  await Share.share('Thank you for sharing Around Japan App!!!',
      subject: 'Around Japan App');
}
