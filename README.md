# react-native-weibo

React Native的新浪微博登录插件, react-native版本需要0.17.0及以上
## 如何安装

### 1.首先安装npm包

```bash
npm install react-native-weibo --save
```

### 2.link
#### 自动link方法~ rnpm requires node version 4.1 or higher

```bash
rnpm link
```
link成功命令行会提示

```bash
rnpm info Linking react-native-weibo android dependency 
rnpm info Linking react-native-weibo ios dependency
```

#### 手动link~（如果不能够自动link）
#####ios
a.打开XCode's工程中, 右键点击Libraries文件夹 ➜ Add Files to <...>
b.去node_modules ➜ react-native-weibo ➜ ios ➜ 选择 RCTWeiboAPI.xcodeproj
c.在工程Build Phases ➜ Link Binary With Libraries中添加libRCTWeiboAPI.a

#####Android

```
// file: android/settings.gradle
...

include ':react-native-weibo'
project(':react-native-weibo').projectDir = new File(settingsDir, '../node_modules/react-native-weibo/android')
```

```
// file: android/app/build.gradle
...

dependencies {
    ...
    compile project(':react-native-weibo')
}
```

`android/app/src/main/java/<你的包名>/MainApplication.java`中添加如下两行：

```java
...
import cn.reactnative.modules.weibo.WeiboPackage;  // 在public class MainApplication之前import

public class MainApplication extends Application implements ReactApplication {

  private final ReactNativeHost mReactNativeHost = new ReactNativeHost(this) {
    @Override
    protected boolean getUseDeveloperSupport() {
      return BuildConfig.DEBUG;
    }

    @Override
    protected List<ReactPackage> getPackages() {
      return Arrays.<ReactPackage>asList(
          new WeiboPackage(), // 然后添加这一行
          new MainReactPackage()
      );
    }
  };

  @Override
  public ReactNativeHost getReactNativeHost() {
      return mReactNativeHost;
  }
}
```

### 3.工程配置
#### ios配置
将`node_modules/react-native-weibo/ios/libWeiboSDK/WeiboSDK.bundle`加入到工程中(必须，很重要，不然登录的时候会crash)

在工程target的`Build Phases->Link Binary with Libraries`中加入`libRCTWeiboAPI.a、libsqlite3.tbd、libz.tbd、ImageIO.framework、SystemConfiguration.framework、Security.framework、CoreTelephony.framework、CoreText.framework`


在`Info->URL Types` 中增加QQ的scheme： `Identifier` 设置为`sina`, `URL Schemes` 设置为你注册的微博开发者账号中的APPID，需要加前缀`wb`，例如`wb1915346979`

在你工程的`AppDelegate.m`文件中添加如下代码：

```
#import "../Libraries/LinkingIOS/RCTLinkingManager.h"


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  return [RCTLinkingManager application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

```

##### iOS9的适配问题

由于iOS9的发布影响了微博SDK与应用的集成方式，为了确保好的应用体验，我们需要采取如下措施：
##### a.对传输安全的支持
在iOS9系统中，默认需要为每次网络传输建立SSL。解决这个问题：

- 将NSAllowsArbitraryLoads属性设置为YES，并添加到你应用的plist中
- 
	<key>NSAppTransportSecurity</key>
	<dict>
	<key>NSAllowsArbitraryLoads</key>
	</true>
	</dict>

###### b.对应用跳转的支持
如果你需要用到微博的相关功能，如登陆，分享等。并且需要实现跳转到微博的功能，在iOS9系统中就需要在你的app的plist中添加下列键值对。否则在canOpenURL函数执行时，就会返回NO。了解详情请至[https://developer.apple.com/videos/wwdc/2015/?id=703](https://developer.apple.com/videos/wwdc/2015/?id=703)

-
	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>sinaweibohd</string>
		<string>sinaweibo</string>
		<string>weibosdk</string>
		<string>weibosdk2.5</string>
	</array>
	

#### Android

在`android/app/build.gradle`里，defaultConfig栏目下添加如下代码：

```
manifestPlaceholders = [
    WB_APPID: "微博的APPID"		//在此修改微博APPID
]
```

如果react-native版本<0.18.0,确保你的MainActivity.java中有`onActivityResult`的实现：

```java
private ReactInstanceManager mReactInstanceManager;
@Override
public void onActivityResult(int requestCode, int resultCode, Intent data){
    super.onActivityResult(requestCode, resultCode, data);
    mReactInstanceManager.onActivityResult(requestCode, resultCode, data);
}
```

## 如何使用

### 引入包

```
import * as WeiboAPI from 'react-native-weibo';
```

### API

#### WeiboAPI.login(config)

```javascript
// 登录参数 
config : {	
	scope: 权限设置, // 默认 'all'
	redirectURI: 重定向地址, // 默认 'https://api.weibo.com/oauth2/default.html'(必须和sina微博开放平台中应用高级设置中的redirectURI设置的一致，不然会登录失败)
}
```

返回一个`Promise`对象。成功时的回调为一个类似这样的对象：

```javascript
{
	"accessToken": "2.005e3HMBzh7eFCca6a3854060GQFJf",
	"userID": "1098604232"
	"expirationDate": "1452884401084.538"	
	"refreshToken": "2.005e3HMBzh8eFC3db19a18bb00pvbp"
}
```

#### WeiboAPI.share(data)

分享到微博

```javascript
// 分享文字
{	
	type: 'text', 
	text: 文字内容,
}
```

```javascript
// 分享图片
{	
	type: 'image',
	text: 文字内容,	
	imageUrl: 图片地址	
}
```
