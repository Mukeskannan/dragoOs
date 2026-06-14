import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/dragon_widget.dart';
import '../widgets/message_input.dart';

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

  final List<ChatMessage> messages = [];

  Color get accentColor => isDragoMode ? Colors.redAccent : Colors.blueAccent;

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

  Future<void> _handleSend() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      messages.add(ChatMessage(text: userInput, isUser: true));
      isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final reply = await ApiService.sendMessage(userInput);

    setState(() {
      messages.add(ChatMessage(text: reply, isUser: false));
      isLoading = false;
    });
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
            // ---- Background dragon (always visible, watermark style) ----
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

            // ---- Foreground content ----
            Column(
              children: [
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
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.5),
                                blurRadius: 15,
                              ),
                            ],
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Drago AI",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isDragoMode ? "Drago Mode" : "Assistant Mode",
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

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
                              border: Border.all(
                                color: accentColor.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accentColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Drago is thinking...",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final msg = messages[index];
                      return ChatBubble(
                        message: msg.text,
                        isUser: msg.isUser,
                        accentColor: accentColor,
                      );
                    },
                  ),
                ),

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