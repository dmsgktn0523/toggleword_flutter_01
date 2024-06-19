import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:toggleworld_flutter_01/word_list_library.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'new_word_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_utils;
import 'package:flutter_tts/flutter_tts.dart';
// import 'package:flutter_svg/flutter_svg.dart';


void main() => runApp(const MyAppWrapper());

class MyAppWrapper extends StatelessWidget {
  const MyAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WordListLibrary(),
    );
  }
}

class MyApp extends StatefulWidget {
  final String listTitle;
  final int listId;
  final List<Map<String, String>> wordLists;

  const MyApp({super.key, required this.listTitle, required this.listId, required this.wordLists});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                VocabularyList(
                  listId: widget.listId,
                  wordLists: widget.wordLists,
                  listTitle: widget.listTitle,
                ),
                const DictionaryScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: '단어장',
          ),
          BottomNavigationBarItem(
            // icon: SvgPicture.asset("assets/icons/Dictionary.svg"),
            icon: Icon(Icons.search),
            label: '영어사전',
          ),
        ],
      ),
    );
  }
}

class VocabularyList extends StatefulWidget {
  final int listId;
  final List<Map<String, String>> wordLists;
  final String listTitle;

  const VocabularyList({super.key, required this.listId, required this.wordLists, required this.listTitle});

  @override
  _VocabularyListState createState() => _VocabularyListState();
}

class _VocabularyListState extends State<VocabularyList> {
  final List<Map<String, String>> words = [];
  late Database _database;
  bool _isToggled = false;
  bool _isEditing = false;
  final Set<int> _selectedWords = <int>{};
  late FlutterTts flutterTts;
  late TextEditingController _wordController;
  late TextEditingController _meaningController;

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
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




  @override
  void initState() {
    super.initState();
    initializeDB().then((value) {
      _database = value;
      _loadWords(widget.listId);
    });

    // flutter_tts 초기화
    flutterTts = FlutterTts();

    //초기화
    _wordController = TextEditingController();
    _meaningController = TextEditingController();
  }

  Future<void> _loadWords(int listId) async {
    final List<Map<String, dynamic>> queryResults = await _database.query(
      'words',
      where: 'list_id = ?',
      whereArgs: [listId],
    );
    setState(() {
      words.clear();
      words.addAll(queryResults.map((e) => {
        'id': e['id'].toString(),
        'word': e['word'] as String,
        'meaning': e['meaning'] as String,
        'favorite': e['favorite'] != null ? e['favorite'].toString() : '0', // favorite 값을 올바르게 설정
      }).toList());
    });
  }

  Future<void> _addWord(String word, String meaning) async {
    await _database.insert(
        'words', {'word': word, 'meaning': meaning, 'list_id': widget.listId});
    _loadWords(widget.listId);
  }


  Future<void> _deleteWord(int id) async {
    await _database.delete('words', where: 'id = ?', whereArgs: [id]);
    _loadWords(widget.listId);
  }

  Future<void> _moveWords(int targetListId) async {
    for (int id in _selectedWords) {
      await _database.update('words', {'list_id': targetListId},
          where: 'id = ?', whereArgs: [id]);
    }
    _loadWords(widget.listId);
    _toggleEditMode();
  }

