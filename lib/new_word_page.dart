import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class NewWordPage extends StatefulWidget {
  final Function(String, String) onAddWord; // 인자 타입을 (Map<String, String>)에서 (String, String)로 변경

  NewWordPage({Key? key, required this.onAddWord}) : super(key: key);

  @override
  _NewWordPageState createState() => _NewWordPageState();
}

class _NewWordPageState extends State<NewWordPage> {



  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _translationController = TextEditingController();
  final TextEditingController _multiWordController = TextEditingController();
  final TextEditingController _multiTranslationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 두 개의 탭
      child: Scaffold(
        resizeToAvoidBottomInset: false,  // Add this line to prevent UI adjustments
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Calculate 10% of the screen height
        double topPadding = MediaQuery.of(context).size.height * 0.1;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50.0),
                  child: TextField(
                    controller: _wordController,
                    decoration: InputDecoration(
                      labelText: '단어 입력',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          if (_wordController.text.isNotEmpty) {
                            translateWord(_wordController.text, _translationController);
                          }
                        },
                      ),
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(height: 50),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50.0),
                  child: TextField(
                    controller: _translationController,
                    decoration: InputDecoration(
                      labelText: "단어의 뜻",
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                actionButtons(_wordController, _translationController),
              ],
            ),
          ),
        );
      },
    );
  }




  Widget multiAddTab() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Calculate 50% of the screen height
        double topPadding = MediaQuery.of(context).size.height * 0.1;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(top: topPadding, left: 50.0, right: 50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Changed to start to respect top padding
              children: <Widget>[
                TextField(
                  controller: _multiWordController,
                  decoration: InputDecoration(
                    labelText: '여러 단어 입력',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        if (_multiWordController.text.isNotEmpty) {
                          translateWord(_multiWordController.text, _multiTranslationController);
                        }
                      },
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
                actionButtons(_multiWordController, _multiTranslationController)
              ],
            ),
          ),
        );
      },
    );
  }


  Widget actionButtons(TextEditingController wordController, TextEditingController translationController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('돌아가기'),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.grey),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // 키보드 감추기
            // FocusScope.of(context).unfocus();
            final word = wordController.text.trim();
            final meaning = translationController.text.trim();

            if (word.isEmpty) {
              showSnackbar('단어를 입력해주세요! ⚠️', 1000);
            } else {
              widget.onAddWord(word, meaning);
              showSnackbar('${word} 추가 완료 ✅',500);
              wordController.clear();
              translationController.clear();
            }
          },
          child: Text('단어 추가', style: TextStyle(color: Colors.white)),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
          ),
        ),
      ],
    );
  }

  void showSnackbar(String message, int durationMillis) {  // durationMillis 파라미터 추가
    var keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(milliseconds: durationMillis),  // milliseconds를 사용하여 지속 시간 설정
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
              bottom: keyboardHeight + 16, // 기본 마진에 키보드 높이를 추가합니다.
              left: 16,
              right: 16
          ),
        )
    );
  }





  void translateWord(String word, TextEditingController translationController) async {
    try {
      final response = await http.get(Uri.parse("https://search.naver.com/search.naver?where=nexearch&sm=top_hty&fbm=0&ie=utf8&query=$word+%EB%9C%BB"));
      var document = parse(response.body);
      var translation = document.querySelector("p.mean.api_txt_lines")?.text;
      setState(() {
        translationController.text = translation ?? " ";
      });
    } catch (e) {
      setState(() {
        translationController.text = "Translation failed.";
      });
    }
  }
}
