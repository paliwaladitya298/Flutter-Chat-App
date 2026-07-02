import 'user.dart';
import 'message.dart';

class Chat {
  final String id;
  final List<User> participants;
  final bool isGroup;
  final Message? lastMessage;

  Chat({
    required this.id,
    required this.participants,
    required this.isGroup,
    this.lastMessage,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['_id'] ?? '',
      participants: (json['participants'] as List?)
              ?.map((e) => User.fromJson(e))
              .toList() ??
          [],
      isGroup: json['isGroup'] ?? false,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'participants': participants.map((e) => e.toJson()).toList(),
      'isGroup': isGroup,
      'lastMessage': lastMessage?.toJson(),
    };
  }

  // Helper: Get the other participant in a 1-to-1 chat
  User getChatPartner(String currentUserId) {
    return participants.firstWhere(
      (user) => user.id != currentUserId,
      orElse: () => User(
        id: '',
        username: 'Unknown User',
        email: '',
        avatarUrl: '',
        isOnline: false,
        lastSeen: DateTime.now(),
      ),
    );
  }
}
