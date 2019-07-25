# rxdio

结合了RxDart+Dio+Sqlite组成的网络库

目前支持GET，POST请求，
缓存模式支持：
1 NO_CACHE, //没有缓存

2 DEFAULT, //按照HTTP协议的默认缓存规则(暂未实现)

3 REQUEST_FAILED_READ_CACHE, //先请求网络，如果请求网络失败，则读取缓存，如果读取缓存失败，本次请求失败

4 FIRST_CACHE_THEN_REQUEST, //先使用缓存，不管是否存在，仍然请求网络




step 1：

添加依赖
rxdio:
    git:
      url: git://github.com/kukugtu/RxDio.git

step 2:
尽早初始化,初始化完成之前缓存功能不可用
DatabaseUtil.initDatabase();

step 3：
RxDio<String>()
  ..setBaseUrl("https://web.kukugtu.top/")
  ..setPath("KukugtuProject/redpackage/ListRedpackage_app.php")
  ..setMethord(REQUEST_METHORD.GET)
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
