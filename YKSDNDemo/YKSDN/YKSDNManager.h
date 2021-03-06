//
//  YKSDNManager.h
//  YKSDN
//
//  Created by shuqiong on 2018/5/8.
//  Copyright © 2018年 shuqiong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YKSDNManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, copy) NSString *oaUrl;
@property (nonatomic, copy) NSString *mac;

//delay 如不设置或设值的小于0，则默认为3s
@property (nonatomic, assign) double delay;

//获取并缓存入口服务器地址
- (void)fetchAndStoreServerList;

//获取最优地址
- (void)getOptimalServer:(void (^)(NSDictionary *serverInfo))completionHandler;

@end
