//
//  uexEasemobManager.h
//  EUExEasemob
//
//  Created by CC on 15/6/13.
//  Copyright (c) 2015年 AppCan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMSDK.h"
#import "EMClient+Call.h"
#import "EMCallSession.h"
#import "EMCDDeviceManager.h"
#import "EMCDDeviceManagerDelegate.h"



extern NSString *const cEMChatTypeUser;
extern NSString *const cEMChatTypeGroup;
extern NSString *const cEMChatTypeChatRoom;
extern NSString *const uexEasemobExtraInfoKey;
extern NSString *const uexEasemobManagerInitSuccessNotificationKey;

static inline NSString *cbName(NSString * func){
    return [NSString stringWithFormat:@"uexEasemob.%@",func];
}




@interface uexEasemobManager : NSObject 

@property (nonatomic,weak)EMClient *SDK;
@property (nonatomic,strong)EMCallSession *callSession;


@property (nonatomic,strong) NSDictionary *remoteLaunchDict;

@property (nonatomic,assign) BOOL isPlaySound;
@property (nonatomic,assign) BOOL isPlayVibration;
@property (nonatomic,assign) BOOL messageNotification;
@property (nonatomic,assign) BOOL hasRegisteredAPNs;


@property (nonatomic,assign) BOOL isShowNotificationInBackgroud;
@property (nonatomic,assign) BOOL noDeliveryNotification;


+ (instancetype)sharedManager;





- (EMError *)initializeEasemobWithOptions:(EMOptions *)option;

- (void)callbackWithFunctionName:(NSString *)funcName obj:(id)obj;

- (NSDictionary *)analyzeEMMessage:(EMMessage *)message;
- (NSDictionary *)analyzeEMConversation:(EMConversation *)conversation;
- (NSDictionary *)analyzeEMGroup:(EMGroup *)group;
@end
