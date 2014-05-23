//
//  HTTP.h
//  Hybrid
//
//  Created by ltebean on 14-5-14.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

@interface SeaportHttp : NSObject

- (id) initWithDomain:(NSString*) domain;

-(void)sendRequestToPath:(NSString*)path method:(NSString*)method params:(NSDictionary*)params cookies:(NSDictionary*)cookies  completionHandler:(void (^)(id)) completionHandler ;

-(void)postJsonToPath:(NSString*)path body:(id)object cookies:(NSDictionary*)cookies  completionHandler:(void (^)(id)) completionHandler;

-(void)downloadFileAtPath:(NSString*)path params:(NSDictionary*)params cookies:(NSDictionary*)cookies  completionHandler:(void (^)(id)) completionHandler;

-(void)downloadFileAtUrl:(NSString*)url params:(NSDictionary*)params cookies:(NSDictionary*)cookies  completionHandler:(void (^)(id)) completionHandler;

@end