  Future<void> _copyWords(int targetListId) async {
    for (int id in _selectedWords) {
      // Get the word details by ID
      final List<Map<String, dynamic>> queryResult = await _database.query(
        'words',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (queryResult.isNotEmpty) {
        final wordData = queryResult.first;
        // Insert the word into the target list
        await _database.insert('words', {
          'word': wordData['word'],
          'meaning': wordData['meaning'],
          'list_id': targetListId,
        });
      }
    }
    _loadWords(widget.listId);
    _toggleEditMode();
  }

  Future<void> _updateWord(int id, String newWord, String newMeaning) async {
    await _database.update(
      'words',
      {'word': newWord, 'meaning': newMeaning},
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadWords(widget.listId);
  }



  Future<void> _toggleFavorite(int id, int currentFavorite) async {
    int newFavorite = currentFavorite == 1 ? 0 : 1;
    await _database.update(
      'words',
      {'favorite': newFavorite},
      where: 'id = ?',
      whereArgs: [id],
    );

    setState(() {
      for (var word in words) {
        if (word['id'] == id.toString()) {
          word['favorite'] = newFavorite.toString();
          break;
        }
      }
    });
  }




  void _sortWords(String criterion) {
    setState(() {
      if (criterion == 'A-Z 순') {
        words.sort((a, b) => a['word']!.compareTo(b['word']!));
      } else if (criterion == 'Z-A 순') {
        words.sort((a, b) => b['word']!.compareTo(a['word']!));
      } else if (criterion == '오래된순') {
        words.sort((a, b) => int.parse(a['id']!).compareTo(int.parse(b['id']!)));
      } else if (criterion == '최신 저장순') {
        words.sort((a, b) => int.parse(b['id']!).compareTo(int.parse(a['id']!)));
      } else if (criterion == '랜덤순') {
        words.shuffle();
      } else if (criterion == '즐겨찾기순') {
        words.sort((a, b) {
          int aFavorite = int.parse(a['favorite']! ?? '0');
          int bFavorite = int.parse(b['favorite']! ?? '0');
          if (aFavorite == bFavorite) {
            return a['word']!.compareTo(b['word']!);
          } else {
            return bFavorite.compareTo(aFavorite);
          }
        });
      }
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      _selectedWords.clear();
    });
  }

  void _handleWordSelection(int id) {
    setState(() {
      if (_selectedWords.contains(id)) {
        _selectedWords.remove(id);
      } else {
        _selectedWords.add(id);
      }
    });
  }




  void _showMoveDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int? selectedListId;
        return AlertDialog(
          title: const Text('이동할 단어장 선택'),
          content: DropdownButtonFormField<int>(
            value: selectedListId,
            items: widget.wordLists.map((list) {
              return DropdownMenuItem<int>(
                value: int.parse(list['id']!),
                child: Text(list['title']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedListId = value!;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedListId != null) {
                  _moveWords(selectedListId!);
                  Navigator.pop(context);
                }
              },
              child: const Text('이동'),
            ),
          ],
        );
      },
    );
  }

