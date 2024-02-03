import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';

import '../model/function.dart';
import '../main.dart';

class TodoImputTime extends StatefulWidget {
  const TodoImputTime({Key? key, required this.date, required this.itemIndex})
      : super(key: key);

  final String date;
  final int itemIndex;

  @override
  _TodoImputTimeState createState() => _TodoImputTimeState();
}

class _TodoImputTimeState extends State<TodoImputTime> {
  final _stopWatchTimer = StopWatchTimer();
  bool startFlug = false;
  bool soundFlug = false;
  String selectedValueUnit = "minute";
  TextEditingController targetController = TextEditingController();

  int time = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _stopWatchTimer.dispose();
    super.dispose();
  }

  Future<void> firebaseUpdate() async {
    try {
      // Firestoreのコレクションの参照を取得
      CollectionReference kagyosCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(account!.userId)
          .collection("kagyoLog")
          .doc(widget.date)
          .collection("log");

      // クエリを作成して該当するドキュメントを取得
      QuerySnapshot querySnapshot = await kagyosCollection
          .where('now', isEqualTo: true)
          .where('order', isEqualTo: widget.itemIndex)
          .get();

      // ドキュメントが存在する場合
      if (querySnapshot.docs.isNotEmpty) {
        // ドキュメントの参照を取得
        DocumentReference documentReference =
            querySnapshot.docs.first.reference;
        Map<String, dynamic> updatedData = {
          'achieveTime': querySnapshot.docs.first['achieveTime'] + time
        };

        await documentReference.update(updatedData);

        await documentReference.get().then((querySnapshot) async {
          if (querySnapshot['achieveTime'] >= querySnapshot['targetDayTime']) {
            Map<String, dynamic> updatedData = {'isDone': true};
            await documentReference.update(updatedData);
          }

          if (querySnapshot['achieveTime'] < querySnapshot['targetDayTime']) {
            if (querySnapshot['isDone'] == true) {
              Map<String, dynamic> updatedData = {'isDone': false};
              await documentReference.update(updatedData);
            }
          }
        });
      } else {
        print('該当するドキュメントが見つかりませんでした');
      }
    } catch (e) {
      print('エラー: $e');
      // エラーが発生した場合の処理
    }
  }

  Future<void> _showResetDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('リセットの確認'),
          content: Text('カウントをリセットしてもよろしいですか？'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                _stopWatchTimer.onResetTimer();
                soundFlug = false;
                setState(() {}); // カウントをリセット
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text('はい'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRegisterDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('登録の確認'),
          content: Text('計測されたカウントを登録してもよろしいですか？'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                firebaseUpdate();
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text('はい'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("詳細"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: GestureDetector(
          onTap: () {
            if (startFlug == false) {
              _stopWatchTimer.onStartTimer();
              startFlug = true;
            } else {
              _stopWatchTimer.onStopTimer();
              startFlug = false;
            }

            setState(() {});
          },
          child: Container(
            color: Color(0xFFe6e6fa),
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Spacer(),
                Expanded(
                  child: Container(
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          right: 0,
                          left: 0,
                          child: Container(
                            alignment: Alignment.center,
                            width: 450,
                            height: 400,
                            child: Image.asset('assets/images/timer.png'),
                          ),
                        ),
                        Positioned(
                          right: 80,
                          top: 162,
                          child: StreamBuilder<int>(
                              stream: _stopWatchTimer.rawTime,
                              initialData: _stopWatchTimer.rawTime.value,
                              builder: (context, snapshot) {
                                final displayTime =
                                    StopWatchTimer.getDisplayTime(
                                  snapshot.data!,
                                  milliSecond: false,
                                );

                                final timeInSeconds =
                                    snapshot.data! ~/ 1000; // ミリ秒から秒に変換
                                var minutes = (timeInSeconds ~/ 60);
                                time = minutes;

                                if (selectedValueUnit == "hour") {
                                  minutes = (minutes ~/ 60);
                                }

                                if (targetController.text.isNotEmpty &&
                                    targetController.text != "0") {
                                  if (minutes ==
                                      int.parse(targetController.text)) {
                                    if (soundFlug == false) {
                                      AudioPlayer audioPlayer = AudioPlayer();
                                      audioPlayer.play(
                                          AssetSource("sounds/omedetou.mp3"));
                                      soundFlug = true;

                                      // ダイアログを非同期で表示
                                      Future.delayed(Duration.zero, () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return CupertinoAlertDialog(
                                              title: Text('おめでとうございます！'),
                                              content: Text('目標時間に達しました。'),
                                              actions: <Widget>[
                                                CupertinoDialogAction(
                                                  isDefaultAction: true,
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(); // ダイアログを閉じる
                                                  },
                                                  child: Text('OK'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      });
                                    }
                                  }
                                }

                                return Text(displayTime,
                                    style: TextStyle(
                                        fontSize: 50, color: Colors.white));
                              }),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    SizedBox(width: 70),
                    Container(
                      width: 120,
                      height: 50,
                      child: TextFormField(
                        controller: targetController,
                        decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            labelText: "目標時間"),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        textAlign: TextAlign.end,
                        onChanged: (value) {
                          soundFlug = false;
                        },
                      ),
                    ),
                    SizedBox(width: 40),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            offset: Offset(1.0, 1.0),
                            blurRadius: 0.8,
                            spreadRadius: 0.8,
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                          items: const [
                            DropdownMenuItem(
                              value: 'minute',
                              child: Text('分', style: TextStyle(fontSize: 20)),
                            ),
                            DropdownMenuItem(
                              value: 'hour',
                              child: Text('時間', style: TextStyle(fontSize: 20)),
                            ),
                          ],
                          value: selectedValueUnit,
                          onChanged: (String? value) {
                            setState(() {
                              selectedValueUnit = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // ボタンを左端と右端に配置
                    children: [
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _showResetDialog();
                            },
                            child: Text("リセット"),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await _showRegisterDialog();
                          await checkCompleted(widget.date);
                        },
                        child: Text("登録する"),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
