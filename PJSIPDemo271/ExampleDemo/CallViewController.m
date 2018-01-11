//
//  CallViewController.m
//  PJSIPSwiftDemo
//
//  Created by Michael-Miao on 2018/1/6.
//  Copyright © 2018年 WECI. All rights reserved.
//

#import "CallViewController.h"
#import <pjsua-lib/pjsua.h>
@interface CallViewController ()
@property (weak, nonatomic) IBOutlet UILabel *callPhone;
@property (weak, nonatomic) IBOutlet UIButton *hangup;
@property (weak, nonatomic) IBOutlet UIButton *answer;

@end

@implementation CallViewController


- (IBAction)hangupMethod:(UIButton *)sender {
	pjsua_call_hangup((pjsua_call_id)self.callId, 0, NULL, NULL);
}
- (IBAction)answerMethod:(UIButton *)sender {
	pjsua_call_answer((pjsua_call_id)self.callId, 200, NULL, NULL);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.callPhone.text = self.phoneNumber;
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
	
	if(call_id != self.callId) return;
	
	if (state == PJSIP_INV_STATE_DISCONNECTED) {
		NSLog(@"挂断成功！");
		[self dismissViewControllerAnimated:YES completion:nil];
	} else if(state == PJSIP_INV_STATE_CONNECTING){
		NSLog(@"连接中...");
	} else if(state == PJSIP_INV_STATE_CONFIRMED) {
		NSLog(@"接听成功！");
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
