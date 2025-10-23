import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cross-platform share/copy helpers with graceful fallbacks.
///
/// For now, we only implement clipboard copy with a SnackBar confirmation.
/// We can later extend [shareOrCopy] to use share sheets (e.g., share_plus)
/// when the dependency is added. Keeping a single entrypoint simplifies
/// swapping out behavior across the app.
class ShareUtils {
  /// Copies [text] to clipboard and shows a SnackBar with [message].
  static Future<void> copyToClipboard(
    BuildContext context,
    String text, {
    String? message,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnack(context, message ?? 'Vágólapra másolva.');
  }

  /// Convenience for copying links with a default localized message.
  static Future<void> copyLink(
    BuildContext context,
    String link, {
    String? message,
  }) async {
    await copyToClipboard(
      context,
      link,
      message: message ?? 'Link vágólapra másolva.',
    );
  }

  /// Attempts to share the [text] using platform share sheets if available;
  /// falls back to copying to the clipboard.
  ///
  /// Note: App currently doesn't include a share plugin. This method provides
  /// a single callsite to upgrade behavior later without changing callers.
  static Future<void> shareOrCopy(
    BuildContext context,
    String text, {
    String? subject,
    String? copyMessage,
  }) async {
    // TODO: Integrate share_plus to show native share sheets when available.
    // For now, just copy and inform the user.
    await copyToClipboard(
      context,
      text,
      message: copyMessage ?? 'Vágólapra másolva.',
    );
  }

  static void _showSnack(BuildContext context, String message) {
    // Use mounted ScaffoldMessenger if possible
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
