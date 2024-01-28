import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_file.dart';
import '../model/FirebaseAuth.dart';
import '../model/account.dart';
import 'home.dart';
import 'login.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';

AuthService authService = AuthService();
late Account account;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Intl.defaultLocale = 'ja_JP';

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('English'), Locale('ja')],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoSansJP',
      ),
      // ここに MaterialApp のプロパティを設定
      home: App(), // あなたのアプリケーションのメイン ウィジェット
    );
  }
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            // ユーザーがログインしていない場合、ログイン画面に遷移
            return Login();
          } else {
            // ユーザーがログインしている場合、ホーム画面に遷移
            account = Account(userId: user!.uid);
            return Home();
          }
        }
        // ConnectionStateがactiveでない場合はローディングなどを表示
        return CircularProgressIndicator();
      },
    );
  }
}
