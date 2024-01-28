import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:kagyo_kanri/model/date_competeted.dart';
import 'package:kagyo_kanri/view/todo_imput.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import '../model/kagyo.dart';
import 'main.dart';
import '../model/function.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: '全体'),
                  Tab(text: '日付別'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    buildChart(),
                    _buildTabContent(1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarTouchData get barTouchData => BarTouchData(
        enabled: false,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.transparent,
          tooltipPadding: EdgeInsets.zero,
          tooltipMargin: 8,
          getTooltipItem: (
            BarChartGroupData group,
            int groupIndex,
            BarChartRodData rod,
            int rodIndex,
          ) {
            return BarTooltipItem(
              rod.toY.round().toString(),
              const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      );

  Widget getTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.lime,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'あああああああああああああああああ';
        break;
      case 1:
        text = 'Te';
        break;
      case 2:
        text = 'Wd';
        break;
      case 3:
        text = 'Tu';
        break;
      case 4:
        text = 'Fr';
        break;
      case 5:
        text = 'St';
        break;
      case 6:
        text = 'Sn';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }

  FlTitlesData get titlesData => FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: getTitles,
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      );

  FlBorderData get borderData => FlBorderData(
        show: false,
      );

  LinearGradient get _barsGradient => LinearGradient(
        colors: [
          Colors.green,
          Colors.redAccent,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  List<BarChartGroupData> get barGroups => [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: 8,
              gradient: _barsGradient,
            )
          ],
          showingTooltipIndicators: [0],
        ),
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: 10,
              gradient: _barsGradient,
            )
          ],
          showingTooltipIndicators: [0],
        ),
        BarChartGroupData(
          x: 2,
          barRods: [
            BarChartRodData(
              toY: 14,
              gradient: _barsGradient,
            )
          ],
          showingTooltipIndicators: [0],
        ),
        BarChartGroupData(
          x: 3,
          barRods: [
            BarChartRodData(
              toY: 15,
              gradient: _barsGradient,
            )
          ],
          showingTooltipIndicators: [0],
        ),
        BarChartGroupData(
          x: 4,
          barRods: [
            BarChartRodData(
              toY: 13,
              gradient: _barsGradient,
            )
          ],
          showingTooltipIndicators: [0],
        ),
        BarChartGroupData(
          x: 5,
          barRods: [
            BarChartRodData(
              toY: 10,
              gradient: _barsGradient,
            )
          ],
          showingTooltipIndicators: [0],
        ),
        BarChartGroupData(
          x: 6,
          barRods: [
            BarChartRodData(
              toY: 16,
              gradient: _barsGradient,
            )
          ],
          showingTooltipIndicators: [0],
        ),
      ];

  Widget buildChart() {
    return SingleChildScrollView(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: BarChart(
          BarChartData(
            barTouchData: barTouchData,
            titlesData: titlesData,
            borderData: borderData,
            barGroups: barGroups,
            gridData: const FlGridData(show: false),
            alignment: BarChartAlignment.spaceAround,
            maxY: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(int tabIndex) {
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
