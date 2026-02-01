class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();
}

class DailyVibe {
  final int energyScore;
  final Outfit ootd;
  final String advice;

  DailyVibe({
    required this.energyScore,
    required this.ootd,
    required this.advice,
  });
}

class Outfit {
  final String color;
  final String style;
  final String emoji;

  Outfit({
    required this.color,
    required this.style,
    required this.emoji,
  });
}
