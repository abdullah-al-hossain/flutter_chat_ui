import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: ChatPage(),
      );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  final _user = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
  );

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);
  }

  void _loadMessages() async {
    final response = await rootBundle.loadString('assets/messages.json');
    final messages = (jsonDecode(response) as List)
        .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _messages = messages;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Chat(
          messages: _messages,
          onAttachmentPressed: _handleAttachmentPressed,
          onMessageTap: _handleMessageTap,
          onPreviewDataFetched: _handlePreviewDataFetched,
          onSendPressed: _handleSendPressed,
          showUserAvatars: true,
          showUserNames: true,
          user: _user,
          l10n: const ChatL10nEn(
            inputPlaceholder: 'Write a message',
          ),
          theme: DefaultChatTheme(
            // ignore: use_named_constants
            inputMargin: const EdgeInsets.symmetric(vertical: 0),
            msgPlaceholderTextColor: SGColors.blackShade3,
            inputTextFieldBGColor: SGColors.whiteShade1,
            sendButtonMargin: EdgeInsets.zero,
            attachmentButtonIcon: const Icon(
              Icons.attach_file,
              color: SGColors.primaryBlue,
            ),
            attachmentButtonMargin: const EdgeInsets.only(
              right: 8,
            ),
            showSendButtonAsSuffixIcon: true,
            sendButtonIcon: SvgPicture.asset('assets/send.svg'),
            primaryColor: SGColors.primaryBlue,
            inputTextCursorColor: SGColors.blackShade2,
            inputBorderRadius: BorderRadius.zero,
            inputTextColor: SGColors.black,
            messageBorderRadius: 8.0,
            attachmentBorderRadius: 8.0,
            inputFieldBorderRadius: 8.0,
            dateDividerTextStyle:
                SGTextStyles.pro10.copyWith(color: SGColors.blackShade2),

            sentMessageBodyTextStyle:
                SGTextStyles.pro14w400.copyWith(color: Colors.white),
            receivedMessageBodyTextStyle: SGTextStyles.pro14w400,
            inputTextStyle: SGTextStyles.pro14w400,
            inputBackgroundColor: SGColors.white,
            inputContainerDecoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 1.0,
                  color: SGColors.whiteShade2,
                ),
              ),
            ),
          ),
        ),
      );
}

class SGColors {
  SGColors._();

  static const Color primaryBlue = Color(0xff0044cc);
  static const Color black = Color(0xff181c23);
  static const Color blackShade1 = Color(0xff3f4755);
  static const Color blackShade2 = Color(0xff70798a);
  static const Color blackShade3 = Color(0xff979faf);
  static const Color whiteShade3 = Color(0xffc1c7d2);
  static const Color whiteShade1 = Color(0xfff5f6f8);
  static const Color whiteShade2 = Color(0xffe6e8ed);
  static const Color white = Color(0xffffffff);
}

class SGTextStyles {
  SGTextStyles._();

  static TextStyle get headline2 => display32;
  static TextStyle get headline3 => display24w600;
  static TextStyle get headline4 => display20w600;
  static TextStyle get headline5 => display20;
  static TextStyle get subtitle1 => pro16w600;
  static TextStyle get subtitle2 => pro14w600;
  static TextStyle get body1 => pro16;
  static TextStyle get body2 => pro14;
  static TextStyle get more1 => pro12;
  static TextStyle get more2 => pro10;
  static TextStyle get more3 => pro10w500;

  // Defined Text Styles.
  static TextStyle get display48 => const TextStyle(
        fontSize: 48,
        fontFamily: 'SFProDisplay',
      );

