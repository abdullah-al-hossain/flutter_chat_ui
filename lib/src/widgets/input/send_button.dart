import 'package:flutter/material.dart';

import '../state/inherited_chat_theme.dart';
import '../state/inherited_l10n.dart';

/// A class that represents send button widget.
class SendButton extends StatelessWidget {
  /// Creates send button widget.
  const SendButton({
    super.key,
    required this.onPressed,
    this.padding = EdgeInsets.zero,
  });

  /// Callback for send button tap event.
  final VoidCallback onPressed;

  /// Padding around the button.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        child: Semantics(
          label: InheritedL10n.of(context).l10n.sendButtonAccessibilityLabel,
          child: IconButton(
            icon: InheritedChatTheme.of(context).theme.sendButtonIcon ??
                Image.asset(
                  'assets/icon-send.png',
                  color: InheritedChatTheme.of(context).theme.inputTextColor,
                  package: 'flutter_chat_ui',
                ),
            onPressed: onPressed,
            padding: EdgeInsets.only(right: 0),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            tooltip:
                InheritedL10n.of(context).l10n.sendButtonAccessibilityLabel,
          ),
        ),
      );
}
