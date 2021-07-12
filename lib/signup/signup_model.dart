import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpModel extends ChangeNotifier {
  String mail = '';
  String password = '';

  Future signUp() async {
    // 大文字と小文字が含まれているかを判定するための変数
    String upPassword = password.toUpperCase();
    String lowPassword = password.toUpperCase();

    // メールアドレスのバリデーション
    if (mail.isEmpty) {
      throw ('メールアドレスを入力してください');
    }

    // パスワードのバリデーション
    if (password.isEmpty) {
      throw ('パスワードを入力してください');
    } else if (password == upPassword || password == lowPassword) {
      throw ('大文字と');
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: mail, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw ('６文字以上入力してください');
      } else if (e.code == 'email-already-in-use') {
        throw ('そのメールアドレスはすでに登録されています');
      }
    } catch (e) {
      throw (e);
    }
    FirebaseFirestore.instance.collection('users').add({
      'email': mail,
      'createdAt': Timestamp.now(),
    });
  }
}
