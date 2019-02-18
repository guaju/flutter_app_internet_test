import 'dart:convert'; //使用 json 解析
import 'package:flutter/material.dart';
import 'package:http/http.dart' as client;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Internet Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}


//获得作者列表
Future<List<Author>> _getAuthorList() async {
  var tempList;
  try {
    var response = await client.get(Constants.NAMES);
    if (response.statusCode == 200) {
      var body = response.body;
      var data = AuthorData.fromJson(json.decode(body));
      tempList = data.data.map((data) {
//        print(data);
        return Author.fromJson(data);
      }).toList();
      return tempList;
    }
  } catch (e) {
    print(e);
  }
}


//主视图生成逻辑
class _MyHomePageState extends State<MyHomePage> {
  //获取数据
  Key key = Key('listview');
  List<Author> list = new List();

  //字体样式
  var authorStyle;
  var articalStyle;


  //第一个视图，作者列表页

  @override
  Widget build(BuildContext context) {
    return new FutureBuilder<List<Author>>(
        future: _getAuthorList(),
        builder: (BuildContext context, AsyncSnapshot<List<Author>> list) {
          switch (list.connectionState) {
            case ConnectionState.none:
//          return new Text('网络数据为空');
            case ConnectionState.waiting:
//          return new Text('请等待...');
            default: //如果_calculation执行完毕
              if (list.hasError) //若_calculation执行出现异常
                return new Text('Error: ${list.error}');
              else //若_calculation执行正常完成
                return Scaffold(
                    appBar: new AppBar(
                      title: new Text('listview with net'),
                    ),
                    body: new ListView.builder(
                      itemBuilder: (BuildContext context, int index) {
                        return _getListItem(list.data, index);
                      },
                      itemCount: list.data==null??list.data.length == 0 ? 0 : list.data.length,
                    ));
          }
        });
//
  }

  // 第一个视图的列表条目生成

  Widget _getListItem(List<Author> list, int pos) {
    authorStyle = TextStyle(color: Colors.red, fontSize: 20.0);
    if (list != null) {
      return new GestureDetector(
          onTap: () {
            push2Artical(list[pos]);
          },
          child: Column(
            children: <Widget>[
              Center(
                child: Container(
                  child: Text(
                    list[pos].name,
                    style: authorStyle,
                  ),
                  padding: EdgeInsets.fromLTRB(10,0,10,0),
                ),
              ),
              Divider(height: 1.0)
            ],
          ));
    }
  }


  // 第二个页面，对应作者的对应的文章列表
  Future<List<ArticalData>> _getArticalList(int id) async {
    var response = await client
        .get(Constants.HISTORY_ARTICLES + id.toString() + '/1/json');
    if (response.statusCode == 200) {
      var body = response.body;
      Data data = Data.fromJson(json.decode(body));
      var data2 = data.data;
      var artical = Artical.fromJson(data2);
      List<ArticalData> list = artical.datas.map((data) {
        return ArticalData.fromJson(data);
      }).toList();
      return list;
    }
  }

  //从 作者 到文章的跳转逻辑
  void push2Artical(Author author) {
    var futureBuilder = new FutureBuilder(
      builder: (BuildContext context, AsyncSnapshot<List<ArticalData>> data) {
        switch (data.connectionState) {
          case ConnectionState.waiting:
            return new Text(
              "请等待。。。",
              style: authorStyle,
            );
          case ConnectionState.none:
            return new Text("数据为空",style: authorStyle,);
          default: //如果_calculation执行完毕
            if (data.hasError) //若_calculation执行出现异常
              return new Text('Error: ${data.error}',style: authorStyle,);
            else //若_calculation执行正常完成
              return Scaffold(
                  appBar: new AppBar(
                    title: new Text('listview with net'),
                  ),
                  body: new ListView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      return _getArticalListItem(data.data, index);
                    },
                    itemExtent: 40.0,
                    itemCount: data.data.length,
                  ));
        }
      },
      future: _getArticalList(author.id),
    );

    var router = new MaterialPageRoute(builder: (BuildContext context) {
      return futureBuilder;
    });
    Navigator.of(context).push(router);
  }

  //第二个页面 文章 的列表生成
  Widget _getArticalListItem(List<ArticalData> data, int index) {
    articalStyle = TextStyle(color: Colors.blue, fontSize: 14.0);
    if (data != null) {
      return new GestureDetector(
          onTap: () {
            _2Artical(data[index].link);
          },
          child: Column(
            children: <Widget>[
              Center(
                child: Container(
                  child: Text(
                    data[index].title,
                    style: articalStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  padding: EdgeInsets.all(4.0),
                ),
              ),
              Divider(height: 1.0)
            ],
          ));
    }
  }

  //第二个页面的条目点击事件
  void _2Artical(String link) async {
    if (await canLaunch(link)) {
      await launch(link);
    } else {
      throw 'Could not launch $link';
    }
  }
}


