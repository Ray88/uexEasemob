//
//  uexEasemobManager.m
//  EUExEasemob
//
//  Created by CC on 15/6/13.
//  Copyright (c) 2015年 AppCan. All rights reserved.
//

#import "uexEasemobManager.h"
#import "EMCDDeviceManager.h"
#import <AppCanKit/ACEXTScope.h>


@interface uexEesemobCallbackReceiver : NSObject
@property (nonatomic,weak)id<AppCanWebViewEngineObject> engine;

@end
@implementation uexEesemobCallbackReceiver
- (instancetype)initWithEngine:(id<AppCanWebViewEngineObject>)engine{
    self = [super init];
    if (self) {
        _engine = engine;
    }
    return self;
}
@end




@interface uexEasemobManager()<EMClientDelegate,EMChatManagerDelegate,EMCallManagerDelegate,EMCDDeviceManagerDelegate,EMContactManagerDelegate,EMGroupManagerDelegate,EMCDDeviceManagerProximitySensorDelegate,EMChatroomManagerDelegate>
@property (nonatomic,strong)NSDictionary *launchOptions;
@property (nonatomic,strong) NSDate *lastPlaySoundDate;
@property (nonatomic,weak) EMCDDeviceManager *EMDevice;
@property (nonatomic,assign)BOOL hasInitialized;
@property (nonatomic,strong)NSMutableArray<uexEesemobCallbackReceiver *> *callbackReceivers;
@end





@implementation uexEasemobManager


NSString *const cEMChatTypeUser = @"0";
NSString *const cEMChatTypeGroup = @"1";
NSString *const cEMChatTypeChatRoom = @"2";
NSString *const uexEasemobExtraInfoKey = @"ext";
NSString *const uexEasemobManagerInitSuccessNotificationKey = @"uexEasemobManagerInitSuccessNotificationKey";



+ (instancetype)sharedManager{
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
        _EMDevice = [EMCDDeviceManager sharedInstance];
        _EMDevice.delegate = self;
        _isShowNotificationInBackgroud = YES;
        _SDK = [EMClient sharedClient];
    }
    return self;
}




- (void)didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    _launchOptions = launchOptions;
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    self.remoteLaunchDict = userInfo;
    

}


- (void)registerCallback:(id<AppCanWebViewEngineObject>)engine{
    if (!engine) {
        return;
    }
    [self.callbackReceivers addObject:[[uexEesemobCallbackReceiver alloc] initWithEngine:engine]];
}

- (void)unregisterCallback:(id<AppCanWebViewEngineObject>)engine{
    if (!engine) {
        return;
    }
    uexEesemobCallbackReceiver *target = nil;
    for (uexEesemobCallbackReceiver *receiver in self.callbackReceivers) {
        if (receiver.engine == engine) {
            target = receiver;
            break;
        }
    }
    if (target) {
        [self.callbackReceivers removeObject:target];
    }
}

- (void)unregisterAllCallback{
    [self.callbackReceivers removeAllObjects];
}



#pragma mark - 初始化SDK

- (EMError *)initializeEasemobWithOptions:(EMOptions *)options{

    if (self.hasInitialized) {
        [self callbackWithFunctionName:@"cbInit" obj:@"EaseMobSDK has already been initialized!"];
        return nil;
    }
    
    EMError *error = [_SDK initializeSDKWithOptions:options];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;

    if (!error) {
        self.hasInitialized = YES;
        [self dataMigration];
        [self setupNotifiers];
        [self registerEaseMobNotification];
        [self setupDefaultValue];
        [[NSNotificationCenter defaultCenter] postNotificationName:uexEasemobManagerInitSuccessNotificationKey object:nil];
        if([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]){
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        }
        [self callbackWithFunctionName:@"cbInit" obj:@"EaseMobSDK initialized successfully!"];
    }
    
    return error;

}

