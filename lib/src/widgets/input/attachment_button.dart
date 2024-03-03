import 'package:flutter/material.dart';

import '../state/inherited_chat_theme.dart';
import '../state/inherited_l10n.dart';

/// A class that represents attachment button widget.
class AttachmentButton extends StatelessWidget {
  /// Creates attachment button widget.
  const AttachmentButton({
    super.key,
    this.isLoading = false,
    this.onPressed,
    this.padding = EdgeInsets.zero,
  });

  /// Show a loading indicator instead of the button.
  final bool isLoading;

  /// Callback for attachment button tap event.
  final VoidCallback? onPressed;

  /// Padding around the button.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        margin: InheritedChatTheme.of(context).theme.attachmentButtonMargin ??
            const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xfff5f6f8),
            borderRadius: BorderRadius.all(
              Radius.circular(
                InheritedChatTheme.of(context).theme.attachmentBorderRadius,
              ),
            ),
          ),
          margin: const EdgeInsets.only(left: 10),
          height: 40,
          width: 40,
          child: IconButton(
            constraints: const BoxConstraints(
              minHeight: 24,
              minWidth: 24,
            ),
            icon: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.transparent,
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        InheritedChatTheme.of(context).theme.inputTextColor,
                      ),
                    ),
                  )
                : InheritedChatTheme.of(context).theme.attachmentButtonIcon ??
                    Image.asset(
                      'assets/icon-attachment.png',
                      color:
                          InheritedChatTheme.of(context).theme.inputTextColor,
                      package: 'flutter_chat_ui',
                    ),
            onPressed: isLoading ? null : onPressed,
            splashRadius: 2,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            tooltip: InheritedL10n.of(context)
                .l10n
                .attachmentButtonAccessibilityLabel,
          ),
        ),
      );
}
