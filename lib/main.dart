import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:toggleworld_flutter_01/word_list_library.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'new_word_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            VocabularyList(),
            DictionaryScreen(),
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
      ),
    );
  }
}

class VocabularyList extends StatefulWidget {
  @override
  _VocabularyListState createState() => _VocabularyListState();
}

class _VocabularyListState extends State<VocabularyList> {
  final List<Map<String, String>> words = [];
  late Database _database;
  bool _isToggled = false;

  Future<Database> initializeDB() async {
    String path = join(await getDatabasesPath(), 'word_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE words (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT, meaning TEXT)',
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    initializeDB().then((value) {
      _database = value;
      _loadWords();
    });
  }

  Future<void> _loadWords() async {
    final List<Map<String, dynamic>> queryResults = await _database.query('words');
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
    await _database.insert('words', {'word': word, 'meaning': meaning});
    _loadWords();
  }

  Future<void> _deleteWord(int id) async {
    await _database.delete('words', where: 'id = ?', whereArgs: [id]);
    _loadWords();
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
          child: Row(
            children: [
              Icon(Icons.arrow_back, color: Colors.black),
              SizedBox(width: 30.0),
              Text(
                '단어장',
                style: TextStyle(color: Colors.black),
              ),
            ],
          )
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) {
              setState(() {
                // Add your logic here for menu item selection
                print(result);
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Option 1',
                child: Text('편집하기'),
              ),
              const PopupMenuItem<String>(
                value: 'Option 2',
                child: Text('정렬하기'),
              ),
              const PopupMenuItem<String>(
                value: 'Option 3',
                child: Text('랜덤섞기'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: words.length,
              itemBuilder: (context, index) {
                final String? idString = words[index]['id'];
                if (idString == null) {
                  return ListTile(
                    title: Text('No ID found'),
                    subtitle: Text('This word has no ID.'),
                  );
                }
                final int id = int.parse(idString);
                final int wordNumber = index + 1;

                return ListTile(
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
                    padding: EdgeInsets.only(left:28.0),
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
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Word'),
                        content: Text('Are you sure you want to delete this word?'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: Text('Delete'),
                            onPressed: () {
                              _deleteWord(id);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
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
                        toggleSize:20.0,
                        padding: 4.0,
                        activeColor: Colors.deepPurple,
                        //showOnOff: true,
                        value: _isToggled,
                        onToggle: (val){
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