- (void)setupDefaultValue{
    self.lastPlaySoundDate = [NSDate date];
    self.isPlayVibration = YES;
    self.isPlaySound = YES;
    self.messageNotification = YES;

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
    static const CGFloat kDefaultPlaySoundInterval = 3.0;
    if (timeInterval < kDefaultPlaySoundInterval) {
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
        UEX_LOG_ERROR(error);
    }else{
        [self callbackWithFunctionName:@"onConnected" obj:nil];
    }
}

- (void)dataMigration{
    static NSString *const kUexEasemobUserDefaultsDataMigrationFlag = @"kUexEasemobUserDefaultsDataMigrationFlag";
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    BOOL hasMigrated = [df boolForKey:kUexEasemobUserDefaultsDataMigrationFlag];
    if (!hasMigrated) {
        [df setBool:YES forKey:kUexEasemobUserDefaultsDataMigrationFlag];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [_SDK migrateDatabaseToLatestSDK];
        });
    }
}




#pragma mark - 连接状态回调
- (void)disconnectedError:(NSInteger)errorCode{

    UEX_ERROR err = uexErrorMake(errorCode);
    [self callbackWithFunctionName:@"onDisconnected" obj:@{@"error": err}];

}


- (void)didRemovedFromServer{
    [self disconnectedError:1];
}

- (void)didLoginFromOtherDevice{
    [self disconnectedError:2];
}

- (void)didConnectionStateChanged:(EMConnectionState)connectionState{
    switch (connectionState) {
        case EMConnectionDisconnected:
            [self disconnectedError:3];
            break;
        case EMConnectionConnected:
            [self callbackWithFunctionName:@"onConnected" obj:nil];
            break;

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
        [self callbackWithFunctionName:@"onNewMessage" obj:dict];
    }
    
}

- (void)didReceiveCmdMessages:(NSArray *)aCmdMessages{
    for(EMMessage *cmdMessage in aCmdMessages){
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        NSDictionary *dictMessage = [self analyzeEMMessage:cmdMessage];
        [dict setValue:cmdMessage.messageId forKey:@"msgId"];
        [dict setValue:dictMessage forKey:@"message"];
        EMCmdMessageBody *body = (EMCmdMessageBody *)cmdMessage.body;
        [dict setValue:body.action forKey:@"action"];
        [self callbackWithFunctionName:@"onCmdMessageReceive" obj:dict];
    }
}


- (void)didReceiveHasReadAcks:(NSArray *)aMessages{
    for(EMMessage* message in aMessages){
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:message.messageId forKey:@"msgId"];
        [dict setValue:message.from forKey:@"username"];
        [self callbackWithFunctionName:@"onAckMessage" obj:dict];
    }
}


- (void)didReceiveHasDeliveredAcks:(NSArray *)aMessages{
    if(self.noDeliveryNotification){
        return;
    }
    for(EMMessage *message in aMessages){
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:message.messageId forKey:@"msgId"];
        [dict setValue:message.from forKey:@"username"];
        [self callbackWithFunctionName:@"onDeliveryMessage" obj:dict];

    }
}




#pragma mark - friend回调

- (void)didReceiveAddedFromUsername:(NSString *)username{
    [self callbackWithFunctionName:@"onContactAdded"  obj:@[username]];

}
- (void)didReceiveDeletedFromUsername:(NSString *)username{
    [self callbackWithFunctionName:@"onContactDeleted"  obj:@[username]];

}
- (void)didReceiveFriendInvitationFromUsername:(NSString *)username message:(NSString *)message{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:message forKey:@"reason"];
    [dict setValue:username forKey:@"username"];
    [self playSoundAndVibration];
    [self callbackWithFunctionName:@"onContactInvited" obj:dict];
}

- (void)didReceiveAgreedFromUsername:(NSString *)username{
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:username forKey:@"username"];
    
    [self callbackWithFunctionName:@"onContactAgreed" obj:dict];
}
- (void)didReceiveDeclinedFromUsername:(NSString *)username{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:username forKey:@"username"];
    
    [self callbackWithFunctionName:@"onContactRefused" obj:dict];
    
}