  static TextStyle get pro14 => const TextStyle(
        fontFamily: 'SFProText',
        fontSize: 14,
      );
  static TextStyle get pro14w400 => const TextStyle(
        fontFamily: 'SFProText',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );
  static TextStyle get pro14w600 => const TextStyle(
        fontFamily: 'SFProText',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get pro12 => const TextStyle(
        fontFamily: 'SFProText',
        fontSize: 12,
      );
  static TextStyle get pro16w400 => const TextStyle(
        fontSize: 16,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w400,
      );
  static TextStyle get pro16w600 => const TextStyle(
        fontSize: 16,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w600,
      );
  static TextStyle get pro16w800 => const TextStyle(
        fontSize: 16,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w800,
      );
  static TextStyle get pro10w500 => const TextStyle(
        fontSize: 10,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w500,
      );

  static TextStyle get pro16 => const TextStyle(
        fontSize: 16,
        fontFamily: 'SFProText',
      );

  static TextStyle get pro32w600 => const TextStyle(
        fontSize: 32,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w600,
      );

  static TextStyle get display24w600 => const TextStyle(
        fontSize: 24,
        fontFamily: 'SFProDisplay',
        fontWeight: FontWeight.w600,
      );
  static TextStyle get display24w700italic => const TextStyle(
        fontSize: 24,
        fontFamily: 'SFProDisplay',
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
      );

  static TextStyle get display20w600 => const TextStyle(
        fontSize: 20,
        fontFamily: 'SFProDisplay',
        fontWeight: FontWeight.w600,
      );

  static TextStyle get display20 => const TextStyle(
        fontSize: 20,
        fontFamily: 'SFProDisplay',
      );

  static TextStyle get display16 => const TextStyle(
        fontSize: 16,
        fontFamily: 'SFProDisplay',
      );

  static TextStyle get display14w600 => const TextStyle(
        fontSize: 14,
        fontFamily: 'SFProDisplay',
        fontWeight: FontWeight.w600,
      );

  static TextStyle get display10 => const TextStyle(
        fontSize: 10,
        fontFamily: 'SFProDisplay',
      );
  static TextStyle get pro10 => const TextStyle(
        fontSize: 10,
        fontFamily: 'SFProText',
      );

  static TextStyle get pro17 => const TextStyle(
        fontSize: 17,
        fontFamily: 'SFProText',
      );

  static TextStyle get pro12w600 => const TextStyle(
        fontFamily: 'SFProText',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get pro12w400 => const TextStyle(
        fontFamily: 'SFProText',
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get pro24w600 => const TextStyle(
        fontFamily: 'SFProText',
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get display32w600 => const TextStyle(
        fontSize: 32,
        fontFamily: 'SFProDisplay',
        fontWeight: FontWeight.w600,
      );

  static TextStyle get display32 => const TextStyle(
        fontSize: 32,
        fontFamily: 'SFProDisplay',
      );

  static TextStyle get display24 => const TextStyle(
        fontSize: 24,
        fontFamily: 'SFProDisplay',
      );

  static TextStyle get display16w600 => const TextStyle(
        fontSize: 16,
        fontFamily: 'SFProDisplay',
        fontWeight: FontWeight.w600,
      );
  static TextStyle get display18w600 => const TextStyle(
        fontSize: 18,
        fontFamily: 'SFProDisplay',
        fontWeight: FontWeight.w600,
      );

  static TextStyle get display12 => const TextStyle(
        fontSize: 12,
        fontFamily: 'SFProDisplay',
      );

  static TextStyle get display12w600 => const TextStyle(
        fontSize: 12,
        fontFamily: 'SFProDisplay',
        fontWeight: FontWeight.w600,
      );

  static TextStyle get pro23w600 => const TextStyle(
        fontSize: 23,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w600,
      );

  static TextStyle get pro14w500 => const TextStyle(
        fontFamily: 'SFProText',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get pro16w700Italic => const TextStyle(
        fontSize: 16,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
      );

  static TextStyle get display14w500 => const TextStyle(
        fontSize: 14,
        fontFamily: 'SFProDisplay',
        fontWeight: FontWeight.w500,
      );

  static TextStyle get pro10w700 => const TextStyle(
        fontSize: 10,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w700,
      );

  static TextStyle get pro14w700 => const TextStyle(
        fontSize: 14,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w700,
      );

  static TextStyle get pro20w700 => const TextStyle(
        fontSize: 20,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w700,
      );

  static TextStyle get pro20w600 => const TextStyle(
        fontSize: 20,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w600,
      );

  static TextStyle get pro16w700 => const TextStyle(
        fontSize: 16,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w700,
      );

  static TextStyle get pro12w500 => const TextStyle(
        fontFamily: 'SFProText',
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get display14 => const TextStyle(
        fontFamily: 'SFProText',
        fontSize: 14,
      );

  static TextStyle get pro20w500 => const TextStyle(
        fontSize: 20,
        fontFamily: 'SFProText',
        fontWeight: FontWeight.w500,
      );
  static TextStyle get pro20 => const TextStyle(
        fontSize: 20,
        fontFamily: 'SFProText',
      );
}

class SGSpacing {
  SGSpacing._();

  static SizedBox sb2 = SizedBox(width: 2.sp, height: 2.sp);
  static SizedBox sb4 = SizedBox(width: 4.sp, height: 4.sp);
  static SizedBox sb6 = SizedBox(width: 6.sp, height: 6.sp);
  static SizedBox sb8 = SizedBox(width: 8.sp, height: 8.sp);
  static SizedBox sb12 = SizedBox(width: 12.sp, height: 12.sp);
  static SizedBox sb16 = SizedBox(width: 16.sp, height: 16.sp);
  static SizedBox sb20 = SizedBox(width: 20.sp, height: 20.sp);
  static SizedBox sb24 = SizedBox(width: 24.sp, height: 24.sp);
  static SizedBox sb28 = SizedBox(width: 28.sp, height: 28.sp);
  static SizedBox sb32 = SizedBox(width: 32.sp, height: 32.sp);
  static SizedBox sb64 = SizedBox(width: 64.sp, height: 64.sp);
  static SizedBox sb48 = SizedBox(width: 48.sp, height: 48.sp);
  static SizedBox sb100 = SizedBox(width: 100.sp, height: 100.sp);

  static const double xsmall = 2;
  static const double small = 4;
  static const double smallmedium = 6;
  static const double medium = 8;
  static const double large = 12;
  static const double xlarge = 16;
  static const double xlarge2 = 20;
  static const double xxlarge = 24;
  static const double xxxlarge = 32;

  static const double elevation = 12;
  static const double cardRadius = 12;
  static const double blurRadius = 8;
}
