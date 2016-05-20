//
//  Seaport.m
//  Seaport
//
//  Created by ltebean on 14-5-14.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import "Seaport.h"
#import <SSZipArchive/SSZipArchive.h>

#define CONFIG_FILE @"config.plist"
#define ERROR_DOMAIN @"io.seaport"

#define FM [NSFileManager defaultManager]
#define ROOT_DIRECTORY @"seaport"


@implementation PackageRequirement
@end

typedef enum {
    CheckUpdatesError = 1000,
    DownloadZipError,
    UnZipError,
} Error;

@interface Seaport()
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *appDirectory;
@property (nonatomic, copy) NSString *serverAddress;
@property (nonatomic, copy) NSString *secret;
@property (nonatomic, copy) NSArray *packageRequirements;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (atomic) BOOL inOperation;
@end

@implementation Seaport


- (id)initWithAppName:(NSString *)appName secret:(NSString *)secret serverAddress:(NSString *)serverAddress packageRequirements:(NSArray *)packageRequirements;
{
    if (self = [super init]) {
        self.appName = appName;
        self.secret = secret;
        self.serverAddress = serverAddress;
        self.packageRequirements = packageRequirements;
        self.appDirectory = [self createAppFolderWithAppName:self.appName];
        NSLog(@"app directory: %@", self.appDirectory);
        if (![self loadConfig]) {
            [self saveConfig:@{@"packages":@{}}];
        }
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (NSString *)createAppFolderWithAppName:(NSString *)appName
{
    NSURL *documentsDirectoryURL = [FM URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    
    NSURL *seaportDirectory = [documentsDirectoryURL URLByAppendingPathComponent:ROOT_DIRECTORY];
    NSString *appDirectory = [seaportDirectory URLByAppendingPathComponent:appName].path;
    
    BOOL exists = [FM fileExistsAtPath:appDirectory];
    if (!exists) {
        [FM removeItemAtPath:seaportDirectory.path error:nil];
        [FM createDirectoryAtPath:appDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return appDirectory;
}

- (void)checkUpdates
{
    [self updateLocal];
    [self updateRemote];
}

- (void)updateLocal
{
    @synchronized(self) {
        NSMutableDictionary *config = [self loadConfig];
        NSMutableDictionary *packages = config[@"packages"];
        for (NSString *packageName in [packages allKeys]) {
            NSMutableDictionary *package = packages[packageName];
            if (![package[@"current"] isEqualToString: package[@"available"]]) {
                [self removeLocalPackage:packageName version:package[@"current"]];
                NSString *oldVersion = [package[@"current"] copy];
                package[@"current"] = package[@"available"];
                [self saveConfig:config];
                // remove the old one asynchronously
                [self.operationQueue addOperationWithBlock:^{
                    [self removeLocalPackage:packageName version:oldVersion];
                }];
                [self.deletage seaport:self didFinishUpdatePackage:packageName version:package[@"current"]];
            }
        }
    }
}

- (void)updateRemote
{
    NSString *urlString = [NSString stringWithFormat:@"%@/api/v1/check_updates", self.serverAddress];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSDictionary *body = @{
        @"secret": self.secret,
        @"packageRequirements": self.packageRequirements
    };
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:bodyData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self.deletage seaport:self didFailedToPullConfigWithError:error];
            return;
        }
        NSError *e;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&e];
        if (e || !result) {
            [self.deletage seaport:self didFailedToPullConfigWithError:e];
            return;
        }
        if ([result[@"code"] integerValue] != 200) {
            NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:CheckUpdatesError userInfo:result];
            [self.deletage seaport:self didFailedToPullConfigWithError:error];
            return;
        }
        NSDictionary *localPackages = [self loadConfig][@"packages"];
        for (NSDictionary *package in result[@"data"]) {
            NSString *packageName = package[@"name"];
            NSDictionary *localPackage = localPackages[packageName];
            BOOL localEqualToRemote = [localPackage[@"available"] isEqualToString:package[@"version"]];
            if (!localPackage || !localEqualToRemote) {
                [self updatePackage:package toVersion:package[@"version"]];
            }
        }
    }];
}

