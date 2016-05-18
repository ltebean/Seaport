//
//  ViewController.m
//  Seaport
//
//  Created by ltebean on 14-5-14.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import "ViewController.h"
#import "Seaport.h"
#import "SeaportWebViewBridge.h"


@interface ViewController  () <UIWebViewDelegate, SeaportDelegate>
@property (nonatomic,strong) Seaport *seaport ;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *packageRequirements = @[
        @{@"name": @"package1", @"versionRange": @">1.0.0"}
    ];
    
    self.seaport = [[Seaport alloc] initWithAppName:@"TestApp"
                                             secret:@"secret"
                                      serverAddress:@"http://localhost:8080"
                                packageRequirements:packageRequirements];
    self.seaport.deletage=self;
}


- (void)viewWillAppear:(BOOL)animated  {
    [self refresh:nil];
}

- (IBAction)refresh:(id)sender {
    
    NSString *rootPath = [self.seaport packagePath:@"package1"];
    if(rootPath){
        NSString *filePath = [rootPath stringByAppendingPathComponent:@"index.html"];
        NSURL *localURL=[NSURL fileURLWithPath:filePath];
        NSURLRequest *request=[NSURLRequest requestWithURL:localURL];
        [self.webView loadRequest:request];
    }
}


- (IBAction)check:(id)sender {
    [self.seaport checkUpdates];
}

- (void)seaport:(Seaport *)seaport didFailedToPullConfigWithError:(NSError *)error
{
    NSLog(@"failed to pull config: %@", error);
}

- (void)seaport:(Seaport *)seaport didStartDownloadPackage:(NSString *)packageName version:(NSString *)version
{
    NSLog(@"start download package: %@@%@", packageName, version);
}

- (void)seaport:(Seaport *)seaport didFinishDownloadPackage:(NSString *)packageName version:(NSString *)version
{
    NSLog(@"finish download package: %@@%@", packageName, version);
}

- (void)seaport:(Seaport *)seaport didFailDownloadPackage:(NSString *)packageName version:(NSString *)version withError:(NSError *)error
{
    NSLog(@"faild download package: %@@%@", packageName, version);
}

- (void)seaport:(Seaport *)seaport didFinishUpdatePackage:(NSString *)packageName version:(NSString *)version
{
    NSLog(@"update local package: %@@%@", packageName, version);
}



@end
