import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/socket_provider.dart';
import '../../models/user.dart';
import '../../core/constants/constants.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final User partner;

  const ChatScreen({super.key, required this.partner});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _imagePicker = ImagePicker();
  
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Scroll to bottom when messages are loaded/updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    // If active chat is being closed, reset active chat in state
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final activeChat = chatProvider.activeChat;
    if (activeChat != null) {
      chatProvider.setTypingStatus(activeChat.id, false);
      chatProvider.setActiveChat(null, '');
    }
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTextChanged(String text) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final activeChat = chatProvider.activeChat;
    if (activeChat == null) return;

    if (!_isTyping && text.trim().isNotEmpty) {
      _isTyping = true;
      chatProvider.setTypingStatus(activeChat.id, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        chatProvider.setTypingStatus(activeChat.id, false);
      }
    });
  }

  void _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final activeChat = chatProvider.activeChat;
    if (activeChat == null) return;

    _messageCtrl.clear();
    
    if (_isTyping) {
      _isTyping = false;
      chatProvider.setTypingStatus(activeChat.id, false);
    }
    _typingTimer?.cancel();

    final success = await chatProvider.sendMessage(activeChat.id, text);
    if (success) {
      _scrollToBottom();
    }
  }

  void _pickAndSendImage() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final activeChat = chatProvider.activeChat;
    if (activeChat == null) return;

    // Show source options sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () => _pickImage(ImageSource.gallery, activeChat.id),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => _pickImage(ImageSource.camera, activeChat.id),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickImage(ImageSource source, String chatId) async {
    Navigator.of(context).pop(); // Dismiss bottom sheet
    
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1200,
      );

      if (pickedFile == null) return;

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      // Show local loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(width: 16),
                Text('Uploading image...'),
              ],
            ),
            duration: Duration(days: 1), // Keeps it open until completed/failed
          ),
        );
      }

      final success = await chatProvider.sendImageMessage(chatId, File(pickedFile.path));
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (success) {
          _scrollToBottom();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error choosing image: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().currentUser?.id ?? '';
    final chatProvider = context.watch<ChatProvider>();
    final socketProvider = context.watch<SocketProvider>();
    
    final activeChat = chatProvider.activeChat;
    
    // Read dynamic states from Provider
    final isOnline = socketProvider.isUserOnline(widget.partner.id, widget.partner.isOnline);
    final lastSeen = socketProvider.getUserLastSeen(widget.partner.id, widget.partner.lastSeen);
    final isPartnerTyping = activeChat != null && chatProvider.typingStates[activeChat.id] == true;

    // Trigger scroll to bottom on new message
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.partner.avatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(widget.partner.avatarUrl)
                  : null,
              child: widget.partner.avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partner.username,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPartnerTyping
                        ? 'typing...'
                        : (isOnline
                            ? 'online'
                            : 'last seen ${DateFormat('hh:mm a').format(lastSeen)}'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isPartnerTyping
                          ? Colors.green
                          : (isOnline ? Colors.green : Colors.grey),
                      fontWeight: isOnline || isPartnerTyping ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          // Subtle chat wallpaper effect
          color: Theme.of(context).brightness == Brightness.dark
              ? AppConstants.backgroundColorDark
              : AppConstants.backgroundColorLight,
        ),
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: chatProvider.isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : chatProvider.messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                'Say hello to ${widget.partner.username}!',
                                style: const TextStyle(color: Colors.grey),
                              )
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          itemCount: chatProvider.messages.length,
                          itemBuilder: (context, index) {
                            final message = chatProvider.messages[index];
                            return MessageBubble(
                              message: message,
                              isMe: message.sender.id == currentUserId,
                            );
                          },
                        ),
            ),
            
            // Subtle indicator if partner is typing
            if (isPartnerTyping)
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  '${widget.partner.username} is typing...',
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.green, fontSize: 13),
                ),
              ),

            // Input Row
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 1,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file, color: Colors.grey),
                            onPressed: _pickAndSendImage,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                              ),
                              onChanged: _onTextChanged,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppConstants.primaryColorLight,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
