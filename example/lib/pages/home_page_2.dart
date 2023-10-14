import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:intl/intl.dart' as intl;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../models/at_mention_search_response_bean.dart';
import '../models/hash_tag_search_response_bean.dart';
import '../universal_ui/universal_ui.dart';
import 'read_only_page.dart';

class HomePage2 extends StatefulWidget {
  @override
  _HomePage2State createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2> {
  QuillController? _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditorLTR = true;
  String? _taggingCharector = '#';
  OverlayEntry? _hashTagOverlayEntry;
  int? lastHashTagIndex = -1;
  BuildContext? _mainContext;
  ValueNotifier<List<HashTagSearchResponseBean>> hashTagWordList =
      ValueNotifier([]);
  ValueNotifier<List<AtMentionSearchResponseBean>> atMentionSearchList =
      ValueNotifier([]);

  final _tempHashTagList = [
    HashTagSearchResponseBean(name: 'Decoration'),
    HashTagSearchResponseBean(name: 'Technology'),
    HashTagSearchResponseBean(name: 'Computer Science'),
    HashTagSearchResponseBean(name: 'Terminator'),
    HashTagSearchResponseBean(name: 'Dead Pool'),
    HashTagSearchResponseBean(name: 'Dance class'),
    HashTagSearchResponseBean(name: 'Climate change'),
    HashTagSearchResponseBean(name: 'Earth Day')
  ];

  final _tempAtMentionList = [
    AtMentionSearchResponseBean(
        firstName: 'Tom', userName: 'tom123', id: '80935823948569'),
    AtMentionSearchResponseBean(
        firstName: 'Jeck', userName: 'jack', id: '80935823948569'),
    AtMentionSearchResponseBean(
        firstName: 'Mical', userName: 'mical_mishra', id: '80935823948569'),
    AtMentionSearchResponseBean(
        firstName: 'Obama', userName: 'obama_fans', id: '80935823948569'),
    AtMentionSearchResponseBean(
        firstName: 'Putin', userName: 'putin', id: '80935823948569'),
    AtMentionSearchResponseBean(
        firstName: 'Modi', userName: 'modi', id: '80935823948569'),
    AtMentionSearchResponseBean(
        firstName: 'Targen', userName: 'targen', id: '80935823948569'),
    AtMentionSearchResponseBean(
        firstName: 'Tommy', userName: 'tomi_', id: '80935823948569'),
  ];

  @override
  void initState() {
    super.initState();
    _loadFromAssets();
  }

  void _refreshScreen() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadFromAssets() async {
    try {
      // final result = await rootBundle.loadString('assets/sample_data.json');
      // final doc = Document.fromJson(jsonDecode(result));
      final doc = Document()..insert(0, 'Enter your data');
      setState(() {
        _controller = QuillController(
            document: doc, selection: const TextSelection.collapsed(offset: 0));
      });
    } catch (error) {
      final doc = Document()..insert(0, 'Empty asset');
      setState(() {
        _controller = QuillController(
            document: doc, selection: const TextSelection.collapsed(offset: 0));
      });
    }
    _controller!.addListener(editorListener);
    _focusNode.addListener(_advanceTextFocusListener);
  }

  void editorListener() {
    try {
      final index = _controller!.selection.baseOffset;
      final value = _controller!.plainTextEditingValue.text;
      if (value.trim().isNotEmpty) {
        final newString = value.substring(index - 1, index);

        /// check text directionality
        if (newString != ' ' && newString != '\n') {
          _checkEditorTextDirection(newString);
        }
        if (newString == '\n') {
          _isEditorLTR = true;
        }

        if (newString == '#') {
          _taggingCharector = '#';
          if (_hashTagOverlayEntry == null &&
              !(_hashTagOverlayEntry?.mounted ?? false)) {
            lastHashTagIndex = _controller!.selection.baseOffset;
            _hashTagOverlayEntry = _createHashTagOverlayEntry();
            Overlay.of(_mainContext!).insert(_hashTagOverlayEntry!);
          }
        }

        if (newString == '@') {
          _taggingCharector = '@';
          if (_hashTagOverlayEntry == null &&
              !(_hashTagOverlayEntry?.mounted ?? false)) {
            lastHashTagIndex = _controller!.selection.baseOffset;
            _hashTagOverlayEntry = _createHashTagOverlayEntry();
            Overlay.of(_mainContext!).insert(_hashTagOverlayEntry!);
          }
        }

        /// Add #tag without selecting from suggestion
        if ((newString == ' ' || newString == '\n') &&
            _hashTagOverlayEntry != null &&
            _hashTagOverlayEntry!.mounted) {
          _removeOverLay();
          if (lastHashTagIndex != -1 && index > lastHashTagIndex!) {
            final newWord = value.substring(lastHashTagIndex!, index);
            _onTapOverLaySuggestionItem(newWord.trim());
          }
        }

        /// Show overlay when #tag detect and filter it's list
        if (lastHashTagIndex != -1 &&
            _hashTagOverlayEntry != null &&
            (_hashTagOverlayEntry?.mounted ?? false)) {
          final newWord = value
              .substring(lastHashTagIndex!, value.length)
              .replaceAll('\n', '');
          if (_taggingCharector == '#') {
            _getHashTagSearchList(newWord.toLowerCase());
          }

          if (_taggingCharector == '@') {
            _getAtMentionSearchList(newWord.toLowerCase());
          }
        }
      }
    } catch (e) {
      print('Exception in catching last charector : $e');
    }
  }

  void _checkEditorTextDirection(String text) {
    try {
      final _isRTL = intl.Bidi.detectRtlDirectionality(text);
      final style = _controller!.getSelectionStyle();
      final attribute = style.attributes[Attribute.align.key];
      // print(attribute);
      if (_isEditorLTR) {
        if (_isEditorLTR != !_isRTL) {
          if (_isRTL) {
            _isEditorLTR = false;
            _controller!
                .formatSelection(Attribute.clone(Attribute.align, null));
            _controller!.formatSelection(Attribute.rightAlignment);
            _refreshScreen();
          } else {
            final validCharacters = RegExp(r'^[a-zA-Z]+$');
            if (validCharacters.hasMatch(text)) {
              _isEditorLTR = true;
              _controller!
                  .formatSelection(Attribute.clone(Attribute.align, null));
              _controller!.formatSelection(Attribute.leftAlignment);
              _refreshScreen();
            }
          }
        } else {
          if (attribute == null && _isRTL) {
            _isEditorLTR = false;
            _controller!
                .formatSelection(Attribute.clone(Attribute.align, null));
            _controller!.formatSelection(Attribute.rightAlignment);
            _refreshScreen();
          } else if (attribute == Attribute.rightAlignment && !_isRTL) {
            final validCharacters = RegExp(r'^[a-zA-Z]+$');
            if (validCharacters.hasMatch(text)) {
              _isEditorLTR = true;
              _controller!
                  .formatSelection(Attribute.clone(Attribute.align, null));
              _controller!.formatSelection(Attribute.leftAlignment);
              _refreshScreen();
            }
          }
        }
      }
    } catch (e) {
      print('Exception in _checkEditorTextDirection : $e');
    }
  }

  OverlayEntry _createHashTagOverlayEntry() {
    return OverlayEntry(
        builder: (context) => Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              width: MediaQuery.of(context).size.width,
              // height: 150,
              child: Material(
                elevation: 4,
                child: Container(
                  constraints:
                      const BoxConstraints(maxHeight: 150, minHeight: 50),
                  child: _taggingCharector == '#'
                      ? ValueListenableBuilder(
                          valueListenable: hashTagWordList,
                          builder: (context, value, child) {
                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount:
                                  (value as List<HashTagSearchResponseBean>)
                                      .length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    _onTapOverLaySuggestionItem(
                                        value[index].name!);
                                  },
                                  child: ListTile(
                                    title: Text(value[index].name!),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : ValueListenableBuilder(
                          valueListenable: atMentionSearchList,
                          builder: (context, value, child) {
                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount:
                                  (value as List<AtMentionSearchResponseBean>)
                                      .length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                final data = value[index];
                                return GestureDetector(
                                  onTap: () {
                                    _onTapOverLaySuggestionItem(data.userName!,
                                        userId: data.userName);
                                  },
                                  child: ListTile(
                                    leading: CachedNetworkImage(
                                      imageUrl: data.pictureLink ?? '',
                                      fit: BoxFit.cover,
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                        height: 30,
                                        width: 30,
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover),
                                            shape: BoxShape.circle),
                                      ),
                                      placeholder: (context, url) => Container(
                                        height: 30,
                                        width: 30,
                                        decoration: const BoxDecoration(
                                            color: Colors.grey,
                                            shape: BoxShape.circle),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        decoration: const BoxDecoration(
                                            color: Colors.grey,
                                            shape: BoxShape.circle),
                                        width: 30,
                                        height: 30,
                                        child: const Icon(
                                          Icons.image_outlined,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    title: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data.firstName!,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(
                                          height: 3,
                                        ),
                                        Text(
                                          '@${data.userName}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ));
  }

  void _removeOverLay() {
    try {
      if (_hashTagOverlayEntry != null && _hashTagOverlayEntry!.mounted) {
        _hashTagOverlayEntry!.remove();
        _hashTagOverlayEntry = null;
        hashTagWordList.value = <HashTagSearchResponseBean>[];
        atMentionSearchList.value = <AtMentionSearchResponseBean>[];
      }
    } catch (e) {
      print('Exception in removing overlay :$e');
    }
  }

  void _onTapOverLaySuggestionItem(String value, {String? userId}) {
    final _lastHashTagIndex = lastHashTagIndex;
    _controller!.replaceText(_lastHashTagIndex!,
        _controller!.selection.extentOffset - _lastHashTagIndex, value, null);
    _controller!.updateSelection(
        TextSelection(
            baseOffset: _lastHashTagIndex - 1,
            extentOffset: _controller!.selection.extentOffset +
                (value.length -
                    (_controller!.selection.extentOffset - _lastHashTagIndex))),
        ChangeSource.LOCAL);
    if (_taggingCharector == '#') {
      /// You can add your own web site
      _controller!.formatSelection(
          LinkAttribute('https://www.google.com/search?q=$value'));
    } else {
      /// You can add your own web site
      _controller!.formatSelection(
          LinkAttribute('https://www.google.com/search?q=$userId'));
      // final cc = <String, dynamic>{'name': 'jack', 'uid': '123456'};
      // _controller?.document.insert(
      //   _controller!.selection.extentOffset,
      //   TimeStampEmbed(cc),
      // );
    }
    Future.delayed(Duration.zero).then((value) {
      _controller!.moveCursorToEnd();
    });
    lastHashTagIndex = -1;
    _controller!.document.insert(_controller!.selection.extentOffset, ' ');
    Future.delayed(const Duration(seconds: 1))
        .then((value) => _removeOverLay());
    hashTagWordList.value = <HashTagSearchResponseBean>[];
    atMentionSearchList.value = <AtMentionSearchResponseBean>[];
  }

  void _advanceTextFocusListener() {
    if (!_focusNode.hasPrimaryFocus) {
      if (_hashTagOverlayEntry != null) {
        if (_hashTagOverlayEntry!.mounted) {
          _removeOverLay();
        }
      }
    }
  }

  Future<void> _getHashTagSearchList(String? query) async {
    /// you can call api here to get the list
    try {
      hashTagWordList.value = _tempHashTagList;
    } catch (e) {
      print('Exception in getHashTagSearchList : $e');
    }
  }

  Future<void> _getAtMentionSearchList(String? query) async {
    /// you can call api here to get the list
    try {
      atMentionSearchList.value = _tempAtMentionList;
    } catch (e) {
      print('Exception in _getAtMentionSearchList : $e');
    }
  }

  @override
  void dispose() {
    _controller!.removeListener(editorListener);
    _focusNode.removeListener(_advanceTextFocusListener);
    _controller!.dispose();
    if (_hashTagOverlayEntry != null) {
      if (_hashTagOverlayEntry!.mounted) {
        _removeOverLay();
      }
      Future.delayed(const Duration(milliseconds: 200)).then((value) {
        _hashTagOverlayEntry!.dispose();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _mainContext = context;
    if (_controller == null) {
      return const Scaffold(body: Center(child: Text('Loading...')));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Flutter Quill',
        ),
        actions: [
          TextButton(
            onPressed: () {
              final json = jsonEncode(_controller!.document.toDelta().toJson());
              debugPrint('+++++++++++++++++++++++json:$json');
            },
            child: const Text(
              'Preview',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          )
        ],
      ),
      drawer: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        color: Colors.grey.shade800,
        child: _buildMenuBar(context),
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event.data.isControlPressed && event.character == 'b') {
            if (_controller!
                .getSelectionStyle()
                .attributes
                .keys
                .contains('bold')) {
              _controller!
                  .formatSelection(Attribute.clone(Attribute.bold, null));
            } else {
              _controller!.formatSelection(Attribute.bold);
            }
          }
        },
        child: _buildWelcomeEditor(context),
      ),
    );
  }

  Widget _buildWelcomeEditor(BuildContext context) {
    final quillEditor = QuillEditor(
      controller: _controller!,
      scrollController: ScrollController(),
      scrollable: true,
      focusNode: _focusNode,
      autoFocus: false,
      readOnly: false,
      placeholder: 'Add content',
      expands: false,
      padding: EdgeInsets.only(bottom: !_focusNode.hasPrimaryFocus ? 10 : 150),
      scrollBottomInset: 150,
    );

    final toolbar = QuillToolbar.basic(
      controller: _controller!,
      // provide a callback to enable picking images from device.
      // if omit, "image" button only allows adding images from url.
      // same goes for videos.
      // uncomment to provide a custom "pick from" dialog.
      // mediaPickSettingSelector: _selectMediaPickSetting,
      showAlignmentButtons: true,
      multiRowsDisplay: false,
    );

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            flex: 15,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: quillEditor,
            ),
          ),
          kIsWeb
              ? Expanded(
                  child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: toolbar,
                ))
              : Container(child: toolbar)
        ],
      ),
    );
  }

  bool _isDesktop() => !kIsWeb && !Platform.isAndroid && !Platform.isIOS;

  Future<String?> openFileSystemPickerForDesktop(BuildContext context) async {
    return await FilesystemPicker.open(
      context: context,
      rootDirectory: await getApplicationDocumentsDirectory(),
      fsType: FilesystemType.file,
      fileTileSelectMode: FileTileSelectMode.wholeTile,
    );
  }

  // Renders the image picked by imagePicker from local file storage
  // You can also upload the picked image to any server (eg : AWS s3
  // or Firebase) and then return the uploaded image URL.
  Future<String> _onImagePickCallback(File file) async {
    // Copies the picked file from temporary cache to applications directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final copiedFile =
        await file.copy('${appDocDir.path}/${basename(file.path)}');
    return copiedFile.path.toString();
  }

  Widget _buildMenuBar(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const itemStyle = TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Divider(
          thickness: 2,
          color: Colors.white,
          indent: size.width * 0.1,
          endIndent: size.width * 0.1,
        ),
        ListTile(
          title: const Center(child: Text('Read only demo', style: itemStyle)),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: _readOnly,
        ),
        Divider(
          thickness: 2,
          color: Colors.white,
          indent: size.width * 0.1,
          endIndent: size.width * 0.1,
        ),
      ],
    );
  }

  void _readOnly() {
    Navigator.push(
      super.context,
      MaterialPageRoute(
        builder: (context) => ReadOnlyPage(),
      ),
    );
  }
}