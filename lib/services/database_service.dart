import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedDatabase() async {
    final categories = [
      {
        'title': 'MCQ',
        'subtitle': 'General Science & History',
        'icon': 'quiz',
        'color': '0xFF00C6FF',
      },
      {
        'title': 'Coding',
        'subtitle': 'Flutter & Dart Challenges',
        'icon': 'code',
        'color': '0xFF7F00FF',
      },
      {
        'title': 'Aptitude',
        'subtitle': 'Logical & Numeric Reasoning',
        'icon': 'psychology',
        'color': '0xFF00D2FF',
      },
    ];

    for (var cat in categories) {
      final docRef = await _db.collection('categories').add(cat);
      
      // Add a dummy question for each
      await _db.collection('questions').add({
        'categoryId': docRef.id,
        'categoryTitle': cat['title'],
        'questionText': 'Is this a real-time ${cat['title']} quiz?',
        'options': ['Yes', 'No', 'Maybe', 'Definitely'],
        'correctAnswerIndex': 0,
      });
    }
  }
}
