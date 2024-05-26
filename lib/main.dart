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
        length: 2,
        child: Scaffold(
          body: Column(
            children: [
              SizedBox(height: 20), // 20px 마진
              TabBar(
                tabs: [
                  Tab(text: '단어장'),
                  Tab(text: '영어사전'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    VocabularyList(words: words),
                    DictionaryScreen(),
                  ],
                ),
              ),
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
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Row(
              children: <Widget>[
                Text(
                  'toggle',
                  style: TextStyle(color: Colors.black),
                ),
                Switch(
                  value: _isToggled,
                  onChanged: (bool value) {
                    setState(() {
                      _isToggled = value;
                    });
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.deepPurple,
                ),
              ],
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
                final int id = int.parse(idString);

                return ListTile(
                  title: Text(widget.words[index]['word'] ?? ''),
                  subtitle: LayoutBuilder(
                    builder: (context, constraints) {
                      // 텍스트의 크기를 측정
                      TextSpan span = TextSpan(
                        text: widget.words[index]['meaning'] ?? '',
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
                              height: tp.size.height ,
                              color: Colors.purple[100],
                            ),
                        ],
                      );
                    },
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
                            _addWord(word, meaning);
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