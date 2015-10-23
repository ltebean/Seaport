//
//  ViewController.m
//  Seaport
//
//  Created by ltebean on 14-5-14.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import "ViewController.h"
#import "Seaport.h"
#import "SeaportHttp.h"
#import "SeaportWebViewBridge.h"


#define APP_NAME @"emma"
#define SERVER_HOST @"223.4.15.141"
#define SERVER_PORT @"9984"
#define DB_NAME @"seaport"

@interface ViewController  () <UIWebViewDelegate,SeaportDelegate>
@property (nonatomic,strong) Seaport *seaport ;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong,nonatomic) SeaportWebViewBridge *bridge;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.seaport = [[Seaport alloc] initWithAppName:APP_NAME serverHost:SERVER_HOST sevrerPort:SERVER_PORT dbName:DB_NAME];
    self.seaport.deletage=self;
    self.bridge = [SeaportWebViewBridge bridgeForWebView:self.webView param:@{@"city":@"shanghai",@"name": @"ltebean"} dataHandler:^(id data) {
        NSLog(@"receive data: %@",data);
    }];
}


- (void)viewWillAppear:(BOOL)animated  {
    [self refresh:nil];
}

- (IBAction)refresh:(id)sender {
    
    NSString *rootPath = [self.seaport packagePath:@"test"];
    if(rootPath){
        NSString *filePath = [rootPath stringByAppendingPathComponent:@"index.html"];
        NSURL *localURL=[NSURL fileURLWithPath:filePath];
        
//        NSURL *debugURL=[NSURL URLWithString:@"http://localhost:8080/index.html"];
        
        NSURLRequest *request=[NSURLRequest requestWithURL:localURL];
        [self.webView loadRequest:request];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}

- (IBAction)check:(id)sender {
    [self.seaport checkUpdate];
}

- (void)seaport:(Seaport *)seaport didStartDownloadPackage:(NSString *)packageName version:(NSString *)version
{
    NSLog(@"start download package: %@@%@",packageName,version);
}

- (void)seaport:(Seaport *)seaport didFinishDownloadPackage:(NSString *)packageName version:(NSString *)version
{
    NSLog(@"finish download package: %@@%@",packageName,version);
}

- (void)seaport:(Seaport *)seaport didFailDownloadPackage:(NSString *)packageName version:(NSString *)version withError:(NSError *)error
{
    NSLog(@"faild download package: %@@%@",packageName,version);
}

- (void)seaport:(Seaport *)seaport didFinishUpdatePackage:(NSString *)packageName version:(NSString *)version
{
    NSLog(@"update local package: %@@%@",packageName,version);
}



@end