  void _showCopyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int? selectedListId;
        return AlertDialog(
          title: const Text('복사할 단어장 선택'),
          content: DropdownButtonFormField<int>(
            value: selectedListId,
            items: widget.wordLists.map((list) {
              return DropdownMenuItem<int>(
                value: int.parse(list['id']!),
                child: Text(list['title']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedListId = value!;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedListId != null) {
                  _copyWords(selectedListId!);
                  Navigator.pop(context);
                }
              },
              child: const Text('복사'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSelectedWords() {
    for (var id in _selectedWords) {
      _deleteWord(id);
    }
    _toggleEditMode();
  }

  void _showEditDialog(BuildContext context, int id, String word, String meaning) {
    _wordController.text = word;
    _meaningController.text = meaning;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('단어 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _wordController,
                decoration: const InputDecoration(labelText: '단어'),
              ),
              TextField(
                controller: _meaningController,
                decoration: const InputDecoration(labelText: '뜻'),
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
            ElevatedButton(
              onPressed: () {
                _updateWord(id, _wordController.text, _meaningController.text);
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _showActionSheet(BuildContext buildContext, int id, String word, String meaning) {
    showDialog(
      context: buildContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('옵션 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('수정하기'),
                onTap: () {
                  Navigator.pop(context);
                  //편집 로직 showEditDialog 추가
                  _showEditDialog(context, id, word, meaning);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('삭제하기'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteWord(id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('복사하기'),
                onTap: () {
                  Navigator.pop(context);
                  _copyWords(widget.listId); // 예를 들어 현재 목록 ID로 복사하려면 widget.listId를 사용
                },
              ),
              ListTile(
                leading: const Icon(Icons.move_to_inbox),
                title: const Text('이동하기'),
                onTap: () {
                  Navigator.pop(context);
                  _moveWords(widget.listId);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const WordListLibrary(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0); // 오른쪽에서 왼쪽으로 애니메이션
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
          child: Row(
            children: [
              const SizedBox(width: 8.0), // 아이콘과 제목 사이의 간격
              Text(widget.listTitle), // listTitle을 표시
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: <Widget>[
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleEditMode,
            ),
          if (!_isEditing)
            PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == '편집하기') {
                  _toggleEditMode();
                } else if (result == '정렬하기') {
                  showSortMenu(context);
                } else if (result == '보기 설정') {
                  setState(() {});
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: '편집하기',
                  child: Text('편집하기'),
                ),
                const PopupMenuItem<String>(
                  value: '정렬하기',
                  child: Text('정렬하기'),
                ),
                const PopupMenuItem<String>(
                  value: '보기 설정',
                  child: Text('보기 설정'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _selectedWords.isEmpty ? null : _showMoveDialog,
                    child: const Text('이동하기'),
                  ),
                  ElevatedButton(
                    onPressed: _selectedWords.isEmpty ? null : _showCopyDialog,
                    child: const Text('복사하기'),
                  ),
                  ElevatedButton(
                    onPressed: _selectedWords.isEmpty ? null : _deleteSelectedWords,
                    child: const Text('삭제하기'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: words.length,
              itemBuilder: (context, index) {
                final String? idString = words[index]['id'];
                if (idString == null) {
                  return const Column(
                    children: [
                      ListTile(
                        title: Text('No ID found'),
                        subtitle: Text('This word has no ID.'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Divider(),
                      ),
                    ],
                  );
                }
                final int id = int.parse(idString);
                final int wordNumber = index + 1;
                final int favorite = words[index]['favorite'] == null ? 0 : int.parse(words[index]['favorite']!);

                return Column(
                  children: [
                    ListTile(
                      leading: _isEditing
                          ? Checkbox(
                        value: _selectedWords.contains(id),
                        onChanged: (bool? value) {
                          _handleWordSelection(id);
                        },
                      )
                          : null,
                      title: Row(
                        children: [
                          CircleAvatar(
                            radius: 10.0,
                            child: Text(
                              '$wordNumber',
                              style: const TextStyle(fontSize: 12.0),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(words[index]['word'] ?? ''),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(left: 28.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            TextSpan span = TextSpan(
                              text: words[index]['meaning'] ?? '',
                              style: const TextStyle(color: Colors.black),
                            );

                            TextPainter tp = TextPainter(
                              text: span,
                              textDirection: TextDirection.ltr,
                            );

                            tp.layout(maxWidth: constraints.maxWidth);

                            return Stack(
                              children: [
                                RichText(text: span),
                                if (_isToggled)
                                  Container(
                                    width: tp.size.width,
                                    height: tp.size.height,
                                    color: Colors.purple[100],
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          favorite == 1 ? Icons.star : Icons.star_border, // 변경된 아이콘
                          color: favorite == 1 ? Colors.purple : null, // 색상을 보라색으로 변경
                        ),
                        onPressed: () {
                          _toggleFavorite(id, favorite); // 아이콘 클릭 시 즐겨찾기 상태 변경
                        },
                      ),
                      onTap: () {
                        _speak(words[index]['word'] ?? ''); // 단어를 읽어주는 기능
                      },
                      onLongPress: () {
                        _showActionSheet(context, id, words[index]['word'] ?? '', words[index]['meaning'] ?? ''); // 옵션 다이얼로그 표시
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Container()), // Left spacer
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewWordPage(
                          onAddWord: (word, meaning) {
                            _addWord(word, meaning);
                          },
                        ),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  child: const Text('+ 단어 추가하기'),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      FlutterSwitch(
                        width: 50.0,
                        height: 35.0,
                        borderRadius: 50.0,
                        toggleSize: 20.0,
                        padding: 4.0,
                        activeColor: Colors.deepPurple,
                        value: _isToggled,
                        onToggle: (val) {
                          setState(() {
                            _isToggled = val;
                          });
                        },
                      )
                    ],
                  ),
                ), // Right spacer with switch
              ],
            ),
          ),
        ],
      ),
    );
  }



  void showSortMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(200, 50, 0, 0),
      items: [
        const PopupMenuItem<String>(
          value: 'A-Z 순',
          child: Text('A-Z 순'),
        ),
        const PopupMenuItem<String>(
          value: 'Z-A 순',
          child: Text('Z-A 순'),
        ),
        const PopupMenuItem<String>(
          value: '오래된순',
          child: Text('오래된순'),
        ),
        const PopupMenuItem<String>(
          value: '최신 저장순',
          child: Text('최신 저장순'),
        ),
        const PopupMenuItem<String>(
          value: '즐겨찾기순',
          child: Text('즐겨찾기순'),
        ),
        const PopupMenuItem<String>(
          value: '랜덤순',
          child: Text('랜덤순'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _sortWords(value);
      }
    });
  }
}

class CustomWebView extends StatefulWidget {
  const CustomWebView({super.key});

  @override
  _CustomWebViewState createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView> {
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: 'https://en.dict.naver.com/#/main',
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (WebViewController webViewController) {
        _controller = webViewController;
      },
    );
  }
}

class DictionaryScreen extends StatelessWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomWebView();
  }
}

class NewPage extends StatelessWidget {
  const NewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Page'),
      ),
      body: const Center(
        child: Text('This is a new page'),
      ),
    );
  }
}
