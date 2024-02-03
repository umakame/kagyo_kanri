import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/kagyo.dart';
import '../main.dart';

class ImportListImput extends StatefulWidget {
  const ImportListImput({Key? key, required this.kagyo, required this.index})
      : super(key: key);

  final Kagyo? kagyo;
  final int? index;

  @override
  _ImportListImputState createState() => _ImportListImputState();
}

class _ImportListImputState extends State<ImportListImput> {
  TextEditingController nameController = TextEditingController();
  TextEditingController targetDayCountController = TextEditingController();
  TextEditingController targetAllCountController = TextEditingController();
  TextEditingController targetDayTimeController = TextEditingController();
  TextEditingController targetAllTimeController = TextEditingController();

  bool selectedValueIsTime = false;
  String selectedValueType = "count";
  String selectedValueTime = "早朝";
  String selectedValueDayUnit = "minute";
  String selectedValueAllUnit = "minute";

  final formKey = GlobalKey<FormState>();

  void init() {
    nameController.text = "";
    targetDayCountController.text = "";
    targetAllCountController.text = "";
    targetDayTimeController.text = "";
    targetAllTimeController.text = "";
//selectedValueIsTime = false;
    selectedValueType = "count";
    selectedValueTime = "早朝";
    selectedValueDayUnit = "minute";
    selectedValueAllUnit = "minute";
  }

  void initType() {
    targetDayCountController.text = "";
    targetAllCountController.text = "";
    targetDayTimeController.text = "";
    targetAllTimeController.text = "";
    selectedValueDayUnit = "minute";
    selectedValueAllUnit = "minute";
  }

