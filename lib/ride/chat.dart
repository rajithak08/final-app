import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBotPage extends StatefulWidget {
  final String chatId;
  final String source;
  final String destination;
  final String seats;
  final String startTime;

  // Add a Key parameter to the constructor
  const ChatBotPage({
    Key? key,
    required this.chatId,
    required this.source,
    required this.destination,
    required this.seats,
    required this.startTime,
  }) : super(key: key);

  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage(String message) {
    final Map<String, String> predefinedResponses = {
      "Hello": "Hi! How can I assist you today?",
      "Source": "Hi ${widget.source}, is the source.",
      "Destination": "Hi ${widget.destination}, is the destination.",
      "Start Time":"The start time is ${widget.startTime}.",
      "Seats":"Hi,${widget.seats}, seats are available. ",
      "ChatId":"Your chat ID is ${widget.chatId}. Let me know if you need help with anything specific!",
    };

    setState(() {
      _messages.add({"user": message});
      String response = predefinedResponses[message] ??
          "I don't understand that. Try using one of these words: Hello, Source, Destination, Start Time, Seats, ChatId.";
      _messages.add({"bot": response});
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // ignore: deprecated_member_use
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatId, // Display chatId here
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              'Online',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        leading: Icon(Icons.arrow_back, color: Colors.white),
        actions: [
          Icon(Icons.search, color: Colors.white),
          SizedBox(width: 10),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image:
                AssetImage('assets/chat.png'), 
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[_messages.length - 1 - index];
                  final isUser = message.containsKey("user");
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      padding: EdgeInsets.all(16),
                      constraints: BoxConstraints(maxWidth: 250),
                      decoration: BoxDecoration(
                        color: isUser
                            // ignore: deprecated_member_use
                            ? Colors.black.withOpacity(0.7)
                            // ignore: deprecated_member_use
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomLeft:
                              isUser ? Radius.circular(12) : Radius.circular(0),
                          bottomRight:
                              isUser ? Radius.circular(0) : Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        isUser ? message["user"]! : message["bot"]!,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.7),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(0, 0, 0, 0),
                    blurRadius: 5,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.white)),
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.black.withOpacity(0.7),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        if (_controller.text.trim().isNotEmpty) {
                          _sendMessage(_controller.text.trim());
                        }
                      },
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
