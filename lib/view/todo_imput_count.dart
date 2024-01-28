import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/function.dart';
import 'main.dart';

class TodoImputCount extends StatefulWidget {
  const TodoImputCount({Key? key,required this.date, required this.itemIndex}) : super(key: key);

  final String date;
  final int itemIndex;

  @override
  _TodoImputCountState createState() => _TodoImputCountState();
}

class _TodoImputCountState extends State<TodoImputCount> {
  int count = 0;

  Future<void> firebaseUpdate() async {
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
        Map<String, dynamic> updatedData = {
          'achieveCount': querySnapshot.docs.first['achieveCount'] + count
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
          title: Text('確認'),
          content: Text('カウントをリセットしてもよろしいですか？'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                count = 0;
                setState(() {});
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
          title: Text('確認'),
          content: Text('計測したカウントを追加してもよろしいですか？'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                await firebaseUpdate();
                count = 0; // カウントをリセット
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
            count++;
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
                          top: 20,
                          left: 30,
                          right: 0,
                          child: Container(
                            width: 360,
                            height: 360,
                            child: Image.asset('assets/images/counter.png'),
                          ),
                        ),
                        Positioned(
                          right: 115,
                          top: 180,
                          child: Text(count.toString(),
                              style:
                                  TextStyle(fontSize: 50, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
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
                          ElevatedButton(
                            onPressed: () {
                              if (count > 0) {
                                count--;
                              }
                              setState(() {});
                            },
                            child: Text("-1"),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await _showRegisterDialog();
                          await checkCompleted(widget.date);
                          print(widget.date);
                        },
                        child: Text("追加する"),
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
