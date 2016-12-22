//
//  SeaportManager.m
//  Seaport
//
//  Created by leo on 16/12/20.
//  Copyright © 2016年 ltebean. All rights reserved.
//

#import "SeaportManager.h"
#import "Seaport.h"

@interface SeaportManager() <SeaportDelegate>
@property (nonatomic, strong) Seaport *seaport;
@end

@implementation SeaportManager
+ (SeaportManager *)shared
{
    static SeaportManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SeaportManager alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray *packageRequirements = @[
            @{@"name": @"main", @"versionRange": @"<1.1.0"}
        ];
        self.seaport = [[Seaport alloc] initWithAppName:@"test"
                                                 secret:@"9ecf3bc4c348592e3590cdfe687e67d7"
                                          serverAddress:@"http://106.187.100.229:8080"
                                    packageRequirements:packageRequirements];
        self.seaport.deletage = self;

    }
    return self;
}

- (void)checkUpdates {
    [self.seaport checkUpdates];
}

- (NSString *)packagePath:(NSString *)package {
    return [self.seaport packagePath:package];
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
