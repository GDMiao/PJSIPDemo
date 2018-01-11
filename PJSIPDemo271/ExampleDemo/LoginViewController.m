//
//  LoginViewController.m
//  PJSIPSwiftDemo
//
//  Created by Michael-Miao on 2018/1/6.
//  Copyright © 2018年 WECI. All rights reserved.
//

#import "LoginViewController.h"
#import <pjsua-lib/pjsua.h>
#import "CurrentNetwork.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *server;
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *login;

@end

@implementation LoginViewController
// MARK: - login Method
- (IBAction)loginMethod:(UIButton *)sender {
	NSString *server = self.server.text;
	NSString *username = self.username.text;
	NSString *password = self.password.text;
	/*
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
	 */
	pjsua_acc_id acc_id;
	pjsua_acc_config acc_cfg;
	pjsua_acc_config_default(&acc_cfg);
	pj_status_t status;
	acc_cfg.id         = pj_str((char *)[NSString stringWithFormat:@"sip:%@@%@", username, server].UTF8String);
	acc_cfg.reg_uri    = pj_str((char *)[NSString stringWithFormat:@"sip:%@", server].UTF8String);
	acc_cfg.reg_retry_interval = 0;
	acc_cfg.cred_count = 1;
	acc_cfg.cred_info[0].realm     = pj_str("*");
	//acc_cfg.cred_info[0].scheme    = pj_str("digest");
	acc_cfg.cred_info[0].username  = pj_str((char *)username.UTF8String);
	acc_cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
	acc_cfg.cred_info[0].data      = pj_str((char *)password.UTF8String);
	BOOL isIpv6 = [CurrentNetwork isIpv6];
	if (!isIpv6) {
		
	} else {
//		pjsua_transport_config tp_cfg;
//		pjsip_transport_type_e tp_type;
//		pjsua_transport_id     udp6_tp_id = -1;
//		pjsua_transport_config_default(&tp_cfg);
//		tp_type = PJSIP_TRANSPORT_UDP6;
//		status = pjsua_transport_create(tp_type, &tp_cfg, &udp6_tp_id);
//		if (status != PJ_SUCCESS){
//		}
//		/* Bind the account to IPv6 transport */
//		acc_cfg.transport_id = udp6_tp_id; // udp6_tp_id is an UDP IPv6 transport ID, e.g: outputed by
//		// pjsua_transport_create(PJSIP_TRANSPORT_UDP6, ..., &udp6_tp_id)
//
//		/* Enable IPv6 in media transport */
//		acc_cfg.ipv6_media_use = PJSUA_IPV6_ENABLED;
//		//acc_cfg.nat64_opt = PJSUA_NAT64_ENABLED;
		
		/* Bind the account to IPv6 transport */
		pjsua_transport_config tp_cfg;
		pjsua_transport_id     udp6_tp_id = -1;
		pjsua_transport_config_default(&tp_cfg);
		pjsua_transport_create(PJSIP_TRANSPORT_UDP6, &tp_cfg, &udp6_tp_id);
		acc_cfg.transport_id = udp6_tp_id; // udp6_tp_id is an UDP IPv6 transport ID, e.g: outputed by
		// pjsua_transport_create(PJSIP_TRANSPORT_UDP6, ..., &udp6_tp_id)
		
		/* Enable IPv6 in media transport */
		acc_cfg.ipv6_media_use = PJSUA_IPV6_ENABLED;
		
		/* Finally */
		status = pjsua_acc_add(&acc_cfg, PJ_TRUE, NULL);
		if (status != PJ_SUCCESS){
			
		}
	}
	/* Finally */
	status = pjsua_acc_add(&acc_cfg, PJ_TRUE, &acc_id);
	if (status != PJ_SUCCESS)
	{

	}
	
	
	
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(__handleRegisterStatus:)
												 name:@"SIPRegisterStatusNotification"
											   object:nil];
	
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
	[[NSUserDefaults standardUserDefaults] setObject:self.server.text forKey:@"server_uri"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[self __switchToDialViewController];
}

- (void)__switchToDialViewController {
	UIViewController *dialViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"DialViewController"];
	
	CATransition *transition = [[CATransition alloc] init];
	
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	transition.type = kCATransitionFade;
	transition.duration  = 0.5;
	transition.removedOnCompletion = YES;
	
	UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
	[keyWindow.layer addAnimation:transition forKey:@"change_view_controller"];
	
	keyWindow.rootViewController = dialViewController;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
