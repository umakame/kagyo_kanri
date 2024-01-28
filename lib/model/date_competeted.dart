class CompletedDate {
  String date;
  bool completed;

  CompletedDate({
    required this.date,
    required this.completed,
  });

  factory CompletedDate.fromMap(Map<String, dynamic> data) {
    return CompletedDate(date: data["date"], completed: data['completed']);
  }
}
