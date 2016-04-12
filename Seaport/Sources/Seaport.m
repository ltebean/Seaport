//
//  Seaport.m
//  Seaport
//
//  Created by ltebean on 14-5-14.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import "Seaport.h"
#import "SeaportHttp.h"
#import "SSZipArchive.h"

#define CONFIG_FILE @"config.plist"
#define ERROR_DOMAIN @"io.seaport"

#define FM [NSFileManager defaultManager]
#define ROOT_DIRECTORY @"seaport"

typedef enum {
    DownloadZipError = -1000,
    UnZipError,
} Error;

@interface Seaport()
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *dbName;
@property (nonatomic, copy) NSString *appDirectory;
@property (nonatomic, strong) SeaportHttp *http;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation Seaport

- (id)initWithAppName:(NSString *)appName serverHost:(NSString *)host sevrerPort:(NSString *)port dbName:(NSString *)dbName {
    if (self = [super init]) {
        self.appName = appName;
        self.dbName = dbName;
        self.appDirectory = [self createAppFolderWithAppName:self.appName];
        if (![self loadConfig]) {
            [self saveConfig:@{@"packages":@{}}];
        }
        self.operationQueue = [[NSOperationQueue alloc] init];
        [self.operationQueue setMaxConcurrentOperationCount:1];
        NSString *serverAddress = [NSString stringWithFormat:@"%@:%@", host, port];
        
        self.http = [[SeaportHttp alloc] initWithDomain:serverAddress operationQueue:self.operationQueue];
    }
    return self;
}

- (NSString *)createAppFolderWithAppName:(NSString *)appName
{
    NSURL *documentsDirectoryURL = [FM URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    
    NSURL *seaportDirectory = [documentsDirectoryURL URLByAppendingPathComponent:ROOT_DIRECTORY];
    NSString *appDirectory = [seaportDirectory URLByAppendingPathComponent:appName].path;
    
//    NSLog(@"%@",appDirectory);
    
    BOOL exists= [FM fileExistsAtPath:appDirectory];
    if (!exists) {
        [FM removeItemAtPath:seaportDirectory.path error:nil];
        [FM createDirectoryAtPath:appDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return appDirectory;
}

- (void)checkUpdate
{
    [self updateLocal];
    [self updateRemote];
}

- (void)updateLocal
{
    @synchronized(self) {
        NSMutableDictionary *config=[self loadConfig];
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
    NSString *path = [NSString stringWithFormat:@"/%@/_design/app/_view/byApp",self.dbName];
    [self.http sendRequestToPath:path method:@"GET" params:@{@"key":[NSString stringWithFormat:@"\"%@\"",self.appName]} cookies:nil completionHandler:^(NSDictionary *result) {
        NSDictionary *localPackages = [self loadConfig][@"packages"];
        for (NSDictionary *row in result[@"rows"]) {
            NSDictionary *package = row[@"value"];
            NSString *packageName = package[@"packageName"];
            NSDictionary *localPackage = localPackages[packageName];
            if (!package[@"activeVersion"]) {
                continue;
            }
            BOOL localEqualToRemote = [localPackage[@"available"] isEqualToString:package[@"activeVersion"]];
            if (!localPackage || !localEqualToRemote) {
                [self updatePackage:package toVersion:package[@"activeVersion"]];
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
    NSString *packageName = package[@"packageName"];
    NSString *destinationPath = [self packagePathWithName:packageName version:version];
    NSString *zipPath = [destinationPath stringByAppendingString:@".zip"];
    
    if ([FM fileExistsAtPath:destinationPath]) {
        return;
    }
    
    [self.deletage seaport:self didStartDownloadPackage:packageName version:version];
    
    NSString *path = [NSString stringWithFormat:@"/%@/%@",self.dbName,package[@"zip"]];
    [self.http downloadFileAtPath:path params:nil cookies:nil completionHandler:^(NSData *data) {
        if ([NSThread isMainThread]) {
            NSLog(@"%@", @"hahahahahha");
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
