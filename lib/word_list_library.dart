import 'package:flutter/material.dart';
import 'main.dart'; // MyApp을 가져오기 위한 import

void main() => runApp(MyAppWrapper());

class MyAppWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word List Home',
      home: WordListLibrary(),
    );
  }
}

class WordListLibrary extends StatefulWidget {
  @override
  _WordListLibraryState createState() => _WordListLibraryState();
}

class _WordListLibraryState extends State<WordListLibrary> {
  final List<Map<String, String>> wordLists = [
    {'title': '데일리', 'description': 'Commonly used words for daily conversation.'},
    {'title': 'Business Vocabulary', 'description': 'Words commonly used in business settings.'},
    {'title': 'Technical Terms', 'description': 'Vocabulary for technical and scientific terms.'},
    // 다른 단어 리스트들을 여기에 추가
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🏠 단어장 홈',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: wordLists.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(wordLists[index]['title']!),
              subtitle: Text(wordLists[index]['description']!),
              leading: Icon(Icons.folder, color: Colors.deepPurple),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => MyApp(listTitle: wordLists[index]['title']!),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;
                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
