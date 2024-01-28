import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../view/main.dart';

String today() {
  DateTime now = DateTime.now();

  // フォーマットして文字列に変換
  String formattedDate =
      "${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}";

  return formattedDate;
}

String _twoDigits(int n) {
  if (n >= 10) {
    return "$n";
  } else {
    return "0$n";
  }
}

String convertDateString(String dateString) {
  // "yyyymmdd"形式の日付をDateTimeに変換
  DateTime date = DateTime.parse(dateString.substring(0, 8));

  // 日付を"yyyy年mm月dd日"形式にフォーマット
  String formattedDate = DateFormat('yyyy年MM月dd日').format(date);

  return formattedDate;
}

Future<void> checkCompleted(String date) async {
  CollectionReference kagyosCollection = FirebaseFirestore.instance
      .collection('users')
      .doc(account.userId)
      .collection("kagyoLog")
      .doc(today())
      .collection("log");

  // ドキュメントの取得
  QuerySnapshot querySnapshotCount =
      await kagyosCollection.where('now', isEqualTo: true).get();

  QuerySnapshot querySnapshotIsDone = await kagyosCollection
      .where('isDone', isEqualTo: true)
      .where("now", isEqualTo: true)
      .get();


  if (querySnapshotCount.size == querySnapshotIsDone.size) {
    CollectionReference docCompleted = FirebaseFirestore.instance
        .collection('users')
        .doc(account.userId)
        .collection("kagyoLog");

    QuerySnapshot querySnapshotIsDone =
        await docCompleted.where('date', isEqualTo: date).get();

    print(querySnapshotIsDone.size);

    Map<String, dynamic> data =
        querySnapshotIsDone.docs[0].data() as Map<String, dynamic>;

    data["completed"] = true;

    await docCompleted.doc(today()).update(data);
  } else {
    CollectionReference docCompleted = FirebaseFirestore.instance
        .collection('users')
        .doc(account.userId)
        .collection("kagyoLog");

    QuerySnapshot querySnapshotIsDone = await docCompleted
        .where('date', isEqualTo: date)
        .where("completed", isEqualTo: true)
        .get();

    if (querySnapshotIsDone.size > 0) {
      Map<String, dynamic> data =
          querySnapshotIsDone.docs[0].data() as Map<String, dynamic>;

      data["completed"] = false;

      await docCompleted.doc(today()).update(data);
    }
  }
}
