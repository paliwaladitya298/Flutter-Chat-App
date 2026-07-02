import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  bool isConnected = false;

  // Initialize socket connection
  void init(String userId, String username) {
    if (socket != null && socket!.connected) {
      log('Socket already connected');
      return;
    }

    try {
      socket = IO.io(AppConstants.socketUrl, IO.OptionBuilder()
        .setTransports(['websocket']) // Use websocket transport
        .disableAutoConnect()
        .build());

      socket!.connect();

      socket!.onConnect((_) {
        isConnected = true;
        log('Socket connected successfully');
        // Emit setup event immediately
        socket!.emit('setup', {'_id': userId, 'username': username});
      });

      socket!.onDisconnect((_) {
        isConnected = false;
        log('Socket disconnected');
      });

      socket!.onConnectError((data) => log('Socket Connect Error: $data'));
      socket!.onError((data) => log('Socket Error: $data'));

    } catch (e) {
      log('Socket initialization error: $e');
    }
  }

  // Join a specific chat room
  void joinChat(String chatId) {
    if (socket != null && isConnected) {
      socket!.emit('join_chat', chatId);
      log('Joined chat room: $chatId');
    }
  }

  // Emit typing status
  void emitTyping(String chatId) {
    if (socket != null && isConnected) {
      socket!.emit('typing', chatId);
    }
  }

  void emitStopTyping(String chatId) {
    if (socket != null && isConnected) {
      socket!.emit('stop_typing', chatId);
    }
  }

  // Listen to typing status
  void onTyping(Function(String chatId) callback) {
    socket?.on('typing', (chatId) => callback(chatId));
  }

  void onStopTyping(Function(String chatId) callback) {
    socket?.on('stop_typing', (chatId) => callback(chatId));
  }

  // Listen for new incoming messages
  void onMessageReceived(Function(dynamic message) callback) {
    socket?.on('message_received', (data) => callback(data));
  }

  // Listen for user online/offline status updates
  void onUserStatusChange(Function(dynamic data) callback) {
    socket?.on('user_status_change', (data) => callback(data));
  }

  // Listen for read receipts
  void onMessagesMarkedRead(Function(dynamic data) callback) {
    socket?.on('messages_marked_read', (data) => callback(data));
  }

  // Read message check
  void readMessage(String chatId, String messageId, String readerId) {
    if (socket != null && isConnected) {
      socket!.emit('read_message', {
        'chatId': chatId,
        'messageId': messageId,
        'readerId': readerId,
      });
    }
  }

  // Disconnect socket
  void disconnect() {
    if (socket != null) {
      socket!.disconnect();
      socket = null;
      isConnected = false;
      log('Socket manual disconnect');
    }
  }
}
