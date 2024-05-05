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
    return Scaffold(
      appBar: AppBar(
        title: Text('단어 추가'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _wordController,
                decoration: InputDecoration(
                  labelText: '단어 입력',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () => translateWord(_wordController.text),
                  ),
                  border: UnderlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _translationController,
                 // Make it readonly if you don't want users to edit it
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
      ),
    );
  }

  void translateWord(String word) async {
    try {
      final response = await http.get(Uri.parse("https://search.naver.com/search.naver?where=nexearch&sm=top_hty&fbm=0&ie=utf8&query=$word+%EB%9C%BB"));
      var document = parse(response.body);
      var translation = document.querySelector("p.mean.api_txt_lines")?.text;

      setState(() {
        _translationController.text = translation ?? "Translation not found.";
      });
    } catch (e) {
      setState(() {
        _translationController.text = "Translation failed.";
      });
    }
  }
}
