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

  Future<void> _deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          'Are you sure you want to delete "${folder.name}" folder and all its cards? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteFolder(folder.id!);
      _loadFolders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${folder.name} folder deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showEditFolderDialog(Folder folder) {
    final nameController = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updatedFolder = Folder(
                id: folder.id,
                name: nameController.text,
                timestamp: folder.timestamp,
              );
              await _dbHelper.updateFolder(updatedFolder);
              await _loadFolders();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Folder renamed'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddFolderDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                return;
              }
              final newFolder = Folder(
                name: nameController.text.trim(),
              );
              await _dbHelper.insertFolder(newFolder);
              await _loadFolders();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Folder added'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Organizer'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFolderDialog,
            tooltip: 'Add Folder',
          ),
        ],
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
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.edit, color: Colors.blue),
                                      title: const Text('Rename Folder'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showEditFolderDialog(folder);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red),
                                      title: const Text('Delete Folder'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _deleteFolder(folder);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                Column(
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
                                    // Folder Name with Edit Icon
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            folder.name,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: _getFolderColor(folder.name),
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => _showEditFolderDialog(folder),
                                          child: Icon(
                                            Icons.edit,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
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
                                // Delete button in top-right corner
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    color: Colors.red,
                                    onPressed: () => _deleteFolder(folder),
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