import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../db/chat_db.dart';


class ChatController extends ChangeNotifier {
  List<MessageModel> messages = [];
  Future<void> loadMessages() async {
  messages = await ChatDB.getMessages();
  notifyListeners();
}
  void addUserMessage(String text) {
    messages.add(
      MessageModel(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addAIMessage(String text) {
    messages.add(
      MessageModel(
        text: text,
        isUser: false,
        time: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}