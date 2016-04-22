//
//  uexEasemobManager.m
//  EUExEasemob
//
//  Created by CC on 15/6/13.
//  Copyright (c) 2015年 AppCan. All rights reserved.
//

#import "uexEasemobManager.h"
#import "EUtility.h"
#import "JSON.h"

@interface uexEasemobManager()
@property (nonatomic,strong)NSDictionary *launchOptions;
@end


static const CGFloat kDefaultPlaySoundInterval = 3.0;


@implementation uexEasemobManager


NSString *const cEMChatTypeUser = @"0";
NSString *const cEMChatTypeGroup = @"1";
NSString *const cEMChatTypeChatRoom = @"2";
NSString *const uexEasemobExtraInfoKey = @"ext";




+ (instancetype)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static uexEasemobManager *sharedObject = nil;
    dispatch_once(&pred, ^{
        sharedObject = [[self alloc] init];
        
        
    });
    return sharedObject;
}


- (instancetype)init{
    self = [super init];
    if(self){
        _callBackDispatchQueue = dispatch_queue_create("gcd.uexEasemobCallBackDispatchQueue",DISPATCH_QUEUE_SERIAL);
        _EMDevice = [EMCDDeviceManager sharedInstance];
        _EMDevice.delegate = self;
        _isShowNotificationInBackgroud = YES;
        
        
            }
    return self;
}




- (void)didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    _launchOptions = launchOptions;
    NSDictionary *userInfo = [launchOptions objectForKey:  @"UIApplicationLaunchOptionsRemoteNotificationKey"];
    if(userInfo)
    {
        self.remoteLaunchDict = userInfo;
    }

}


#pragma mark - 初始化SDK
- (void)initEasemobWithAppKey:(NSString *)appKey apnsCertName:(NSString *)certName{
    if(!_SDK){
        _SDK = [EMClient sharedClient];
        EMOptions *opts=[EMOptions optionsWithAppkey:appKey];
        opts.isAutoLogin=_isAutoLoginEnabled;
        opts.apnsCertName=certName;
        opts.enableConsoleLog=NO;
        opts.enableDeliveryAck=YES;
        
        [_SDK initializeSDKWithOptions:opts];
        
        //[_SDK application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:_launchOptions];
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        [self setupNotifiers];
        [self registerEaseMobNotification];
        [self setupDefaultValue];
        [self callBackJSONWithFunction:@"cbInit" parameter:@"EaseMobSDK initialized successfully!"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"uexEasemobInitSuccess"
                                                            object:nil];
        if([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
        {
            UIUserNotificationType notificationTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        }
    }else{
        [self callBackJSONWithFunction:@"cbInit" parameter:@"EaseMobSDK has already been initialized!"];
    }
    
}
- (void)setupDefaultValue{
    self.lastPlaySoundDate = [NSDate date];
    self.isPlayVibration = YES;
    self.isPlaySound = YES;
    self.messageNotification = YES;
    self.isAutoLoginEnabled = YES;
}


//注册回调
- (void)registerEaseMobNotification{
    [self unRegisterEaseMobNotification];
    
    [_SDK addDelegate:self delegateQueue:nil];
    [_SDK.chatManager addDelegate:self delegateQueue:nil];
    [_SDK.callManager addDelegate:self delegateQueue:nil];
    [_SDK.groupManager addDelegate:self delegateQueue:nil];
    [_SDK.contactManager addDelegate:self delegateQueue:nil];
    [_SDK.roomManager addDelegate:self delegateQueue:nil];
}

- (void)unRegisterEaseMobNotification{
    [_SDK removeDelegate:self];
    [_SDK.chatManager removeDelegate:self];
    [_SDK.callManager removeDelegate:self];
    [_SDK.groupManager removeDelegate:self];
    [_SDK.contactManager removeDelegate:self];
    [_SDK.roomManager removeDelegate:self];
}

    
    
//监听系统事件
    
    
    
- (void)setupNotifiers{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidEnterBackgroundNotif:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
}
    
- (void)appDidEnterBackgroundNotif:(NSNotification*)notif{
    [_SDK applicationDidEnterBackground:notif.object];
}
    
- (void)appWillEnterForeground:(NSNotification*)notif
{
    [_SDK applicationWillEnterForeground:notif.object];
}

#pragma mark - 振动响铃


- (void)playSoundAndVibration{
    NSTimeInterval timeInterval = [[NSDate date]
                                   timeIntervalSinceDate:self.lastPlaySoundDate];
    if (timeInterval < kDefaultPlaySoundInterval) {
        //如果距离上次响铃和震动时间太短, 则跳过响铃
        //NSLog(@"skip ringing & vibration %@, %@", [NSDate date], self.lastPlaySoundDate);
        return;
    }
    if(!self.messageNotification){
        //新消息提醒关闭
        return;
    }
    
    //保存最后一次响铃时间
    self.lastPlaySoundDate = [NSDate date];
    
    // 收到消息时，播放音频
    if(self.isPlaySound){
        [_EMDevice playNewMessageSound];
    }
    // 收到消息时，震动
    if(self.isPlayVibration){
        [_EMDevice playVibration];
    }
}


#pragma mark - 自动登录回调

- (void)willAutoLoginWithInfo:(NSDictionary *)loginInfo
                       error:(EMError *)error{
    
}


- (void)didAutoLoginWithError:(EMError *)error{
    if (error) {
        NSLog(@"didAutoLoginWithError:%d-%@",error.code,error.errorDescription);
    }
    else{
        //self.apnsOptions = _SDK.pushOptions;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [_SDK dataMigrationTo3];
        });
        [self callBackJSONWithFunction:@"onConnected" parameter:nil];
    }
}
#pragma mark - 连接状态回调
- (void)disconnectedError:(NSInteger)errorCode{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:[NSString stringWithFormat: @"%ld", (long)errorCode] forKey:@"error"];
    
    [self callBackJSONWithFunction:@"onDisconnected" parameter:dict];
}


