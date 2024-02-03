import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kagyo_kanri/model/date_competeted.dart';
import 'package:kagyo_kanri/view/todo_imput.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import '../model/kagyo.dart';
import '../main.dart';
import '../model/function.dart';
import 'package:intl/intl.dart';

import 'calendar_import.dart';

final dateToday = DateUtils.dateOnly(DateTime.now());

class Calendar extends StatefulWidget {
  const Calendar({Key? key}) : super(key: key);

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  List<DateTime?> _singleDatePickerValueWithDefaultValue = [DateTime.now()];

  final List<DateTime> specialDates = [];

  List<CompletedDate> completedDateList = [];

  bool isChecked = false;
  List<bool> isCheckedList = [];
  List<Kagyo> kagyoList = [];
  String selectedDay = today();

  Stream<List<Kagyo>> _fetchKagyosStream(String date) {
    final firestore = FirebaseFirestore.instance;
    final stream = firestore
        .collection('users')
        .doc(account!.userId)
        .collection("kagyoLog")
        .doc(date)
        .collection("log")
        .orderBy('order') // 'order' パラメーターでソート
        .snapshots();

    return stream.map((snapshot) =>
        snapshot.docs.map((doc) => Kagyo.fromMap(doc.data())).toList());
  }

  Future<void> isDoneUpdate(int tappedIndex, bool isDone) async {
    CollectionReference kagyosCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(account.userId)
        .collection("kagyoLog")
        .doc(selectedDay)
        .collection("log");

    // ドキュメントの取得
    QuerySnapshot querySnapshot = await kagyosCollection.orderBy("order").get();

    // ドキュメントID
    String docId = querySnapshot.docs[tappedIndex].id;

    // ドキュメントデータ
    Map<String, dynamic> data =
        querySnapshot.docs[tappedIndex].data() as Map<String, dynamic>;

    if (isDone == true) {
      data['isDone'] = false;
    } else {
      data['isDone'] = true;
    }

    // ドキュメントを更新
    await kagyosCollection.doc(docId).update(data);
  }

  Stream<List<CompletedDate>> _fetchCompletedStream() {
    final firestore = FirebaseFirestore.instance;

    // get メソッドを使用してデータを同期的に取得
    final querySnapshot = firestore
        .collection('users')
        .doc(account!.userId)
        .collection("kagyoLog")
        .get();

    return querySnapshot
        .then((snapshot) => snapshot.docs
            .map((doc) => CompletedDate.fromMap(doc.data()))
            .toList())
        .asStream();
  }

  DateTime convertDateTime(String date) {
    String year = date.substring(0, 4);
    String month = date.substring(4, 6);
    String day = date.substring(6, 8);

    DateTime dateTime =
        DateTime(int.parse(year), int.parse(month), int.parse(day));

    return dateTime;
  }

