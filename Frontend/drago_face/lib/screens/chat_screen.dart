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

  // ── NEW: conversation history for multi-turn context ──────────────────────
  final List<Map<String, String>> _conversationHistory = [];

  Color get accentColor => isDragoMode ? Colors.redAccent : Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  // =========================
  // LOAD FROM SQLITE
  // =========================
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

  // =========================
  // SEND MESSAGE
  // =========================
  Future<void> _handleSend() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    _controller.clear();

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
    _scrollToBottom();

    // ── 1. Extract & save memory (parallel, non-blocking) ──────────────────
    ApiService.extractMemory(userInput).then((extracted) async {
      for (final entry in extracted.entries) {
        if (entry.value.isNotEmpty) {
          await ChatDB.saveMemory(entry.key, entry.value);
        }
      }
    });

    // ── 2. Load full memory context for this turn ───────────────────────────
    final memoryContext = await ChatDB.buildMemoryContext();

    // ── 3. Call AI with memory context + conversation history ───────────────
    final reply = await ApiService.sendMessage(
      message: userInput,
      memoryContext: memoryContext,
      history: List.from(_conversationHistory),
    );

    // ── 4. Update in-memory conversation history ────────────────────────────
    _conversationHistory.add({'role': 'user', 'content': userInput});
    _conversationHistory.add({'role': 'assistant', 'content': reply});

    // Keep last 20 entries (10 turns) to avoid token bloat
    if (_conversationHistory.length > 20) {
      _conversationHistory.removeRange(0, _conversationHistory.length - 20);
    }

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