- (void)didRemovedFromServer{
    [self disconnectedError:1];
}

- (void)didLoginFromOtherDevice{
    [self disconnectedError:2];
}

- (void)didConnectionStateChanged:(EMConnectionState)connectionState{
    if (connectionState == EMConnectionDisconnected){
        [self disconnectedError:3];
        return;
    }
    if (connectionState == EMConnectionConnected){
        [self callBackJSONWithFunction:@"onConnected" parameter:nil];
        return;
    }
}
#pragma mark - Message回调

- (void)didReceiveMessages:(NSArray *)aMessages{
    for(EMMessage *message in aMessages){
        
        NSDictionary *dict = [self analyzeEMMessage:message];
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        if (state != UIApplicationStateActive && self.isShowNotificationInBackgroud ) {
            UILocalNotification *notif = [[UILocalNotification alloc]init];
            notif.alertBody = @"您有一条新消息";
            notif.repeatCalendar = 0;
            notif.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication]presentLocalNotificationNow:notif];
        }
        
        [self playSoundAndVibration];
        [self callBackJSONWithFunction:@"onNewMessage" parameter:dict];
    }
    
}

- (void)didReceiveCmdMessages:(NSArray *)aCmdMessages{
    for(EMMessage *cmdMessage in aCmdMessages){
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
        NSDictionary *dictMessage = [self analyzeEMMessage:cmdMessage];
        [dict setValue:cmdMessage.messageId forKey:@"msgId"];
        [dict setValue:dictMessage forKey:@"message"];
        EMCmdMessageBody *body = (EMCmdMessageBody *)cmdMessage.body;
        [dict setValue:body.action forKey:@"action"];
        //[self playSoundAndVibration];
        [self callBackJSONWithFunction:@"onCmdMessageReceive" parameter:dict];
    }
}


- (void)didReceiveHasReadAcks:(NSArray *)aMessages{
    for(EMMessage* message in aMessages){
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
        [dict setValue:message.messageId forKey:@"msgId"];
        [dict setValue:message.from forKey:@"username"];
        
        [self callBackJSONWithFunction:@"onAckMessage" parameter:dict];
    }
}


- (void)didReceiveHasDeliveredAcks:(NSArray *)aMessages{
    if(self.noDeliveryNotification){
        return;
    }
    for(EMMessage *message in aMessages){
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
        [dict setValue:message.messageId forKey:@"msgId"];
        [dict setValue:message.from forKey:@"username"];
        [self callBackJSONWithFunction:@"onDeliveryMessage" parameter:dict];
    }
}

