import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginModel extends ChangeNotifier {
  String mail = '';
  String password = '';
  static String userId = '';

  Future Login() async {
    // 大文字と小文字が含まれているかを判定するための変数
    String upPassword = password.toUpperCase();
    String lowPassword = password.toLowerCase();

    // メールアドレスのバリデーション
    if (mail.isEmpty) {
      throw ('メールアドレスを入力してください');
    } else if (!RegExp(
            r'^[a-zA-Z0-9_.+-]+@([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.)+[a-zA-Z]{2,}$')
        .hasMatch(mail)) {
      throw ('メールアドレスが不正です');
    }

    // パスワードのバリデーション
    if (password.isEmpty) {
      throw ('パスワードを入力してください');
    } else if (password.length < 8 || 16 < password.length) {
      throw ('パスワードの文字数を8~16文字に設定してください');
    } else if ((password == upPassword || password == lowPassword) ||
        (!RegExp(r'^[a-zA-Z0-9_.+-]*[0-9]+[a-zA-Z0-9_.+-]*$')
            .hasMatch(password))) {
      throw ('パスワードは半角大英文字・半角小英文字・半角数字を入れてください');
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: mail, password: password);
      userId = userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw ('ユーザーが見つかりません');
      } else if (e.code == 'wrong-password') {
        throw ('パスワードが間違っています');
      }
    }
  }
}
