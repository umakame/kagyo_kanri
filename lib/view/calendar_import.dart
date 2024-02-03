import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

import '../main.dart';
import '../model/kagyo.dart';

class CalendarImport extends StatefulWidget {
  const CalendarImport({Key? key, required this.date}) : super(key: key);

  final String? date;

  @override
  _CalendarImportState createState() => _CalendarImportState();
}

class _CalendarImportState extends State<CalendarImport> {
  TextEditingController nameController = TextEditingController();
  TextEditingController achieveCountController = TextEditingController();
  TextEditingController achieveTimeController = TextEditingController();

  bool selectedValueIsTime = false;
  String selectedValueType = "count";
  String selectedValueUnit = "minute";

  final formKey = GlobalKey<FormState>();

  late Kagyo kagyo;

  void init() {
    nameController.text = "";
    achieveCountController.text = "";
    achieveTimeController.text = "";

//selectedValueIsTime = false;
    selectedValueType = "count";
    selectedValueUnit = "minute";
  }

  void initType() {
    achieveCountController.text = "";
    achieveTimeController.text = "";
    selectedValueUnit = "minute";
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> firestoreSet() async {
    final firestoreInstance = FirebaseFirestore.instance;

    CollectionReference kagyoLog = firestoreInstance
        .collection("users")
        .doc(account!.userId)
        .collection("kagyoLog")
        .doc(widget.date)
        .collection("log");

    int order = (await kagyoLog.get()).docs.length;


    try {
      kagyoLog.add({
        "docId": kagyoLog.doc().id,
        "userId": account.userId,
        "title": nameController.text,
        "isTime": false,
        "now": false,
        "type": selectedValueType,
        "isDone": true,
        "createdTime": Timestamp.now(),
        "updatedTime": Timestamp.now(),
        "order": order,
        "achieveCount":selectedValueType == "count"? int.parse(achieveCountController.text):0,
        "achieveTime": selectedValueType == "time"?selectedValueUnit == "minute"
            ? int.parse(achieveTimeController.text)
            : int.parse(achieveTimeController.text * 60):0,
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    ProgressDialog pd = ProgressDialog(context: context);
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text("加行入力画面"),
        //automaticallyImplyLeading:false,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              SizedBox(height: 40),
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(left: 30),
                    child: Text(
                      selectedValueIsTime ? "加行の内容" : "加行の名前",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: 300,
                    child: selectedValueIsTime
                        ? TextFormField(
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            minLines: 5,
                            controller: nameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '加行の内容を入力して下さい';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: "加行の内容",
                              border: OutlineInputBorder(),
                            ),
                          )
                        : TextFormField(
                            controller: nameController,
                            keyboardType: TextInputType.multiline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '加行の名前を入力して下さい';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: "加行の名前",
                              border: OutlineInputBorder(),
                            ),
                          ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Visibility(
                visible: selectedValueIsTime,
                child: Container(
                    alignment: Alignment.topLeft,
                    padding: EdgeInsets.only(left: 30),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          child: Text(
                            "時間",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )),
              ),
              if (selectedValueIsTime == false) SizedBox(height: 40),
              if (selectedValueIsTime == false)
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(left: 30),
                      child: Text(
                        "加行のタイプ",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            Radio(
                              value: "count",
                              groupValue: selectedValueType,
                              onChanged: (value) {
                                selectedValueType = value!;
                                initType();
                                setState(() {});
                              },
                            ),
                            Text('回数')
                          ],
                        ),
                        Row(
                          children: [
                            Radio(
                              value: "time",
                              groupValue: selectedValueType,
                              onChanged: (value) {
                                selectedValueType = value!;
                                initType();
                                setState(() {});
                              },
                            ),
                            Text('時間')
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              if (selectedValueIsTime == false) SizedBox(height: 40),
              if (selectedValueIsTime == false)
                Column(
                  children: [
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(left: 30),
                        child: Text(
                          selectedValueType == "count" ? "達成回数(回)" : "達成時間",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        )),
                    SizedBox(
                      height: 10,
                    ),
                    selectedValueType == "count"
                        ? Container(
                            width: 300,
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              controller: achieveCountController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '達成回数を入力して下さい';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: "達成回数(回)",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Container(
                                margin: EdgeInsets.only(left: 30, right: 10),
                                width: 230,
                                child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  controller: achieveTimeController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '達成時間を入力して下さい';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: "達成時間",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              Container(
                                height: 60,
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
                                        child: Text('分',
                                            style: TextStyle(fontSize: 20)),
                                      ),
                                      DropdownMenuItem(
                                        value: 'hour',
                                        child: Text('時間',
                                            style: TextStyle(fontSize: 20)),
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
                  ],
                ),
              if (selectedValueIsTime == false) SizedBox(height: 40),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  pd.show(msg: "書き込み中...");
                  await firestoreSet();
                  pd.close();

                },
                child: Text("追加"),
              )
            ],
          ),
        ),
      ),
    ));
  }
}