//- (void)didSendMessage:(EMMessage *)message
//                 error:(EMError *)error{
//    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//    
//    if(!error){
//        
//        EMConversation *conversation = [_SDK.chatManager conversationForChatter:message.to
//                                                                              conversationType:(EMConversationType)message.messageType];
//        [conversation removeMessageWithId:message.messageId];
//        [_SDK.chatManager insertMessagesToDB:@[message] forChatter:message.conversationChatter append2Chat:YES];
//        [dict setValue:@(YES) forKey:@"isSuccess"];
//
//    }else{
//        [dict setValue:@(NO) forKey:@"isSuccess"];
//        [dict setValue:error.description forKey:@"errorStr"];
//    }
//    [dict setValue:[self analyzeEMMessage:message] forKey:@"message"];
//    [self callBackJSONWithFunction:@"onMessageSent" parameter:dict];
//    
//}

#pragma mark - friend回调

- (void)didReceiveAddedFromUsername:(NSString *)username{
    [self callBackJSONWithFunction:@"onContactAdded" parameter:@[username]];
}
- (void)didReceiveDeletedFromUsername:(NSString *)username{
    [self callBackJSONWithFunction:@"onContactDeleted" parameter:@[username]];
}
- (void)didReceiveFriendInvitationFromUsername:(NSString *)username message:(NSString *)message{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    [dict setValue:message forKey:@"reason"];
    [dict setValue:username forKey:@"username"];
    [self playSoundAndVibration];
    [self callBackJSONWithFunction:@"onContactInvited" parameter:dict];
}

- (void)didReceiveAgreedFromUsername:(NSString *)username{
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:username forKey:@"username"];
    
    [self callBackJSONWithFunction:@"onContactAgreed" parameter:dict];
}
- (void)didReceiveDeclinedFromUsername:(NSString *)username{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:username forKey:@"username"];
    
    [self callBackJSONWithFunction:@"onContactRefused" parameter:dict];
    
}

#pragma mark - group回调
- (void)didReceiveDeclinedGroupInvitation:(EMGroup *)aGroup
                                  invitee:(NSString *)aInvitee
                                   reason:(NSString *)aReason{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict setValue:aGroup.groupId forKey:@"groupId"];
    [dict setValue:aInvitee forKey:@"invitee"];
    [dict setValue:aReason forKey:@"reason"];
    [self callBackJSONWithFunction:@"onInvitationDeclined" parameter:dict];
    
}
- (void)didReceiveAcceptedGroupInvitation:(EMGroup *)aGroup
                                  invitee:(NSString *)aInvitee{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict setValue:aGroup.groupId forKey:@"groupId"];
    [dict setValue:@"" forKey:@"reason"];
    [dict setValue:aInvitee forKey:@"inviter"];
    [self callBackJSONWithFunction:@"onInvitationAccpted" parameter:dict];
}
- (void)didJoinedGroup:(EMGroup *)aGroup
               inviter:(NSString *)aInviter
               message:(NSString *)aMessage{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict setValue:aGroup.groupId forKey:@"groupId"];
    [dict setValue:@"" forKey:@"reason"];
    [dict setValue:aInviter forKey:@"inviter"];
    [self callBackJSONWithFunction:@"onInvitationAccpted" parameter:dict];
    
}

- (void)didReceiveLeavedGroup:(EMGroup *)aGroup
                       reason:(EMGroupLeaveReason)reason{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:aGroup.groupId forKey:@"groupId"];
    [dict setValue:aGroup.subject forKey:@"groupName"];
    
    //群组被销毁
    if(reason == EMGroupLeaveReasonDestroyed){
        [self callBackJSONWithFunction:@"onGroupDestroy" parameter:dict];
        
    }else if(reason == EMGroupLeaveReasonBeRemoved){
        //用户被移除
        [self callBackJSONWithFunction:@"onUserRemoved" parameter:dict];
    }
}

- (void)didReceiveJoinGroupApplication:(EMGroup *)aGroup
                             applicant:(NSString *)aApplicant
                                reason:(NSString *)aReason{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:aGroup.subject forKey:@"groupName"];
    [dict setValue:aGroup.groupId forKey:@"groupId"];
    [dict setValue:aApplicant forKey:@"applyer"];
    [dict setValue:aReason forKey:@"reason"];
    [self playSoundAndVibration];
    [self callBackJSONWithFunction:@"onApplicationReceived" parameter:dict];
    
}

