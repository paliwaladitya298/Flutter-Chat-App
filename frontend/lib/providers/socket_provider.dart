import 'package:flutter/material.dart';
import '../core/network/socket_service.dart';

class SocketProvider extends ChangeNotifier {
  final SocketService _socketService = SocketService();
  final Map<String, bool> _onlineStatusMap = {};
  final Map<String, DateTime> _lastSeenMap = {};

  bool get isConnected => _socketService.isConnected;
  Map<String, bool> get onlineStatusMap => _onlineStatusMap;
  Map<String, DateTime> get lastSeenMap => _lastSeenMap;

  // Initialize socket connection
  void connectSocket(String userId, String username) {
    _socketService.init(userId, username);
    
    // Set up listeners
    _socketService.onUserStatusChange((data) {
      if (data != null && data['userId'] != null) {
        final userId = data['userId'] as String;
        final isOnline = data['isOnline'] as bool;
        final lastSeenStr = data['lastSeen'] as String?;
        
        _onlineStatusMap[userId] = isOnline;
        if (lastSeenStr != null) {
          _lastSeenMap[userId] = DateTime.parse(lastSeenStr);
        }
        notifyListeners();
      }
    });

    notifyListeners();
  }

  // Check user online status
  bool isUserOnline(String userId, bool dbFallbackValue) {
    return _onlineStatusMap[userId] ?? dbFallbackValue;
  }

  // Check user last seen
  DateTime getUserLastSeen(String userId, DateTime dbFallbackValue) {
    return _lastSeenMap[userId] ?? dbFallbackValue;
  }

  // Disconnect
  void disconnectSocket() {
    _socketService.disconnect();
    _onlineStatusMap.clear();
    _lastSeenMap.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    disconnectSocket();
    super.dispose();
  }
}
