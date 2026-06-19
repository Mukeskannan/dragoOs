import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/dragon_widget.dart';
import '../widgets/message_input.dart';
import '../db/chat_db.dart';
import 'dart:async' show unawaited;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

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
  final List<Map<String, String>> _conversationHistory = [];
  List<Map<String, dynamic>> conversations = [];
  int currentConversationId = 1;

  Color get accentColor => isDragoMode ? Colors.redAccent : Colors.blueAccent;

  late stt.SpeechToText _speech;
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool waitingForDragoPassword = false;

  static const String dragoPassword = "drago 007";

 @override
void initState() {
  super.initState();

  _startFreshChat();

  _speech = stt.SpeechToText();
  _initTts();
}

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _startFreshChat() async {
  final id = await ChatDB.createConversation("New Chat");

  setState(() {
    currentConversationId = id;
    messages.clear();
    _conversationHistory.clear();
  });

  await loadConversations();
}

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        onResult: (result) async {
          setState(() {
            _controller.text = result.recognizedWords;
          });
          if (result.finalResult) {
            await _stopListening();
          }
        },
      );
    }
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);

    await _speech.stop();

    if (_controller.text.trim().isNotEmpty) {
      await _handleSend();
    }
     _controller.clear();
  }

  Future<void> _loadMessages() async {
    final data = await ChatDB.getMessages(currentConversationId);
    setState(() {
      messages.clear();
      messages.addAll(data);
    });
    _scrollToBottom();
  }

  Future<void> _loadConverstaion(int conversationId) async {
    currentConversationId = conversationId;
    final data = await ChatDB.getMessages((conversationId));
    setState(() {
      messages.clear();
      messages.addAll(data);
    });
    Navigator.pop(context);
  }

  Future<void> createNewChat() async {
    final id = await ChatDB.createConversation("New Chat");
    await loadConversations();
    setState(() {
      currentConversationId = id;
      messages.clear();
      _conversationHistory.clear();
    });

    print("Current Chat: $currentConversationId");
  }

  Future<void> loadConversations() async {
    final data = await ChatDB.getConversations();

    setState(() {
      conversations = data;
    });

    print(conversations);
  }

  Future<void> _showDeleteDialog(int conversationId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            "Delete Chat",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Are you sure you want to delete this chat?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancle"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await ChatDB.deleteConversation(conversationId);

      await loadConversations();

      if (conversationId == currentConversationId) {
        setState(() {
          messages.clear();
          _conversationHistory.clear();
        });
      }
    }
  }

  void _toggleMode() {
    setState(() => isDragoMode = !isDragoMode);
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

    final lowerInput = userInput.toLowerCase();

    if (
    lowerInput.contains("drago") &&
    (
      lowerInput.contains("deactivate") ||
      lowerInput.contains("disable") ||
      lowerInput.contains("off")
    )
   ) {

  setState(() {
    isDragoMode = false;
  });

  await _tts.speak("Drago mode deactivated");

  final aiMsg = MessageModel(
    text: "🔵 Assistant Mode Activated",
    isUser: false,
    time: DateTime.now(),
    conversationId: currentConversationId,
  );

  setState(() {
    messages.add(aiMsg);
  });

  await ChatDB.insertMessage(aiMsg);

  return;
}

    /// ── DRAGO ACTIVATION REQUEST ─────────────────────────────
    if ((lowerInput.contains("dragon") || lowerInput.contains("drago")) &&
        (lowerInput.contains("activate") ||
            lowerInput.contains("active") ||
            lowerInput.contains("control") ||
            lowerInput.contains("wake"))) {
      waitingForDragoPassword = true;

      await _tts.speak("Password required");
      await _startListening();

      return;
    }

    /// ── PASSWORD CHECK ───────────────────────────────────────
    if (waitingForDragoPassword) {
      waitingForDragoPassword = false;

      if (lowerInput == dragoPassword) {
        setState(() {
          isDragoMode = true;
        });

        await _tts.speak("Access granted. Drago mode activated");

        final aiMsg = MessageModel(
          text: "🔥 Drago Mode Activated",
          isUser: false,
          time: DateTime.now(),
          conversationId: currentConversationId,
        );

        setState(() {
          messages.add(aiMsg);
        });

        await ChatDB.insertMessage(aiMsg);

        return;
      } else {
        await _tts.speak("Access denied");

        final aiMsg = MessageModel(
          text: "❌ Access Denied",
          isUser: false,
          time: DateTime.now(),
          conversationId: currentConversationId,
        );

        setState(() {
          messages.add(aiMsg);
        });

        await ChatDB.insertMessage(aiMsg);

        return;
      }
    }

    _controller.clear();

    final userMsg = MessageModel(
      text: userInput,
      isUser: true,
      time: DateTime.now(),
      conversationId: currentConversationId,
    );

    setState(() {
      messages.add(userMsg);
      isLoading = true;
      _isListening = false;
    });

    print('[Send] User said: $userInput');

    await ChatDB.insertMessage(userMsg);
    Map<String, dynamic>? currentChat;
    for (final chat in conversations) {
      if (chat['id'] == currentConversationId) {
        currentChat = chat;
        break;
      }
    }

    if (currentChat != null && currentChat['title'] == "New Chat") {
      await ChatDB.updateConversationTitle(
        currentConversationId,
        userInput.length > 30 ? userInput.substring(0, 30) : userInput,
      );
      await loadConversations();
    }
    _scrollToBottom();

    // ── 1. Load memory from SQLite (fast, local) ───────────────────────────
    final memoryContext = await ChatDB.buildMemoryContext();
    print('[Send] Memory context: $memoryContext');

    // ── 2. Extract memory in background only for long messages ─────────────
    if (userInput.trim().split(' ').length >= 4) {
      unawaited(
        ApiService.extractMemory(userInput).then((extracted) async {
          if (extracted.isNotEmpty) {
            print('[Send] Saving memory: $extracted');
            for (final entry in extracted.entries) {
              if (entry.value.isNotEmpty) {
                await ChatDB.saveMemory(entry.key, entry.value);
              }
            }
          }
        }),
      );
    }

    // ── 3. Call AI ─────────────────────────────────────────────────────────
    print('[Send] Calling AI...');
    final reply = await ApiService.sendMessage(
      message: userInput,
      memoryContext: memoryContext,
      history: List.from(_conversationHistory),
    );
    print('[Send] Got reply: $reply');

    // ── 4. Update history ──────────────────────────────────────────────────
    _conversationHistory.add({'role': 'user', 'content': userInput});
    _conversationHistory.add({'role': 'assistant', 'content': reply});

    if (_conversationHistory.length > 20) {
      _conversationHistory.removeRange(0, _conversationHistory.length - 20);
    }

    final aiMsg = MessageModel(
      text: reply,
      isUser: false,
      time: DateTime.now(),
      conversationId: currentConversationId,
    );

    setState(() {
      messages.add(aiMsg);
      isLoading = false;
    });

    await ChatDB.insertMessage(aiMsg);

    // ── 5. Speak reply in Drago mode ───────────────────────────────────────
    if (isDragoMode) {
      await _tts.speak(reply);
    }

    _scrollToBottom();
  }

  void _handleMicTap() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
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
      drawer: Drawer(
        backgroundColor: const Color(0xFF111111),
        child: Column(
          children: [
            const DrawerHeader(
              child: Center(
                child: Text(
                  "Drago AI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.add, color: Colors.white),
              title: const Text(
                "New Chat",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                final newId = await ChatDB.createConversation("New Chat");

                await loadConversations();

                setState(() {
                  currentConversationId = newId;
                  messages.clear();
                  _conversationHistory.clear();
                });

                Navigator.pop(context);
                print("Current conversation: $currentConversationId");
              },
            ),

            const Divider(color: Colors.white24),

            Expanded(
              child: ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final chat = conversations[index];

                  return GestureDetector(
                    onLongPress: () async {
                      await _showDeleteDialog(chat['id']);

                      await loadConversations();

                      if (chat['id'] == currentConversationId) {
                        setState(() {
                          messages.clear();
                        });
                      }
                    },
                    child: ListTile(
                      leading: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white70,
                      ),
                      title: Text(
                        chat['title'] ?? 'Untitled Chat',
                        style: const TextStyle(color: Colors.white),
                      ),
                      // subtitle: Text(
                      //   "ID: ${chat['id']}",
                      //   style: const TextStyle(color: Colors.white54),
                      // ),
                      onTap: () async {
                        await _loadConverstaion(chat['id']);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
                  child: Builder(
                    builder: (context) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),

                        GestureDetector(
                          onTap: _toggleMode,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withOpacity(0.15),
                              border: Border.all(
                                color: accentColor,
                                width: 1.5,
                              ),
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
                if (_isListening)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      "🎤  Drago Listening...",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                      ),
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