- (void)didReceiveDeclinedJoinGroup:(NSString *)groupId
                             reason:(NSString *)aReason{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    EMError *error=nil;
    EMGroup *group=[self.SDK.groupManager fetchGroupInfo:groupId includeMembersList:NO error:&error];
    if(error){
        [dict setValue:@"" forKey:@"decliner"];
        [dict setValue:@"" forKey:@"groupName"];
    }
    else{
        [dict setValue:group.owner forKey:@"decliner"];
        [dict setValue:group.subject forKey:@"groupName"];
    }
    [dict setValue:groupId forKey:@"groupId"];
    [dict setValue:aReason forKey:@"reason"];
    [self callBackJSONWithFunction:@"onApplicationDeclined" parameter:dict];
    
}
- (void)didReceiveAcceptedJoinGroup:(EMGroup *)aGroup{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict setValue:aGroup.groupId forKey:@"groupId"];
    [dict setValue:aGroup.subject forKey:@"groupName"];
    [dict setValue:aGroup.owner forKey:@"accepter"];
    [self callBackJSONWithFunction:@"onApplicationAccept" parameter:dict];
}
//- (void)groupDidUpdateInfo:(EMGroup *)group error:(EMError *)error{
//    
//    if(!error){
//        NSDictionary *dict = [self analyzeEMGroup:group];
//        [self callBackJSONWithFunction:@"onGroupUpdateInfo" parameter:dict];
//        
//    }
//}
- (void)didUpdateGroupList:(NSArray *)aGroupList{
    for(EMGroup *group in aGroupList){
        NSDictionary *result=[self analyzeEMGroup:group];
        [self callBackJSONWithFunction:@"onGroupUpdateInfo" parameter:result];
    }
}

#pragma mark - Call
- (void)didReceiveCallIncoming:(EMCallSession *)callSession{
    
    self.callSession = callSession;
    
    NSMutableDictionary *dictCallReceive = [NSMutableDictionary dictionary];
    [dictCallReceive setValue:callSession.sessionId forKey:@"callId"];
    [dictCallReceive setValue:callSession.remoteUsername forKey:@"from"];
    NSString *callType = nil;
    
    switch (callSession.type) {
        case EMCallTypeVoice:
            callType = @"0";
            break;
        case EMCallTypeVideo:
            callType = @"1";
            break;
            
        default:
            break;
    }
    [dictCallReceive setValue:callType forKey:@"callType"];
    
    [self callBackJSONWithFunction:@"onCallReceive" parameter:dictCallReceive];
}
- (void)didReceiveCallConnected:(EMCallSession *)aSession{
    
    [self callBackJSONWithFunction:@"onCallStateChanged" parameter:@{@"state":@"2"}];
}
- (void)didReceiveCallAccepted:(EMCallSession *)aSession{
    
    [self callBackJSONWithFunction:@"onCallStateChanged" parameter:@{@"state":@"3"}];
}
- (void)didReceiveCallTerminated:(EMCallSession *)aSession
                          reason:(EMCallEndReason)aReason
                           error:(EMError *)aError{
    
    [self callBackJSONWithFunction:@"onCallStateChanged" parameter:@{@"state":@"4"}];
}
- (void)didReceiveCallUpdated:(EMCallSession *)aSession
                         type:(EMCallStreamControlType)aType{
    NSMutableDictionary *dictCallStateChanged = [NSMutableDictionary dictionary];
    NSString *callState = nil;
    switch (aType) {
        case EMCallStreamControlTypeVoicePause:
            callState = @"5";
            break;
        case EMCallStreamControlTypeVoiceResume:
            callState = @"7";
            break;
            
        default:
            break;
    }
    
    
    [dictCallStateChanged setValue:callState forKey:@"state"];
    
    [self callBackJSONWithFunction:@"onCallStateChanged" parameter:dictCallStateChanged];
}
- (void)didReceiveCallNetworkChanged:(EMCallSession *)callSession
                              status:(EMCallNetworkStatus)aStatus{
    
        NSMutableDictionary *dictCallStateChanged = [NSMutableDictionary dictionary];
        NSString *callState = nil;
        switch (callSession.status) {
            case EMCallSessionStatusRinging:
                callState = @"1";
                break;
            case EMCallSessionStatusConnected:
                callState = @"2";
                break;
            case EMCallSessionStatusAccepted:
                callState = @"3";
                break;
//            case EMCallSessionStatusDisconnected:
//                callState = @"4";
//                break;
            case EMCallSessionStatusConnecting:
                callState = @"6";
                break;

            default:
                break;
        }
        [dictCallStateChanged setValue:callState forKey:@"state"];
        
        [self callBackJSONWithFunction:@"onCallStateChanged" parameter:dictCallStateChanged];
    
}


