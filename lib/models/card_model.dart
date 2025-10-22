class CardModel {
  final int? id;
  final String name;
  final String suit;
  final String imageUrl;
  final int? folderId;

  CardModel({
    this.id,
    required this.name,
    required this.suit,
    required this.imageUrl,
    this.folderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'suit': suit,
      'imageUrl': imageUrl,
      'folderId': folderId,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      suit: map['suit'] as String,
      imageUrl: map['imageUrl'] as String,
      folderId: map['folderId'] as int?,
    );
  }
}