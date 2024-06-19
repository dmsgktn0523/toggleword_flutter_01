import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class NewWordPage extends StatefulWidget {
  const NewWordPage({super.key});

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
          title: const Text('단어 추가'),
          bottom: const TabBar(
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
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _wordController,
              decoration: InputDecoration(
                labelText: '단어 입력 (대소문자에 따라 달라요)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_wordController.text.isNotEmpty) {
                      translateWord(_wordController.text);
                    }
                  },
                ),
                border: const UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _translationController,
              decoration: const InputDecoration(
                labelText: "단어의 뜻",
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 돌아가기 기능
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.grey),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  child: const Text('돌아가기'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 단어 추가 로직 (예: 데이터베이스에 저장)
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
                  ),
                  child: const Text('단어 추가', style: TextStyle(color: Colors.white)),
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
    TextEditingController multiWordController = TextEditingController();
    TextEditingController multiTranslationController = TextEditingController();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: multiWordController,
              decoration: InputDecoration(
                labelText: '단어 입력 (띄어쓰기로 구분해 여러 단어를 입력하면 자동으로 추가됩니다)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => translateWord(multiWordController.text), // translateWord 함수를 재사용
                ),
                border: const UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: multiTranslationController,
              decoration: const InputDecoration(
                labelText: "단어의 뜻",
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 돌아가기 기능
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.grey),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  child: const Text('돌아가기'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 단어 추가 로직 (예: 데이터베이스에 저장)
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
                  ),
                  child: const Text('단어 추가', style: TextStyle(color: Colors.white)),
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
