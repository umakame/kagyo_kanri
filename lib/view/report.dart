import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:kagyo_kanri/model/date_competeted.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import '../model/kagyo.dart';
import '../main.dart';
import '../model/function.dart';
import 'package:intl/intl.dart';

final dateToday = DateUtils.dateOnly(DateTime.now());

class Report extends StatefulWidget {
  const Report({Key? key}) : super(key: key);

  @override
  _ReportState createState() => _ReportState();
}

class _ReportState extends State<Report> {
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

  Future<void> checkTodo() async {
    final firestore = FirebaseFirestore.instance;

    // クエリを作成
    final query = firestore
        .collection('users')
        .doc(account!.userId)
        .collection("kagyoLog");

    QuerySnapshot snapshot =
        await query.where("date", isEqualTo: today()).get();

    // ドキュメントが存在しない場合
    if (snapshot.size == 0) {
      final kagyoLog = firestore
          .collection('users')
          .doc(account!.userId)
          .collection("kagyoLog");

      final kagyoDayTarget = firestore
          .collection("users")
          .doc(account!.userId)
          .collection("kagyoDayTarget");

      // isDoneがtrueのドキュメントを取得
      QuerySnapshot dayTargetSnapshots =
          await kagyoDayTarget.where("now", isEqualTo: true).get();

      // 新しいドキュメントを作成
      DocumentReference kagyoLogDoc = kagyoLog.doc(today());

      // dayTargetSnapshotsの各ドキュメントをkagyoLogDocに追加
      for (QueryDocumentSnapshot doc in dayTargetSnapshots.docs) {
        // doc.data() の返り値は Map<String, dynamic>? (null許容型)
        Map<String, dynamic>? docData = doc.data() as Map<String, dynamic>?;

        if (docData != null) {
          // nullでないことを確認した上で追加
          kagyoLogDoc.collection("log").add(docData);
          // もしサブコレクションがない場合は、直接kagyoLogDocに追加することもできます
          // kagyoLogDoc.set(docData, SetOptions(merge: true));
        }
      }

      // "date" パラメータを追加
      kagyoLogDoc
          .set({"date": today(), "completed": false}, SetOptions(merge: true));
    }
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text("レポート"),
        ),
        body: Column(
          children: [],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    ProgressDialog pd = ProgressDialog(context: context);
    return SingleChildScrollView(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
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
            Text(
              convertDateString(selectedDay),
              style: TextStyle(fontSize: 20),
            ),
            Expanded(
              child: Container(
                child: StreamBuilder<List<Kagyo>>(
                  stream: _fetchKagyosStream(selectedDay),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('エラーが発生しました'); // エラー時の表示
                    } else if (snapshot.data == null ||
                        snapshot.data!.isEmpty) {
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
                          return InkWell(
                            onTap: () {},
                            child: Container(),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
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
