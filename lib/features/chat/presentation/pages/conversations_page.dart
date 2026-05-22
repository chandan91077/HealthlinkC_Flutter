import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  Timer? _autoRefreshTimer;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _conversations = const [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted || _isLoading) {
        return;
      }
      _loadConversations();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await sl<ApiClient>().get('/api/messages/conversations');
      final data = response.data;
      final conversations = data is List
          ? data
              .whereType<Map>()
              .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
              .toList()
          : <Map<String, dynamic>>[];

      conversations.sort(
        (a, b) => _conversationTimestamp(b).compareTo(
          _conversationTimestamp(a),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations = conversations;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load conversations.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _subtitle(Map<String, dynamic> conversation) {
    final lastMessage = conversation['lastMessage'];
    if (lastMessage is Map<String, dynamic>) {
      final content = lastMessage['content']?.toString() ?? '';
      if (content.isNotEmpty) {
        return content;
      }
    }
    return 'Start chatting';
  }

  String _timeLabel(Map<String, dynamic> conversation) {
    final lastMessage = conversation['lastMessage'];
    if (lastMessage is Map<String, dynamic>) {
      final raw = lastMessage['createdAt']?.toString() ?? '';
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        return DateFormat('hh:mm a').format(dt.toLocal());
      }
    }
    return '';
  }

  DateTime _conversationTimestamp(Map<String, dynamic> conversation) {
    final lastMessage = conversation['lastMessage'];
    if (lastMessage is Map) {
      final candidates = [
        lastMessage['createdAt'],
        lastMessage['created_at'],
        lastMessage['updatedAt'],
        lastMessage['updated_at'],
      ];

      for (final candidate in candidates) {
        final timestamp = DateTime.tryParse(candidate?.toString() ?? '');
        if (timestamp != null) {
          return timestamp;
        }
      }
    }

    final fallbackCandidates = [
      conversation['updatedAt'],
      conversation['updated_at'],
      conversation['createdAt'],
      conversation['created_at'],
    ];

    for (final candidate in fallbackCandidates) {
      final timestamp = DateTime.tryParse(candidate?.toString() ?? '');
      if (timestamp != null) {
        return timestamp;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _appointmentId(Map<String, dynamic> conversation) {
    final raw = conversation['appointment_id'];
    if (raw is String) {
      return raw;
    }
    if (raw is Map<String, dynamic>) {
      return raw['_id']?.toString() ?? '';
    }
    if (raw is Map) {
      return raw['_id']?.toString() ?? '';
    }
    return raw?.toString() ?? '';
  }

  bool _chatUnlocked(Map<String, dynamic> conversation) {
    return conversation['chat_unlocked'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: _conversations.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('No conversations yet.')),
                          ],
                        )
                      : ListView.separated(
                          itemCount: _conversations.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final conversation = _conversations[index];
                            final appointmentId = _appointmentId(conversation);
                            final chatUnlocked = _chatUnlocked(conversation);
                            final unread = (conversation['unreadCount'] as num?)
                                    ?.toInt() ??
                                0;
                            final currentUserId = context.read<AuthProvider>().user?.id;
                            bool isMine = false;
                            bool isRead = false;
                            final lastMessage = conversation['lastMessage'];
                            if (lastMessage is Map<String, dynamic>) {
                               final sender = lastMessage['sender_id'];
                               String senderId = '';
                               if (sender is Map<String, dynamic>) {
                                 senderId = sender['_id']?.toString() ?? sender['id']?.toString() ?? '';
                               } else {
                                 senderId = sender?.toString() ?? '';
                               }
                               isMine = senderId.isNotEmpty && senderId == currentUserId;
                               isRead = lastMessage['is_read'] == true;
                            }

                            return InkWell(
                              onTap: appointmentId.isEmpty
                                  ? null
                                  : () => context.push('/chat/$appointmentId'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.grey.shade200,
                                          child: Icon(Icons.person, color: Colors.grey.shade600, size: 28),
                                        ),
                                        if (chatUnlocked)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Theme.of(context).scaffoldBackgroundColor,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  conversation['otherPartyName']?.toString() ?? 'Conversation',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                _timeLabel(conversation),
                                                style: TextStyle(
                                                  color: unread > 0 ? Theme.of(context).primaryColor : Colors.grey.shade600,
                                                  fontSize: 12,
                                                  fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (isMine) ...[
                                                Icon(
                                                  Icons.done_all,
                                                  size: 16,
                                                  color: isRead ? Colors.blue : Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  _subtitle(conversation),
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (unread > 0)
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).primaryColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    unread.toString(),
                                                    style: const TextStyle(
                                                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
