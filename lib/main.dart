import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:toggleworld_flutter_01/word_list_library.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'new_word_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(MyAppWrapper());

class MyAppWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WordListLibrary(),
    );
  }
}

class MyApp extends StatefulWidget {
  final String listTitle;
  final int listId;
  final List<Map<String, String>> wordLists;

  MyApp({required this.listTitle, required this.listId, required this.wordLists});

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
          // AppBar 대신 제목을 포함한 새로운 레이아웃 추가
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                VocabularyList(listId: widget.listId, wordLists: widget.wordLists),
                DictionaryScreen(),
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
            _pageController.animateToPage(index,
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: '단어장',
          ),
          BottomNavigationBarItem(
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

  VocabularyList({required this.listId, required this.wordLists});

  @override
  _VocabularyListState createState() => _VocabularyListState();
}

class _VocabularyListState extends State<VocabularyList> {
  final List<Map<String, String>> words = [];
  late Database _database;
  bool _isToggled = false;
  bool _isEditing = false;
  Set<int> _selectedWords = Set<int>();

  Future<Database> initializeDB() async {
    String path = join(await getDatabasesPath(), 'word_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE words (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT, meaning TEXT, list_id INTEGER)',
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
  }

  Future<void> _loadWords(int listId) async {
    final List<Map<String, dynamic>> queryResults = await _database.query('words', where: 'list_id = ?', whereArgs: [listId]);
    setState(() {
      words.clear();
      words.addAll(queryResults.map((e) => {
        'id': e['id'].toString(),
        'word': e['word'] as String,
        'meaning': e['meaning'] as String,
      }).toList());
    });
  }

  Future<void> _addWord(String word, String meaning) async {
    await _database.insert('words', {'word': word, 'meaning': meaning, 'list_id': widget.listId});
    _loadWords(widget.listId);
  }

  Future<void> _deleteWord(int id) async {
    await _database.delete('words', where: 'id = ?', whereArgs: [id]);
    _loadWords(widget.listId);
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

  void _deleteSelectedWords() {
    _selectedWords.forEach((id) {
      _deleteWord(id);
    });
    _toggleEditMode();
  }

  void _showActionSheet(BuildContext context, int id, String word, String meaning) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('옵션 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('수정하기'),
                onTap: () {
                  Navigator.pop(context);
                  // 편집하기 로직 추가
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('삭제하기'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteWord(id);
                },
              ),
              ListTile(
                leading: Icon(Icons.copy),
                title: Text('복사하기'),
                onTap: () {
                  Navigator.pop(context);
                  // 복사하기 로직 추가
                },
              ),
              ListTile(
                leading: Icon(Icons.move_to_inbox),
                title: Text('이동하기'),
                onTap: () {
                  Navigator.pop(context);
                  // 이동하기 로직 추가
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('취소'),
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
                pageBuilder: (context, animation, secondaryAnimation) => WordListLibrary(),
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
        ),
        iconTheme: IconThemeData(color: Colors.black),
        actions: <Widget>[
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _toggleEditMode,
            ),
          if (!_isEditing)
            PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == '편집하기') {
                  _toggleEditMode();
                } else if (result == '정렬하기') {
                  showSortMenu(context);
                } else if (result == '랜덤섞기') {
                  setState(() {
                    words.shuffle();
                  });
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
                  value: '랜덤섞기',
                  child: Text('랜덤섞기'),
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
                    onPressed: _selectedWords.isEmpty ? null : () {
                      // 이동하기 로직 추가
                    },
                    child: Text('이동하기'),
                  ),
                  ElevatedButton(
                    onPressed: _selectedWords.isEmpty ? null : () {
                      // 복사하기 로직 추가
                    },
                    child: Text('복사하기'),
                  ),
                  ElevatedButton(
                    onPressed: _selectedWords.isEmpty ? null : _deleteSelectedWords,
                    child: Text('삭제하기'),
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
                  return Column(
                    children: [
                      ListTile(
                        title: Text('No ID found'),
                        subtitle: Text('This word has no ID.'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Divider(),
                      ), // Add Divider here
                    ],
                  );
                }
                final int id = int.parse(idString);
                final int wordNumber = index + 1;

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
                              style: TextStyle(fontSize: 12.0),
                            ),
                          ),
                          SizedBox(width: 8.0),
                          Text(words[index]['word'] ?? ''),
                        ],
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.only(left: 28.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // 텍스트의 크기를 측정
                            TextSpan span = TextSpan(
                              text: words[index]['meaning'] ?? '',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            );

                            TextPainter tp = TextPainter(
                              text: span,
                              textDirection: TextDirection.ltr,
                            );

                            tp.layout(maxWidth: constraints.maxWidth);

                            return Stack(
                              children: [
                                RichText(
                                  text: span,
                                ),
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
                      onLongPress: () {
                        _showActionSheet(context, id, words[index]['word'] ?? '', words[index]['meaning'] ?? '');
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(),
                    ), // Add Divider here
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
                  child: Text('+ 단어 추가하기'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
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
                        // showOnOff: true,
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
      position: RelativeRect.fromLTRB(200, 50, 0, 0),
      items: [
        PopupMenuItem<String>(
          value: 'A-Z 순',
          child: Text('A-Z 순'),
        ),
        PopupMenuItem<String>(
          value: 'Z-A 순',
          child: Text('Z-A 순'),
        ),
        PopupMenuItem<String>(
          value: '오래된순',
          child: Text('오래된순'),
        ),
        PopupMenuItem<String>(
          value: '최신 저장순',
          child: Text('최신 저장순'),
        ),
        PopupMenuItem<String>(
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
  @override
  Widget build(BuildContext context) {
    return CustomWebView();
  }
}

class NewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Page'),
      ),
      body: Center(
        child: Text('This is a new page'),
      ),
    );
  }
}
