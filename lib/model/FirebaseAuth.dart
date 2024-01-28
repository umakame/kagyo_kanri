import 'package:firebase_auth/firebase_auth.dart';
import 'package:kagyo_kanri/model/account.dart';

class AuthService {
  FirebaseAuth _auth = FirebaseAuth.instance;
  Account? account;

  // サインイン
  Future<void> signIn(String email,String password) async {
    // ログイン処理
    var result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // ログイン成功時にユーザー情報を保存
    account = Account(userId:result.user!.uid);
  }

  // ユーザー情報の取得
  Account? getAccount() {
    return account;
  }
}