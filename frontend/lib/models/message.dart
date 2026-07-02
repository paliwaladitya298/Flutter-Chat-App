import 'user.dart';

class Message {
  final String id;
  final String chatId;
  final User sender;
  final String text;
  final String imageUrl;
  final String type; // 'text' or 'image'
  final bool isRead;
  final List<String> readBy;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.text,
    required this.imageUrl,
    required this.type,
    required this.isRead,
    required this.readBy,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      chatId: json['chatId'] is Map 
          ? (json['chatId']['_id'] ?? '') 
          : (json['chatId'] ?? ''),
      sender: User.fromJson(json['sender'] ?? {}),
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: json['type'] ?? 'text',
      isRead: json['isRead'] ?? false,
      readBy: (json['readBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'chatId': chatId,
      'sender': sender.toJson(),
      'text': text,
      'imageUrl': imageUrl,
      'type': type,
      'isRead': isRead,
      'readBy': readBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
