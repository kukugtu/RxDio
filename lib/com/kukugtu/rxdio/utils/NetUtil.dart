import 'package:dio/dio.dart';
import 'package:rxdio/com/kukugtu/rxdio/utils/DatabaseUtil.dart';
import 'package:rxdio/com/kukugtu/rxdio/utils/MD5Util.dart';
import 'package:rxdio/com/kukugtu/rxdio/utils/TextUtil.dart';
class NetUtil {
  //缓存模式设置
  static CacheMode cacheMode = CacheMode.REQUEST_FAILED_READ_CACHE;
  static const String _BASEURL = "https://server.kukugtu.top/UGrowService";

  Future<Response> get(String path, Map<String, String> params,
      Function(Object, bool) stringCallback) async {
    switch (cacheMode) {
      // TODO 默认缓存还未实现，需要读取请求头。
      case CacheMode.DEFAULT:
        break;

      case CacheMode.FIRST_CACHE_THEN_REQUEST:
        getCache(path, params, stringCallback).then((list) {
          if (list.length > 0) {
            stringCallback(list[0]["value"].toString(), true);
          } else {
            return getNet(path, params, stringCallback).then((response) {
              stringCallback(response.toString(), false);
              saveCache(
                  getCacheKeyFromParams(path, params), response.toString());
            });
          }
          getNet(path, params, stringCallback).then((response) {
            stringCallback(response.toString(), false);
            saveCache(getCacheKeyFromParams(path, params), response.toString());
          });
        });

        break;
      case CacheMode.NO_CACHE:
        return getNet(path, params, stringCallback).then((response) {
          stringCallback(response.toString(), false);
          saveCache(getCacheKeyFromParams(path, params), response.toString());
        });
        break;
      case CacheMode.REQUEST_FAILED_READ_CACHE:
        return getNet(path, params, stringCallback).then((response) {
          stringCallback(response.toString(), false);
          saveCache(getCacheKeyFromParams(path, params), response.toString());
        }, onError: (e) {
          getNetCache(path, params, stringCallback).then((response) {
            stringCallback(response.toString(), true);
          });
        });
        break;
    }
  }

  /*
   * 获取get缓存请求
   */
  static Future<Response> getNetCache(String path, Map<String, String> params,
      Function(Object, bool) stringCallback) async {
    Dio dio = new Dio();
    dio.interceptors.add(createInterceptor(
        getCacheKeyFromParams(path, params), dio, stringCallback));
    return await dio.get(_BASEURL + path + fromMap2ParamsString(params));
  }

  /*
   * 获取get缓存请求
   */
  static Future<List> getCache(String path, Map<String, String> params,
      Function(Object, bool) stringCallback) async {
    return DatabaseUtil.queryHttp(
        DatabaseUtil.database, getCacheKeyFromParams(path, params));
  }

  /*
   * 获取get网络请求
   */
  static Future<Response> getNet(String path, Map<String, String> params,
      Function(Object, bool) stringCallback) async {
    Dio dio = new Dio();
    return await dio.get(_BASEURL + path + fromMap2ParamsString(params));
  }

  /*
   * 拼接get参数
   */
  static String fromMap2ParamsString(Map<String, String> params) {
    if (params == null || params.length <= 0) {
      return "";
    }
    String paramsStr = "?";
    params.forEach((key, value) {
      paramsStr = paramsStr + key + "=" + value + "&";
    });

    return paramsStr;
  }

  /*
   * 生成Dio对象，确定是否需要缓存
   */
  static Dio createDio(String path, Map<String, String> params,
      Function(Object, bool) stringCallback, bool useCache) {
    Dio dio = new Dio();

    //需要缓存时，生成cacheKey
    if (useCache) {
      dio.interceptors.add(createInterceptor(
          getCacheKeyFromParams(path, params), dio, stringCallback));
    }
    return dio;
  }

  /*
   * 生成缓存拦截器
   */
  static InterceptorsWrapper createInterceptor(
      String cacheKey, Dio dio, Function(Object, bool) stringCallback) {
    InterceptorsWrapper interceptor =
        InterceptorsWrapper(onRequest: (RequestOptions options) async {
      DatabaseUtil.queryHttp(DatabaseUtil.database, cacheKey).then((cacheList) {
        if (cacheList.length > 0 &&
            !TextUtil.isEmpty(cacheList[0].toString())) {
          //返回数据库内容
          stringCallback(cacheList[0]["value"].toString(), true);
        }
      });
      return options;
    }, onResponse: (Response response) {
      return response;
    }, onError: (DioError e) {
      return e;
    });
    return interceptor;
  }

  static void saveCache(String cacheKey, String value) {

    DatabaseUtil.queryHttp(DatabaseUtil.database, cacheKey).then((list) {
      if (list != null && list.length > 0) {
        //更新数据库数据
        DatabaseUtil.updateHttp(DatabaseUtil.database, cacheKey, value);
      } else {
        //插入数据库数据
        DatabaseUtil.insertHttp(DatabaseUtil.database, cacheKey, value);
      }
    });
  }

  static String getCacheKeyFromParams(String path, Map<String, String> params) {
    String cacheKey = "";
    if (!(TextUtil.isEmpty(path))) {
      cacheKey = cacheKey + MD5Util.generateMd5(path);
    } else {
      throw new Exception("请求地址不能为空！");
    }
    if (params != null && params.length > 0) {
      String paramsStr = "";
      params.forEach((key, value) {
        paramsStr = paramsStr + key + value;
      });
      cacheKey = cacheKey + MD5Util.generateMd5(paramsStr);
    }
    return cacheKey;
  }
}

enum CacheMode {
  NO_CACHE, //没有缓存
  DEFAULT, //按照HTTP协议的默认缓存规则，例如有304响应头时缓存
  REQUEST_FAILED_READ_CACHE, //先请求网络，如果请求网络失败，则读取缓存，如果读取缓存失败，本次请求失败
  FIRST_CACHE_THEN_REQUEST, //先使用缓存，不管是否存在，仍然请求网络
}

//给请求异常封装一下，用于判断异常，添加自己的错误信息
class NetError {
  Object e;
  String errorMsg;

  NetError({this.e, this.errorMsg});
}
