import 'package:url_launcher/url_launcher.dart';

class EmailService {
  static final EmailService instance = EmailService._internal();
  EmailService._internal();

  // ─────────────────────────────────────────────
  // Send Group Invite Email
  // ─────────────────────────────────────────────

  Future<bool> sendGroupInviteEmail({
    required String toEmail,
    required String groupName,
    required String inviteCode,
  }) async {
    final subject = 'You are invited to join $groupName on Flowva!';
    final body = '''
Hi there!

You have been invited to join the group "$groupName" on Flowva.

Use this invite code to join: $inviteCode

Download Flowva and enter the code to get started.

See you inside!
The Flowva Team
    ''';

    final uri = Uri(
      scheme: 'mailto',
      path: toEmail,
      query: _encodeQueryParameters({
        'subject': subject,
        'body': body,
      }),
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Helper
  // ─────────────────────────────────────────────

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}