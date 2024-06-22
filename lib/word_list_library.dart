import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  List<Map<String, String>> wordLists = [];

  @override
  void initState() {
    super.initState();
    _loadWordLists();
  }

  Future<void> _loadWordLists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? wordListsString = prefs.getString('wordLists');
    if (wordListsString != null) {
      List<dynamic> jsonList = jsonDecode(wordListsString);
      setState(() {
        wordLists = jsonList.map((item) => Map<String, String>.from(item)).toList();
      });
    } else {
      setState(() {
        wordLists = [
          {'id': '1', 'title': '데일리', 'description': 'Commonly used words for daily conversation.'},
          {'id': '2', 'title': 'Business Vocabulary', 'description': 'Words commonly used in business settings.'},
          {'id': '3', 'title': 'Technical Terms', 'description': 'Vocabulary for technical and scientific terms.'},
        ];
      });
    }
  }

  Future<void> _saveWordLists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(wordLists);
    await prefs.setString('wordLists', jsonString);
  }

  void _showEditDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('단어장 수정하기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('수정하기'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(index);
                },
              ),
              ListTile(
                title: const Text('복사하기'),
                onTap: () {
                  Navigator.pop(context);
                  _showDuplicateDialog(index);
                },
              ),
              ListTile(
                title: const Text('삭제하기'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(int index) {
    final titleController = TextEditingController(text: wordLists[index]['title']);
    final descriptionController = TextEditingController(text: wordLists[index]['description']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('편집'),
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
                  hintText: '단어장 설명 (선택 사항)',
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
                final description = descriptionController.text.isNotEmpty ? descriptionController.text : ' ';

                bool isDuplicate = wordLists.any((element) => element['title'] == title && element['id'] != wordLists[index]['id']);

                if (title.isNotEmpty && !isDuplicate) {
                  setState(() {
                    wordLists[index]['title'] = title;
                    wordLists[index]['description'] = description;
                  });
                  _saveWordLists();
                  Navigator.pop(context);
                } else if (isDuplicate) {
                  Navigator.pop(context);
                  _showWarningDialog('동일한 제목의 단어장이 이미 존재합니다.');
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('경고'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }




  void _showDuplicateDialog(int index) {
    final titleController = TextEditingController(text: '${wordLists[index]['title']} (1)');
    final descriptionController = TextEditingController(text: wordLists[index]['description']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('복사'),
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
                final description = descriptionController.text.isNotEmpty ? descriptionController.text : ' ';

                bool isDuplicate = wordLists.any((element) => element['title'] == title);

                if (title.isNotEmpty && !isDuplicate) {
                  setState(() {
                    int newId = wordLists.length + 1;
                    wordLists.add({
                      'id': newId.toString(),
                      'title': title,
                      'description': description,
                    });
                  });
                  Navigator.pop(context);
                  _saveWordLists();
                } else if (isDuplicate) {
                  Navigator.pop(context);
                  _showWarningDialog('동일한 제목의 단어장이 이미 존재합니다.');
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }



  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('삭제'),
          content: const Text('정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  wordLists.removeAt(index);
                });
                _saveWordLists();
                Navigator.pop(context);
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }




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
                          pageBuilder: (context, animation, secondaryAnimation) => MyApp(
                            listTitle: wordLists[index]['title']!,
                            listId: int.parse(wordLists[index]['id']!),
                            wordLists: wordLists,
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
                    onLongPress: () {
                      _showEditDeleteDialog(index);
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
                            final description = descriptionController.text.isNotEmpty ? descriptionController.text : ' ';

                            bool isDuplicate = wordLists.any((element) => element['title'] == title);

                            if (title.isNotEmpty && !isDuplicate) {
                              setState(() {
                                int newId = wordLists.length + 1;
                                wordLists.add({
                                  'id': newId.toString(),
                                  'title': title,
                                  'description': description,
                                });
                              });
                              Navigator.pop(context);
                              _saveWordLists();
                            } else if (isDuplicate) {
                              Navigator.pop(context);
                              _showWarningDialog('동일한 제목의 단어장이 이미 존재합니다.');

                            }
                          },
                          child: const Text('추가'),
                        ),
                      ],
                    );
                  },
                );
              },

              child: const Text('+ 새 단어장 추가'),
            ),

          ),

        ],
      ),
    );
  }
}

