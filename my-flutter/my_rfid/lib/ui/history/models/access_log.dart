class AccessLog {
  final String cardId;
  final String cardName;
  final String time;
  final String type; // 'Entry' or 'Exit'
  final String location;

  AccessLog({
    required this.cardId,
    required this.cardName,
    required this.time,
    required this.type,
    required this.location,
  });
}