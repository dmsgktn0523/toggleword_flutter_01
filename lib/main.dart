import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'new_word_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final List<Map<String, String>> words = [];


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2, // webview 잠시 disable 하단 세 개!!
        child: Scaffold(
          appBar: AppBar(
            title: Text('Toggle Word'),
            bottom: TabBar(
              tabs: [
                Tab(text: '단어장'),
                Tab(text: '영어사전'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              VocabularyList(words: words),
              DictionaryScreen(),
            ],
          ),
        ),
      ),
    );
  }
}



class VocabularyList extends StatefulWidget {
  final List<Map<String, String>> words;


  VocabularyList({Key? key, required this.words}) : super(key: key);

  @override
  _VocabularyListState createState() => _VocabularyListState();
}

class _VocabularyListState extends State<VocabularyList> {
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
      widget.words.clear();
      widget.words.addAll(queryResults.map((e) => {
        'id': e['id'].toString(), // Convert int to String if the 'id' is expected as String elsewhere
        'word': e['word'] as String,
        'meaning': e['meaning'] as String,
      }).toList());
    });
  }

  Future<void> _addWord(String word, String meaning) async {
    await _database.insert('words', {'word': word, 'meaning': meaning});
    _loadWords(); // 단어를 추가한 후 _loadWords를 호출합니다.
  }

  Future<void> _deleteWord(int id) async {
    await _database.delete('words', where: 'id = ?', whereArgs: [id]);
    _loadWords();
  }



  @override
  void dispose() {
    _database.close(); // 데이터베이스 연결 닫기
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Container(
            padding: EdgeInsets.only(right: 20.0),
            child: Switch(
              value: _isToggled,
              onChanged: (bool value) {
                setState(() {
                  _isToggled = value;  // 토글 상태 업데이트
                });
              },
              activeColor: Colors.white,
              activeTrackColor: Colors.deepPurple,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.words.length,
              itemBuilder: (context, index) {
                final String? idString = widget.words[index]['id'];
                if (idString == null) {
                  return ListTile(
                    title: Text('No ID found'),
                    subtitle: Text('This word has no ID.'),
                  );
                }
                final int id = int.parse(idString);  // Convert 'id' back to int before using
                return ListTile(
                  title: Text(widget.words[index]['word'] ?? ''),
                  subtitle: Text(widget.words[index]['meaning'] ?? '',
                      style: TextStyle(
                          color: _isToggled ? Colors.transparent : Colors.black,
                          backgroundColor: _isToggled ? Colors.purple[100] : Colors.transparent),  // 배경색 변경

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
                            onPressed: () => Navigator.of(context). pop(),
                          ),
                          TextButton(
                            child: Text('Delete'),
                            onPressed: () {
                              _deleteWord(id);  // Ensure _deleteWord expects an int
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: Text('정렬'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('설정'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewWordPage(
                          onAddWord: (word, meaning) {
                            _addWord(word, meaning); // _addWord 메서드 직접 호출
                          },
                        ),
                      ),
                    );
                  },
                  child: Text('+단어'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('편집'),
                ),
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

