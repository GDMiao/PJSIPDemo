//
//  PJSIPManager.m
//  PJSIPSwiftDemo
//
//  Created by Michael-Miao on 2018/1/5.
//  Copyright © 2018年 WECI. All rights reserved.
//

#import "PJSIPManager.h"
#import "CurrentNetwork.h"
#import <pjsua-lib/pjsua.h>
#include "pj-nat64.h"
#import "IPTools.h"
// 创建静态对象 防止外部访问
@interface PJSIPManager()
{
	pjsua_call_id _call_id;
}
@end
static PJSIPManager * _singleton;
@implementation PJSIPManager
+ (instancetype)allocWithZone:(struct _NSZone *)zone{
	
	static dispatch_once_t onceToken;
	// 一次函数
	dispatch_once(&onceToken, ^{
		if (_singleton == nil) {
			_singleton = [super allocWithZone:zone];
		}
	});
	
	return _singleton;
}
+ (instancetype)share{
	
	return  [[self alloc] init];
}
// MARK: - 初始化 PJSua
- (BOOL)initPJSua
{

	pj_status_t status;
	
	// 创建SUA
	status = pjsua_create();
	
	if (status != PJ_SUCCESS) {
		NSLog(@"error create pjsua"); return NO;
	}
	
	{
		// SUA 相关配置
		pjsua_config cfg;
		pjsua_media_config media_cfg;
		pjsua_logging_config log_cfg;
		
		pjsua_config_default(&cfg);
		
		// 回调函数配置
		cfg.cb.on_incoming_call = &on_incoming_call;            // 来电回调
		cfg.cb.on_call_media_state = &on_call_media_state;      // 媒体状态回调（通话建立后，要播放RTP流）
		cfg.cb.on_call_state = &on_call_state;                  // 电话状态回调
		cfg.cb.on_reg_state = &on_reg_state;                    // 注册状态回调
		
		// 媒体相关配置
		pjsua_media_config_default(&media_cfg);
		media_cfg.clock_rate = 16000;
		media_cfg.snd_clock_rate = 16000;
		media_cfg.ec_tail_len = 0;
		
		// 日志相关配置
		pjsua_logging_config_default(&log_cfg);
#ifdef DEBUG
		log_cfg.msg_logging = PJ_TRUE;
		log_cfg.console_level = 4;
		log_cfg.level = 5;
#else
		log_cfg.msg_logging = PJ_FALSE;
		log_cfg.console_level = 0;
		log_cfg.level = 0;
#endif
		
		
		// 初始化PJSUA
		status = pjsua_init(&cfg, &log_cfg, &media_cfg);
		if (status != PJ_SUCCESS) {
			NSLog(@"error init pjsua"); return NO;
		}
		
	}
	
	

	// udp transport
	{
		// 原来
//		pjsua_transport_config cfg;
//		pjsua_transport_config_default(&cfg);
//
//		// 传输类型配置
//		status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, NULL);
//		if (status != PJ_SUCCESS) {
//			NSLog(@"error add transport for pjsua"); return NO;
//		}
		// 原来
		BOOL isIpv6 = [CurrentNetwork isIpv6];
		if (!isIpv6) {
			NSLog(@"The Network Is In IpV4");
			pjsua_transport_config cfg;
			pjsua_transport_config_default(&cfg);
			
			// 传输类型配置
			status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, NULL);
			if (status != PJ_SUCCESS) {
				NSLog(@"error add transport for pjsua"); return NO;
			}
		}else{
			NSLog(@"The Network Is In IpV6");
			// PJ_nat64
			pj_nat64_enable_rewrite_module();
			pjsua_transport_config tp_cfg;
			pjsip_transport_type_e tp_type;
			pjsua_transport_id     tp_id = -1;
			
			pjsua_transport_config_default(&tp_cfg);
			//tp_cfg.port = 5060;
			
			/* TCP */
			//		tp_type = PJSIP_TRANSPORT_TCP6;
			//		status = pjsua_transport_create(tp_type, &tp_cfg, &tp_id);
			//		if (status != PJ_SUCCESS){}
			
			/* UDP */
			tp_type = PJSIP_TRANSPORT_UDP6;
			status = pjsua_transport_create(tp_type, &tp_cfg, &tp_id);
			if (status != PJ_SUCCESS){
				NSLog(@"error add transport for pjsua"); return NO;
			}
		}
		
		
	}

	// 启动PJSUA
	status = pjsua_start();
	if (status != PJ_SUCCESS) {
		NSLog(@"error start pjsua"); return NO;
	}
	
	return YES;
}
// MARK: - 回调函数配置
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
	pjsua_acc_config acc_cfg;
	pjsua_acc_config_default(&acc_cfg);
	BOOL isIPv6 = [CurrentNetwork isIpv6];
	if (isIPv6) {
		acc_cfg.ipv6_media_use = PJSUA_IPV6_ENABLED;
		//acc_cfg.nat64_opt = PJSUA_NAT64_ENABLED;
		pj_nat64_set_options(NAT64_REWRITE_ROUTE_AND_CONTACT);
	}
	pjsua_call_info ci;
	pjsua_call_get_info(call_id, &ci);
	
	NSString *remote_info = [NSString stringWithUTF8String:ci.remote_info.ptr];
	
	NSUInteger startIndex = [remote_info rangeOfString:@"<"].location;
	NSUInteger endIndex = [remote_info rangeOfString:@">"].location;
	
	NSString *remote_address = [remote_info substringWithRange:NSMakeRange(startIndex + 1, endIndex - startIndex - 1)];
	remote_address = [remote_address componentsSeparatedByString:@":"][1];
	
	id argument = @{
					@"call_id"          : @(call_id),
					@"remote_address"   : remote_address
					};
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SIPIncomingCallNotification" object:nil userInfo:argument];
	});
	
}

