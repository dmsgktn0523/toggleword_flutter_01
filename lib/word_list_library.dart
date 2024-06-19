import 'package:flutter/material.dart';
import 'main.dart';

void main() => runApp(const MyAppWrapper());

class MyAppWrapper extends StatelessWidget {
  const MyAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Word List Home',
      home: WordListLibrary(),
    );
  }
}

class WordListLibrary extends StatefulWidget {
  const WordListLibrary({super.key});

  @override
  _WordListLibraryState createState() => _WordListLibraryState();
}

class _WordListLibraryState extends State<WordListLibrary> {
  final List<Map<String, String>> wordLists = [
    {'id': '1', 'title': '데일리', 'description': 'Commonly used words for daily conversation.'},
    {'id': '2', 'title': 'Business Vocabulary', 'description': 'Words commonly used in business settings.'},
    {'id': '3', 'title': 'Technical Terms', 'description': 'Vocabulary for technical and scientific terms.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🏠 단어장 홈',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: wordLists.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(wordLists[index]['title']!),
                    subtitle: Text(wordLists[index]['description']!),
                    leading: const Icon(Icons.folder, color: Colors.deepPurple),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              MyApp(
                                listTitle: wordLists[index]['title']!,
                                listId: int.parse(wordLists[index]['id']!),
                                wordLists: wordLists, // wordLists 전달
                              ),
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
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    final titleController = TextEditingController();
                    final descriptionController = TextEditingController();

                    return AlertDialog(
                      title: const Text('새 단어장 추가'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              hintText: '단어장 제목',
                            ),
                          ),
                          TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              hintText: '단어장 설명',
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            final title = titleController.text;
                            final description = descriptionController.text;

                            if (title.isNotEmpty && description.isNotEmpty) {
                              setState(() {
                                int newId = wordLists.length + 1;
                                wordLists.add({
                                  'id': newId.toString(),
                                  'title': title,
                                  'description': description,
                                });
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('추가'),
                        ),
                      ],
                    );
                  },
                );
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              child: const Text('+ 새 단어장 추가'),
            ),
          ),
        ],
      ),
    );
  }
}
