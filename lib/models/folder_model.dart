class Folder {
  final int? id;
  final String name;
  final String? timestamp;

  Folder({
    this.id,
    required this.name,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'timestamp': timestamp ?? DateTime.now().toIso8601String(),
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as int?,
      name: map['name'] as String,
      timestamp: map['timestamp'] as String?,
    );
  }
}