//
//  YKSDNManager.m
//  YKSDN
//
//  Created by shuqiong on 2018/5/8.
//  Copyright © 2018年 shuqiong. All rights reserved.
//

#import "YKSDNManager.h"

#define tsSdnServer @"tsSdnServer"
#define tsSdnClient @"tsSdnClient"

static NSString * const kServerList = @"k_yk_serverList";

@interface YKSDNManager()

@end

@implementation YKSDNManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static YKSDNManager *_manager;
    dispatch_once(&onceToken, ^{
        _manager = [[YKSDNManager alloc] init];
    });
    return _manager;
}

- (void)fetchAndStoreServerList {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?interfaceid=%@&mac=%@", self.oaUrl, @"cs-getServerURL", self.mac]]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!data) {
            return ;
        }
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [[NSUserDefaults standardUserDefaults] setObject:responseString forKey:kServerList];
    }] resume];
    
}

- (void)getOptimalServer:(void (^)(NSDictionary *))completionHandler {
    if (!completionHandler) {
        return;
    }
    [self getOptimalServerWithLevel:1 completion:^(NSDictionary *level1Server) {
        if (level1Server) {
            completionHandler(level1Server);
        } else {
            [self getOptimalServerWithLevel:2 completion:^(NSDictionary *level2Server) {
                if (level2Server) {
                    completionHandler(level2Server);
                } else {
                    completionHandler(@{@"error": @"not found"});
                }
            }];
        }
    }];
}

- (void)getOptimalServerWithLevel:(NSInteger)level completion:(void (^)(NSDictionary *))completionHandler{
    dispatch_queue_t sdnQueue = dispatch_queue_create("com.dlsoft.yksdnqueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t sdnGroup = dispatch_group_create();
    NSMutableArray *servers = [NSMutableArray array];
    self.delay = self.delay > 0 ? self.delay : 3000;
    
    [[self serverListWithLevel:level] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        dispatch_group_enter(sdnGroup);
        dispatch_group_async(sdnGroup, sdnQueue, ^{
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/slh/check.do?svc=checkSdn&mac=%@&tsSdnClient=%f",obj[@"slhurl"], self.mac, [[NSDate new] timeIntervalSince1970]*1000]];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
            request.timeoutInterval = 2;
            
            [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSDictionary *result = [NSJSONSerialization JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                if (result) {
                    NSMutableDictionary *serverItem = [obj mutableCopy];
                    double cost = [result[tsSdnServer] doubleValue] - [result[tsSdnClient] doubleValue];
                    [serverItem addEntriesFromDictionary:result];
                    serverItem[@"cost"] = [@(cost) description];
                    if (cost < self.delay) {
                        [servers addObject:serverItem];
                    }
//#ifdef DEBUG
//                    NSLog(@"server: %@", serverItem);
//#endif
                }
                
                dispatch_group_leave(sdnGroup);
            }] resume];
        });
    }];
    
    dispatch_group_notify(sdnGroup, sdnQueue, ^{
        [servers sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            double server1Cost = [obj1[tsSdnServer] doubleValue] - [obj1[tsSdnClient] doubleValue];
            double server2Cost = [obj2[tsSdnServer] doubleValue] - [obj2[tsSdnClient] doubleValue];
            return server1Cost > server2Cost;
        }];
        completionHandler([servers firstObject]);
    });
}

/**
 *  根据level获取服务器列表
 *  @param level 一级或二级入口
 *  @return
 *  @by sq
 */
- (NSArray *)serverListWithLevel:(NSInteger)level {
    NSString *serverListString = [[NSUserDefaults standardUserDefaults] objectForKey:kServerList];
    NSError *error = nil;
    NSData *data = [serverListString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *serverList = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        return nil;
    }
    
    NSMutableArray *servers = [NSMutableArray array];
    [serverList[@"serverList"] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"level"] integerValue] == level) {
            [servers addObject:obj];
        }
    }];
    
    return servers;
}

@end