#pragma mark - group回调
- (void)didReceiveDeclinedGroupInvitation:(EMGroup *)aGroup
                                  invitee:(NSString *)aInvitee
                                   reason:(NSString *)aReason{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:aGroup.groupId forKey:@"groupId"];
    [dict setValue:aInvitee forKey:@"invitee"];
    [dict setValue:aReason forKey:@"reason"];
    
    [self callbackWithFunctionName:@"onInvitationDeclined" obj:dict];
    
}
- (void)didReceiveAcceptedGroupInvitation:(EMGroup *)aGroup
                                  invitee:(NSString *)aInvitee{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:aGroup.groupId forKey:@"groupId"];
    [dict setValue:aInvitee forKey:@"inviter"];
    [self callbackWithFunctionName:@"onInvitationAccpted" obj:dict];
}

- (void)didReceiveLeavedGroup:(EMGroup *)aGroup
                       reason:(EMGroupLeaveReason)reason{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:aGroup.groupId forKey:@"groupId"];
    [dict setValue:aGroup.subject forKey:@"groupName"];
    
    //群组被销毁
    if(reason == EMGroupLeaveReasonDestroyed){
        [self callbackWithFunctionName:@"onGroupDestroy" obj:dict];
        
    }else if(reason == EMGroupLeaveReasonBeRemoved){
        //用户被移除
        [self callbackWithFunctionName:@"onUserRemoved" obj:dict];
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
    [self callbackWithFunctionName:@"onApplicationReceived" obj:dict];
    
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
    [self callbackWithFunctionName:@"onApplicationDeclined" obj:dict];
    
}
- (void)didReceiveAcceptedJoinGroup:(EMGroup *)aGroup{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:aGroup.groupId forKey:@"groupId"];
    [dict setValue:aGroup.subject forKey:@"groupName"];
    [dict setValue:aGroup.owner forKey:@"accepter"];
    [self callbackWithFunctionName:@"onApplicationAccept" obj:dict];
}
//- (void)groupDidUpdateInfo:(EMGroup *)group error:(EMError *)error{
//    
//    if(!error){
//        NSDictionary *dict = [self analyzeEMGroup:group];
//        [self callBackJSONWithFunction:@"onGroupUpdateInfo" obj:dict];
//        
//    }
//}
- (void)didUpdateGroupList:(NSArray *)aGroupList{
    for(EMGroup *group in aGroupList){
        NSDictionary *result=[self analyzeEMGroup:group];
        [self callbackWithFunctionName:@"onGroupUpdateInfo" obj:result];
    }
}

//3.0.22新增接口
- (void)didJoinedGroup:(EMGroup *)aGroup inviter:(NSString *)aInviter message:(NSString *)aMessage{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:aGroup.groupId forKey:@"groupId"];
    [dict setValue:aGroup.subject forKey:@"groupName"];
    [dict setValue:aMessage forKey:@"meaasge"];
    [dict setValue:aInviter forKey:@"username"];
    [self callbackWithFunctionName:@"onDidJoinedGroup" obj:dict];
}
//3.0.22新增接口
- (void)didReceiveGroupInvitation:(NSString *)aGroupId inviter:(NSString *)aInviter message:(NSString *)aMessage{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:aGroupId forKey:@"groupId"];
    [dict setValue:aMessage forKey:@"meaasge"];
    [dict setValue:aInviter forKey:@"username"];
    [self callbackWithFunctionName:@"onReceiveGroupInvitation" obj:dict];
}
#pragma mark - Call回调
#pragma mark EMCallManagerDelegate


- (void)callDidReceive:(EMCallSession *)aSession{
    self.callSession = aSession;
    
    NSMutableDictionary *dictCallReceive = [NSMutableDictionary dictionary];
    [dictCallReceive setValue:aSession.callId forKey:@"callId"];
    [dictCallReceive setValue:aSession.remoteName forKey:@"from"];
    [dictCallReceive setValue:@(aSession.type) forKey:@"callType"];
    
    [self callbackWithFunctionName:@"onCallReceive" obj:dictCallReceive];
}


