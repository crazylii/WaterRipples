import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WaterRipples extends StatefulWidget {
  const WaterRipples({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WaterRipplesState();
}

class _WaterRipplesState extends State<WaterRipples>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  //动画控制器
  final List<AnimationController> _controllers = [];
  //动画控件集合
  final List<Widget> _children = [];
  //添加蓝牙检索动画计时器
  Timer? _searchBluetoothTimer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("蓝牙扫描"),
      ),
      body: Align(
        alignment: Alignment.center,
        child: Column(children: [
          const SizedBox(
            height: 40,
          ),
          SizedBox(
            width: 290,
            height: 290,
            child: Stack(
              alignment: Alignment.center,
              children: _children,
            ),
          ),
          const SizedBox(
            height: 48,
          ),
          const Text(
            "正在扫描附近的蓝牙设备...",
            style: TextStyle(color: Color(0xff282c37), fontSize: 18),
          )
        ]),
      ),
    );
  }

  ///初始化蓝牙检索动画，依次添加5个缩放动画，形成水波纹动画效果
  void _startAnimation() {
    //动画启动前确保_children控件总数为0
    _children.clear();
    int count = 0;
    //添加第一个圆形缩放动画
    _addSearchAnimation(true);
    //以后每隔1秒，再次添加一个缩放动画，总共添加4个
    _searchBluetoothTimer =
        Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _addSearchAnimation(true);
      count++;
      if (count >= 4) {
        timer.cancel();
      }
    });
  }

  ///添加蓝牙检索动画控件
  ///init: 首次添加5个基本控件时，=true，
  void _addSearchAnimation(bool init) {
    var controller = _createController();
    _controllers.add(controller);
    print("tag——children length : ${_children.length}");
    var animation = Tween(begin: 50.0, end: 290.0)
        .animate(CurvedAnimation(parent: controller, curve: Curves.linear));
    if (!init) {
      //5个基本动画控件初始化完成的情况下，每次添加新的动画控件时，移除第一个，确保动画控件始终保持5个
      _children.removeAt(0);
      //添加新的动画控件
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        //动画页面没有执行退出情况下，继续添加动画
        _children.add(AnimatedBuilder(
            animation: controller,
            builder: (BuildContext context, Widget? child) {
              return Opacity(
                // opacity: (300.0 - animation.value) / 300.0,
                opacity: 1.0 - ((animation.value - 50.0) / 240.0),
                child: ClipOval(
                  child: Container(
                    width: animation.value,
                    height: animation.value,
                    color: const Color(0xff9fbaff),
                  ),
                ),
              );
            }));
        try {
          //动画页退出时，捕获可能发生的异常
          controller.forward();
          setState(() {});
        } catch (e) {
          return;
        }
      });
    } else {
      _children.add(AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            return Opacity(
              opacity: 1.0 - ((animation.value - 50.0) / 240.0),
              child: ClipOval(
                child: Container(
                  width: animation.value,
                  height: animation.value,
                  color: const Color(0xff9fbaff),
                ),
              ),
            );
          }));
      controller.forward();
      setState(() {});
    }
  }

  ///创建蓝牙检索动画控制器
  AnimationController _createController() {
    var controller = AnimationController(
        duration: const Duration(milliseconds: 4000), vsync: this);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
        if (_controllers.contains(controller)) {
          _controllers.remove(controller);
        }
        //每次动画控件结束时，添加新的控件，保持动画的持续性
        if (mounted) _addSearchAnimation(false);
      }
    });
    return controller;
  }

  ///监听应用状态，
  /// 生命周期变化时回调
  /// resumed:应用可见并可响应用户操作
  /// inactive:用户可见，但不可响应用户操作
  /// paused:已经暂停了，用户不可见、不可操作
  /// suspending：应用被挂起，此状态IOS永远不会回调
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      //应用退至后台，销毁蓝牙检索动画
      _disposeSearchAnimation();
    } else if (state == AppLifecycleState.resumed) {
      //应用回到前台，重新启动动画
      _startAnimation();
    }
  }

  ///销毁动画
  void _disposeSearchAnimation() {
    //释放动画所有controller
    for (var element in _controllers) {
      element.dispose();
    }
    _controllers.clear();
    _searchBluetoothTimer?.cancel();
    _children.clear();
  }

  @override
  void initState() {
    super.initState();
    _startAnimation();
    //添加应用生命周期监听
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    print("tag--=========================dispose===================");
    //销毁动画
    _disposeSearchAnimation();
    //销毁应用生命周期观察者
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }
}
