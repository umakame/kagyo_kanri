import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kagyo_kanri/model/kagyo.dart';
import 'package:kagyo_kanri/main.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import '../model/function.dart';
import 'todo_imput.dart';

//todo 日付が変わる瞬間に再読込するようにする

class Todo extends StatefulWidget {
  const Todo({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Todo> {
  bool isChecked = false;
  List<bool> isCheckedList = [];
  List<Kagyo> kagyoList = [];

  Stream<List<Kagyo>> _fetchKagyosStream() {
    final firestore = FirebaseFirestore.instance;
    final stream = firestore
        .collection('users')
        .doc(account!.userId)
        .collection("kagyoLog")
        .doc(today())
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
        .doc(today())
        .collection("log");

    // ドキュメントの取得
    QuerySnapshot querySnapshot = await kagyosCollection
        .where('now', isEqualTo: true)
        .orderBy("order")
        .get();

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

  @override
  void initState() {
    super.initState();

    Future(() async {
      await checkTodo();
    });
  }

  @override
  Widget build(BuildContext context) {
    ProgressDialog pd = ProgressDialog(context: context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("今日の加行"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          key: PageStorageKey(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                convertDateString(today()),
                style: TextStyle(fontSize: 20),
              ),
              Container(
                child: StreamBuilder<List<Kagyo>>(
                  stream: _fetchKagyosStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('エラーが発生しました'); // エラー時の表示
                    } else if (snapshot.data == null ||
                        snapshot.data!.isEmpty) {
                      return Container(
                        height: MediaQuery.of(context).size.height, // 薄暗い背景
                        child: Center(
                          child: CircularProgressIndicator(), // サークルインジケーター
                        ),
                      ); // データが null または空の場合は何も表示しない
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
                                      date: today(), title: kagyoList[index].title),
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
                                      await checkCompleted(today());
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
            ],
          ),
        ),
      ),
    );
  }
}
