import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/folder_model.dart';
import '../models/card_model.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Folder> _folders = [];
  Map<int, int> _cardCounts = {};
  Map<int, CardModel?> _firstCards = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
    });

    final folders = await _dbHelper.getAllFolders();
    final Map<int, int> cardCounts = {};
    final Map<int, CardModel?> firstCards = {};

    for (var folder in folders) {
      final count = await _dbHelper.getCardCountInFolder(folder.id!);
      cardCounts[folder.id!] = count;

      final cardsInFolder = await _dbHelper.getCardsInFolder(folder.id!);
      firstCards[folder.id!] = cardsInFolder.isNotEmpty ? cardsInFolder.first : null;
    }

    setState(() {
      _folders = folders;
      _cardCounts = cardCounts;
      _firstCards = firstCards;
      _isLoading = false;
    });
  }

  String _getFolderIcon(String folderName) {
    switch (folderName) {
      case 'Hearts':
        return '♥️';
      case 'Spades':
        return '♠️';
      case 'Diamonds':
        return '♦️';
      case 'Clubs':
        return '♣️';
      default:
        return '📁';
    }
  }

  Color _getFolderColor(String folderName) {
    switch (folderName) {
      case 'Hearts':
        return Colors.red;
      case 'Spades':
        return Colors.black;
      case 'Diamonds':
        return Colors.red;
      case 'Clubs':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Organizer'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFolders,
              child: _folders.isEmpty
                  ? const Center(
                      child: Text(
                        'No folders available',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _folders.length,
                      itemBuilder: (context, index) {
                        final folder = _folders[index];
                        final cardCount = _cardCounts[folder.id] ?? 0;
                        final firstCard = _firstCards[folder.id];

                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CardsScreen(folder: folder),
                              ),
                            );
                            _loadFolders();
                          },
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Preview Image
                                Container(
                                  height: 120,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: firstCard != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            firstCard.imageUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Text(
                                                  _getFolderIcon(folder.name),
                                                  style: const TextStyle(fontSize: 48),
                                                ),
                                              );
                                            },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(
                                                child: CircularProgressIndicator(),
                                              );
                                            },
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            _getFolderIcon(folder.name),
                                            style: const TextStyle(fontSize: 48),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 12),
                                // Folder Name
                                Text(
                                  folder.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getFolderColor(folder.name),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Card Count
                                Text(
                                  '$cardCount card${cardCount != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}