#pragma mark - APNS
//- (void)didUpdatePushOptions:(EMPushOptions *)options
//                       error:(EMError *)error{
//    if(options){
//        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//        
//        [dict setValue:options.nickname forKey:@"nickname"];
//        [dict setValue:[NSString stringWithFormat:@"%lu",(unsigned long)options.noDisturbingStartH] forKey:@"noDisturbingStartH"];
//        [dict setValue:[NSString stringWithFormat:@"%lu",(unsigned long)options.noDisturbingStartH] forKey:@"noDisturbingEndH"];
//        NSString *noDisturbStatus;
//        
//        switch (options.noDisturbStatus) {
//            case ePushNotificationNoDisturbStatusClose:
//                noDisturbStatus = @"2";
//                break;
//            case ePushNotificationNoDisturbStatusCustom:
//                noDisturbStatus = @"1";
//                break;
//                
//            default://case ePushNotificationNoDisturbStatusDay
//                noDisturbStatus = @"0";
//                break;
//        }
//        NSString *displayStyle = @"";
//        if(options.displayStyle == ePushNotificationDisplayStyle_simpleBanner){
//            displayStyle = @"0";
//        }else if(options.displayStyle == ePushNotificationDisplayStyle_messageSummary){
//            displayStyle = @"1";
//        }
//        
//        [dict setValue:displayStyle forKey:@"displayStyle"];
//        [dict setValue:noDisturbStatus forKey:@"noDisturbingStyle"];
//        self.apnsOptions = options;
//        [self callBackJSONWithFunction:@"cbUpdatePushOptions" parameter:dict];
//    }
//}
//
//
//- (void)didIgnoreGroupPushNotification:(NSArray *)ignoredGroupList
//                                 error:(EMError *)error{
//    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//    [dict setValue:ignoredGroupList forKey:@"groupIds"];
//    [self callBackJSONWithFunction:@"cbIgnoreGroupPushNotification" parameter:dict];
//}



#pragma mark - EMCDDeviceManagerDelegate
- (void)proximitySensorChanged:(BOOL)isCloseToUser{

}

#pragma mark - CallBack Method
const static NSString *kPluginName = @"uexEasemob";
- (void)callBackJSONWithFunction:(NSString *)functionName parameter:(id)obj{
    
    NSString *paramStr = [obj JSONFragment];
    NSString *jsonStr = [NSString stringWithFormat:@"if(%@.%@ != null){%@.%@('%@');}",kPluginName,functionName,kPluginName,functionName,paramStr];
    dispatch_async(self.callBackDispatchQueue, ^(void){
        if([EUtility respondsToSelector:@selector(browserView:callbackWithFunctionKeyPath:arguments:completion:)]){
            [EUtility browserView:[EUtility rootBrwoserView]
      callbackWithFunctionKeyPath:[NSString stringWithFormat:@"%@.%@",kPluginName,functionName]
                        arguments:paramStr?@[paramStr]:nil
                       completion:nil];
        }else{
            [EUtility evaluatingJavaScriptInRootWnd:jsonStr];
        }
        
    });

}




