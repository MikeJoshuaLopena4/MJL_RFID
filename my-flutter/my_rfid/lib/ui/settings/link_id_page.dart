import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_id_page.dart';
import '../../theme/color_palette.dart';

class LinkIdPage extends StatefulWidget {
  const LinkIdPage({super.key});

  @override
  State<LinkIdPage> createState() => _LinkIdPageState();
}

class _LinkIdPageState extends State<LinkIdPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    final idsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('ids')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Linked IDs'),
        backgroundColor: ColorPalette.primary500,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        color: ColorPalette.background50,
        child: StreamBuilder<QuerySnapshot>(
          stream: idsCollection.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.primary500),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final docs = snapshot.data!.docs;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Linked Cards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.text800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final cardId = data['id'] ?? '';
                        final cardLabel = data['label'] ?? 'Unnamed Card';
                        final createdAt = data['createdAt'] as Timestamp?;

                        return _buildCardItem(
                          context,
                          cardId: cardId,
                          cardLabel: cardLabel,
                          createdAt: createdAt,
                          onDelete: () async {
                            await _showDeleteDialog(context, doc.reference, cardLabel);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push<Map<String, String>>(
            context,
            MaterialPageRoute(builder: (_) => const AddIdPage()),
          );
        },
        backgroundColor: ColorPalette.primary500,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off,
            size: 64,
            color: ColorPalette.text300,
          ),
          const SizedBox(height: 16),
          Text(
            'No linked cards yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.text600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first card',
            style: TextStyle(
              color: ColorPalette.text400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(
    BuildContext context, {
    required String cardId,
    required String cardLabel,
    required Timestamp? createdAt,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ColorPalette.primary100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.credit_card,
            color: ColorPalette.primary500,
            size: 24,
          ),
        ),
        title: Text(
          cardLabel,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ColorPalette.text800,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              cardId,
              style: TextStyle(
                color: ColorPalette.text500,
                fontSize: 12,
              ),
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 2),
              Text(
                'Added ${_formatDate(createdAt.toDate())}',
                style: TextStyle(
                  color: ColorPalette.text400,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Colors.red[400],
            size: 22,
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, DocumentReference docRef, String cardLabel) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Delete Card',
            style: TextStyle(
              color: ColorPalette.text800,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$cardLabel"?',
            style: TextStyle(
              color: ColorPalette.text600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: ColorPalette.text500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await docRef.delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$cardLabel" has been deleted'),
                    backgroundColor: ColorPalette.primary500,
                  ),
                );
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}