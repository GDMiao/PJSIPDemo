//
//  CurrentNetwork.h
//  PJSIPDemo271
//
//  Created by Michael-Miao on 2018/1/9.
//  Copyright © 2018年 WECI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CurrentNetwork : NSObject
+ (BOOL)isIpv6;
+ (NSDictionary *)getIPAddresses;

@end
