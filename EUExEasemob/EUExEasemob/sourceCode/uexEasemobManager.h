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


extern NSString * const uexEasemobExtraInfoKey;
@interface uexEasemobManager : NSObject <EMClientDelegate,EMChatManagerDelegate,EMCallManagerDelegate,EMCDDeviceManagerDelegate,EMContactManagerDelegate,EMGroupManagerDelegate,EMCDDeviceManagerProximitySensorDelegate,EMChatroomManagerDelegate>

@property (nonatomic,weak)EMClient *SDK;
@property (nonatomic,strong)EMCallSession *callSession;
//@property (nonatomic,strong)EMPushOptions *apnsOptions;
@property (nonatomic,weak) EMCDDeviceManager *EMDevice;
@property (nonatomic,strong) NSDictionary *remoteLaunchDict;
@property (nonatomic,strong) NSDate *lastPlaySoundDate;
@property (nonatomic,assign) BOOL isPlaySound;
@property (nonatomic,assign) BOOL isPlayVibration;
@property (nonatomic,assign) BOOL messageNotification;
@property (nonatomic,assign) BOOL hasRegisteredAPNs;

@property (nonatomic,assign) BOOL isAutoLoginEnabled;
@property (nonatomic,assign) BOOL isShowNotificationInBackgroud;
@property (nonatomic,assign) BOOL noDeliveryNotification;
@property (nonatomic,strong) dispatch_queue_t callBackDispatchQueue;


extern NSString *const cEMChatTypeUser;
extern NSString *const cEMChatTypeGroup;
extern NSString *const cEMChatTypeChatRoom;



+ (instancetype)sharedInstance;
-(void)didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
-(void)initEasemobWithAppKey:(NSString *)appKey apnsCertName:(NSString *)certName;
-(void) callBackJSONWithFunction:(NSString *)functionName parameter:(id)obj;

- (NSDictionary *)analyzeEMMessage:(EMMessage *)message;
- (NSDictionary *)analyzeEMConversation:(EMConversation *)conversation;
- (NSDictionary *)analyzeEMGroup:(EMGroup *)group;
@end
