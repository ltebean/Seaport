//
//  ViewController.m
//  Seaport
//
//  Created by ltebean on 14-5-14.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import "WebViewController.h"
#import "SeaportManager.h"
#import "SeaportWebViewBridge.h"

#define DEBUGGING NO

@interface WebViewController  () <UIWebViewDelegate>
@property (nonatomic,strong) SeaportManager *seaportManager;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) SeaportWebViewBridge *bridge;
@end



@implementation WebViewController


+ (WebViewController *)instance {
    WebViewController *instance = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateInitialViewController];
    return instance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.seaportManager = [SeaportManager shared];
    
    self.bridge = [[SeaportWebViewBridge alloc] initWithWebView:self.webView viewController:self param:self.param handler:^(id data) {
        
    }];
    
    if (DEBUGGING) {
        NSString *urlString = [NSString stringWithFormat:@"http://localhost:3000/%@/%@", self.package, self.page];
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    } else {
        NSString *rootPath = [self.seaportManager packagePath:self.package];
        if(rootPath){
            NSString *filePath = [rootPath stringByAppendingPathComponent:self.page];
            NSURL *localURL = [NSURL fileURLWithPath:filePath];
            NSURLRequest *request = [NSURLRequest requestWithURL:localURL];
            [self.webView loadRequest:request];
        }
    }
    

    
}


- (void)viewWillAppear:(BOOL)animated  {
    [super viewWillAppear:animated];
}

@end