- (NSDictionary *)analyzeEMMessage:(EMMessage *)message{
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    switch (message.chatType) {
        case EMChatTypeChat:
            [result setValue:message.from forKey:@"from"];
            [result setValue:message.to forKey:@"to"];
            
            [result setValue:cEMChatTypeUser forKey:@"isGroup"];
            [result setValue:cEMChatTypeUser forKey:@"chatType"];
            break;
        case EMChatTypeGroupChat:
//            if ([message.groupSenderName isEqual:message.from]) {
//                //来自自己的群消息，from为自己 to为群id，不做修改。(用于已发送消息的监听)
//                [result setValue:message.from forKey:@"from"];
//                [result setValue:message.to forKey:@"to"];
//            }else{
//                //来自他人的群消息，此处修改为from为消息实际发送人 to为群id (与Android保持一致)
//                [result setValue:message.groupSenderName forKey:@"from"];
//                [result setValue:message.from forKey:@"to"];
//            }
            [result setValue:message.from forKey:@"from"];
            [result setValue:message.to forKey:@"to"];
            
            [result setValue:cEMChatTypeGroup forKey:@"isGroup"];
            [result setValue:cEMChatTypeGroup forKey:@"chatType"];
            break;
            
        case EMChatTypeChatRoom:
            [result setValue:cEMChatTypeChatRoom forKey:@"chatType"];
            break;
        default:
            return nil;
            break;
    }

    [result setValue:message.messageId forKey:@"messageId"];
    [result setValue:[NSString stringWithFormat:@"%lld",message.timestamp] forKey:@"messageTime"];
    [result setValue:message.isDeliverAcked?@(YES):@(NO) forKey:@"isDelievered"];
    [result setValue:message.isReadAcked?@(YES):@(NO) forKey:@"isAcked"];
    [result setValue:message.isRead?@(YES):@(NO) forKey:@"isRead"];
    
    
    NSString *type = @"";
    NSMutableDictionary *bodyDict = [NSMutableDictionary dictionary];
    switch (message.body.type) {
        case EMMessageBodyTypeText:
        {
            // 收到的文字消息
            type = @"text";
            NSString *txt = ((EMTextMessageBody *)message.body).text;
            [bodyDict setValue:txt forKey:@"text"];
        }
            break;
        case EMMessageBodyTypeImage:
        {
            // 得到一个图片消息body
            type = @"image";
            EMImageMessageBody *body = ((EMImageMessageBody *)message.body);
            [bodyDict setValue:body.remotePath forKey:@"remotePath"];
            [bodyDict setValue:body.secretKey forKey:@"secretKey"];
            [bodyDict setValue:body.thumbnailRemotePath forKey:@"thumbnailRemotePath"];
            [bodyDict setValue:body.thumbnailSecretKey forKey:@"thumbnailSecretKey"];
            [bodyDict setValue:body.displayName forKey:@"displayName"];
            
        }
            break;
        case EMMessageBodyTypeLocation:
        {
            type = @"location";
            EMLocationMessageBody *body = (EMLocationMessageBody *)message.body;
            [bodyDict setValue:[NSString stringWithFormat:@"%f",body.latitude] forKey:@"latitude"];
            [bodyDict setValue:[NSString stringWithFormat:@"%f",body.longitude] forKey:@"longitude"];
            [bodyDict setValue:body.address forKey:@"address"];
            
        }
            break;
        case EMMessageBodyTypeVoice:
        {
            
            type = @"audio";
            EMVoiceMessageBody *body = (EMVoiceMessageBody *)message.body;
            [bodyDict setValue:body.remotePath forKey:@"remotePath"];
            [bodyDict setValue:body.secretKey forKey:@"secretKey"];
            [bodyDict setValue:body.displayName forKey:@"displayName"];
            [bodyDict setValue:[NSString stringWithFormat:@"%ld",(long)body.duration] forKey:@"length"];
        }
            break;
        case EMMessageBodyTypeVideo:
        {
            type = @"video";
            EMVideoMessageBody *body = (EMVideoMessageBody *)message.body;
            
            [bodyDict setValue:body.remotePath forKey:@"remotePath"];
            [bodyDict setValue:body.secretKey forKey:@"secretKey"];
            [bodyDict setValue:body.thumbnailRemotePath forKey:@"thumbnailRemotePath"];
            [bodyDict setValue:body.thumbnailSecretKey forKey:@"thumbnailSecretKey"];
            [bodyDict setValue:body.displayName forKey:@"displayName"];
            [bodyDict setValue:[NSString stringWithFormat:@"%ld",(long)body.duration] forKey:@"length"];
        }
            break;
        case EMMessageBodyTypeFile:
        {
            type = @"file";
            EMFileMessageBody *body = (EMFileMessageBody *)message.body;
            [bodyDict setValue:body.remotePath forKey:@"remotePath"];
            [bodyDict setValue:body.secretKey forKey:@"secretKey"];
            [bodyDict setValue:body.displayName forKey:@"displayName"];
        }
            break;
            
        case EMMessageBodyTypeCmd:
        {
            type = @"cmd";
            EMCmdMessageBody *body = (EMCmdMessageBody *)message.body;
            [bodyDict setValue:body.action forKey:@"action"];
        }
        default:
            break;
    }
    [result setValue:type forKey:@"messageType"];
    [result setValue:bodyDict forKey:@"messageBody"];
    
    if(message.ext){
        [result setValue:[message.ext objectForKey:uexEasemobExtraInfoKey] forKey:@"ext"];
        [result setValue:message.ext forKey:@"extObj"];
    }
    
    return result;
}

