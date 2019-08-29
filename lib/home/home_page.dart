import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gank/entity/entity.dart';
import 'package:gank/home/drawer.dart';
import 'package:gank/home/gank_list_widget.dart';

import '../api/api.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.blue),
      home: _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  final String title = "最新";

  _HomePage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> with TickerProviderStateMixin {
  Future<Daily> _future;

  @override
  void initState() {
    super.initState();
    _future = API().getLatest();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Daily>(
      // 加载最新数据
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<Daily> snapshot) {
        TabBar tabBar;
        Widget bodyWidget;
        if (snapshot.connectionState != ConnectionState.done) {
          // 正在加载
          bodyWidget = _createLoadingBody();
        } else if (snapshot.hasError || snapshot.data.error) {
          // 加载失败
          bodyWidget = _createErrorBody(context);
        } else {
          // 加载成功
          List<String> categories = snapshot.data.categories;
          _filterAndSortCategories(categories);
          TabController controller = TabController(length: categories.length, vsync: this);
          tabBar = _initTabBar(categories, controller);
          bodyWidget = _initTabBarView(categories, snapshot.data.result, controller);
        }
        // 构建最终显示的 Widget 树
        return Scaffold(
          appBar: _createAppBar(widget.title, tabBar),
          body: Center(child: bodyWidget),
          drawer: HomeDrawer(),
        );
      },
    );
  }

  AppBar _createAppBar(String title, TabBar tabBar) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      bottom: tabBar,
    );
  }

  Widget _createLoadingBody() {
    return CircularProgressIndicator();
  }

  Widget _createErrorBody(context) {
    return FlatButton(
      child: Text(
        "加载失败，点我重试",
        style: TextStyle(color: Theme.of(context).primaryColor),
      ),
      onPressed: () {
        setState(() {});
      },
    );
  }

  _filterAndSortCategories(List<String> categories) {
    categories.remove("福利");
    categories.remove("休息视频");
    categories.sort();
  }

  TabBar _initTabBar(List<String> categories, TabController _controller) {
    return TabBar(
      isScrollable: true,
      controller: _controller,
      tabs: categories.map((category) => Tab(text: category)).toList(),
    );
  }

  TabBarView _initTabBarView(
    List<String> categories,
    Map<String, List<Gank>> data,
    TabController _controller,
  ) {
    return TabBarView(
      controller: _controller,
      physics: PageScrollPhysics(parent: BouncingScrollPhysics()),
      children: categories.map((category) => GankListWidget(data[category])).toList(),
    );
  }
}