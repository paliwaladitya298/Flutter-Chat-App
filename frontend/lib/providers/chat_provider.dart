import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/network/socket_service.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';

class ChatProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SocketService _socketService = SocketService();

  List<Chat> _chats = [];
  List<Message> _messages = [];
  Chat? _activeChat;
  bool _isLoadingChats = false;
  bool _isLoadingMessages = false;
  
  // Track typing states: chatId -> isTyping
  final Map<String, bool> _typingStates = {};
  
  // Track unread counts: chatId -> unreadCount
  final Map<String, int> _unreadCounts = {};

  List<Chat> get chats => _chats;
  List<Message> get messages => _messages;
  Chat? get activeChat => _activeChat;
  bool get isLoadingChats => _isLoadingChats;
  bool get isLoadingMessages => _isLoadingMessages;
  Map<String, bool> get typingStates => _typingStates;
  Map<String, int> get unreadCounts => _unreadCounts;

  // Initialize socket event handlers for chatting
  void initSocketListeners(String currentUserId) {
    _socketService.onMessageReceived((data) {
      log('Incoming socket message received: ${data['_id']}');
      final message = Message.fromJson(data);
      
      // Update chat list position and lastMessage reference
      _updateChatListWithNewMessage(message);

      // If this message belongs to the active chat screen
      if (_activeChat != null && message.chatId == _activeChat!.id) {
        // Exclude duplicates
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
          
          // If we received it from the other user, mark it as read immediately
          if (message.sender.id != currentUserId) {
            _socketService.readMessage(message.chatId, message.id, currentUserId);
            // Run a background request to sync db read receipt
            _apiClient.get('/messages/${message.chatId}');
          }
        }
      } else {
        // Message is for another chat: increment unread count
        if (message.sender.id != currentUserId) {
          _unreadCounts[message.chatId] = (_unreadCounts[message.chatId] ?? 0) + 1;
        }
      }
      notifyListeners();
    });

    _socketService.onTyping((chatId) {
      _typingStates[chatId] = true;
      notifyListeners();
    });

    _socketService.onStopTyping((chatId) {
      _typingStates[chatId] = false;
      notifyListeners();
    });

    _socketService.onMessagesMarkedRead((data) {
      final chatId = data['chatId'] as String;
      final readerId = data['readBy'] as String;
      
      if (_activeChat != null && _activeChat!.id == chatId) {
        // Update all our sent messages in this active chat to isRead = true
        _messages = _messages.map((m) {
          if (m.sender.id != readerId) {
            // This is a message sent by current user, marked read by recipient
            return Message(
              id: m.id,
              chatId: m.chatId,
              sender: m.sender,
              text: m.text,
              imageUrl: m.imageUrl,
              type: m.type,
              isRead: true,
              readBy: [...m.readBy, readerId],
              createdAt: m.createdAt,
            );
          }
          return m;
        }).toList();
        notifyListeners();
      }
    });
  }

  // Set active chat and fetch historical messages
  void setActiveChat(Chat? chat, String currentUserId) {
    _activeChat = chat;
    if (chat != null) {
      _unreadCounts[chat.id] = 0; // Clear unread counts for active chat
      _socketService.joinChat(chat.id);
      fetchMessages(chat.id);
    } else {
      _messages.clear();
    }
    notifyListeners();
  }

  // Fetch all chats
  Future<void> fetchChats() async {
    _isLoadingChats = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/chats');
      if (response.statusCode == 200) {
        final List chatsData = jsonDecode(response.body);
        _chats = chatsData.map((e) => Chat.fromJson(e)).toList();
      }
    } catch (e) {
      log('Fetch chats error: $e');
    } finally {
      _isLoadingChats = false;
      notifyListeners();
    }
  }

  // Fetch messages for active chat
  Future<void> fetchMessages(String chatId) async {
    _isLoadingMessages = true;
    _messages.clear();
    notifyListeners();

    try {
      final response = await _apiClient.get('/messages/$chatId');
      if (response.statusCode == 200) {
        final List messagesData = jsonDecode(response.body);
        _messages = messagesData.map((e) => Message.fromJson(e)).toList();
      }
    } catch (e) {
      log('Fetch messages error: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // Create or get conversation with another user
  Future<Chat?> startChat(String userId) async {
    try {
      final response = await _apiClient.post('/chats', {'userId': userId});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final chat = Chat.fromJson(jsonDecode(response.body));
        
        // Add to chat list if not already there
        if (!_chats.any((c) => c.id == chat.id)) {
          _chats.insert(0, chat);
        }
        return chat;
      }
    } catch (e) {
      log('Start chat error: $e');
    }
    return null;
  }

  // Send message API
  Future<bool> sendMessage(String chatId, String text, {String imageUrl = '', String type = 'text'}) async {
    try {
      final response = await _apiClient.post('/messages', {
        'chatId': chatId,
        'text': text,
        'imageUrl': imageUrl,
        'type': type,
      });

      if (response.statusCode == 201) {
        final message = Message.fromJson(jsonDecode(response.body));
        
        // Exclude duplicate (already populated via socket fallback)
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
        }
        
        _updateChatListWithNewMessage(message);
        notifyListeners();
        return true;
      }
    } catch (e) {
      log('Send message error: $e');
    }
    return false;
  }

  // Upload image to Cloudinary (or local fallback) and send message
  Future<bool> sendImageMessage(String chatId, File imageFile) async {
    try {
      final uploadResponse = await _apiClient.uploadFile('/messages/upload', imageFile);
      if (uploadResponse.statusCode == 200) {
        final urlData = jsonDecode(uploadResponse.body);
        final imageUrl = urlData['imageUrl'] as String;
        
        // Cloudinary returns full secure URL, fallback returns local path like `/uploads/123.jpg`
        // If it's a local fallback, append baseUrl so Flutter can read it
        final fullImageUrl = imageUrl.startsWith('/') 
            ? '${AppConstants.baseUrl}$imageUrl' 
            : imageUrl;

        return await sendMessage(chatId, '', imageUrl: fullImageUrl, type: 'image');
      }
    } catch (e) {
      log('Upload image and send message error: $e');
    }
    return false;
  }

  // Emit typing indicator to socket
  void setTypingStatus(String chatId, bool isTyping) {
    if (isTyping) {
      _socketService.emitTyping(chatId);
    } else {
      _socketService.emitStopTyping(chatId);
    }
  }

  // Helper method: update chat list and push chat to top when new message arrives
  void _updateChatListWithNewMessage(Message message) {
    final chatIndex = _chats.indexWhere((c) => c.id == message.chatId);
    
    if (chatIndex != -1) {
      final existingChat = _chats[chatIndex];
      final updatedChat = Chat(
        id: existingChat.id,
        participants: existingChat.participants,
        isGroup: existingChat.isGroup,
        lastMessage: message,
      );
      
      _chats.removeAt(chatIndex);
      _chats.insert(0, updatedChat); // Move to top
    } else {
      // If the chat object is not in cache, fetch all chats to refresh
      fetchChats();
    }
  }

  // Search users API helper
  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await _apiClient.get('/users?search=$query');
      if (response.statusCode == 200) {
        final List usersData = jsonDecode(response.body);
        return usersData.map((e) => User.fromJson(e)).toList();
      }
    } catch (e) {
      log('Search users error: $e');
    }
    return [];
  }

  // Clear state on logout
  void clearState() {
    _chats.clear();
    _messages.clear();
    _activeChat = null;
    _typingStates.clear();
    _unreadCounts.clear();
  }
}
