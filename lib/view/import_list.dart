import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kagyo_kanri/view/import_list_imput.dart';
import '../model/kagyo.dart';
import 'package:reorderables/reorderables.dart';
import 'main.dart';

class ImportList extends StatefulWidget {
  const ImportList({Key? key}) : super(key: key);

  @override
  _ImportListState createState() => _ImportListState();
}

class _ImportListState extends State<ImportList> {
  List<Kagyo> kagyoList = [];


  Future<void> firestoreGet() async {
    final firestoreInstance = FirebaseFirestore.instance;

    CollectionReference kagyoAllTarget = firestoreInstance
        .collection("users")
        .doc(account!.userId)
        .collection("kagyoAllTarget");

    for (int i = 0; i < kagyoList.length; i++) {
      QuerySnapshot allTargetSnapshots = await kagyoAllTarget
          .where("title", isEqualTo: kagyoList[i].title)
          .get();

      if (allTargetSnapshots == null || allTargetSnapshots.size == 0) {
        if (kagyoList[i].type == "count") {
          await kagyoAllTarget
              .doc()
              .set({"targetAllCount": kagyoList[i].targetAllCount});
        } else if (kagyoList[i].type == "time") {
          await kagyoAllTarget
              .doc()
              .set({"targetAllCount": kagyoList[i].targetAllTime});
        }


      } else {
        for (QueryDocumentSnapshot doc in allTargetSnapshots.docs) {
          if (kagyoList[i].type == "count") {
            await kagyoAllTarget
                .doc(doc.id)
                .update({"targetAllCount": kagyoList[i].targetAllCount});
          } else if (kagyoList[i].type == "time") {
            await kagyoAllTarget
                .doc(doc.id)
                .update({"targetAllCount": kagyoList[i].targetAllTime});
          }
        }
      }
    }

    CollectionReference kagyoDayTarget = firestoreInstance
        .collection("users")
        .doc(account!.userId)
        .collection("kagyoDayTarget");

    // isDoneがtrueのドキュメントを取得
    QuerySnapshot dayTargetSnapshots =
        await kagyoDayTarget.where("now", isEqualTo: true).get();

    // 取得したドキュメントのisDoneをfalseに更新
    if (dayTargetSnapshots != null || dayTargetSnapshots.size != 0) {
      for (QueryDocumentSnapshot doc in dayTargetSnapshots.docs) {
        await kagyoDayTarget.doc(doc.id).update({"now": false});
      }
    }

    try {
      for (int i = 0; i < kagyoList.length; i++) {
        kagyoDayTarget.doc(kagyoDayTarget.doc().id).set({
          "docId": kagyoDayTarget.doc().id,
          "userId": account.userId,
          "title": kagyoList[i].title,
          "isTime": kagyoList[i].isTime,
          "now": kagyoList[i].now,
          "specifiedTime": kagyoList[i].specifiedTime,
          "targetDayCount": kagyoList[i].targetDayCount,
          "targetAllCount": kagyoList[i].targetAllCount,
          "targetDayTime": kagyoList[i].targetDayTime,
          "targetAllTime": kagyoList[i].targetAllTime,
          "targetDayTimeUnit": kagyoList[i].targetDayTimeUnit,
          "targetAllTimeUnit": kagyoList[i].targetAllTimeUnit,
          "type": kagyoList[i].type,
          "isDone": kagyoList[i].isDone,
          "createdTime": Timestamp.now(),
          "updatedTime": Timestamp.now(),
          "order": i,
          "achieveCount": 0,
          "achieveTime": 0,
        });
      }

      Navigator.of(context).pop();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("新しい加行"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: Icon(Icons.add_box_outlined),
              color: Colors.blue,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ImportListImput(kagyo: null, index: null)),
                );
                if (result != null) {
                  kagyoList.add(result["kagyo"]);
                  setState(() {});
                }
              },
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            ReorderableSliverList(
              delegate: ReorderableSliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ImportListImput(
                                kagyo: kagyoList[index], index: index)),
                      );

                      if (result == null) {
                      } else {
                        final Kagyo kagyo = result["kagyo"];
                        final int itemIndex = result["index"];

                        kagyoList[itemIndex] = kagyo;
                      }
                    },
                    child: Slidable(
                      closeOnScroll: true,
                      // Specify a key if the Slidable is dismissible.
                      key: ValueKey(index),

                      // The start action pane is the one at the left or the top side.
                      endActionPane: ActionPane(
                        // A motion is a widget used to control how the pane animates.
                        motion: const DrawerMotion(),

                        // A pane can dismiss the Slidable.
                        dismissible: DismissiblePane(onDismissed: () {
                          kagyoList.removeAt(index);
                          setState(() {});
                        }),

                        // All actions are defined in the children parameter.
                        children: [
                          // A SlidableAction can have an icon and/or a label.
                          SlidableAction(
                            onPressed: (_) {
                              kagyoList.removeAt(index);
                              setState(() {});
                            },
                            backgroundColor: Color(0xFFFE4A49),
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: Container(
                        margin: EdgeInsets.only(top: 10, left: 10, right: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(0xFFe6e6fa),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                kagyoList[index].title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: true, // 自動で改行する
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              child: Icon(Icons.reorder),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: kagyoList.length,
              ),
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  final Kagyo item = kagyoList.removeAt(oldIndex);
                  kagyoList.insert(newIndex, item);
                });
              },
            ),
          ],
        ),
        bottomNavigationBar: ElevatedButton(
          onPressed: () async {
            await firestoreGet();
          },
          child: Text("新しい加行として設定する"),
        ),
      ),
    );
  }
}

void doNothing(BuildContext context) {}
