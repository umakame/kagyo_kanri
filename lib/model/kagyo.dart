import 'package:cloud_firestore/cloud_firestore.dart';

class Kagyo {
  String? docId;
  String userId;
  String title;
  bool isTime;
  bool now;
  String? specifiedTime;
  int? targetDayCount;
  int? targetAllCount;
  int? targetDayTime;
  int? targetAllTime;
  int? achieveCount;
  int? achieveTime;
  String? targetDayTimeUnit;
  String? targetAllTimeUnit;
  String type;
  bool isDone;
  Timestamp createdTime;
  Timestamp updatedTime;
  int? order;

  Kagyo(
      {this.docId,
        required this.userId,
      required this.title,
        required this.isTime,
      required this.now,
      this.specifiedTime,
      this.targetDayCount,
      this.targetDayTime,
      this.targetAllCount,
      this.targetAllTime,
        this.achieveCount,
        this.achieveTime,
        this.targetDayTimeUnit,
        this.targetAllTimeUnit,
      required this.type,
      required this.isDone,
      required this.createdTime,
      required this.updatedTime,
      this.order,
      });

  factory Kagyo.fromMap(Map<String, dynamic> data) {
    return Kagyo(
      docId:data["docId"],
        userId: data['userId'],
        title: data['title'],
        isTime:data["isTime"],
        now: data['now'],
        specifiedTime:data["specifiedTime"],
        targetDayCount:data["targetDayCount"],
        targetAllCount:data["targetAllCount"],
        targetDayTime:data["targetDayTime"],
        targetAllTime:data["targetAllTime"],
        targetDayTimeUnit:data["targetDayTimeUnit"],
        targetAllTimeUnit:data["targetAllTimeUnit"],
        isDone: data['isDone'],
        type:data["type"],
        createdTime: data['createdTime'],
        updatedTime: data['updatedTime'],
    order: data["order"],
    achieveCount: data["achieveCount"],
    achieveTime: data["achieveTime"]);
  }
}
