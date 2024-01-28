import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kagyo_kanri/view/main.dart';
import 'package:kagyo_kanri/view/todo_imput_count.dart';
import 'package:kagyo_kanri/view/todo_imput_time.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import '../model/function.dart';
import '../model/kagyo.dart';

class TodoImput extends StatefulWidget {
  const TodoImput({Key? key, required this.date, required this.itemIndex}) : super(key: key);

  final String date;
  final int itemIndex;

  @override
  _TodoImputState createState() => _TodoImputState();
}

class _TodoImputState extends State<TodoImput> {
  late int itemIndex;
  String targetAllTimeUnit = "";
  String targetDayTimeUnit = "";

  var editCountController = TextEditingController();
  var addCountController = TextEditingController();

  var editTimeController = TextEditingController();
  var addTimeController = TextEditingController();

  late Kagyo kagyo;

  final formKeyEditCount = GlobalKey<FormState>();
  final formKeyAddCount = GlobalKey<FormState>();
  final formKeyEditTime = GlobalKey<FormState>();
  final formKeyAddTime = GlobalKey<FormState>();

  var selectedValueEditTimeUnit = "minute";
  var selectedValueAddTimeUnit = "minute";


  @override
  void initState() {
    super.initState();
    _fetchKagyosStream();
  }

  Stream<List<Kagyo>> _fetchKagyosStream() {
    final firestore = FirebaseFirestore.instance;
    final stream = firestore
        .collection('users')
        .doc(account!.userId)
        .collection("kagyoLog").doc(widget.date).collection("log")
        .where('now', isEqualTo: true)
        .orderBy('order') // 'order' パラメーターでソート
        .snapshots();
    return stream.map((snapshot) =>
        snapshot.docs.map((doc) => Kagyo.fromMap(doc.data())).toList());
  }

  void initKagyo(Kagyo kagyo) {
    if (kagyo.targetAllTimeUnit == "minute") {
      targetAllTimeUnit = "分";
    } else if (kagyo.targetAllTimeUnit == "hour") {
      targetAllTimeUnit = "時間";
    }

    if (kagyo.targetDayTimeUnit == "minute") {
      targetDayTimeUnit = "分";
    } else if (kagyo.targetDayTimeUnit == "hour") {
      targetDayTimeUnit = "時間";
    }
  }

  String timeConvert(int time) {
    int minute = time % 60;
    int hour = (time ~/ 60);

    String txt = hour.toString() + "時間" + minute.toString() + "分";

    return txt;
  }

