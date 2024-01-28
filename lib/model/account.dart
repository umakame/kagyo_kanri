import 'package:cloud_firestore/cloud_firestore.dart';

class Account {
  String userId;

  Timestamp? createdTime;
  Timestamp? updatedTime;

  Account(
      {required this.userId,
      this.createdTime,
      this.updatedTime});
}
