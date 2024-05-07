import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'new_word_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final List<Map<String, String>> words = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
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
                  child: Text('버튼 1'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('버튼 2'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NewWordPage(onAddWord: (word) {
                        setState(() {
                          widget.words.add(word);
                        });
                        Navigator.pop(context);
                      })),
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
                  child: Text('버튼 4'),
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