//
//  Seaport.h
//  Seaport
//
//  Created by ltebean on 14-5-14.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Seaport;
@protocol SeaportDelegate<NSObject>
-(void)seaport:(Seaport*)seaport didStartDownloadPackage:(NSString*) packageName version:(NSString*) version;
-(void)seaport:(Seaport*)seaport didFinishDownloadPackage:(NSString*) packageName version:(NSString*) version;
-(void)seaport:(Seaport*)seaport didFailDownloadPackage:(NSString*) packageName version:(NSString*) version withError:(NSError*) error;
-(void)seaport:(Seaport*)seaport didFinishUpdatePackage:(NSString*) packageName version:(NSString*) version;
@end


@interface Seaport : NSObject
@property(nonatomic,weak) id<SeaportDelegate> deletage;

- (id) initWithAppName:(NSString*) appName serverHost:(NSString*) host sevrerPort:(NSString*) port dbName:(NSString*) dbName;

- (void) checkUpdate;

- (NSString*) packagePath:(NSString*) packageName;

@end
