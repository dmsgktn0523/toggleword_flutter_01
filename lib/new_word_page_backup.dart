import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class NewWordPage extends StatefulWidget {
  @override
  _NewWordPageState createState() => _NewWordPageState();
}

class _NewWordPageState extends State<NewWordPage> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _translationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 두 개의 탭
      child: Scaffold(
        appBar: AppBar(
          title: Text('단어 추가'),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add), text: '간단 추가'),
              Tab(icon: Icon(Icons.list), text: '멀티 추가'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            simpleAddTab(), // 간단 추가 탭
            multiAddTab(), // 멀티 추가 탭
          ],
        ),
      ),
    );
  }

  Widget simpleAddTab() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _wordController,
              decoration: InputDecoration(
                labelText: '단어 입력 (대소문자에 따라 달라요)',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (_wordController.text.isNotEmpty) {
                      translateWord(_wordController.text);
                    }
                  },
                ),
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _translationController,
              decoration: InputDecoration(
                labelText: "단어의 뜻",
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 돌아가기 기능
                  },
                  child: Text('돌아가기'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.grey),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 단어 추가 로직 (예: 데이터베이스에 저장)
                  },
                  child: Text('단어 추가', style: TextStyle(color: Colors.white)),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // Multi adding
  Widget multiAddTab() {
    TextEditingController _multiWordController = TextEditingController();
    TextEditingController _multiTranslationController = TextEditingController();

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _multiWordController,
              decoration: InputDecoration(
                labelText: '단어 입력 (띄어쓰기로 구분해 여러 단어를 입력하면 자동으로 추가됩니다)',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => translateWord(_multiWordController.text), // translateWord 함수를 재사용
                ),
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _multiTranslationController,
              decoration: InputDecoration(
                labelText: "단어의 뜻",
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 돌아가기 기능
                  },
                  child: Text('돌아가기'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.grey),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 단어 추가 로직 (예: 데이터베이스에 저장)
                  },
                  child: Text('단어 추가', style: TextStyle(color: Colors.white)),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void translateWord(String word) async {
    try {
      final response = await http.get(Uri.parse("https://search.naver.com/search.naver?where=nexearch&sm=top_hty&fbm=0&ie=utf8&query=$word+%EB%9C%BB"));
      var document = parse(response.body);
      var translation = document.querySelector("p.mean.api_txt_lines")?.text;

      setState(() {
        _translationController.text = translation ?? " ";
      });
    } catch (e) {
      setState(() {
        _translationController.text = "Translation failed.";
      });
    }
  }
}
