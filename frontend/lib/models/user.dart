class User {
  final String id;
  final String username;
  final String email;
  final String avatarUrl;
  final bool isOnline;
  final DateTime lastSeen;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.isOnline,
    required this.lastSeen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
