import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpModel extends ChangeNotifier {
  String mail = '';
  String password = '';
  String userId = '';

  Future signUp() async {
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
          .createUserWithEmailAndPassword(email: mail, password: password);
      userId = userCredential.user!.uid;
      if (userCredential.user == null) {
        return;
      }
      FirebaseFirestore.instance.collection('users').doc(userId).set({
        'userId': userId,
        'email': mail,
        'createdAt': Timestamp.now(),
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw ('６文字以上入力してください');
      } else if (e.code == 'email-already-in-use') {
        throw ('そのメールアドレスはすでに登録されています');
      }
    } catch (e) {
      throw (e);
    }
  }
}
