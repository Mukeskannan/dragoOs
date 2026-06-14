import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final Color accentColor;
  final DateTime time; // 👈 ADD THIS

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.accentColor,
    required this.time, // 👈 ADD THIS
  });

  String formatTime(DateTime t) {
    return DateFormat('hh:mm a').format(t);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? accentColor.withOpacity(0.65)
              : const Color(0xFF1C1C1E).withOpacity(0.65),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: Border.all(
            color: isUser
                ? accentColor.withOpacity(0.6)
                : Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 4),

            // 👇 TIME TEXT
            Text(
              formatTime(time),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}