static void on_call_state(pjsua_call_id call_id, pjsip_event *e) {
	pjsua_acc_config acc_cfg;
	pjsua_acc_config_default(&acc_cfg);
	BOOL isIPv6 = [CurrentNetwork isIpv6];
	if (isIPv6) {
		acc_cfg.ipv6_media_use = PJSUA_IPV6_ENABLED;
		//acc_cfg.nat64_opt = PJSUA_NAT64_ENABLED;
		pj_nat64_set_options(NAT64_REWRITE_ROUTE_AND_CONTACT);
		
	}
	
	pjsua_call_info ci;
	pjsua_call_get_info(call_id, &ci);
	
	id argument = @{
					@"call_id"  : @(call_id),
					@"state"    : @(ci.state)
					};
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SIPCallStatusChangedNotification" object:nil userInfo:argument];
	});
}

static void on_call_media_state(pjsua_call_id call_id) {
	pjsua_acc_config acc_cfg;
	pjsua_acc_config_default(&acc_cfg);
	BOOL isIPv6 = [CurrentNetwork isIpv6];
	if (isIPv6) {
		acc_cfg.ipv6_media_use = PJSUA_IPV6_ENABLED;
		acc_cfg.nat64_opt = PJSUA_NAT64_ENABLED;
		pj_nat64_set_options(NAT64_REWRITE_ROUTE_AND_CONTACT);
	}
	pjsua_call_info ci;
	pjsua_call_get_info(call_id, &ci);
	
	if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
		// When media is active, connect call to sound device.
		pjsua_conf_connect(ci.conf_slot, 0);
		pjsua_conf_connect(0, ci.conf_slot);
	}
}

static void on_reg_state(pjsua_acc_id acc_id) {
	
	pjsua_acc_config acc_cfg;
	pjsua_acc_config_default(&acc_cfg);
	BOOL isIPv6 = [CurrentNetwork isIpv6];
	if (isIPv6) {
		pj_nat64_set_active_account(acc_id);
		acc_cfg.ipv6_media_use = PJSUA_IPV6_ENABLED;
		acc_cfg.nat64_opt = PJSUA_NAT64_ENABLED;
		pj_nat64_set_options(NAT64_REWRITE_ROUTE_AND_CONTACT);
	}
	//////
	pj_status_t status;
	pjsua_acc_info info;
	
	status = pjsua_acc_get_info(acc_id, &info);
	if (status != PJ_SUCCESS)
		return;
	
	id argument = @{
					@"acc_id"       : @(acc_id),
					@"status_text"  : [NSString stringWithUTF8String:info.status_text.ptr],
					@"status"       : @(info.status)
					};
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SIPRegisterStatusNotification" object:nil userInfo:argument];
	});
}



