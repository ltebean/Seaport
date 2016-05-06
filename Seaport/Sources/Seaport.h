//
//  Seaport.h
//  Seaport
//
//  Created by ltebean on 14-5-14.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PackageRequirement : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *versionRange;
@end


@class Seaport;
@protocol SeaportDelegate<NSObject>
- (void)seaport:(Seaport *)seaport didStartDownloadPackage:(NSString *)packageName version:(NSString *)version;
- (void)seaport:(Seaport *)seaport didFinishDownloadPackage:(NSString *)packageName version:(NSString *)version;
- (void)seaport:(Seaport *)seaport didFailDownloadPackage:(NSString *)packageName version:(NSString *)version withError:(NSError *)error;
- (void)seaport:(Seaport *)seaport didFinishUpdatePackage:(NSString *)packageName version:(NSString *)version;
- (void)seaport:(Seaport *)seaport didFailedToPullConfigWithError:(NSError *)error;
@end


@interface Seaport : NSObject
@property(nonatomic,weak) id<SeaportDelegate> deletage;
- (id)initWithAppName:(NSString *)appName secret:(NSString *)secret serverAddress:(NSString *)serverAddress packageRequirements:(NSArray *)packageRequirements;
- (void)checkUpdates;
- (NSString *)packagePath:(NSString *)packageName;
@end
