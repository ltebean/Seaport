//
//  SeaportWebViewBridge.m
//  Seaport
//
//  Created by ltebean on 14-7-2.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import "SeaportWebViewBridge.h"
#import "WebViewJavascriptBridge.h"
#import "WebViewController.h"

@interface SeaportWebViewBridge()
@property(nonatomic, strong) NSDictionary *param;
@property(nonatomic, strong) WebViewJavascriptBridge *bridge;
@property(nonatomic, weak) UIViewController *vc;
@end

@implementation SeaportWebViewBridge



- (id)initWithWebView:(UIWebView *)webView viewController:(UIViewController *)vc param:(NSDictionary *)param handler:(void (^)(id)) handler

{
    if (self = [super init]) {
        self.param = param;
        self.vc = vc;
        self.bridge = [WebViewJavascriptBridge bridgeForWebView:webView handler:^(id data, WVJBResponseCallback responseCallback) {
            handler(data);
        }];
        
        [WebViewJavascriptBridge enableLogging];
        
        [self.bridge registerHandler:@"userdefaults:set" handler:^(id data, WVJBResponseCallback responseCallback){
            [[NSUserDefaults standardUserDefaults] setObject:data[@"value"] forKey:data[@"key"]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            responseCallback(@200);
        }];
        
        [self.bridge registerHandler:@"userdefaults:get" handler:^(id data, WVJBResponseCallback responseCallback){
            responseCallback([[NSUserDefaults standardUserDefaults] objectForKey:data]);
        }];
        
        [self.bridge registerHandler:@"page:push" handler:^(id data, WVJBResponseCallback responseCallback){
            WebViewController *vc = [WebViewController instance];
            vc.title = data[@"title"];
            vc.package = data[@"package"];
            vc.page = data[@"page"];
            vc.param = data[@"param"];
            [self.vc.navigationController pushViewController:vc animated:YES];
        }];
        
        [self.bridge registerHandler:@"param:get" handler:^(id data, WVJBResponseCallback responseCallback){
            responseCallback(self.param[data]);
        }];
        
        [self.bridge registerHandler:@"param:getAll" handler:^(id data, WVJBResponseCallback responseCallback){
            responseCallback(self.param);
        }];
        
        [self.bridge registerHandler:@"url:open" handler:^(id data, WVJBResponseCallback responseCallback){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:data]];
        }];
        
    }
    return self;
}

- (void)sendData:(id)data
{
    [self.bridge send:data];
}

@end