  Future<void> fireStoreDelete(int tappedIndex) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(account.userId)
        .collection("kagyoLog")
        .doc(selectedDay)
        .collection("log").where("order", isEqualTo: tappedIndex).get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }

    
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text("レポート"),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    ProgressDialog pd = ProgressDialog(context: context);
    return SingleChildScrollView(
      child: Column(
        children: [
          StreamBuilder<List<CompletedDate>>(
              stream: _fetchCompletedStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('エラーが発生しました'); // エラー時の表示
                } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return Container(
                    height: MediaQuery.of(context).size.height, // 薄暗い背景
                    child: Center(
                      child: CircularProgressIndicator(), // サークルインジケーター
                    ),
                  ); // データが null または空の場合は何も表示しない
                } else {
                  completedDateList = snapshot.data!;
                  specialDates.clear();

                  for (int i = 0; i < completedDateList.length; i++) {
                    if (completedDateList[i].completed == true) {
                      specialDates
                          .add(convertDateTime(completedDateList[i].date));
                    }
                  }
                }

                return Container(
                    color: Colors.grey,
                    child: _buildDefaultSingleDatePickerWithValue());
              }),
          Row(
            children: [
              Text(
                convertDateString(selectedDay),
                style: TextStyle(fontSize: 20),
              ),
              Container(
                  alignment: Alignment.centerRight,
                  child: int.parse(selectedDay) <= int.parse(today())
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    CalendarImport(date: selectedDay),
                              ),
                            );
                          },
                          child: Icon(Icons.add_box_outlined))
                      : Container()),
            ],
          ),
          StreamBuilder<List<Kagyo>>(
            stream: _fetchKagyosStream(selectedDay),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('エラーが発生しました'); // エラー時の表示
              } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                return Container(); // データが null または空の場合は何も表示しない
              } else {
                kagyoList = snapshot.data!;
                isCheckedList =
                    List.generate(kagyoList.length, (index) => false);

                for (int i = 0; i < kagyoList.length; i++) {
                  isCheckedList[i] = kagyoList[i].isDone;
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Slidable(
                        closeOnScroll: true,
                        // Specify a key if the Slidable is dismissible.
                        key: ValueKey(index),

                        // The start action pane is the one at the left or the top side.
                        endActionPane: ActionPane(
                          // A motion is a widget used to control how the pane animates.
                          motion: const DrawerMotion(),

                          // A pane can dismiss the Slidable.
                          dismissible: DismissiblePane(onDismissed: () async{
                            await fireStoreDelete(index);
                            setState(() {});
                          }),

                          // All actions are defined in the children parameter.
                          children: [
                            // A SlidableAction can have an icon and/or a label.
                            SlidableAction(
                              onPressed: (_) async{
                                await fireStoreDelete(index);
                                setState(() {});
                              },
                              backgroundColor: Color(0xFFFE4A49),
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TodoImput(
                                    date: selectedDay, itemIndex: index),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.only(top: 10, bottom: 5),
                            margin: EdgeInsets.only(
                                top: 5, bottom: 5, right: 10, left: 10),
                            decoration: BoxDecoration(
                              color: kagyoList[index].isDone == false
                                  ? Color(0xFFe6e6fa)
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isCheckedList[index],
                                  onChanged: (value) async {
                                    pd.show(msg: "書き込み中...");
                                    await isDoneUpdate(index, !value!);
                                    isCheckedList[index] = !value;
                                    await checkCompleted(selectedDay);
                                    setState(() {});
                                    pd.close();
                                  },
                                ),
                                Text(
                                  kagyoList[index].title,
                                  maxLines: null,
                                  style: TextStyle(
                                      decoration:
                                          kagyoList[index].isDone == true
                                              ? TextDecoration.lineThrough
                                              : null),
                                ),
                              ],
                            ),
                          ),
                        ));
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultSingleDatePickerWithValue() {
    final config = CalendarDatePicker2Config(
      selectedDayHighlightColor: Colors.purple,
      weekdayLabelTextStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      firstDayOfWeek: 1,
      controlsHeight: 50,
      controlsTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      dayTextStyle: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
      disabledDayTextStyle: const TextStyle(
        color: Colors.grey,
      ),
      dayBuilder: (
          {required DateTime date,
          BoxDecoration? decoration,
          bool? isDisabled,
          bool? isSelected,
          bool? isToday,
          TextStyle? textStyle}) {
        final isSpecialDate = specialDates
            .any((specialDate) => DateUtils.isSameDay(date, specialDate));

        final isSelectedDate = isSelected ?? false;
        final isTodayDate = DateUtils.isSameDay(date, dateToday);

        return Container(
          decoration: BoxDecoration(
            color: isSpecialDate
                ? Colors.red
                : isSelectedDate
                    ? Colors.green
                    : null,
            border:
                isTodayDate ? Border.all(color: Colors.blue, width: 2) : null,
            borderRadius: isTodayDate ? BorderRadius.circular(50) : null,
          ),
          child: Center(child: Text(date.day.toString())),
        );
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CalendarDatePicker2(
          config: config,
          value: _singleDatePickerValueWithDefaultValue,
          onValueChanged: (dates) {
            setState(() {
              selectedDay = DateFormat('yyyyMMdd').format(dates.first!);
              _singleDatePickerValueWithDefaultValue = dates;
            });
          },
        ),
      ],
    );
  }
}
