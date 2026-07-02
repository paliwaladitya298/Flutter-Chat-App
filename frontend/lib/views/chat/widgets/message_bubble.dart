import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/message.dart';
import '../../../core/constants/constants.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Choose bubble background color
    final bubbleColor = isMe
        ? (isDark ? AppConstants.bubbleSentDark : AppConstants.bubbleSentLight)
        : (isDark ? AppConstants.bubbleReceivedDark : AppConstants.bubbleReceivedLight);

    // Choose text color
    final textColor = isMe
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.white : Colors.black87);

    final timeColor = isDark ? Colors.white60 : Colors.black54;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft: isMe ? const Radius.circular(16.0) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 1),
            )
          ]
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display Content
              if (message.type == 'image') ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrl,
                    placeholder: (context, url) => Container(
                      width: 200,
                      height: 200,
                      color: Colors.black12,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 200,
                      height: 200,
                      color: Colors.black12,
                      child: const Icon(Icons.error_outline, color: Colors.redAccent),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 4),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    message.text,
                    style: TextStyle(color: textColor, fontSize: 16.0),
                  ),
                ),
              ],
              
              // Timestamp + Read receipts row
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(message.createdAt),
                    style: TextStyle(color: timeColor, fontSize: 10.0),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4.0),
                    Icon(
                      Icons.done_all,
                      size: 14.0,
                      color: message.isRead ? Colors.blue : Colors.grey,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
