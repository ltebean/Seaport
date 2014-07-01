//
//  ViewController.m
//  Seaport
//
//  Created by ltebean on 14-5-14.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import "ViewController.h"
#import "Seaport.h"
@interface ViewController  () <UIWebViewDelegate,SeaportDelegate>
@property (nonatomic,strong) Seaport* seaport ;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView.delegate=self;
    self.seaport = [[Seaport alloc]initWithAppName:@"TestApp"
                                        serverHost:@"223.4.15.141"
                                        sevrerPort:@"9984"
                                            dbName:@"seaport"];
    self.seaport.deletage=self;
}

-(void) viewWillAppear:(BOOL)animated  {
    [self refresh:nil];
    
}
- (IBAction)refresh:(id)sender {
    NSString *rootPath = [self.seaport packagePath:@"hello-world"];
    if(rootPath){
        NSString *filePath = [rootPath stringByAppendingPathComponent:@"index.html"];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]];
        [self.webView loadRequest:request];
    }
}
- (IBAction)check:(id)sender {
    [self.seaport checkUpdate];
}

-(void)seaport:(Seaport*)seaport didStartDownloadPackage:(NSString*) packageName version:(NSString*) version
{
    NSLog(@"start download package: %@@%@",packageName,version);
}

-(void)seaport:(Seaport*)seaport didFinishDownloadPackage:(NSString*) packageName version:(NSString*) version
{
    NSLog(@"finish download package: %@@%@",packageName,version);
}

-(void)seaport:(Seaport*)seaport didFailDownloadPackage:(NSString*) packageName version:(NSString*) version withError:(NSError*) error
{
    NSLog(@"faild download package: %@@%@",packageName,version);
}

-(void)seaport:(Seaport*)seaport didFinishUpdatePackage:(NSString*) packageName version:(NSString*) version
{
    NSLog(@"update local package: %@@%@",packageName,version);
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
