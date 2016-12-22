//
//  ViewController.h
//  Seaport
//
//  Created by Yu Cong on 14-5-18.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController
@property (nonatomic, strong) NSDictionary *param;
@property (nonatomic, copy) NSString *package;
@property (nonatomic, copy) NSString *page;
+ (WebViewController *)instance;
@end
