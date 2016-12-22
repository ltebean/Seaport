//
//  SeaportManager.h
//  Seaport
//
//  Created by leo on 16/12/20.
//  Copyright © 2016年 ltebean. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SeaportManager : NSObject
+ (SeaportManager *)shared;
- (void)checkUpdates;
- (NSString *)packagePath:(NSString *)package;
@end
