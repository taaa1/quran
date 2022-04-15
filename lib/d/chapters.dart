class Chapters {
  final List<Chapter> chapters;

  const Chapters({required this.chapters});

  factory Chapters.fromJson(Map<String, dynamic> json) {
    return Chapters(chapters: json['chapters'].map<Chapter>((v) => Chapter.fromJson(v)).toList());
  }
}

class Chapter {
  final String arabic;
  final String latin;
  final int id;

  const Chapter({required this.arabic, required this.latin, required this.id});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(arabic: json['name_arabic'], latin: json['name_simple'], id: json['id']);
  }
}