  @override
  void initState() {
    super.initState();

    if (widget.kagyo != null) {
      Kagyo kagyo = widget.kagyo!;
      if (kagyo.isTime == true) {
        selectedValueIsTime = kagyo.isTime;
        nameController.text = kagyo.title;
        selectedValueTime = kagyo.specifiedTime!;
      } else {
        selectedValueIsTime = kagyo.isTime;
        nameController.text = kagyo.title;

        if (kagyo.targetDayCount == null) {
          targetDayCountController.text = "";
        } else {
          targetDayCountController.text = kagyo.targetDayCount.toString();
        }

        if (kagyo.targetAllCount == null) {
          targetAllCountController.text = "";
        } else {
          targetAllCountController.text = kagyo.targetAllCount.toString();
        }

        if (kagyo.targetDayTime == null) {
          targetDayTimeController.text = "";
        } else {
          targetDayTimeController.text = kagyo.targetDayTime.toString();
        }

        if (kagyo.targetAllTime == null) {
          targetAllTimeController.text = "";
        } else {
          targetAllTimeController.text = kagyo.targetAllTime.toString();
        }

        if (kagyo.targetDayTimeUnit == null) {
          selectedValueDayUnit = "minute";
        } else if (kagyo.targetDayTimeUnit! == "minute") {
          selectedValueDayUnit = kagyo.targetDayTimeUnit!;
        } else if (kagyo.targetDayTimeUnit! == "hour") {
          selectedValueDayUnit = kagyo.targetDayTimeUnit!;
        }

        if (kagyo.targetAllTimeUnit == null) {
          selectedValueAllUnit = "minute";
        } else if (kagyo.targetAllTimeUnit! == "minute") {
          selectedValueAllUnit = kagyo.targetAllTimeUnit!;
        } else if (kagyo.targetAllTimeUnit! == "hour") {
          selectedValueAllUnit = kagyo.targetAllTimeUnit!;
        }

        selectedValueType = kagyo.type;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Container(
                child: Column(
                  children: [
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(left: 30),
                        child: Text(
                          "時間指定",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        )),
                    Container(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              Radio(
                                value: false,
                                groupValue: selectedValueIsTime,
                                onChanged: (value) {
                                  selectedValueIsTime = value!;
                                  init();
                                  setState(() {});
                                },
                              ),
                              Text('なし')
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: true,
                                groupValue: selectedValueIsTime,
                                onChanged: (value) {
                                  selectedValueIsTime = value!;
                                  init();
                                  setState(() {});
                                },
                              ),
                              Text('あり')
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                        Container(
                          height: 40,
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
                                  value: '早朝',
                                  child: Text('早朝'),
                                ),
                                DropdownMenuItem(
                                  value: '08:00',
                                  child: Text('08:00'),
                                ),
                                DropdownMenuItem(
                                  value: '10:00',
                                  child: Text('10:00'),
                                ),
                                DropdownMenuItem(
                                  value: '12:00',
                                  child: Text('12:00'),
                                ),
                                DropdownMenuItem(
                                  value: '夕方',
                                  child: Text('夕方'),
                                ),
                                DropdownMenuItem(
                                  value: '夜',
                                  child: Text('夜'),
                                ),
                                DropdownMenuItem(
                                  value: '就寝前',
                                  child: Text('就寝前'),
                                ),
                              ],
                              value: selectedValueTime,
                              onChanged: (String? value) {
                                setState(() {
                                  selectedValueTime = value!;
                                });
                              },
                            ),
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
                          selectedValueType == "count" ? "全体の目標回数(回)" : "全体の目標時間",
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
                              controller: targetAllCountController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '全体の目標回数を入力して下さい';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: "全体の目標回数(回)",
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
                                  controller: targetAllTimeController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '全体の目標時間を入力して下さい';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: "全体の目標時間",
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
                                    value: selectedValueDayUnit,
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedValueDayUnit = value!;
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
              if (selectedValueIsTime == false)
                Column(
                  children: [
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(left: 30),
                        child: Text(
                          selectedValueType == "count" ? "1日の目標回数(回)" : "1日の目標時間",
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
                              controller: targetDayCountController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '1日の目標回数を入力して下さい';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: "1日の目標回数(回)",
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
                                  controller: targetDayTimeController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '1日の目標時間を入力して下さい';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: "1日の目標時間",
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
                                    value: selectedValueAllUnit,
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedValueAllUnit = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              SizedBox(height: 40),
              ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                    if (formKey.currentState!.validate()) {
                      Kagyo kagyo = Kagyo(
                          userId: account!.userId,
                          isTime: selectedValueIsTime,
                          title: nameController.text,
                          specifiedTime:
                              selectedValueIsTime ? selectedValueTime : null,
                          targetDayCount: selectedValueIsTime == false
                              ? selectedValueType == "count"
                                  ? int.parse(targetDayCountController.text)
                                  : null
                              : null,
                          targetAllCount: selectedValueIsTime == false
                              ? selectedValueType == "count"
                                  ? int.parse(targetAllCountController.text)
                                  : null
                              : null,
                          targetDayTime: selectedValueIsTime == false
                              ? selectedValueType == "time"
                                  ? int.parse(targetDayTimeController.text)
                                  : null
                              : null,
                          targetAllTime: selectedValueIsTime == false
                              ? selectedValueType == "time"
                                  ? int.parse(targetAllTimeController.text)
                                  : null
                              : null,
                          now: true,
                          isDone: false,
                          type: selectedValueIsTime == false
                              ? selectedValueType == "time"
                                  ? "time"
                                  : "count"
                              : "",
                          targetDayTimeUnit: selectedValueIsTime == false
                              ? selectedValueType == "time"
                                  ? selectedValueDayUnit == "minute"
                                      ? "minute"
                                      : "hour"
                                  : null
                              : null,
                          targetAllTimeUnit: selectedValueIsTime == false
                              ? selectedValueType == "time"
                                  ? selectedValueAllUnit == "minute"
                                      ? "minute"
                                      : "hour"
                                  : null
                              : null,
                          createdTime: Timestamp.now(),
                          updatedTime: Timestamp.now());

                      Map<String, dynamic> result = {
                        'kagyo': kagyo,
                        'index': widget.index,
                      };

                      Navigator.pop(context, result);
                    }
                  },
                  child: Text(widget.index == null ? "追加" : "更新")),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ));
  }
}
