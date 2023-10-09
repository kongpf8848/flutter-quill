class MentionInfo {
  MentionInfo({this.id, this.index, this.denotationChar, this.value});

  MentionInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    index = json['name'];
    denotationChar = json['denotationChar'];
    value = json['value'];
  }

  String? id;
  String? index;
  String? denotationChar;
  String? value;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['index'] = index;
    data['denotationChar'] = denotationChar;
    data['value'] = value;
    return data;
  }

  static List<MentionInfo> fromJsonList(dynamic jsonList) {
    final contentList = <MentionInfo>[];
    for (final item in jsonList) {
      contentList.add(MentionInfo.fromJson(item));
    }
    return contentList;
  }
}
