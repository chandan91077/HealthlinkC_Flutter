import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:healthlink_connect_flutter/features/chat/domain/entities/chat_message.dart';

class WebSocketService {
  final String baseUrl;
  WebSocketChannel? _channel;
  final _messageController = StreamController<ChatMessage>.broadcast();
  bool _isConnected = false;
  
  Stream<ChatMessage> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  WebSocketService({required this.baseUrl});

  void connect(String token) {
    if (_isConnected) return;
    
    try {
      final wsUrl = Uri.parse('$baseUrl/ws/chat').replace(
        queryParameters: {'token': token},
      );
      
      _channel = WebSocketChannel.connect(wsUrl);
      _isConnected = true;
      
      _channel?.stream.listen(
        (data) {
          final jsonMap = jsonDecode(data as String);
          final message = ChatMessage.fromJson(jsonMap);
          _messageController.add(message);
        },
        onError: (error) {
          _isConnected = false;
          // Implement reconnect logic here
          Future.delayed(const Duration(seconds: 5), () => connect(token));
        },
        onDone: () {
          _isConnected = false;
        },
      );
    } catch (e) {
      _isConnected = false;
    }
  }

  void sendMessage(ChatMessage message) {
    if (!_isConnected || _channel == null) return;
    
    final jsonStr = jsonEncode(message.toJson());
    _channel!.sink.add(jsonStr);
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }
  
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
