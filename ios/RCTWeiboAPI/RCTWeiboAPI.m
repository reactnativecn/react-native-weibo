//
//  RCTWeiboAPI.m
//  RCTWeiboAPI
//
//  Created by LvBingru on 1/6/16.
//  Copyright © 2016 erica. All rights reserved.
//

#import "RCTWeiboAPI.h"
#import "WeiboSDK.h"

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTImageLoader.h>
#else
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import "RCTImageLoader.h"
#endif

#define INVOKE_FAILED (@"WeiBo API invoke returns false.")
#define RCTWBEventName (@"Weibo_Resp")


#define RCTWBShareTypeNews @"news"
#define RCTWBShareTypeImage @"image"
#define RCTWBShareTypeText @"text"
#define RCTWBShareTypeVideo @"video"
#define RCTWBShareTypeAudio @"audio"

#define RCTWBShareType @"type"
#define RCTWBShareText @"text"
#define RCTWBShareTitle @"title"
#define RCTWBShareDescription @"description"
#define RCTWBShareWebpageUrl @"webpageUrl"
#define RCTWBShareImageUrl @"imageUrl"
#define RCTWBShareAccessToken @"accessToken"

BOOL gRegister = NO;

@interface RCTWeiboAPI()<WeiboSDKDelegate>

@end

