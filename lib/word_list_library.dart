import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'main.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_utils;

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
  Database? _database;

  Future<void> _ensureDatabaseConnected() async {
    if (_database == null || !_database!.isOpen) {
      print('데이터베이스 재연결 시도');
      _database = await initializeDB();
    }
  }
  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      _database = await initializeDB();
      await _loadWordLists();
    } catch (e) {
      print('데이터베이스 초기화 오류: $e');
      // 사용자에게 오류 메시지를 표시할 수 있습니다.
    }
  }

  Future<Database> initializeDB() async {
    String databasesPath = await getDatabasesPath();
    String path = path_utils.join(databasesPath, 'word_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE words (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT, meaning TEXT, list_id INTEGER, favorite INTEGER)',
        );
      },
    );
  }

  Future<void> _loadWordLists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? wordListsString = prefs.getString('wordLists');

    if (wordListsString != null) {
      List<dynamic> jsonList = jsonDecode(wordListsString);
      List<Map<String, String>> loadedWordLists = jsonList.map((item) => Map<String, String>.from(item)).toList();

      // Ensure each word list has a unique `list_id`
      for (int i = 0; i < loadedWordLists.length; i++) {
        if (!loadedWordLists[i].containsKey('id')) {
          loadedWordLists[i]['id'] = (i + 1).toString();
        }
      }

      setState(() {
        wordLists = loadedWordLists;
      });
    } else {
      // Initialize with default word lists
      setState(() {
        wordLists = [
          {'id': '1', 'title': '데일리', 'description': 'Commonly used words for daily conversation.'},
          {'id': '2', 'title': 'Business Vocabulary', 'description': 'Words commonly used in business settings.'},
          {'id': '3', 'title': 'Technical Terms', 'description': 'Vocabulary for technical and scientific terms.'},
        ];
      });
      _saveWordLists(); // Save the default word lists with `id`
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
                  _showWarningDialog('동일한 제목의 단어장이 이미 존재합니다.',context, _showEditDialog);
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _showWarningDialog(String message, BuildContext previousContext, Function showPreviousDialog) {
    showDialog(
      context: previousContext,
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
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 현재 경고 대화상자를 닫음
                showPreviousDialog();   // 이전 입력 팝업을 다시 띄움
              },
              child: const Text('돌아가기'),
            ),
          ],
        );
      },
    );
  }




  void _showDuplicateDialog(int index) {
    final titleController = TextEditingController(text: '${wordLists[index]['title']} 복사본');
    final descriptionController = TextEditingController(text: wordLists[index]['description']);

    void showDuplicateDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('단어장 복사'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: '새 단어장 제목',
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
                onPressed: () async {
                  final title = titleController.text;
                  final description = descriptionController.text.isNotEmpty ? descriptionController.text : ' ';

                  bool isDuplicate = wordLists.any((element) => element['title'] == title);

                  if (title.isNotEmpty && !isDuplicate) {
                    int newId = wordLists.length + 1;
                    while (wordLists.any((element) => int.parse(element['id']!) == newId)) {
                      newId++;
                    }

                    final originalWordListId = int.parse(wordLists[index]['id']!);
                    bool copySuccess = await _copyWords(originalWordListId, newId);

                    if (copySuccess) {
                      setState(() {
                        wordLists.add({
                          'id': newId.toString(),
                          'title': title,
                          'description': description,
                        });
                      });

                      _saveWordLists();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('단어장이 성공적으로 복사되었습니다.')),
                      );
                    } else {
                      Navigator.pop(context);
                      _showWarningDialog('단어장 복사 중 오류가 발생했습니다.', context, showDuplicateDialog);
                    }
                  } else if (isDuplicate) {
                    Navigator.pop(context);
                    _showWarningDialog('동일한 제목의 단어장이 이미 존재합니다.', context, showDuplicateDialog);
                  }
                },
                child: const Text('복사'),
              ),
            ],
          );
        },
      );
    }

    showDuplicateDialog();
  }






  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('삭제'),
          content: const Text('정말 삭제하시겠습니까? 이 단어장과 단어장 내 단어가 모두 삭제됩니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                final listId = int.parse(wordLists[index]['id']!);
                await _deleteWordsInList(listId);

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

  Future<void> _deleteWordsInList(int listId) async {
    if (_database != null && _database!.isOpen) {
      await _database!.delete(
        'words',
        where: 'list_id = ?',
        whereArgs: [listId],
      );
    }
  }

  Future<bool> _copyWords(int originalListId, int newListId) async {
    print('단어 복사 시작: 원본 ID=$originalListId, 새 ID=$newListId');
    await _ensureDatabaseConnected();
    if (_database != null && _database!.isOpen) {
      try {
        final List<Map<String, dynamic>> queryResults = await _database!.query(
          'words',
          where: 'list_id = ?',
          whereArgs: [originalListId],
        );
        print('복사할 단어 수: ${queryResults.length}');

        for (var word in queryResults) {
          await _database!.insert('words', {
            'word': word['word'],
            'meaning': word['meaning'],
            'list_id': newListId,
            'favorite': word['favorite'],
          });
          print('단어 복사됨: ${word['word']}');
        }
        print('단어 복사 완료');
        return true;
      } catch (e) {
        print('단어 복사 오류: $e');
        return false;
      }
    }
    print('데이터베이스가 초기화되지 않았거나 열려있지 않습니다.');
    return false;
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
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
                              _showWarningDialog('동일한 제목의 단어장이 이미 존재합니다.', context, showDialog);
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
