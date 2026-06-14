import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/dragon_widget.dart';
import '../widgets/message_input.dart';
import '../db/chat_db.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool isDragoMode = false;
  bool isLoading = false;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<MessageModel> messages = [];

  Color get accentColor => isDragoMode ? Colors.redAccent : Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  // ✅ LOAD FROM SQLITE ON START
  Future<void> _loadMessages() async {
    final data = await ChatDB.getMessages();

    setState(() {
      messages.clear();
      messages.addAll(data);
    });

    _scrollToBottom();
  }

  void _toggleMode() {
    setState(() {
      isDragoMode = !isDragoMode;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ✅ SEND MESSAGE + SAVE TO SQLITE
  Future<void> _handleSend() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    final userMsg = MessageModel(
      text: userInput,
      isUser: true,
      time: DateTime.now(),
    );

    setState(() {
      messages.add(userMsg);
      isLoading = true;
    });

    await ChatDB.insertMessage(userMsg);

    _controller.clear();
    _scrollToBottom();

    final reply = await ApiService.sendMessage(userInput);

    final aiMsg = MessageModel(
      text: reply,
      isUser: false,
      time: DateTime.now(),
    );

    setState(() {
      messages.add(aiMsg);
      isLoading = false;
    });

    await ChatDB.insertMessage(aiMsg);

    _scrollToBottom();
  }

  void _handleMicTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Voice input coming soon"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // 🔥 Background dragon (UNCHANGED UI)
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: DragonWidget(
                  isDragoMode: isDragoMode,
                  size: 300,
                  opacity: 0.90,
                ),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 10),

                // 🔥 Mode toggle (UNCHANGED UI)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _toggleMode,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withOpacity(0.15),
                            border: Border.all(color: accentColor, width: 1.5),
                          ),
                          child: Icon(
                            isDragoMode
                                ? Icons.local_fire_department
                                : Icons.auto_awesome,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 🔥 Chat list (FIXED)
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && isLoading) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(
                              "Drago is thinking...",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        );
                      }

                      final msg = messages[index];

                      return ChatBubble(
                        message: msg.text,
                        isUser: msg.isUser,
                        accentColor: accentColor,
                        time: msg.time,
                      );
                    },
                  ),
                ),

                // 🔥 Input (UNCHANGED UI)
                MessageInput(
                  controller: _controller,
                  onSend: _handleSend,
                  onMicTap: _handleMicTap,
                  accentColor: accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}