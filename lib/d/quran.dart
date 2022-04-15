class Quran {
  final List<QuranVal> val;

  const Quran({required this.val});

  factory Quran.fromJson(Map<String, dynamic> json) {
    return Quran(val: json['verses'].map<QuranVal>((v) => QuranVal.fromJson(v)).toList());
  }
}

class QuranVal {
  final String id;
  final String text;
  final int i;

  const QuranVal({required this.id, required this.text, required this.i});

  factory QuranVal.fromJson(Map<String, dynamic> json) {
    return QuranVal(id: json['verse_key'], text: json['text_uthmani'], i: json['id']);
  }
}