- (BOOL)removeLocalPackage:(NSString *)packageName version:(NSString *)version
{
    NSString *path = [self packagePathWithName:packageName version:version];
    return [FM removeItemAtPath:path error:nil];
}

- (void)updatePackage:(NSDictionary *)package toVersion:(NSString *)version
{
    NSString *packageName = package[@"name"];
    NSString *destinationPath = [self packagePathWithName:packageName version:version];
    NSString *zipPath = [destinationPath stringByAppendingString:@".zip"];
    
    if ([FM fileExistsAtPath:destinationPath]) {
        return;
    }
    
    [self.deletage seaport:self didStartDownloadPackage:packageName version:version];
    
    NSURL *url = [NSURL URLWithString:package[@"url"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self.deletage seaport:self didFailDownloadPackage:packageName version:version withError:[NSError errorWithDomain:ERROR_DOMAIN code:DownloadZipError userInfo:nil]];
            return;
        }
        if (!data) {
            [self.deletage seaport:self didFailDownloadPackage:packageName version:version withError:[NSError errorWithDomain:ERROR_DOMAIN code:DownloadZipError userInfo:nil]];
            return;
        }
        // write data to zip
        if (![data writeToFile:zipPath atomically:YES]) {
            [self.deletage seaport:self didFailDownloadPackage:packageName version:version withError:[NSError errorWithDomain:ERROR_DOMAIN code:DownloadZipError userInfo:nil]];
            return;
        }
        
        //unzip
        if (![SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath]) {
            [FM removeItemAtPath:zipPath error:nil];
            [self.deletage seaport:self didFailDownloadPackage:packageName version:version withError:[NSError errorWithDomain:ERROR_DOMAIN code:UnZipError userInfo:nil]];
            return;
        }
        [FM removeItemAtPath:zipPath error:nil];
        
        [self.deletage seaport:self didFinishDownloadPackage:packageName version:version];
        
        // update config
        BOOL localUpdated = NO;
        @synchronized(self) {
            NSMutableDictionary *config = [self loadConfig];
            NSMutableDictionary *packages = config[@"packages"];
            NSMutableDictionary *package = packages[packageName];
            if (!package) {
                package = [[NSMutableDictionary alloc]init];
                packages[packageName] = package;
                package[@"current"] = version;
                localUpdated = YES;
            }
            package[@"available"] = version;
            package[@"time"] = [NSDate date];
            [self saveConfig:config];
        }
        if (localUpdated) {
            [self.deletage seaport:self didFinishUpdatePackage:packageName version:version];
        }
    }];
}

- (NSString *)packagePathWithName:(NSString *)packageName version:(NSString *)version
{
    NSString *packageRootPath = [self.appDirectory stringByAppendingPathComponent:packageName];
    if(![FM fileExistsAtPath:packageName]) {
        [FM createDirectoryAtPath:packageRootPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [packageRootPath stringByAppendingPathComponent:version];
}

- (NSMutableDictionary *)loadConfig
{
    NSString *configFilePath = [self.appDirectory stringByAppendingPathComponent:CONFIG_FILE];
    NSMutableDictionary *config = [[NSMutableDictionary alloc] initWithContentsOfFile:configFilePath];
    return config;
}

- (BOOL)saveConfig:(NSDictionary *)config
{
    NSLog(@"update config to %@",config);
    NSString *configFilePath = [self.appDirectory stringByAppendingPathComponent:CONFIG_FILE];
    return [config writeToFile:configFilePath atomically:YES];
}

- (NSString *)packagePath:(NSString *)packageName;
{
    NSDictionary *package;
    @synchronized(self) {
        package = [self loadConfig][@"packages"][packageName];
    }
    if (!package) {
        return nil;
    }
    NSString *path = [self packagePathWithName:packageName version:package[@"current"]];
    
    if(![FM fileExistsAtPath:path]) {
        return nil;
    }
    return path;
}

@end
