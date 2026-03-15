import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openExternalLink(
  BuildContext context,
  String rawUrl, {
  String invalidMessage = 'Invalid link.',
  String failureMessage = 'Unable to open link.',
}) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(invalidMessage)),
    );
    return;
  }

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failureMessage)),
    );
  }
}
