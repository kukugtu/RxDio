import 'package:rxdio/com/kukugtu/rxdio/NetCallBack.dart';
import 'package:rxdio/com/kukugtu/rxdio/rxdio.dart';

void main() {
  print("开始测试");
  RxDio<String>()
    ..setBaseUrl("https://web.kukugtu.top/")
    ..setPath("KukugtuProject/redpackage/ListRedpackage_app.php")
    ..setMethord(REQUEST_METHORD.POST)
    ..setParams(null)
    ..setCacheMode(CacheMode.FIRST_CACHE_THEN_REQUEST)
    ..call(
      new NetCallback(
        onCacheFinish: (data) {
          print("缓存回调：" + data);
        },
        onNetFinish: (data) {
          print("网络回调：" + data);
        },
        onUnkownFinish: (data) {
          print("未知回调：" + data);
        },
      ),
    );
  print("结束测试");
}
