//
//  ViewController.m
//  Hybrid
//
//  Created by ltebean on 14-5-14.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import "ViewController.h"
#import "Seaport.h"
@interface ViewController  () <UIWebViewDelegate>
@property (nonatomic,strong) Seaport* searport ;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView.delegate=self;
    self.searport = [[Seaport alloc]initWithAppKey:@"Nova" appSecret:@"secret" serverDomain:@"127.0.0.1:9000"];
}

-(void) viewWillAppear:(BOOL)animated  {
    [self refresh:nil];
    
}
- (IBAction)refresh:(id)sender {
    NSString *rootPath = [self.searport packagePath:@"rocket"];
    if(rootPath){
        NSString *filePath = [rootPath stringByAppendingPathComponent:@"test/runner.html"];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]];
        [self.webView loadRequest:request];
    }
}
- (IBAction)check:(id)sender {
    [self.searport checkUpdate];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    
}

-(void) webViewDidStartLoad:(UIWebView *)webView
{
    
}

-(void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"%@",error.description);
}

@end
