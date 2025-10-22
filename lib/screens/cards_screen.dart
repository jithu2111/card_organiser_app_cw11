import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/folder_model.dart';
import '../models/card_model.dart';

class CardsScreen extends StatefulWidget {
  final Folder folder;

  const CardsScreen({super.key, required this.folder});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<CardModel> _cardsInFolder = [];
  List<CardModel> _availableCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
    });

    final cardsInFolder = await _dbHelper.getCardsInFolder(widget.folder.id!);
    final unassignedCards = await _dbHelper.getUnassignedCards();

    // Filter unassigned cards to show only cards matching the folder's suit
    final availableCards = unassignedCards
        .where((card) => card.suit == widget.folder.name)
        .toList();

    setState(() {
      _cardsInFolder = cardsInFolder;
      _availableCards = availableCards;
      _isLoading = false;
    });
  }

  Future<void> _addCardToFolder(CardModel card) async {
    // Check folder limit
    if (_cardsInFolder.length >= 6) {
      _showErrorDialog('This folder can only hold 6 cards.');
      return;
    }

    final updatedCard = CardModel(
      id: card.id,
      name: card.name,
      suit: card.suit,
      imageUrl: card.imageUrl,
      folderId: widget.folder.id,
    );

    await _dbHelper.updateCard(updatedCard);
    await _loadCards();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${card.name} added to ${widget.folder.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _removeCardFromFolder(CardModel card) async {
    // Check minimum card limit
    if (_cardsInFolder.length <= 3) {
      _showWarningDialog('You need at least 3 cards in this folder.');
      return;
    }

    final updatedCard = CardModel(
      id: card.id,
      name: card.name,
      suit: card.suit,
      imageUrl: card.imageUrl,
      folderId: null,
    );

    await _dbHelper.updateCard(updatedCard);
    await _loadCards();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${card.name} removed from ${widget.folder.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteCard(CardModel card) async {
    final confirmed = await _showDeleteConfirmationDialog(card);
    if (confirmed == true) {
      await _dbHelper.deleteCard(card.id!);
      await _loadCards();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${card.name} deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(CardModel card) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Are you sure you want to delete ${card.name}? This action cannot be undone.'),
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
  }

  void _showAddCardsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Add Cards to ${widget.folder.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _availableCards.isEmpty
                      ? const Center(
                          child: Text(
                            'No cards available to add',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : GridView.builder(
                          controller: scrollController,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: _availableCards.length,
                          itemBuilder: (context, index) {
                            final card = _availableCards[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                _addCardToFolder(card);
                              },
                              child: Card(
                                elevation: 2,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Image.network(
                                        card.imageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.error);
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditCardDialog(CardModel card) {
    final nameController = TextEditingController(text: card.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Card'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Card Name',
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
              final updatedCard = CardModel(
                id: card.id,
                name: nameController.text,
                suit: card.suit,
                imageUrl: card.imageUrl,
                folderId: card.folderId,
              );
              await _dbHelper.updateCard(updatedCard);
              await _loadCards();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Card updated'),
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

  Color _getFolderColor() {
    switch (widget.folder.name) {
      case 'Hearts':
      case 'Diamonds':
        return Colors.red;
      case 'Spades':
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
        title: Text('${widget.folder.name} (${_cardsInFolder.length} cards)'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCards,
              child: _cardsInFolder.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No cards in this folder',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to add cards',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: _cardsInFolder.length,
                      itemBuilder: (context, index) {
                        final card = _cardsInFolder[index];
                        return GestureDetector(
                          onTap: () => _showEditCardDialog(card),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(8),
                                        ),
                                        child: Image.network(
                                          card.imageUrl,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.error,
                                                color: Colors.grey[400],
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
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle),
                                            iconSize: 20,
                                            color: Colors.orange,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _removeCardFromFolder(card),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            iconSize: 20,
                                            color: Colors.red,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _deleteCard(card),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardsBottomSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}