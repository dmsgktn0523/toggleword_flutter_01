import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'new_word_page.dart';



void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Toggle Word❤️'),
            bottom: TabBar(
              tabs: [
                Tab(text: '단어장'),
                Tab(text: '영어사전'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              VocabularyList(),
              DictionaryScreen(),
            ],
          ),
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
  bool _isToggled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Container(
            // color: Colors.blueGrey[100],  // 토글 스위치의 배경색
            padding: EdgeInsets.only(right: 20.0),  // 오른쪽 패딩
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
              itemCount: 10,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('단어 $index'),
                  subtitle: Text('설명 $index'),
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
                    // Navigator.push를 사용하여 새 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NewWordPage()),
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
class DictionaryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Text('영어사전 화면'),
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
                onPressed: () {},
                child: Text('버튼 3'),
              ),
              ElevatedButton(
                onPressed: () {},
                child: Text('버튼 4'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

