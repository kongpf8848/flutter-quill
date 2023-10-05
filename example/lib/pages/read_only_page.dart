// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/extensions.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

import '../universal_ui/universal_ui.dart';
import '../widgets/demo_scaffold.dart';

class ReadOnlyPage extends StatefulWidget {
  @override
  _ReadOnlyPageState createState() => _ReadOnlyPageState();
}

class _ReadOnlyPageState extends State<ReadOnlyPage> {
  final FocusNode _focusNode = FocusNode();

  bool _edit = false;
  QuillEditor? quillEditor;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      documentFilename: isDesktop() ? 'assets/test.json' : 'test.json',
      builder: _buildContent,
      showToolbar: _edit == true,
      floatingActionButton: FloatingActionButton.extended(
          label: Text(_edit == true ? 'Done' : 'Edit'),
          onPressed: _toggleEdit,
          icon: Icon(_edit == true ? Icons.check : Icons.edit)),
    );
  }

  Widget _buildContent(BuildContext context, QuillController? controller) {
    quillEditor = QuillEditor(
      controller: controller!,
      scrollController: ScrollController(),
      scrollable: true,
      focusNode: _focusNode,
      autoFocus: true,
      readOnly: !_edit,
      expands: false,
      padding: EdgeInsets.zero,
      embedBuilders: FlutterQuillEmbeds.builders(),
    );
    if (kIsWeb) {
      quillEditor = QuillEditor(
          controller: controller,
          scrollController: ScrollController(),
          scrollable: true,
          focusNode: _focusNode,
          autoFocus: true,
          readOnly: !_edit,
          expands: false,
          padding: EdgeInsets.zero,
          embedBuilders: defaultEmbedBuildersWeb);
    }
    final toolbar = QuillToolbar.basic(
      controller: controller,
      showSuperscript: false,
      showSubscript: false,
      //embedButtons: FlutterQuillEmbeds.buttons(),
      customButtons: [
        QuillCustomButton(
            icon: Icons.ac_unit,
            tooltip: '雪花',
            onTap: () {
              debugPrint('snowflake');
            })
      ],
    );
    return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_edit) toolbar,
            Expanded(
                child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: quillEditor,
            ))
          ],
        ));
  }

  void _toggleEdit() {
    final delta = quillEditor?.controller.document.toDelta();
    debugPrint('++++++++++++++delta:$delta');
    final json = jsonEncode(delta?.toJson());
    debugPrint('++++++++++++++json:$json');
    setState(() {
      _edit = !_edit;
      if (_edit) {
        quillEditor?.controller.moveCursorToEnd();
      }
    });
  }
}
