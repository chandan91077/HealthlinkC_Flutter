import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalRecordsPage extends StatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  static const List<String> _filters = [
    'All',
    'Lab Reports',
    'Prescriptions',
    'Invoices',
    'Other',
  ];

  bool _isLoading = true;
  bool _isUploading = false;
  String? _error;
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _records = const [];
  List<Map<String, dynamic>> _appointments = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  ApiClient get _api => sl<ApiClient>();

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        _api.get('/api/medical-records'),
        _api.get('/api/appointments'),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _records = _mapList(responses[0].data);
        _appointments = _mapList(responses[1].data);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load medical records.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<Map>().map((item) {
      return item.map((key, val) => MapEntry(key.toString(), val));
    }).toList();
  }

  String _recordTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.contains('invoice') || lower.contains('bill')) {
      return 'Invoices';
    }
    if (lower.contains('prescription') || lower.contains('rx')) {
      return 'Prescriptions';
    }
    if (lower.contains('report') ||
        lower.contains('test') ||
        lower.contains('lab')) {
      return 'Lab Reports';
    }
    return 'Other';
  }

  bool _isImageRecord(Map<String, dynamic> record) {
    final mime = record['mime_type']?.toString().toLowerCase() ?? '';
    if (mime.startsWith('image/')) {
      return true;
    }
    final url = record['file_url']?.toString().toLowerCase() ?? '';
    return url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.webp');
  }

  String _sizeLabel(dynamic bytes) {
    final size = (bytes as num?)?.toDouble() ?? 0;
    if (size <= 0) {
      return 'Unknown size';
    }
    if (size < 1024) {
      return '${size.toStringAsFixed(0)} B';
    }
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _doctorNameFromAppointment(Map<String, dynamic> appointment) {
    final doctor = appointment['doctor_id'];
    if (doctor is Map<String, dynamic>) {
      final user = doctor['user_id'];
      if (user is Map<String, dynamic>) {
        final name = user['full_name']?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          return name.startsWith('Dr.') ? name : 'Dr. $name';
        }
      }
    }
    return 'Doctor';
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_selectedFilter == 'All') {
      return _records;
    }
    return _records
        .where((record) =>
            (record['record_type']?.toString().trim() ?? '') == _selectedFilter)
        .toList();
  }

  List<Map<String, dynamic>> get _shareableAppointments {
    return _appointments.where((appointment) {
      final id = appointment['_id']?.toString() ?? '';
      if (id.isEmpty) {
        return false;
      }
      final chatUnlocked = appointment['chat_unlocked'] == true;
      final status = appointment['status']?.toString() ?? '';
      final validStatus = status != 'cancelled';
      return chatUnlocked && validStatus;
    }).toList();
  }

  Future<void> _uploadRecord() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx'],
    );

    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final file = picked.files.first;
    final filePath = file.path;
    if (filePath == null || !File(filePath).existsSync()) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to access selected file.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final uploadResponse = await _api.dio.post(
        '/api/upload',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(
            filePath,
            filename: file.name,
          ),
        }),
      );

      final fileUrl = uploadResponse.data is Map<String, dynamic>
          ? (uploadResponse.data['fileUrl']?.toString() ?? '')
          : '';

      if (fileUrl.isEmpty) {
        throw Exception('Upload URL missing');
      }

      await _api.post(
        '/api/medical-records',
        data: {
          'file_name': file.name,
          'file_url': fileUrl,
          'mime_type':
              file.extension == null ? '' : _mimeFromExt(file.extension!),
          'file_size': file.size,
          'record_type': _recordTypeFromFileName(file.name),
        },
      );

      await _loadData();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical record uploaded successfully.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload medical record.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _mimeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final id = record['_id']?.toString() ?? '';
    if (id.isEmpty) {
      return;
    }

    try {
      await _api.dio.delete('/api/medical-records/$id');
      await _loadData();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical record deleted.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete record.')),
      );
    }
  }

  Future<void> _shareRecord(Map<String, dynamic> record) async {
    final appointments = _shareableAppointments;
    if (appointments.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Chat is not enabled yet by any doctor for your appointments.'),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: appointments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final doctorName = _doctorNameFromAppointment(appointment);
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person_outline),
                ),
                title: Text(doctorName),
                subtitle: Text(
                  '${appointment['appointment_date'] ?? '-'} • ${appointment['appointment_time'] ?? '-'}',
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _sendRecordToChat(record, appointment);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _sendRecordToChat(
    Map<String, dynamic> record,
    Map<String, dynamic> appointment,
  ) async {
    final appointmentId = appointment['_id']?.toString() ?? '';
    final fileUrl = record['file_url']?.toString() ?? '';
    final fileName = record['file_name']?.toString() ?? 'Medical record';

    if (appointmentId.isEmpty || fileUrl.isEmpty) {
      return;
    }

    try {
      await _api.post(
        '/api/messages',
        data: {
          'appointment_id': appointmentId,
          'content': 'Shared medical record: $fileName',
          'file_url': fileUrl,
          'message_type': _isImageRecord(record) ? 'image' : 'file',
        },
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record shared in chat successfully.')),
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response?.data['message']?.toString() ??
              'Failed to share record in chat.')
          : 'Failed to share record in chat.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share record in chat.')),
      );
    }
  }

  Future<void> _viewRecord(Map<String, dynamic> record) async {
    final fileUrl = record['file_url']?.toString() ?? '';
    final title = record['file_name']?.toString() ?? 'Medical Record';

    if (fileUrl.isEmpty) {
      return;
    }

    if (_isImageRecord(record)) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.network(
                      fileUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Unable to preview this image.'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Document preview is available in chat after sharing with doctor.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  fileUrl,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(fileUrl);
                    if (uri == null) {
                      return;
                    }
                    final launched = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!launched && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Unable to open this document.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Document'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Medical Records'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filters
                  .map((label) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(label),
                          selected: _selectedFilter == label,
                          onSelected: (_) {
                            setState(() {
                              _selectedFilter = label;
                            });
                          },
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _selectedFilter == label
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: _filteredRecords.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 100),
                                  Center(
                                      child: Text(
                                          'No medical records uploaded yet.')),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                itemCount: _filteredRecords.length,
                                itemBuilder: (context, index) {
                                  final record = _filteredRecords[index];
                                  final name =
                                      record['file_name']?.toString() ??
                                          'Medical Record';
                                  final type =
                                      record['record_type']?.toString() ??
                                          'Other';
                                  final sizeText =
                                      _sizeLabel(record['file_size']);
                                  final isImage = _isImageRecord(record);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isImage
                                              ? Icons.image_outlined
                                              : Icons.picture_as_pdf,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      title: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text('$type • $sizeText'),
                                      trailing: PopupMenuButton<String>(
                                        itemBuilder: (context) => const [
                                          PopupMenuItem<String>(
                                            value: 'view',
                                            child: Text('View File'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'share',
                                            child: Text('Share with Doctor'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Text(
                                              'Delete',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'view') {
                                            _viewRecord(record);
                                          } else if (value == 'share') {
                                            _shareRecord(record);
                                          } else if (value == 'delete') {
                                            _deleteRecord(record);
                                          }
                                        },
                                      ),
                                      onTap: () => _viewRecord(record),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadRecord,
        backgroundColor: AppColors.primary,
        icon: _isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.upload_file, color: Colors.white),
        label: Text(
          _isUploading ? 'Uploading...' : 'Upload Medical Records',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
