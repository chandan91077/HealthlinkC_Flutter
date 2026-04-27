import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';
import 'package:healthlink_connect_flutter/core/utils/external_link_opener.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  const ChatPage({super.key, required this.conversationId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _zoomLinkController = TextEditingController();
  final TextEditingController _meetingTimeController = TextEditingController();

  bool _isLoading = true;
  bool _isSending = false;
  bool _isUpdatingPermissions = false;
  String? _error;

  List<Map<String, dynamic>> _messages = const [];
  Map<String, dynamic>? _appointment;
  bool _isPolling = false;
  String _messagesFingerprint = '';
  String _appointmentFingerprint = '';

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadChatData();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || _isLoading || _isPolling) {
        return;
      }
      _loadMessagesSilently();
    });
  }

  String _buildMessagesFingerprint(List<Map<String, dynamic>> messages) {
    return messages
        .map(
          (message) =>
              '${message['_id'] ?? message['id'] ?? ''}|${message['createdAt'] ?? message['created_at'] ?? ''}|${message['message_type'] ?? ''}|${message['content'] ?? ''}|${message['file_url'] ?? ''}|${message['is_read'] ?? ''}',
        )
        .join('~');
  }

  String _buildAppointmentFingerprint(Map<String, dynamic>? appointment) {
    if (appointment == null) {
      return '';
    }
    final video = appointment['video'];
    final doctorInCall = video is Map ? video['doctorInCall'] : null;
    final payload = {
      'chat_unlocked': appointment['chat_unlocked'],
      'video_unlocked': appointment['video_unlocked'],
      'zoom_join_url': appointment['zoom_join_url'],
      'meeting_time': appointment['meeting_time'],
      'meeting_provider': appointment['meeting_provider'],
      'doctorInCall': doctorInCall,
    };
    return jsonEncode(payload);
  }

  String get _role => context.read<AuthProvider>().role ?? 'patient';
  bool get _isDoctor => _role == 'doctor';

  String? get _currentUserId => context.read<AuthProvider>().user?.id;

  Future<void> _loadChatData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = sl<ApiClient>();
      final responses = await Future.wait([
        api.get('/api/appointments/${widget.conversationId}'),
        api.get(
          '/api/messages/conversation',
          queryParameters: {'appointment_id': widget.conversationId},
        ),
      ]);

      final appointmentData = responses[0].data;
      final appointmentMap = appointmentData is Map<String, dynamic>
          ? appointmentData
          : appointmentData is Map
              ? appointmentData.map((k, v) => MapEntry(k.toString(), v))
              : <String, dynamic>{};

      final messagesData = responses[1].data;
      final parsedMessages = messagesData is List
          ? messagesData
              .whereType<Map>()
              .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
              .toList()
          : <Map<String, dynamic>>[];

      parsedMessages.sort(
        (a, b) => _messageSortTimestamp(b).compareTo(
          _messageSortTimestamp(a),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _appointment = appointmentMap;
        _messages = parsedMessages;
        _zoomLinkController.text =
            appointmentMap['zoom_join_url']?.toString() ?? '';
        _meetingTimeController.text =
            appointmentMap['meeting_time']?.toString() ?? '';
        _messagesFingerprint = _buildMessagesFingerprint(parsedMessages);
        _appointmentFingerprint = _buildAppointmentFingerprint(appointmentMap);
      });

      await _markRead();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load chat.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMessagesSilently() async {
    if (_isPolling) {
      return;
    }
    _isPolling = true;
    try {
      final responses = await Future.wait([
        sl<ApiClient>().get(
          '/api/messages/conversation',
          queryParameters: {'appointment_id': widget.conversationId},
        ),
        sl<ApiClient>().get('/api/appointments/${widget.conversationId}'),
      ]);

      final messagesData = responses[0].data;
      final parsedMessages = messagesData is List
          ? messagesData
              .whereType<Map>()
              .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
              .toList()
          : <Map<String, dynamic>>[];

      parsedMessages.sort(
        (a, b) => _messageSortTimestamp(b).compareTo(
          _messageSortTimestamp(a),
        ),
      );

      final appointmentData = responses[1].data;
      final appointmentMap = appointmentData is Map<String, dynamic>
          ? appointmentData
          : appointmentData is Map
              ? appointmentData.map((k, v) => MapEntry(k.toString(), v))
              : <String, dynamic>{};

      if (!mounted) {
        return;
      }
      final nextMessagesFingerprint = _buildMessagesFingerprint(parsedMessages);
      final nextAppointmentFingerprint =
          _buildAppointmentFingerprint(appointmentMap);
      final hasMessagesChanged =
          nextMessagesFingerprint != _messagesFingerprint;
      final hasAppointmentChanged =
          nextAppointmentFingerprint != _appointmentFingerprint;

      if (!hasMessagesChanged && !hasAppointmentChanged) {
        return;
      }

      setState(() {
        _messages = parsedMessages;
        _appointment = appointmentMap;
        _messagesFingerprint = nextMessagesFingerprint;
        _appointmentFingerprint = nextAppointmentFingerprint;
      });
      if (hasMessagesChanged) {
        await _markRead();
      }
    } catch (_) {
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _markRead() async {
    try {
      await sl<ApiClient>().put(
        '/api/messages/mark-read',
        data: {'appointment_id': widget.conversationId},
      );
    } catch (_) {}
  }

  String _otherPartyName() {
    final appt = _appointment;
    if (appt == null) {
      return 'Chat';
    }

    if (_isDoctor) {
      final patient = appt['patient_id'];
      if (patient is Map<String, dynamic>) {
        final name = patient['full_name']?.toString() ?? 'Patient';
        return name;
      }
      return 'Patient';
    }

    final doctor = appt['doctor_id'];
    if (doctor is Map<String, dynamic>) {
      final user = doctor['user_id'];
      if (user is Map<String, dynamic>) {
        final rawName = user['full_name']?.toString() ?? 'Doctor';
        final normalized = rawName.replaceFirst(
            RegExp(r'^dr\.?\s*', caseSensitive: false), '');
        return 'Dr. ${normalized.isEmpty ? 'Doctor' : normalized}';
      }
    }
    return 'Doctor';
  }

  bool get _chatUnlocked => _appointment?['chat_unlocked'] == true;
  bool get _videoUnlocked => _appointment?['video_unlocked'] == true;
  bool get _sessionEndedForPatient {
    if (_isDoctor || _videoUnlocked) {
      return false;
    }

    final meetingTime = _appointment?['meeting_time']?.toString().trim() ?? '';
    final meetingProvider =
        _appointment?['meeting_provider']?.toString().trim() ?? '';
    final hasPriorSessionMetadata =
        meetingTime.isNotEmpty || meetingProvider.isNotEmpty;

    return hasPriorSessionMetadata;
  }

  bool get _doctorInCall {
    final video = _appointment?['video'];
    if (video is Map<String, dynamic>) {
      return video['doctorInCall'] == true;
    }
    if (video is Map) {
      return video['doctorInCall'] == true;
    }
    return false;
  }

  String _statusText() {
    if (_isDoctor) {
      return _chatUnlocked
          ? 'Chat enabled for patient'
          : 'Patient chat is disabled';
    }
    return _chatUnlocked ? 'Chat enabled by doctor' : 'Chat disabled by doctor';
  }

  bool _isMine(Map<String, dynamic> message) {
    final sender = message['sender_id'];
    String senderId = '';
    if (sender is Map<String, dynamic>) {
      senderId = sender['_id']?.toString() ?? sender['id']?.toString() ?? '';
    } else {
      senderId = sender?.toString() ?? '';
    }
    return senderId.isNotEmpty && senderId == _currentUserId;
  }

  Future<void> _sendText() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      return;
    }

    if (!_isDoctor && !_chatUnlocked) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Doctor has disabled chat for this appointment.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });
    try {
      await sl<ApiClient>().post(
        '/api/messages',
        data: {
          'appointment_id': widget.conversationId,
          'content': content,
          'message_type': 'text',
        },
      );
      _messageController.clear();
      await _loadMessagesSilently();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.response?.data is Map<String, dynamic>
          ? error.response?.data['message']?.toString() ??
              'Failed to send message.'
          : 'Failed to send message.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message.')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendAttachment() async {
    if (!_isDoctor && !_chatUnlocked) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Doctor has disabled chat for this appointment.')),
      );
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx'],
    );

    if (picked == null ||
        picked.files.isEmpty ||
        picked.files.first.path == null) {
      return;
    }

    setState(() {
      _isSending = true;
    });
    try {
      final file = picked.files.first;
      final uploadResponse = await sl<ApiClient>().dio.post(
            '/api/upload',
            data: FormData.fromMap({
              'file':
                  await MultipartFile.fromFile(file.path!, filename: file.name),
            }),
          );

      final fileUrl = uploadResponse.data is Map<String, dynamic>
          ? uploadResponse.data['fileUrl']?.toString() ?? ''
          : '';
      if (fileUrl.isEmpty) {
        throw Exception('Upload failed');
      }

      final ext = (file.extension ?? '').toLowerCase();
      final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);

      await sl<ApiClient>().post(
        '/api/messages',
        data: {
          'appointment_id': widget.conversationId,
          'content': isImage ? 'Image shared' : 'File shared: ${file.name}',
          'file_url': fileUrl,
          'message_type': isImage ? 'image' : 'file',
        },
      );

      await _loadMessagesSilently();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send attachment.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _joinCall() async {
    final messenger = ScaffoldMessenger.of(context);
    final video = _appointment?['video'];
    final doctorLink =
        video is Map ? (video['doctorJoinUrl']?.toString() ?? '') : '';
    final patientLink =
        video is Map ? (video['patientJoinUrl']?.toString() ?? '') : '';
    final zoomLink = _isDoctor
        ? (doctorLink.isNotEmpty
            ? doctorLink
            : (_appointment?['zoom_join_url']?.toString() ?? ''))
        : (patientLink.isNotEmpty
            ? patientLink
            : (_appointment?['zoom_join_url']?.toString() ?? ''));

    if (!_videoUnlocked || zoomLink.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Video link is not available yet.')),
      );
      return;
    }

    try {
      if (_isDoctor) {
        await sl<ApiClient>().dio.patch(
              '/api/appointments/${widget.conversationId}/doctor-join-call',
            );
      }
      if (!mounted) {
        return;
      }
      await openExternalLink(
        context,
        zoomLink,
        invalidMessage: 'Invalid video link.',
        failureMessage: 'Unable to open link.',
      );
      await _loadChatData();
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to join call right now.')),
      );
    }
  }

  Future<void> _endSession() async {
    if (!_isDoctor) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isUpdatingPermissions = true;
    });

    try {
      await sl<ApiClient>().dio.patch(
            '/api/appointments/${widget.conversationId}/doctor-leave-call',
          );

      final response = await sl<ApiClient>().put(
        '/api/appointments/${widget.conversationId}/permissions',
        data: {
          'chat_unlocked': _chatUnlocked,
          'video_unlocked': false,
          'zoom_join_url': '',
          'meeting_provider':
              _appointment?['meeting_provider']?.toString() ?? 'zoom',
          'meeting_time': _appointment?['meeting_time']?.toString() ?? '',
          'auto_send': false,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _appointment = data;
        });
      } else if (data is Map) {
        setState(() {
          _appointment = data.map((k, v) => MapEntry(k.toString(), v));
        });
      }

      await _loadMessagesSilently();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Session ended by doctor.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to end session.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPermissions = false;
        });
      }
    }
  }

  Future<void> _confirmEndSession() async {
    if (!_isDoctor) {
      return;
    }

    final shouldEnd = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('End Session?'),
              content: const Text(
                'This will end the current call session and remove video access for this appointment.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('End Session'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldEnd) {
      return;
    }

    await _endSession();
  }

  Widget _callActionsCard() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_sessionEndedForPatient) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video session ended by doctor.',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
            ),
            SizedBox(height: 4),
            Text(
              'Join Call is no longer available for this appointment.',
              style:
                  TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final video = _appointment?['video'];
    final doctorLink =
        video is Map ? (video['doctorJoinUrl']?.toString() ?? '') : '';
    final patientLink =
        video is Map ? (video['patientJoinUrl']?.toString() ?? '') : '';
    final zoomLink = _isDoctor
        ? (doctorLink.isNotEmpty
            ? doctorLink
            : (_appointment?['zoom_join_url']?.toString() ?? ''))
        : (patientLink.isNotEmpty
            ? patientLink
            : (_appointment?['zoom_join_url']?.toString() ?? ''));
    final hasJoin = _videoUnlocked && zoomLink.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasJoin
                ? 'Video call link is available.'
                : 'Video call is not active.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _isDoctor
                ? (_doctorInCall
                    ? 'You are marked in-call.'
                    : 'Tap Join Call when ready.')
                : (_doctorInCall
                    ? 'Doctor is in call. You can join now.'
                    : 'Waiting for doctor to join call.'),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed:
                    (_isUpdatingPermissions || !hasJoin) ? null : _joinCall,
                icon: const Icon(Icons.videocam, size: 18),
                label: const Text('Join Call'),
              ),
              if (_isDoctor) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isUpdatingPermissions ? null : _confirmEndSession,
                  icon: const Icon(Icons.call_end, size: 18, color: Colors.red),
                  label: const Text(
                    'End Session',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDoctorActions() async {
    try {
      final response = await sl<ApiClient>().get(
        '/api/appointments/${widget.conversationId}',
      );
      final data = response.data;
      final latestAppointment = data is Map<String, dynamic>
          ? data
          : data is Map
              ? data.map((k, v) => MapEntry(k.toString(), v))
              : <String, dynamic>{};

      if (mounted) {
        setState(() {
          _appointment = latestAppointment;
          _zoomLinkController.text =
              latestAppointment['zoom_join_url']?.toString() ?? '';
          _meetingTimeController.text =
              latestAppointment['meeting_time']?.toString() ?? '';
        });
      }
    } catch (_) {}

    bool chatUnlocked = _chatUnlocked;
    bool videoUnlocked = _videoUnlocked;
    bool autoSend = true;
    String provider =
        _appointment?['meeting_provider']?.toString().isNotEmpty == true
            ? _appointment!['meeting_provider'].toString()
            : 'zoom';

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doctor Chat Actions',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: chatUnlocked,
                        onChanged: (value) {
                          setSheetState(() {
                            chatUnlocked = value;
                          });
                        },
                        title: const Text('Enable Patient Chat'),
                      ),
                      SwitchListTile(
                        value: videoUnlocked,
                        onChanged: (value) {
                          setSheetState(() {
                            videoUnlocked = value;
                          });
                        },
                        title: const Text('Enable Video Link'),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: provider,
                        decoration: const InputDecoration(
                          labelText: 'Meeting Provider',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'zoom', child: Text('Zoom')),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setSheetState(() {
                            provider = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _zoomLinkController,
                        decoration: const InputDecoration(
                          labelText:
                              'Video Link (enter optional, auto-generated if empty)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _meetingTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Meeting Time (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        value: autoSend,
                        onChanged: (value) {
                          setSheetState(() {
                            autoSend = value;
                          });
                        },
                        title: const Text('Auto-send video link notification'),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUpdatingPermissions
                              ? null
                              : () async {
                                  final messenger =
                                      ScaffoldMessenger.of(this.context);
                                  final zoomLink =
                                      _zoomLinkController.text.trim();
                                  final parsedZoomLink = Uri.tryParse(zoomLink);
                                  final hasValidZoomLink = parsedZoomLink !=
                                          null &&
                                      (parsedZoomLink.scheme == 'https' ||
                                          parsedZoomLink.scheme == 'http') &&
                                      parsedZoomLink.host.isNotEmpty;

                                  if (zoomLink.isNotEmpty &&
                                      !hasValidZoomLink) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter a valid video link (http/https).',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }

                                  setState(() {
                                    _isUpdatingPermissions = true;
                                  });
                                  try {
                                    final response = await sl<ApiClient>().put(
                                      '/api/appointments/${widget.conversationId}/permissions',
                                      data: {
                                        'chat_unlocked': chatUnlocked,
                                        'video_unlocked': videoUnlocked,
                                        'zoom_join_url': zoomLink,
                                        'meeting_provider': provider,
                                        'meeting_time':
                                            _meetingTimeController.text.trim(),
                                        'auto_send': autoSend,
                                      },
                                    );

                                    final data = response.data;
                                    if (data is Map<String, dynamic>) {
                                      setState(() {
                                        _appointment = data;
                                      });
                                    } else if (data is Map) {
                                      setState(() {
                                        _appointment = data.map((k, v) =>
                                            MapEntry(k.toString(), v));
                                      });
                                    }

                                    await _loadMessagesSilently();
                                    if (!mounted) {
                                      return;
                                    }
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Doctor chat actions updated.'),
                                      ),
                                    );
                                  } on DioException catch (error) {
                                    if (!mounted) {
                                      return;
                                    }
                                    final message = error.response?.data
                                            is Map<String, dynamic>
                                        ? error.response?.data['message']
                                                ?.toString() ??
                                            'Failed to update doctor actions.'
                                        : 'Failed to update doctor actions.';
                                    messenger.showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  } catch (_) {
                                    if (!mounted) {
                                      return;
                                    }
                                    messenger.showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Failed to update doctor actions.')),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isUpdatingPermissions = false;
                                      });
                                    }
                                  }
                                },
                          child: _isUpdatingPermissions
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Actions'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  DateTime? _messageDateTime(Map<String, dynamic> message) {
    final raw = message['createdAt']?.toString() ??
        message['created_at']?.toString() ??
        '';
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }

  DateTime _messageSortTimestamp(Map<String, dynamic> message) {
    final candidates = [
      message['createdAt'],
      message['created_at'],
      message['updatedAt'],
      message['updated_at'],
    ];

    for (final candidate in candidates) {
      final timestamp = DateTime.tryParse(candidate?.toString() ?? '');
      if (timestamp != null) {
        return timestamp.toLocal();
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _isSameCalendarDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dayLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (_isSameCalendarDate(messageDay, today)) {
      return 'Today';
    }
    if (_isSameCalendarDate(messageDay, yesterday)) {
      return 'Yesterday';
    }
    return DateFormat('dd MMM yyyy').format(messageDay);
  }

  String _timeLabel(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  Widget _dateSeparator(String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> message, {DateTime? timestamp}) {
    final colorScheme = Theme.of(context).colorScheme;
    final mine = _isMine(message);
    final type = message['message_type']?.toString() ?? 'text';
    final content = message['content']?.toString() ?? '';
    final fileUrl = message['file_url']?.toString() ?? '';

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 290),
        child: Card(
          color: mine
              ? AppColors.primary
              : colorScheme.surfaceVariant.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (type == 'image' && fileUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => openExternalLink(
                      context,
                      fileUrl,
                      invalidMessage: 'Invalid file link.',
                      failureMessage: 'Unable to open link.',
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        fileUrl,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          'Image unavailable',
                          style: TextStyle(
                              color: mine
                                  ? Colors.white70
                                  : colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                if (type == 'file' && fileUrl.isNotEmpty)
                  InkWell(
                    onTap: () => openExternalLink(
                      context,
                      fileUrl,
                      invalidMessage: 'Invalid file link.',
                      failureMessage: 'Unable to open link.',
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file,
                            color: mine ? Colors.white : AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Open file',
                          style: TextStyle(
                            color: mine ? Colors.white : AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (content.isNotEmpty) ...[
                  if ((type == 'image' || type == 'file') && fileUrl.isNotEmpty)
                    const SizedBox(height: 6),
                  Text(
                    content,
                    style: TextStyle(
                        color: mine ? Colors.white : colorScheme.onSurface),
                  ),
                ],
                if (timestamp != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _timeLabel(timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          mine ? Colors.white70 : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputArea() {
    final colorScheme = Theme.of(context).colorScheme;
    final canSend = _isDoctor || _chatUnlocked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              color: canSend ? AppColors.primary : Colors.grey,
              onPressed: (_isSending || !canSend) ? null : _sendAttachment,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: canSend,
                decoration: InputDecoration(
                  hintText:
                      canSend ? 'Type a message...' : 'Chat disabled by doctor',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.45),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: canSend ? AppColors.primary : Colors.grey,
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: (_isSending || !canSend) ? null : _sendText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _zoomLinkController.dispose();
    _meetingTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const CircleAvatar(
                    radius: 16, child: Icon(Icons.person, size: 20)),
                if (_chatUnlocked)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: colorScheme.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_otherPartyName(), style: const TextStyle(fontSize: 16)),
                Text(
                  _statusText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _chatUnlocked ? Colors.green : Colors.orange,
                  ),
                ),
                if (_sessionEndedForPatient) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Session Ended',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChatData,
          ),
          if (_isDoctor)
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: _showDoctorActions,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    _callActionsCard(),
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(child: Text('No messages yet.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final currentDateTime =
                                    _messageDateTime(message);
                                final currentMine = _isMine(message);
                                DateTime? previousDateTime;
                                bool sameSenderAsPrevious = false;
                                if (index > 0) {
                                  final previousMessage = _messages[index - 1];
                                  previousDateTime =
                                      _messageDateTime(previousMessage);
                                  sameSenderAsPrevious =
                                      currentMine == _isMine(previousMessage);
                                }

                                final showDateSection = currentDateTime !=
                                        null &&
                                    (previousDateTime == null ||
                                        !_isSameCalendarDate(
                                            previousDateTime, currentDateTime));

                                final double topSpacing;
                                if (index == 0 || showDateSection) {
                                  topSpacing = 0;
                                } else if (sameSenderAsPrevious) {
                                  topSpacing = 2;
                                } else {
                                  topSpacing = 8;
                                }

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (showDateSection)
                                      _dateSeparator(
                                          _dayLabel(currentDateTime)),
                                    SizedBox(height: topSpacing),
                                    _messageBubble(
                                      message,
                                      timestamp: currentDateTime,
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                    _inputArea(),
                  ],
                ),
    );
  }
}
