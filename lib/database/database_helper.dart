import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/folder_model.dart';
import '../models/card_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Folders table
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Create Cards table
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        folderId INTEGER,
        FOREIGN KEY (folderId) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');

    // Prepopulate Folders table with the four suits
    await db.insert('folders', {
      'name': 'Hearts',
      'timestamp': DateTime.now().toIso8601String(),
    });
    await db.insert('folders', {
      'name': 'Spades',
      'timestamp': DateTime.now().toIso8601String(),
    });
    await db.insert('folders', {
      'name': 'Diamonds',
      'timestamp': DateTime.now().toIso8601String(),
    });
    await db.insert('folders', {
      'name': 'Clubs',
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Prepopulate Cards table with all standard cards (1-13 for each suit)
    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    final cardNames = [
      'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'
    ];

    for (var suit in suits) {
      for (int i = 0; i < cardNames.length; i++) {
        await db.insert('cards', {
          'name': '${cardNames[i]} of $suit',
          'suit': suit,
          'imageUrl': 'https://deckofcardsapi.com/static/img/${_getCardCode(cardNames[i], suit)}.png',
          'folderId': null,
        });
      }
    }
  }

  String _getCardCode(String cardName, String suit) {
    String value;
    switch (cardName) {
      case 'Ace':
        value = 'A';
        break;
      case 'Jack':
        value = 'J';
        break;
      case 'Queen':
        value = 'Q';
        break;
      case 'King':
        value = 'K';
        break;
      default:
        value = cardName;
    }

    String suitCode;
    switch (suit) {
      case 'Hearts':
        suitCode = 'H';
        break;
      case 'Spades':
        suitCode = 'S';
        break;
      case 'Diamonds':
        suitCode = 'D';
        break;
      case 'Clubs':
        suitCode = 'C';
        break;
      default:
        suitCode = 'S';
    }

    return '$value$suitCode';
  }

  // Folder CRUD operations
  Future<List<Folder>> getAllFolders() async {
    final db = await database;
    final result = await db.query('folders');
    return result.map((map) => Folder.fromMap(map)).toList();
  }

  Future<Folder> getFolder(int id) async {
    final db = await database;
    final maps = await db.query(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Folder.fromMap(maps.first);
    } else {
      throw Exception('Folder not found');
    }
  }

  Future<int> insertFolder(Folder folder) async {
    final db = await database;
    return await db.insert('folders', folder.toMap());
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await database;
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Card CRUD operations
  Future<List<CardModel>> getAllCards() async {
    final db = await database;
    final result = await db.query('cards');
    return result.map((map) => CardModel.fromMap(map)).toList();
  }

  Future<List<CardModel>> getCardsInFolder(int folderId) async {
    final db = await database;
    final result = await db.query(
      'cards',
      where: 'folderId = ?',
      whereArgs: [folderId],
    );
    return result.map((map) => CardModel.fromMap(map)).toList();
  }

  Future<List<CardModel>> getUnassignedCards() async {
    final db = await database;
    final result = await db.query(
      'cards',
      where: 'folderId IS NULL',
    );
    return result.map((map) => CardModel.fromMap(map)).toList();
  }

  Future<int> getCardCountInFolder(int folderId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cards WHERE folderId = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> insertCard(CardModel card) async {
    final db = await database;
    return await db.insert('cards', card.toMap());
  }

  Future<int> updateCard(CardModel card) async {
    final db = await database;
    return await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(int id) async {
    final db = await database;
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}