//两个接口
class Constants {
//  获取公众号列表
  static String NAMES = "http://wanandroid.com/wxarticle/chapters/json";

//  查看某个公众号历史数据
//  "http://wanandroid.com/wxarticle/list/405/1/json";
  static String HISTORY_ARTICLES = "http://wanandroid.com/wxarticle/list/";
}


//用到的一些 bean 对象
class AuthorData {
  List<dynamic> data;
  int errorCode;
  String errorMsg;

  AuthorData.fromJson(Map<String, dynamic> map) {
    data = map['data'];
    errorCode = map['errorCode'];
    errorMsg = map['errorMsg'];
  }
}

class Data {
  var data;
  var errorCode;
  var errorMsg;

  Data.fromJson(Map<String, dynamic> map) {
    data = map['data'];
    errorCode = map['errorCode'];
    errorMsg = map['errorMsg'];
  }
}

// 作者bean
class Author {
  var courseId;
  var id;
  var name;
  var order;
  var parentChapterId;
  var userControlSetTop;
  var visible;
  var children;

  //构造方法
  Author.fromJson(Map<String, dynamic> map) {
    courseId = map['courseId'];
    id = map['id'];
    name = map['name'];
    order = map['order'];
    parentChapterId = map['parentChapterId'];
    userControlSetTop = map['userControlSetTop'];
    visible = map['visible'];
    children = map['children'];
  }
}

//  文章bean
class Artical {
  var curPage;
  List<dynamic> datas;
  var offset;
  var over;
  var pageCount;
  var size;
  var total;

  Artical.fromJson(Map<String, dynamic> map) {
    curPage = map['curPage'];
    datas = map['datas'];
    offset = map['offset'];
    over = map['over'];
    pageCount = map['pageCount'];
    size = map['size'];
    total = map['total'];
  }
}

class ArticalData {
  var apkLink;
  var author;
  var chapterId;
  var chapterName;
  var collect;
  var courseId;
  var desc;
  var envelopePic;
  var fresh;
  var id;
  var link;
  var niceDate;
  var origin;
  var projectLink;
  var publishTime;
  var superChapterId;
  var superChapterName;
  List<dynamic> tags;
  var title;
  var type;
  var userId;
  var visible;
  var zan;

  ArticalData.fromJson(Map<String, dynamic> map) {
    apkLink = map['apkLink'];
    author = map['author'];
    chapterId = map['chapterId'];
    chapterName = map['chapterName'];
    collect = map['collect'];
    courseId = map['courseId'];
    desc = map['desc'];
    envelopePic = map['envelopePic'];
    fresh = map['fresh'];
    id = map['id'];
    link = map['link'];
    niceDate = map['niceDate'];
    origin = map['origin'];
    projectLink = map['projectLink'];
    publishTime = map['publishTime'];
    superChapterId = map['superChapterId'];
    superChapterName = map['superChapterName'];
    tags = map['tags'];
    title = map['title'];
    type = map['type'];
    userId = map['userId'];
    visible = map['visible'];
    zan = map['zan'];
  }
}

class Tag {
  var name;
  var url;

  Tag.fromJson(Map<String, dynamic> map) {
    name = map['name'];
    url = map['url'];
  }
}