@implementation RCTWeiboAPI

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (instancetype)init
{
    self = [super init];
    if (self) {

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURL:) name:@"RCTOpenURLNotification" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

RCT_EXPORT_METHOD(login:(NSDictionary *)config
                  :(RCTResponseSenderBlock)callback)
{
    [self _autoRegisterAPI];

    WBAuthorizeRequest *request = [self _genAuthRequest:config];
    BOOL success = [WeiboSDK sendRequest:request];
    callback(@[success?[NSNull null]:INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(logout)
{
    [WeiboSDK logOutWithToken:nil delegate:nil withTag:nil];
}

RCT_EXPORT_METHOD(shareToWeibo:(NSDictionary *)aData
                  :(RCTResponseSenderBlock)callback)
{
    [self _autoRegisterAPI];

    NSString *imageUrl = aData[RCTWBShareImageUrl];
    if (imageUrl.length && _bridge.imageLoader) {
        CGSize size = CGSizeZero;
        if (![aData[RCTWBShareType] isEqualToString:RCTWBShareTypeImage]) {
            size = CGSizeMake(80,80);
        }
        [_bridge.imageLoader loadImageWithURLRequest:[RCTConvert NSURLRequest:imageUrl] size:size scale:1 clipped:FALSE resizeMode:UIViewContentModeScaleToFill progressBlock:nil partialLoadBlock: nil completionBlock:^(NSError *error, UIImage *image) {
            [self _shareWithData:aData image:image];
        }];
    }
    else {
        [self _shareWithData:aData image:nil];
    }
    callback(@[[NSNull null]]);
}


- (void)handleOpenURL:(NSNotification *)note
{
    NSDictionary *userInfo = note.userInfo;
    NSString *url = userInfo[@"url"];
    [WeiboSDK handleOpenURL:[NSURL URLWithString:url] delegate:self];
}


#pragma mark - sina delegate
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request
{
    if ([request isKindOfClass:WBProvideMessageForWeiboRequest.class])
    {
        
    }
}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response
{
    NSMutableDictionary *body = [NSMutableDictionary new];
    body[@"errCode"] = @(response.statusCode);
    // 分享
    if ([response isKindOfClass:WBSendMessageToWeiboResponse.class])
    {
        body[@"type"] = @"WBSendMessageToWeiboResponse";
        if (response.statusCode == WeiboSDKResponseStatusCodeSuccess)
        {
            WBSendMessageToWeiboResponse *sendResponse = (WBSendMessageToWeiboResponse *)response;
            WBAuthorizeResponse *authorizeResponse = sendResponse.authResponse;
            if (sendResponse.authResponse != nil) {
                body[@"userID"] = authorizeResponse.userID;
                body[@"accessToken"] = authorizeResponse.accessToken;
                body[@"expirationDate"] = @([authorizeResponse.expirationDate timeIntervalSince1970]);
                body[@"refreshToken"] = authorizeResponse.refreshToken;
            }
        }
        else
        {
            body[@"errMsg"] = [self _getErrMsg:response.statusCode];
        }
    }
    // 认证
    else if ([response isKindOfClass:WBAuthorizeResponse.class])
    {
        body[@"type"] = @"WBAuthorizeResponse";
        if (response.statusCode == WeiboSDKResponseStatusCodeSuccess)
        {
            WBAuthorizeResponse *authorizeResponse = (WBAuthorizeResponse *)response;
            body[@"userID"] = authorizeResponse.userID;
            body[@"accessToken"] = authorizeResponse.accessToken;
            body[@"expirationDate"] = @([authorizeResponse.expirationDate timeIntervalSince1970]*1000);
            body[@"refreshToken"] = authorizeResponse.refreshToken;
        }
        else
        {
            body[@"errMsg"] = [self _getErrMsg:response.statusCode];
        }
    }
    [self.bridge.eventDispatcher sendAppEventWithName:RCTWBEventName body:body];
}

#pragma mark - private

// 如果js没有调用registerApp，自动从plist中读取appId
- (void)_autoRegisterAPI
{
    if (gRegister) {
        return;
    }
    
    NSArray *list = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleURLTypes"];
    for (NSDictionary *item in list) {
        NSString *name = item[@"CFBundleURLName"];
        if ([name isEqualToString:@"sina"]) {
            NSArray *schemes = item[@"CFBundleURLSchemes"];
            if (schemes.count > 0)
            {
                NSString *appId = [schemes[0] substringFromIndex:@"wb".length];
                if ([WeiboSDK registerApp:appId]) {
                    gRegister = YES;
                }
#ifdef DEBUG
                [WeiboSDK enableDebugMode:YES];
#endif
                break;
            }
        }
    }
}

- (NSString *)_getErrMsg:(NSInteger)errCode
{
    NSString *errMsg = @"微博认证失败";
    switch (errCode) {
        case WeiboSDKResponseStatusCodeUserCancel:
            errMsg = @"用户取消发送";
            break;
        case WeiboSDKResponseStatusCodeSentFail:
            errMsg = @"发送失败";
            break;
        case WeiboSDKResponseStatusCodeAuthDeny:
            errMsg = @"授权失败";
            break;
        case WeiboSDKResponseStatusCodeUserCancelInstall:
            errMsg = @"用户取消安装微博客户端";
            break;
        case WeiboSDKResponseStatusCodePayFail:
            errMsg = @"支付失败";
            break;
        case WeiboSDKResponseStatusCodeShareInSDKFailed:
            errMsg = @"分享失败";
            break;
        case WeiboSDKResponseStatusCodeUnsupport:
            errMsg = @"不支持的请求";
            break;
        default:
            errMsg = @"位置";
            break;
    }
    return errMsg;
}

- (void)_shareWithData:(NSDictionary *)aData image:(UIImage *)aImage
{
    WBMessageObject *message = [WBMessageObject message];
    NSString *text = aData[RCTWBShareText];
    message.text = text;
    
    NSString *type = aData[RCTWBShareType];
    if ([type isEqualToString:RCTWBShareTypeText]) {
    }
    else if ([type isEqualToString:RCTWBShareTypeImage]) {
        //        大小不能超过10M
        WBImageObject *imageObject = [WBImageObject new];
        if (aImage) {
            imageObject.imageData = UIImageJPEGRepresentation(aImage, 0.7);
        }
        message.imageObject = imageObject;
    }
    else {
        if ([type isEqualToString:RCTWBShareTypeVideo]) {
            WBVideoObject *videoObject = [WBVideoObject new];
            videoObject.videoUrl = aData[RCTWBShareWebpageUrl];
            message.mediaObject = videoObject;
        }
        else if ([type isEqualToString:RCTWBShareTypeAudio]) {
            WBMusicObject *musicObject = [WBMusicObject new];
            musicObject.musicUrl = aData[RCTWBShareWebpageUrl];
            message.mediaObject = musicObject;
        }
        else {
            WBWebpageObject *webpageObject = [WBWebpageObject new];
            webpageObject.webpageUrl = aData[RCTWBShareWebpageUrl];
            message.mediaObject = webpageObject;
        }
        message.mediaObject.objectID = [NSDate date].description;
        message.mediaObject.description = aData[RCTWBShareDescription];
        message.mediaObject.title = aData[RCTWBShareTitle];
        if (aImage) {
            //            @warning 大小小于32k
            message.mediaObject.thumbnailData = UIImageJPEGRepresentation(aImage, 0.7);
        }
    }
    
    WBAuthorizeRequest *authRequest = [self _genAuthRequest:aData];
    NSString *accessToken = aData[RCTWBShareAccessToken];
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message authInfo:authRequest access_token:accessToken];
    
    BOOL success = [WeiboSDK sendRequest:request];
    if (!success) {
        NSMutableDictionary *body = [NSMutableDictionary new];
        body[@"errMsg"] = INVOKE_FAILED;
        body[@"errCode"] = @(-1);
        body[@"type"] = @"WBSendMessageToWeiboResponse";
        [_bridge.eventDispatcher sendAppEventWithName:RCTWBEventName body:body];
    }
}

- (WBAuthorizeRequest *)_genAuthRequest:(NSDictionary *)config
{
    NSString *redirectURI = config[@"redirectURI"];
    NSString *scope = config[@"scope"];
    
    WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
    authRequest.redirectURI = redirectURI;
    authRequest.scope = scope;
    
    return authRequest;
}

@end