  Future<void> firebaseUpdate(String type) async {
    try {
      // Firestoreのコレクションの参照を取得
      CollectionReference kagyosCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(account!.userId)
          .collection("kagyoLog").doc(widget.date).collection("log");

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

        if (type == "editCount") {
          Map<String, dynamic> updatedData = {
            'achieveCount': int.parse(editCountController.text)
          };

          await documentReference.update(updatedData);

          await documentReference.get().then((querySnapshot) async {
            if (querySnapshot['achieveCount'] >=
                querySnapshot['targetDayCount']) {
              Map<String, dynamic> updatedData = {'isDone': true};
              await documentReference.update(updatedData);
            }

            if (querySnapshot['achieveCount'] <
                querySnapshot['targetDayCount']) {
              if (querySnapshot['isDone'] == true) {
                Map<String, dynamic> updatedData = {'isDone': false};
                await documentReference.update(updatedData);
              }
            }
          });

          editCountController.text = "";
        } else if (type == "addCount") {
          Map<String, dynamic> updatedData = {
            'achieveCount': querySnapshot.docs.first['achieveCount'] +
                int.parse(addCountController.text)
          };

          await documentReference.update(updatedData);

          await documentReference.get().then((querySnapshot) async {
            if (querySnapshot['achieveCount'] >=
                querySnapshot['targetDayCount']) {
              Map<String, dynamic> updatedData = {'isDone': true};
              await documentReference.update(updatedData);
            }

            if (querySnapshot['achieveCount'] <
                querySnapshot['targetDayCount']) {
              if (querySnapshot['isDone'] == true) {
                Map<String, dynamic> updatedData = {'isDone': false};
                await documentReference.update(updatedData);
              }
            }
          });

          addCountController.text = "";
        } else if (type == "editTime") {
          int time = 0;

          if (selectedValueEditTimeUnit == "minute") {
            time = int.parse(editTimeController.text);
          }

          if (selectedValueEditTimeUnit == "hour") {
            time = int.parse(editTimeController.text) * 60;
          }

          Map<String, dynamic> updatedData = {'achieveTime': time};

          await documentReference.update(updatedData);

          await documentReference.get().then((querySnapshot) async {
            if (querySnapshot['achieveTime'] >=
                querySnapshot['targetDayTime']) {
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

          editTimeController.text = "";
        } else if (type == "addTime") {
          int time = 0;

          if (selectedValueAddTimeUnit == "minute") {
            time = int.parse(addTimeController.text);
          }

          if (selectedValueAddTimeUnit == "hour") {
            time = int.parse(addTimeController.text) * 60;
          }

          Map<String, dynamic> updatedData = {
            'achieveTime': querySnapshot.docs.first['achieveTime'] + time
          };

          await documentReference.update(updatedData);

          await documentReference.get().then((querySnapshot) async {
            if (querySnapshot['achieveTime'] >=
                querySnapshot['targetDayTime']) {
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

          addTimeController.text = "";
        }
      } else {
        print('該当するドキュメントが見つかりませんでした');
      }
    } catch (e) {
      print('エラー: $e');
      // エラーが発生した場合の処理
    }
  }

  @override
  Widget build(BuildContext context) {
    ProgressDialog pd = ProgressDialog(context: context);

    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Text("詳細"),
              backgroundColor: Theme
                  .of(context)
                  .colorScheme
                  .inversePrimary,
            ),
            body: SingleChildScrollView(
                child: StreamBuilder<List<Kagyo>>(
                    stream: _fetchKagyosStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('エラーが発生しました'); // エラー時の表示
                      } else if (snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return Container(
                          height: MediaQuery
                              .of(context)
                              .size
                              .height, // 薄暗い背景
                          child: Center(
                            child: CircularProgressIndicator(), // サークルインジケーター
                          ),
                        ); // データが null または空の場合は何も表示しない
                      } else {
                        kagyo = snapshot.data![widget.itemIndex];

                        if (kagyo.achieveTime == null) {
                          kagyo.achieveTime = 0;
                        }

                        if (kagyo.achieveCount == null) {
                          kagyo.achieveCount = 0;
                        }

                        return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(kagyo.title),
                              kagyo.isTime == true
                                  ? Text(
                                  "指定時間:" + kagyo.specifiedTime.toString())
                                  : Container(),
                              kagyo.isTime == false
                                  ? kagyo.type == "count"
                                  ? Text("目標回数:" +
                                  kagyo.targetAllCount.toString() +
                                  "回")
                                  : Text("目標時間:" +
                                  timeConvert(kagyo.targetAllTime!))
                                  : Container(),
                              kagyo.isTime == false
                                  ? kagyo.type == "count"
                                  ? Text("達成回数:" +
                                  kagyo.targetAllCount.toString() +
                                  "回")
                                  : Text("達成時間:" +
                                  timeConvert(kagyo.targetAllTime!))
                                  : Container(),
                              kagyo.isTime == false
                                  ? kagyo.type == "count"
                                  ? Text("1日の目標回数:" +
                                  kagyo.targetDayCount.toString() +
                                  "回")
                                  : Text("１日の目標時間:" +
                                  timeConvert(kagyo.targetDayTime!))
                                  : Container(),
                              kagyo.isTime == false
                                  ? kagyo.type == "count"
                                  ? Text("今日の達成回数:" +
                                  kagyo.achieveCount.toString() +
                                  "回")
                                  : Text("今日の達成時間:" +
                                  timeConvert(kagyo.achieveTime!))
                                  : Container(),
                              SizedBox(
                                height: 50,
                              ),
                              kagyo.isTime == false
                                  ? kagyo.type == "count"
                                  ? Column(children: [
                                Row(children: [
                                  SizedBox(width: 20),
                                  Expanded(
                                      child: Container(
                                        color: Color(0xFFe6e6fa),
                                        child: Form(
                                          key: formKeyEditCount,
                                          child: TextFormField(
                                            validator: (value) {
                                              // メールアドレスが入力されていない場合
                                              if (value == null ||
                                                  value.isEmpty) {
                                                // 問題があるときはメッセージを返す
                                                return '回数を入力して下さい';
                                              }
                                              // 問題ないときはnullを返す
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                                enabledBorder:
                                                OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color:
                                                      Colors.black),
                                                ),
                                                labelText: "今日の達成回数"),
                                            keyboardType:
                                            TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly
                                            ],
                                            textAlign: TextAlign.end,
                                            controller:
                                            editCountController,
                                          ),
                                        ),
                                      )),
                                  SizedBox(width: 20),
                                  ElevatedButton(
                                      onPressed: () async {
                                        if (formKeyEditCount
                                            .currentState!
                                            .validate()) {
                                          pd.show(msg: "書き込み中...");
                                          await firebaseUpdate(
                                              "editCount");
                                          await checkCompleted(widget.date);
                                          pd.close();
                                        }
                                      },
                                      child: Text("変更")),
                                  SizedBox(width: 20),
                                ]),
                                SizedBox(height: 20),
                                Row(
                                  children: [
                                    SizedBox(width: 20),
                                    Expanded(
                                        child: Container(
                                          color: Color(0xFFe6e6fa),
                                          child: Form(
                                            key: formKeyAddCount,
                                            child: TextFormField(
                                              validator: (value) {
                                                // メールアドレスが入力されていない場合
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  // 問題があるときはメッセージを返す
                                                  return '回数を入力して下さい';
                                                }
                                                // 問題ないときはnullを返す
                                                return null;
                                              },
                                              decoration: InputDecoration(
                                                  enabledBorder:
                                                  OutlineInputBorder(
                                                    borderSide:
                                                    BorderSide(
                                                        color: Colors
                                                            .black),
                                                  ),
                                                  labelText: "追加したい回数"),
                                              keyboardType:
                                              TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                              textAlign: TextAlign.end,
                                              controller:
                                              addCountController,
                                            ),
                                          ),
                                        )),
                                    SizedBox(width: 20),
                                    ElevatedButton(
                                        onPressed: () async {
                                          if (formKeyAddCount
                                              .currentState!
                                              .validate()) {
                                            pd.show(msg: "書き込み中...");
                                            await firebaseUpdate(
                                                "addCount");
                                            await checkCompleted(widget.date);
                                            pd.close();
                                          }
                                        },
                                        child: Text(
                                          "追加",
                                        )),
                                    SizedBox(width: 20),
                                  ],
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            // （2） 実際に表示するページ(ウィジェット)を指定する
                                              builder: (context) =>
                                                  TodoImputCount(date:widget.date,itemIndex:widget.itemIndex)));
                                    },
                                    child: Text("カウンターで計測する")),
                              ])
                                  : Column(children: [
                                Row(children: [
                                  SizedBox(width: 20),
                                  Expanded(
                                      child: Container(
                                        color: Color(0xFFe6e6fa),
                                        child: Form(
                                          key: formKeyEditTime,
                                          child: TextFormField(
                                            validator: (value) {
                                              // メールアドレスが入力されていない場合
                                              if (value == null ||
                                                  value.isEmpty) {
                                                // 問題があるときはメッセージを返す
                                                return '時間を入力して下さい';
                                              }
                                              // 問題ないときはnullを返す
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                                enabledBorder:
                                                OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color:
                                                      Colors.black),
                                                ),
                                                labelText: "今日の達成時間"),
                                            keyboardType:
                                            TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly
                                            ],
                                            textAlign: TextAlign.end,
                                            controller:
                                            editTimeController,
                                          ),
                                        ),
                                      )),
                                  SizedBox(width: 20),
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
                                    child:
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton(
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'minute',
                                            child: Text('分',
                                                style: TextStyle(
                                                    fontSize: 20)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'hour',
                                            child: Text('時間',
                                                style: TextStyle(
                                                    fontSize: 20)),
                                          ),
                                        ],
                                        value:
                                        selectedValueEditTimeUnit,
                                        onChanged: (String? value) {
                                          setState(() {
                                            selectedValueEditTimeUnit =
                                            value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  ElevatedButton(
                                      onPressed: () async {
                                        if (formKeyEditTime
                                            .currentState!
                                            .validate()) {
                                          pd.show(msg: "書き込み中...");
                                          await firebaseUpdate(
                                              "editTime");
                                          await checkCompleted(widget.date);
                                          pd.close();
                                        }
                                      },
                                      child: Text("変更")),
                                  SizedBox(width: 20),
                                ]),
                                SizedBox(height: 20),
                                Row(
                                  children: [
                                    SizedBox(width: 20),
                                    Expanded(
                                        child: Container(
                                          color: Color(0xFFe6e6fa),
                                          child: Form(
                                            key: formKeyAddTime,
                                            child: TextFormField(
                                              validator: (value) {
                                                // メールアドレスが入力されていない場合
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  // 問題があるときはメッセージを返す
                                                  return '時間を入力して下さい';
                                                }
                                                // 問題ないときはnullを返す
                                                return null;
                                              },
                                              decoration: InputDecoration(
                                                  enabledBorder:
                                                  OutlineInputBorder(
                                                    borderSide:
                                                    BorderSide(
                                                        color: Colors
                                                            .black),
                                                  ),
                                                  labelText: "追加したい時間"),
                                              keyboardType:
                                              TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                              textAlign: TextAlign.end,
                                              controller:
                                              addTimeController,
                                            ),
                                          ),
                                        )),
                                    SizedBox(width: 20),
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
                                      child:
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton(
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'minute',
                                              child: Text('分',
                                                  style: TextStyle(
                                                      fontSize: 20)),
                                            ),
                                            DropdownMenuItem(
                                              value: 'hour',
                                              child: Text('時間',
                                                  style: TextStyle(
                                                      fontSize: 20)),
                                            ),
                                          ],
                                          value:
                                          selectedValueAddTimeUnit,
                                          onChanged: (String? value) {
                                            setState(() {
                                              selectedValueAddTimeUnit =
                                              value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    ElevatedButton(
                                        onPressed: () async {
                                          if (formKeyAddTime
                                              .currentState!
                                              .validate()) {
                                            pd.show(msg: "書き込み中...");
                                            await firebaseUpdate(
                                                "addTime");
                                            await checkCompleted(widget.date);
                                            pd.close();
                                          }
                                        },
                                        child: Text(
                                          "追加",
                                        )),
                                    SizedBox(width: 20),
                                  ],
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            // （2） 実際に表示するページ(ウィジェット)を指定する
                                              builder: (context) =>
                                                  TodoImputTime(date:widget.date,itemIndex:widget.itemIndex)));
                                    },
                                    child: Text("タイマーで計測する")),
                              ])
                                  : Container()
                            ]);
                      }
                    }))));
  }
}
