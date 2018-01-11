//
//  DialViewController.m
//  PJSIPSwiftDemo
//
//  Created by Michael-Miao on 2018/1/6.
//  Copyright © 2018年 WECI. All rights reserved.
//

#import "DialViewController.h"
#import <pjsua-lib/pjsua.h>
#import "PJSIPManager.h"
@interface DialViewController ()
{
	pjsua_call_id _call_id;
}
@property (weak, nonatomic) IBOutlet UITextField *phoneNumber;


@property (weak, nonatomic) IBOutlet UIButton *dialBt;

@end

@implementation DialViewController
// MARK: - 拨号
- (IBAction)dialMethod:(UIButton *)sender {
	if ([[sender titleForState:UIControlStateNormal] isEqualToString:@"呼叫"]) {
		[self __processMakeCall];
	} else {
		[self __processHangup];
		NSLog(@"挂断！");
	}
	[sender setEnabled:NO];
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewDidLoad {
    [super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleCallStatusChanged:)
												 name:@"SIPCallStatusChangedNotification"
											   object:nil];
}

- (void)handleCallStatusChanged:(NSNotification *)notification {
	pjsua_call_id call_id = [notification.userInfo[@"call_id"] intValue];
	pjsip_inv_state state = [notification.userInfo[@"state"] intValue];
	
	if(call_id != _call_id) return;
	
	if (state == PJSIP_INV_STATE_DISCONNECTED) {
		[self.dialBt setTitle:@"呼叫" forState:UIControlStateNormal];
		[self.dialBt setEnabled:YES];
	} else if(state == PJSIP_INV_STATE_CONNECTING){
		NSLog(@"正在连接...");
	} else if(state == PJSIP_INV_STATE_CONFIRMED) {
		[self.dialBt setTitle:@"挂断" forState:UIControlStateNormal];
		[self.dialBt setEnabled:YES];
	}
}

- (void)__processMakeCall {
	pjsua_acc_id acc_id = (pjsua_acc_id)[[NSUserDefaults standardUserDefaults] integerForKey:@"login_account_id"];
	NSString *server = [[NSUserDefaults standardUserDefaults] stringForKey:@"server_uri"];
	NSString *targetUri = [NSString stringWithFormat:@"sip:%@@%@", self.phoneNumber.text , server];
	
	pj_status_t status;
	pj_str_t dest_uri = pj_str((char *)targetUri.UTF8String);
	status = pjsua_call_make_call(acc_id, &dest_uri, 0, NULL, NULL, &_call_id);
	if (status != PJ_SUCCESS) {
		char  errMessage[PJ_ERR_MSG_SIZE];
		pj_strerror(status, errMessage, sizeof(errMessage));
		NSLog(@"外拨错误, 错误信息:%d(%s) !", status, errMessage);
	}
	
}
- (void)__processHangup {
	pj_status_t status = pjsua_call_hangup(_call_id, 0, NULL, NULL);
	
	if (status != PJ_SUCCESS) {
		const pj_str_t *statusText =  pjsip_get_status_text(status);
		NSLog(@"挂断错误, 错误信息:%d(%s) !", status, statusText->ptr);
	}
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