- (NSDictionary *)analyzeEMConversation:(EMConversation *)conversation{
    
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setValue:conversation.conversationId forKey:@"chatter"];
    switch (conversation.type) {
        case EMConversationTypeChat:
            [result setValue:cEMChatTypeUser forKey:@"isGroup"];
            [result setValue:cEMChatTypeUser forKey:@"chatType"];
            break;
        case EMConversationTypeGroupChat:
            [result setValue:cEMChatTypeGroup forKey:@"isGroup"];
            [result setValue:cEMChatTypeGroup forKey:@"chatType"];
            break;
        case EMConversationTypeChatRoom:
            [result setValue:cEMChatTypeChatRoom forKey:@"chatType"];
            break;
            
        default:
            break;
    }
    
    
    NSMutableArray *msgList = [NSMutableArray arrayWithCapacity:1];
    NSArray *messages = [conversation loadMoreMessagesFromId:nil limit:10000];
    for(EMMessage *msg in messages){
        [msgList addObject:[self analyzeEMMessage:msg]];
    }
    [result setValue:msgList forKey:@"messages"];
    
    return result;
}

/*
 @constant eGroupStyle_PrivateOnlyOwnerInvite 私有群组，只能owner权限的人邀请人加入
 @constant eGroupStyle_PrivateMemberCanInvite 私有群组，owner和member权限的人可以邀请人加入
 @constant eGroupStyle_PublicJoinNeedApproval 公开群组，允许非群组成员申请加入，需要管理员同意才能真正加入该群组
 @constant eGroupStyle_PublicOpenJoin         公开群组，允许非群组成员加入，不需要管理员同意
 @constant eGroupStyle_PublicAnonymous        公开匿名群组，允许非群组成员加入，不需要管理员同意
 @constant eGroupStyle_Default                默认群组类型
 */


- (NSDictionary *)analyzeEMGroup:(EMGroup *)group{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setValue:group.subject forKey:@"groupSubject"];
    [result setValue:group.subject forKey:@"groupName"];
    [result setValue:group.description forKey:@"groupDescription"];
    [result setValue:group.members forKey:@"members"];
    [result setValue:group.owner forKey:@"owner"];
    [result setValue:group.isPushNotificationEnabled?@(YES):@(NO) forKey:@"isPushNotificationEnabled"];
    [result setValue:group.isBlocked?@(YES):@(NO) forKey:@"isBlock"];
    id isPublic = @"";
    id allowInvites = @"";
    id membersOnly = @"";

    switch (group.setting.style) {
        case EMGroupStylePrivateOnlyOwnerInvite:
            isPublic = @(NO);
            allowInvites = @(NO);
            membersOnly = @(YES);
            break;
        case EMGroupStylePrivateMemberCanInvite:
            isPublic = @(NO);
            allowInvites = @(YES);
            membersOnly = @(YES);
            
            break;
        case EMGroupStylePublicJoinNeedApproval:
            isPublic = @(YES);
            allowInvites = @(YES);
            membersOnly = @(YES);
            break;
        case EMGroupStylePublicOpenJoin :
            isPublic = @(YES);
            allowInvites = @(YES);
            membersOnly = @(NO);
            break;
            
        default:
            break;
    }
    [result setValue:group.groupId forKey:@"groupId"];
    [result setValue:isPublic forKey:@"isPublic"];
    [result setValue:allowInvites forKey:@"allowInvites"];
    [result setValue:membersOnly forKey:@"membersOnly"];
    [result setValue:[NSString stringWithFormat: @"%ld", (long)group.setting.maxUsersCount] forKey:@"groupMaxUserCount"];
    [result setValue:[NSString stringWithFormat: @"%ld", (long)group.setting.style] forKey:@"groupStyle"];
    return result;
}




@end