- (void)callDidConnect:(EMCallSession *)aSession{
    [self callbackWithFunctionName:@"onCallStateChanged" obj:@{@"state": @2}];
}

- (void)callDidAccept:(EMCallSession *)aSession{
    [self callbackWithFunctionName:@"onCallStateChanged" obj:@{@"state": @3}];
}


- (void)callDidEnd:(EMCallSession *)aSession
            reason:(EMCallEndReason)aReason
             error:(EMError *)aError{
    if (aError) {
        UEX_LOG_ERROR(aError);
    }
    [self callbackWithFunctionName:@"onCallStateChanged" obj:@{@"state": @4}];
}

- (void)callStateDidChange:(EMCallSession *)aSession
                      type:(EMCallStreamingStatus)aType{
    switch (aType) {
        case EMCallStreamStatusVideoPause:
        case EMCallStreamStatusVoicePause:
            [self callbackWithFunctionName:@"onCallStateChanged" obj:@{@"state": @5}];
        break;
        
        case EMCallStreamStatusVideoResume:
        case EMCallStreamStatusVoiceResume:
            [self callbackWithFunctionName:@"onCallStateChanged" obj:@{@"state": @7}];
        break;
    }
}


- (void)callNetworkDidChange:(EMCallSession *)aSession
                      status:(EMCallNetworkStatus)aStatus{
    
}



#pragma mark - APNS




#pragma mark - EMCDDeviceManagerDelegate
- (void)proximitySensorChanged:(BOOL)isCloseToUser{

}

#pragma mark - Callback Method

- (void)callbackWithFunctionName:(NSString *)funcName obj:(id)obj{
    id param = nil;
    if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]]) {
        param = [obj ac_JSONFragment];
    }
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
        param = obj;
    }
    NSArray *args = param ? ACArgsPack(param) : nil;
    [AppCanRootWebViewEngine() callbackWithFunctionKeyPath:[NSString stringWithFormat:@"uexEasemob.%@",funcName] arguments:args];

    
}







- (NSDictionary *)analyzeEMMessage:(EMMessage *)message{
    if (!message) {
        return nil;
    }
    
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
    [result setValue:@(message.timestamp) forKey:@"messageTime"];
    [result setValue:@(message.isDeliverAcked) forKey:@"isDelievered"];
    [result setValue:@(message.isReadAcked) forKey:@"isAcked"];
    [result setValue:@(message.isRead) forKey:@"isRead"];
    
    
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



- (void)asyncAnalyzeEMConversation:(EMConversation *)conversation completion:(void (^)(NSDictionary *))completion{
    if (!completion) {
        return;
    }
    if (!conversation) {
        completion(nil);
        return;
    }
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
    }
    [conversation loadMessagesStartFromId:nil count:10000 searchDirection:EMMessageSearchDirectionUp completion:^(NSArray *aMessages, EMError *aError) {
        if (aError) {
            UEX_LOG_ERROR(aError);
        }else{
            NSMutableArray *msgList = [NSMutableArray array];
            for (EMMessage *msg in aMessages) {
                NSDictionary *msgDict = [self analyzeEMMessage:msg];
                if (msgDict) {
                    [msgList addObject:msgDict];
                }
            }
            [result setValue:msgList forKey:@"messages"];
        }
        completion(result);
    }];
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
    if (!group) {
        return nil;
    }
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setValue:group.subject forKey:@"groupSubject"];
    [result setValue:group.subject forKey:@"groupName"];
    [result setValue:group.description forKey:@"groupDescription"];
    [result setValue:group.members forKey:@"members"];
    [result setValue:group.owner forKey:@"owner"];
    [result setValue:@(group.isPushNotificationEnabled) forKey:@"isPushNotificationEnabled"];
    [result setValue:@(group.isBlocked) forKey:@"isBlock"];
    NSNumber *isPublic = nil,*allowInvites = nil,*membersOnly = nil;


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
