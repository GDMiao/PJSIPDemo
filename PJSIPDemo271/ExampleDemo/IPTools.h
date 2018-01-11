//
//  IPTools.h
//  PJSIPDemo271
//
//  Created by Michael-Miao on 2018/1/10.
//  Copyright © 2018年 WECI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IPTools : NSObject
// 域名转IP:需有网络才能进行
+ (NSString *)queryIpWithDomain:(NSString *)domain;

+ (NSString *)getIPAddress:(NSString *)ipAddress;
@end
