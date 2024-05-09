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
    final words = await _database.query('words');
    setState(() {
      widget.words.clear();
      widget.words.addAll(words.map((e) => Map.fromEntries([
        MapEntry('word', e['word'] as String),
        MapEntry('meaning', e['meaning'] as String),
      ])));
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

  bool _isToggled = false;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Container(
            padding: EdgeInsets.only(right: 20.0),
            child: Switch(
              value: _isToggled,
              onChanged: (value) {
                setState(() {
                  _isToggled = value;
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
                return ListTile(
                  title: Text(widget.words[index]['word'] ?? ''),
                  subtitle: Text(widget.words[index]['meaning'] ?? ''),
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

