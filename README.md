# react-native-weibo

React Native的新浪微博登录插件, react-native版本需要0.17.0及以上
## 如何安装

### 首先安装npm包

```bash
npm install react-native-weibo --save
```

#### Note: rnpm requires node version 4.1 or higher

### 安装iOS工程
将`node_modules/react-native-weibo/ios/RCTWeiboAPI.xcodeproj`加入到工程中
将`node_modules/react-native-weibo/ios/libWeiboSDK/WeiboSDK.bundle`加入到工程中(必须，很重要，不然登录的时候会crash)

在工程target的`Build Phases->Link Binary with Libraries`中加入`libRCTWeiboAPI.a、libsqlite3.tbd、liz.tbd、ImageIO.framework、SystemConfiguration.framework、Security.framework、CoreTelephony.framework、CoreText.framework`


在`Info->URL Types` 中增加QQ的scheme： `Identifier` 设置为`sina`, `URL Schemes` 设置为你注册的微博开发者账号中的APPID，需要加前缀`wb`，例如`wb1915346979`

在你工程的`AppDelegate.m`文件中添加如下代码：

```
#import "../Libraries/LinkingIOS/RCTLinkingManager.h"


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  return [RCTLinkingManager application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

```

### iOS9的适配问题

由于iOS9的发布影响了微博SDK与应用的集成方式，为了确保好的应用体验，我们需要采取如下措施：
#### 1.对传输安全的支持
在iOS9系统中，默认需要为每次网络传输建立SSL。解决这个问题：

- 将NSAllowsArbitraryLoads属性设置为YES，并添加到你应用的plist中
- 
	<key>NSAppTransportSecurity</key>
	<dict>
	<key>NSAllowsArbitraryLoads</key>
	</true>
	</dict>

#### 2.对应用跳转的支持
如果你需要用到微博的相关功能，如登陆，分享等。并且需要实现跳转到微博的功能，在iOS9系统中就需要在你的app的plist中添加下列键值对。否则在canOpenURL函数执行时，就会返回NO。了解详情请至[https://developer.apple.com/videos/wwdc/2015/?id=703](https://developer.apple.com/videos/wwdc/2015/?id=703)

-
	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>sinaweibohd</string>
		<string>sinaweibo</string>
		<string>weibosdk</string>
		<string>weibosdk2.5</string>
	</array>
	


### 安装Android工程

在`android/settings.gradle`里添加如下代码：

```
include ':react-native-weibo'
project(':react-native-weibo').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-weibo/android')
```

在`android/app/build.gradle`里的`dependencies`结构中添加如下代码：

```
dependencies{
    ... // 原本的代码
    compile project(':react-native-weibo')
}
```

`android/app/build.gradle`里，defaultConfig栏目下添加如下代码：

```
		manifestPlaceholders = [
            WB_APPID: "微博的APPID"		//在此修改微博APPID
        ]
```

以后如果需要修改APPID，只需要修改此一处。


`android/app/src/main/java/<你的包名>/MainActivity.java`中，`public class MainActivity`之前增加：

```java
import cn.reactnative.modules.weibo.WeiboPackage;
```

`.addPackage(new MainReactPackage())`之后增加：

```java
                .addPackage(new WeiboPackage())
```

另外，确保你的MainActivity.java中有`onActivityResult`的实现：

```java
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

#### WeiboAPI.shareToWeibo(data)

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