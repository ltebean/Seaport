//
//  API.m
//  Hybrid
//
//  Created by ltebean on 14-5-14.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import "Seaport.h"
#import "SeaportHttp.h"
#import "SSZipArchive.h"

#define CONFIG_FILE @"config.plist"

@interface Seaport ()
@property(nonatomic,copy) NSString* appKey;
@property(nonatomic,copy) NSString* appSecret;
@property(nonatomic,strong) NSString* packageDirectory;
@property(nonatomic,strong) SeaportHttp* http;
@end

@implementation Seaport
- (id) initWithAppKey:(NSString*) appKey appSecret:(NSString*) appSecret serverDomain:(NSString*) serverDomain
{
    if (self = [super init]) {
        self.appKey=appKey;
        self.appSecret=appSecret;
        self.http = [[SeaportHttp alloc]initWithDomain:serverDomain];
        self.packageDirectory= [self createPackageFolderIfNeeded];
        if(![self loadConfig]){
            [self saveConfig:@{@"packages":@{}}];
        }
    }
    return self;
}

-(NSString *) createPackageFolderIfNeeded
{
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString * packageDirectory = [documentsDirectoryURL URLByAppendingPathComponent:@"packages"].path;

    BOOL exists=[[NSFileManager defaultManager] fileExistsAtPath:packageDirectory];
    if (!exists) {
        [[NSFileManager defaultManager] createDirectoryAtPath:packageDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        NSLog(@"create package folder: %@",packageDirectory);
    }else{
        NSLog(@"package folder already exist");
    }
    return packageDirectory;
}

-(void)checkUpdate
{
    [self updateLocal];
    [self updateRemote];
}

-(void) updateLocal
{
    @synchronized(self) {
        BOOL needsUpdate=NO;
        NSMutableDictionary * config=[self loadConfig];
        NSMutableDictionary * packages = config[@"packages"];
        for(NSString* packageName in [packages allKeys]){
            NSMutableDictionary* package = packages[packageName];
            if(![package[@"current"] isEqualToString: package[@"available"]]){
                NSLog(@"update local package %@ to version %@",packageName,package[@"available"]);
                [self removeLocalPackage:packageName version:package[@"current"]];
                package[@"current"]=package[@"available"];
                needsUpdate=YES;
            }
        }
        if(needsUpdate){
            [self saveConfig:config];
        }
    }
}

-(void) updateRemote
{
    [self.http sendRequestToPath:@"/package/_design/app/_view/package" method:@"GET" params:@{@"key":[NSString stringWithFormat:@"\"%@\"",self.appKey]} cookies:nil completionHandler:^(NSDictionary* result) {
        NSDictionary* localPackages = [self loadConfig][@"packages"];
        for(NSDictionary* row in result[@"rows"]){
            NSDictionary* package=row[@"value"];
            NSString *packageName = package[@"name"];
            NSDictionary* localPackage=localPackages[packageName];
            if(!localPackage || ![localPackage[@"available"] isEqualToString:package[@"latest"]]){
                [self updatePackage:package toVersion:package[@"latest"]];
            }
        }
    }];

}

-(BOOL)removeLocalPackage:(NSString*) packageName version:(NSString*) version
{
    NSString *path = [self packagePathWithName:packageName version:version];
    NSLog(@"remove folder: %@",path);
    return [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
}


-(void) updatePackage:(NSDictionary*) package toVersion:(NSString*) version
{
    NSString *packageName = package[@"name"];
    NSString *destinationPath = [self packagePathWithName:packageName version:version];
    NSString *zipPath = [destinationPath stringByAppendingString:@".zip"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:destinationPath]){
        NSLog(@"package already exsits: %@",destinationPath);
        return;
    }
    
    [self.http downloadFileAtPath:package[@"zip"] params:nil cookies:nil completionHandler:^(NSData* data) {
        if(!data){
            NSLog(@"no data received");
            return;
        }
        // write data to zip
        NSLog(@"save file to path %@",zipPath);
        if(![data writeToFile:zipPath atomically:YES]){
            NSLog(@"failed to save file to path %@",zipPath);
            return;
        }
        
        //unzip
        NSLog(@"unzip file to path %@",destinationPath);
        if(![SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath]){
            NSLog(@"failed to unzip file: %@",zipPath);
            [[NSFileManager defaultManager]removeItemAtPath:zipPath error:nil];
            return;
        }
        [[NSFileManager defaultManager]removeItemAtPath:zipPath error:nil];
        
        // update config
        @synchronized(self) {
            NSMutableDictionary * config=[self loadConfig];
            NSMutableDictionary * packages = config[@"packages"];
            NSMutableDictionary * package = packages[packageName];
            if(!package){
                package=[[NSMutableDictionary alloc]init];
                packages[packageName]=package;
                package[@"current"]=version;
            }
            package[@"available"]=version;
            package[@"time"]=[NSDate date];
            [self saveConfig:config];
        }
    }];
}

-(NSString*) packagePathWithName:(NSString*) packageName version:(NSString*)version
{
    NSString * packageRootPath = [self.packageDirectory stringByAppendingPathComponent:packageName];
    if(![[NSFileManager defaultManager] fileExistsAtPath:packageName]){
        [[NSFileManager defaultManager] createDirectoryAtPath:packageRootPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [packageRootPath stringByAppendingPathComponent:version];
}

-(NSMutableDictionary*) loadConfig
{
    NSString *configFilePath =[self.packageDirectory stringByAppendingPathComponent:CONFIG_FILE];
    NSMutableDictionary *config = [[NSMutableDictionary alloc] initWithContentsOfFile:configFilePath];
    return config;
}

-(BOOL) saveConfig:(NSDictionary*) config
{
    NSLog(@"update config to %@",config);
    NSString *configFilePath =[self.packageDirectory stringByAppendingPathComponent:CONFIG_FILE];
    return [config writeToFile:configFilePath atomically:YES];
}

- (NSString*) packagePath:(NSString*) packageName;
{
    NSDictionary* package;
    @synchronized(self){
        package =[self loadConfig][@"packages"][packageName];
    }
    if(!package){
        return nil;
    }
    NSString* path=[self packagePathWithName:packageName version:package[@"current"]];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
        return nil;
    }    
    return path;
}



@end
