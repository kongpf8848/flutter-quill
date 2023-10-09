import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;

class TimeStampEmbed extends Embeddable {
  const TimeStampEmbed(
    dynamic value,
  ) : super(timeStampType, value);

  static const String timeStampType = 'mention';

  static TimeStampEmbed fromDocument(Document document) =>
      TimeStampEmbed(jsonEncode(document.toDelta().toJson()));

  Document get document => Document.fromJson(jsonDecode(data));
}

class TimeStampEmbedBuilderWidget extends EmbedBuilder {
  @override
  String get key => 'mention';

  @override
  String toPlainText(Embed embed) {
    return embed.value.data;
  }

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    return Text((node.value.data as Map)['name']);
  }
}
