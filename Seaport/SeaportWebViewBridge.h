//
//  SeaportWebViewBridge.h
//  Seaport
//
//  Created by ltebean on 14-7-2.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SeaportWebViewBridge : NSObject
- (id)initWithWebView:(UIWebView *)webView viewController:(UIViewController *)vc param:(NSDictionary *)param handler:(void (^)(id)) handler;
- (void)sendData:(id)data;
@end