// MARK: - 登录
// 登录页面 设置注册结果监听
/*
 - (void)viewDidLoad {
 	[super viewDidLoad];
 
 	[[NSNotificationCenter defaultCenter] addObserver:self
 	selector:@selector(__handleRegisterStatus:)
 	name:@"SIPRegisterStatusNotification"
 	object:nil];
 
 }
 
 - (void)dealloc {
 	[[NSNotificationCenter defaultCenter] removeObserver:self];
 }
 
 - (void)__handleRegisterStatus:(NSNotification *)notification {
 	pjsua_acc_id acc_id = [notification.userInfo[@"acc_id"] intValue];
 	pjsip_status_code status = [notification.userInfo[@"status"] intValue];
	NSString *statusText = notification.userInfo[@"status_text"];
 
 	if (status != PJSIP_SC_OK) {
 		NSLog(@"登录失败, 错误信息: %d(%@)", status, statusText);
 		return;
 	}
 
 	[[NSUserDefaults standardUserDefaults] setInteger:acc_id forKey:@"login_account_id"];
 	[[NSUserDefaults standardUserDefaults] setObject:self.serverField.text forKey:@"server_uri"];
 	[[NSUserDefaults standardUserDefaults] synchronize];
 	// 登录成功切换页面
 	[self __switchToDialViewController];
 }
 */
- (void)loginWith:(NSString *)username
		   server:(NSString *)server
		 password:(NSString *)password
{
	pjsua_acc_id acc_id;
	pjsua_acc_config cfg;
	
	pjsua_acc_config_default(&cfg);
	cfg.id = pj_str((char *)[NSString stringWithFormat:@"sip:%@@%@", username, server].UTF8String);
	cfg.reg_uri = pj_str((char *)[NSString stringWithFormat:@"sip:%@", server].UTF8String);
	cfg.reg_retry_interval = 0;
	cfg.cred_count = 1;
	cfg.cred_info[0].realm = pj_str("*");
	cfg.cred_info[0].username = pj_str((char *)username.UTF8String);
	cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
	cfg.cred_info[0].data = pj_str((char *)password.UTF8String);
	
	pj_status_t status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
	
	if (status != PJ_SUCCESS) {
		NSString *errorMessage = [NSString stringWithFormat:@"登录失败, 返回错误号:%d!", status];
		NSLog(@"register error: %@", errorMessage);
	}
}

// MARK: - 拨号
// 拨号页面 设置电话状态变监听
/*
 - (void)viewDidLoad {
 	[super viewDidLoad];
 
 	[[NSNotificationCenter defaultCenter] addObserver:self
	selector:@selector(handleCallStatusChanged:)
 	name:@"SIPCallStatusChangedNotification"
 	object:nil];
 }
 
 - (void)dealloc {
 	[[NSNotificationCenter defaultCenter] removeObserver:self];
 }
 
 - (void)handleCallStatusChanged:(NSNotification *)notification {
 	pjsua_call_id call_id = [notification.userInfo[@"call_id"] intValue];
 	pjsip_inv_state state = [notification.userInfo[@"state"] intValue];
 
 	if(call_id != _call_id) return;
 
 	if (state == PJSIP_INV_STATE_DISCONNECTED) {
 		[self.actionButton setTitle:@"呼叫" forState:UIControlStateNormal];
 		[self.actionButton setEnabled:YES];
 	} else if(state == PJSIP_INV_STATE_CONNECTING){
 		NSLog(@"正在连接...");
 	} else if(state == PJSIP_INV_STATE_CONFIRMED) {
 		[self.actionButton setTitle:@"挂断" forState:UIControlStateNormal];
 		[self.actionButton setEnabled:YES];
 	}
 }
 */
- (void)dialwith:(NSString *)number
{
	pjsua_acc_id acct_id = (pjsua_acc_id)[[NSUserDefaults standardUserDefaults] integerForKey:@"login_account_id"];
	NSString *server = [[NSUserDefaults standardUserDefaults] stringForKey:@"server_uri"];
	NSString *targetUri = [NSString stringWithFormat:@"sip:%@@%@", number , server];
	
	pj_status_t status;
	pj_str_t dest_uri = pj_str((char *)targetUri.UTF8String);
	
	status = pjsua_call_make_call(acct_id, &dest_uri, 0, NULL, NULL, &_call_id);
	
	if (status != PJ_SUCCESS) {
		char  errMessage[PJ_ERR_MSG_SIZE];
		pj_strerror(status, errMessage, sizeof(errMessage));
		NSLog(@"外拨错误, 错误信息:%d(%s) !", status, errMessage);
	}
}
// MARK: - 挂断
- (void)hangup:(int)call_id
{
	pjsua_call_hangup((pjsua_call_id)call_id, 0, NULL, NULL);
}

// MARK: - 接听
- (void)answer:(int)call_id
{
	pjsua_call_answer((pjsua_call_id)call_id, 200, NULL, NULL);
}


@end
