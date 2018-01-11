//
//  PJSIPManager.h
//  PJSIPSwiftDemo
//
//  Created by Michael-Miao on 2018/1/5.
//  Copyright © 2018年 WECI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PJSIPManager : NSObject
+ (instancetype)share;
// 初始化
- (BOOL)initPJSua;
// 登录
// 登录页面 设置监听
- (void)loginWith:(NSString *)username
		   server:(NSString *)server
		 password:(NSString *)password;
// 拨号
// 设置监听
- (void)dialwith:(NSString *)number;
// 挂断
- (void)hangup:(int)call_id;
// 来电
/*
 在AppDelegate里添加来电通知的监听：
 	[[NSNotificationCenter defaultCenter] addObserver:self
 	selector:@selector(__handleIncommingCall:)
 	name:@"SIPIncomingCallNotification"
 	object:nil];
 
 - (void)__handleIncommingCall:(NSNotification *)notification {
 	pjsua_call_id callId = [notification.userInfo[@"call_id"] intValue];
 	NSString *phoneNumber = notification.userInfo[@"remote_address"];
 
 	// 页面切换
 	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
 	IncomingCallViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"IncomingCallViewController"];
 
 	viewController.phoneNumber = phoneNumber;
 	viewController.callId = callId;
 
 	UIViewController *rootViewController = self.window.rootViewController;
 	[rootViewController presentViewController:viewController animated:YES completion:nil];
 
 }
 */

// 接听
- (void)answer:(int)call_id;



@end
