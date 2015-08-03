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





@implementation uexEasemobManager


NSString *const cEMChatTypeUser=@"0";
NSString *const cEMChatTypeGroup=@"1";
NSString *const cEMChatTypeChatRoom=@"2";





+ (instancetype)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static uexEasemobManager *sharedObject = nil;
    dispatch_once(&pred, ^{
        sharedObject = [[self alloc] init];
        
        
    });
    return sharedObject;
}


-(instancetype)init{
    self=[super init];
    if(self){
        self.callBackDispatchQueue=dispatch_queue_create("gcd.uexEasemobCallBackDispatchQueue",NULL);
        self.EMDevice=[EMCDDeviceManager sharedInstance];
        _EMDevice.delegate=self;
        
        
        
            }
    return self;
}




-(void)didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    _launchOptions=launchOptions;
    NSDictionary *userInfo = [launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
    if(userInfo)
    {
        self.remoteLaunchDict=userInfo;
    }

}


#pragma mark - 初始化SDK
-(void)initEasemobWithAppKey:(NSString *)appKey apnsCertName:(NSString *)certName{
    if(!_SDK){
        _SDK=[EaseMob sharedInstance];
        [_SDK registerSDKWithAppKey:appKey
                           apnsCertName:certName
                            otherConfig:@{kSDKConfigEnableConsoleLogger:[NSNumber numberWithBool:YES]}];
        
        [_SDK application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:_launchOptions];
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        [self setupNotifiers];
        [self registerEaseMobNotification];
        [self setupDefaultValue];
        [self callBackJsonWithFunction:@"cbInit" parameter:@"EaseMobSDK initialized successfully!"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"uexEasemobInitSuccess"
                                                            object:nil];
    }else{
        [self callBackJsonWithFunction:@"cbInit" parameter:@"EaseMobSDK has already been initialized!"];
    }
    

}
-(void)setupDefaultValue{
    self.lastPlaySoundDate = [NSDate date];
    self.isPlayVibration = YES;
    self.isPlaySound = YES;
    self.messageNotification = YES;

    [_SDK.chatManager enableDeliveryNotification];//开启消息已送达回执
    self.isAutoLoginEnabled=YES;
}


//注册回调
- (void)registerEaseMobNotification{
    [self unRegisterEaseMobNotification];

    [_SDK.chatManager addDelegate:self delegateQueue:nil];
    [_SDK.callManager addDelegate:self delegateQueue:nil];
    
}

- (void)unRegisterEaseMobNotification{
    [_SDK.chatManager removeDelegate:self];
    [_SDK.callManager removeDelegate:self];
}

    
    
//监听系统事件
    
    
    
-(void)setupNotifiers{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidEnterBackgroundNotif:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidFinishLaunching:)
                                                     name:UIApplicationDidFinishLaunchingNotification
                                                   object:nil];
        
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidBecomeActiveNotif:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillResignActiveNotif:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillTerminateNotif:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appProtectedDataWillBecomeUnavailableNotif:)
                                                     name:UIApplicationProtectedDataWillBecomeUnavailable
                                                   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appProtectedDataDidBecomeAvailableNotif:)
                                                     name:UIApplicationProtectedDataDidBecomeAvailable
                                                   object:nil];
}
    
- (void)appDidEnterBackgroundNotif:(NSNotification*)notif{
    [_SDK applicationDidEnterBackground:notif.object];
}
    
- (void)appWillEnterForeground:(NSNotification*)notif
{
    [_SDK applicationWillEnterForeground:notif.object];
}
    
- (void)appDidFinishLaunching:(NSNotification*)notif
{
    [_SDK applicationDidFinishLaunching:notif.object];
}
    
- (void)appDidBecomeActiveNotif:(NSNotification*)notif
{
    [_SDK applicationDidBecomeActive:notif.object];
}
    
- (void)appWillResignActiveNotif:(NSNotification*)notif
{
    [_SDK applicationWillResignActive:notif.object];
}
    
- (void)appDidReceiveMemoryWarning:(NSNotification*)notif
{
    [_SDK applicationDidReceiveMemoryWarning:notif.object];
}
    
- (void)appWillTerminateNotif:(NSNotification*)notif
{
    [_SDK applicationWillTerminate:notif.object];
}
    
- (void)appProtectedDataWillBecomeUnavailableNotif:(NSNotification*)notif
{
    [_SDK applicationProtectedDataWillBecomeUnavailable:notif.object];
}
    
- (void)appProtectedDataDidBecomeAvailableNotif:(NSNotification*)notif
{
    [_SDK applicationProtectedDataDidBecomeAvailable:notif.object];
}

#pragma mark - 振动响铃
static const CGFloat kDefaultPlaySoundInterval = 3.0;

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

-(void)willAutoLoginWithInfo:(NSDictionary *)loginInfo
                       error:(EMError *)error{
    
}


-(void)didAutoLoginWithInfo:(NSDictionary *)loginInfo error:(EMError *)error{
    if (!error && loginInfo) {
        self.apnsOptions =[_SDK.chatManager pushNotificationOptions];
        [_SDK.chatManager importDataToNewDatabase];
        [_SDK.chatManager loadDataFromDatabase];
        [self callBackJsonWithFunction:@"onConnected" parameter:nil];

    }
}
#pragma mark - 连接状态回调
-(void)disconnectedError:(NSInteger)errorCode{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:[NSString stringWithFormat: @"%ld", (long)errorCode] forKey:@"error"];
    
    [self callBackJsonWithFunction:@"onDisconnected" parameter:dict];
}


-(void)didRemovedFromServer{
    [_SDK.chatManager asyncLogoffWithUnbindDeviceToken:NO completion:^(NSDictionary *info, EMError *error) {
        
    } onQueue:nil];
    [self disconnectedError:1];
}

-(void)didLoginFromOtherDevice{
    [_SDK.chatManager asyncLogoffWithUnbindDeviceToken:NO completion:^(NSDictionary *info, EMError *error) {
        
    } onQueue:nil];
    [self disconnectedError:2];
}

- (void)didConnectionStateChanged:(EMConnectionState)connectionState{
    if (connectionState == eEMConnectionDisconnected){
        [self disconnectedError:3];
        return;
    }
    if (connectionState == eEMConnectionConnected){
        [self callBackJsonWithFunction:@"onConnected" parameter:nil];
        return;
    }
}
#pragma mark - Message回调

-(void)didReceiveMessage:(EMMessage *)message{
      NSDictionary *dict = [self analyzeEMMessage:message];
    
    [self playSoundAndVibration];
    [self callBackJsonWithFunction:@"onNewMessage" parameter:dict];
    
}
- (void)didReceiveOfflineMessages:(NSArray *)offlineMessages{
    for(EMMessage *msg in offlineMessages){
        [self didReceiveMessage:msg];
    }
    
}
- (void)didReceiveCmdMessage:(EMMessage *)cmdMessage{
 
    NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:3];
    NSDictionary *dictMessage =[self analyzeEMMessage:cmdMessage];
    [dict setValue:cmdMessage.messageId forKey:@"msgId"];
    [dict setValue:dictMessage forKey:@"message"];
    EMCommandMessageBody *body = (EMCommandMessageBody *)cmdMessage.messageBodies.lastObject;
    [dict setValue:body.action forKey:@"action"];
    [self playSoundAndVibration];
    [self callBackJsonWithFunction:@"onCmdMessageReceive" parameter:dict];
}


- (void)didReceiveOfflineCmdMessages:(NSArray *)offlineCmdMessages{
    for(EMMessage *msg in offlineCmdMessages){
        [self didReceiveCmdMessage:msg];
    }
    
}


-(void)didReceiveHasReadResponse:(EMReceipt *)resp{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
    [dict setValue:resp.chatId forKey:@"msgId"];
    [dict setValue:resp.from forKey:@"username"];
    
    [self callBackJsonWithFunction:@"onAckMessage" parameter:dict];
}


-(void)didReceiveHasDeliveredResponse:(EMReceipt *)resp{
    
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
    [dict setValue:resp.chatId forKey:@"msgId"];
    [dict setValue:resp.from forKey:@"username"];
    [self callBackJsonWithFunction:@"onDeliveryMessage" parameter:dict];
}

- (void)didSendMessage:(EMMessage *)message
                 error:(EMError *)error{
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    
    if(!error){
        
        EMConversation *conversation = [_SDK.chatManager conversationForChatter:message.to
                                                                              conversationType:(EMConversationType)message.messageType];
        [conversation removeMessageWithId:message.messageId];
        [_SDK.chatManager insertMessagesToDB:@[message] forChatter:message.conversationChatter append2Chat:YES];
        [dict setValue:@(YES) forKey:@"isSuccess"];

    }else{
        [dict setValue:@(NO) forKey:@"isSuccess"];
        [dict setValue:error.description forKey:@"errorStr"];
    }
    [dict setValue:[self analyzeEMMessage:message] forKey:@"message"];
    [self callBackJsonWithFunction:@"onMessageSent" parameter:dict];
    
}

#pragma mark - friend回调
-(void)didReceiveBuddyRequest:(NSString *)username message:(NSString *)message{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
    [dict setValue:message forKey:@"reason"];
    [dict setValue:username forKey:@"username"];
    [self callBackJsonWithFunction:@"onContactInvited" parameter:dict];
}

-(void)didAcceptedByBuddy:(NSString *)username{
    
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:username forKey:@"username"];
    
    [self callBackJsonWithFunction:@"onContactAgreed" parameter:dict];
}
-(void)didRejectedByBuddy:(NSString *)username{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:username forKey:@"username"];
    
    [self callBackJsonWithFunction:@"onContactRefused" parameter:dict];
    
}

#pragma mark - group回调
-(void)didReceiveGroupRejectFrom:(NSString *)groupId
                         invitee:(NSString *)username
                          reason:(NSString *)reason
                           error:(EMError *)error{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:3];
    [dict setValue:groupId forKey:@"groupId"];
    [dict setValue:username forKey:@"invitee"];
    [dict setValue:reason forKey:@"reason"];
    [self callBackJsonWithFunction:@"onInvitationDeclined" parameter:dict];
    
}

- (void)group:(EMGroup *)group didLeave:(EMGroupLeaveReason)reason error:(EMError *)error{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:group.groupId forKey:@"groupId"];
    [dict setValue:group.groupSubject forKey:@"groupName"];
    
    //群组被销毁
    if(reason == eGroupLeaveReason_Destroyed){
        [self callBackJsonWithFunction:@"onGroupDestroy" parameter:dict];
        
    }else if(reason == eGroupLeaveReason_BeRemoved){
        //用户被移除
        [self callBackJsonWithFunction:@"onUserRemoved" parameter:dict];
    }
}

-(void)didReceiveApplyToJoinGroup:(NSString *)groupId
                        groupname:(NSString *)groupname
                    applyUsername:(NSString *)username
                           reason:(NSString *)reason
                            error:(EMError *)error{
    if(!error){
        NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:3];
        [dict setValue:groupId forKey:@"groupId"];
        [dict setValue:groupname forKey:@"groupName"];
        [dict setValue:username forKey:@"applyer"];
        [dict setValue:reason forKey:@"reason"];
        [self playSoundAndVibration];
        [self callBackJsonWithFunction:@"onApplicationReceived" parameter:dict];
    }
    
    
}

- (void)didReceiveAcceptApplyToJoinGroup:(NSString *)groupId
                               groupname:(NSString *)groupname
                                   error:(EMError *)error
{
    if(!error){
        NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:3];
        EMError *error2=nil;
        EMGroup *group=[_SDK.chatManager fetchGroupInfo:groupId error:&error2];
        [dict setValue:groupId forKey:@"groupId"];
        [dict setValue:groupname forKey:@"groupName"];
        [dict setValue:group.owner forKey:@"accepter"];
        [self callBackJsonWithFunction:@"onApplicationAccept" parameter:dict];
    }
}

-(void)didReceiveRejectApplyToJoinGroupFrom:(NSString *)fromId
                                  groupname:(NSString *)groupname
                                     reason:(NSString *)reason
                                      error:(EMError *)error{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:3];
    [dict setValue:fromId forKey:@"decliner"];
    [dict setValue:groupname forKey:@"groupName"];
    [dict setValue:reason forKey:@"reason"];
    [self callBackJsonWithFunction:@"onApplicationDeclined" parameter:dict];
    
}

-(void)didFetchAllPublicGroups:(NSArray *)groups
                         error:(EMError *)error{
    
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
    if(!error){
        [dict setValue:@"0" forKey:@"result"];
        NSMutableArray *grouplist=[NSMutableArray arrayWithCapacity:10] ;
        for (EMGroup  *group in groups){
            [grouplist addObject:[self analyzeEMGroup:group]];
        }
        
        [dict setValue:grouplist forKey:@"grouplist"];
    }else{
        [dict setValue:@"1" forKey:@"result"];
    }
    [self callBackJsonWithFunction:@"cbGetAllPublicGroupsFromServer" parameter:dict];
}

- (void)groupDidUpdateInfo:(EMGroup *)group error:(EMError *)error{
    
    if(!error){
        NSDictionary *dict =[self analyzeEMGroup:group];
        [self callBackJsonWithFunction:@"onGroupUpdateInfo" parameter:dict];
        
    }
}
#pragma mark - Call
-(void)callSessionStatusChanged:(EMCallSession *)callSession
                   changeReason:(EMCallStatusChangedReason)reason
                          error:(EMError *)error{
    
    
    if(!error){
        static BOOL callReceive =   YES;

        if(callReceive) {
            self.callSession = callSession;
            
            NSMutableDictionary *dictCallReceive =[NSMutableDictionary dictionary];
            [dictCallReceive setValue:callSession.sessionId forKey:@"callId"];
            [dictCallReceive setValue:callSession.sessionChatter forKey:@"from"];
            NSString *callType=nil;
            
            switch (callSession.type) {
                case eCallSessionTypeAudio:
                    callType = @"0";
                    break;
                case eCallSessionTypeVideo:
                    callType = @"1";
                    break;
                case eCallSessionTypeContent:
                    callType = @"2";
                    break;
                    
                default:
                    break;
            }
            
            [dictCallReceive setValue:callType forKey:@"callType"];
            
            [self callBackJsonWithFunction:@"onCallReceive" parameter:dictCallReceive];
            callReceive=NO;
        }
            
        
       

        
        
        NSMutableDictionary *dictCallStateChanged =[NSMutableDictionary dictionary];
        NSString *callState=nil;
        switch (callSession.status) {
            case eCallSessionStatusDisconnected:
                callState =@"4";
                callReceive=YES;
                break;
            case eCallSessionStatusRinging:
                callState =@"6";
                break;
            case eCallSessionStatusAnswering:
                callState =@"7";
                break;
            case eCallSessionStatusPausing:
                callState =@"5";
                break;
            case eCallSessionStatusConnected:
                callState =@"2";
                break;
            case eCallSessionStatusAccepted:
                callState =@"3";
                break;
            case eCallSessionStatusConnecting:
                callState =@"1";
                break;

            default:
                break;
        }

        
        [dictCallStateChanged setValue:callState forKey:@"state"];
        
        [self callBackJsonWithFunction:@"onCallStateChanged" parameter:dictCallStateChanged];
    }
}

#pragma mark - APNS
- (void)didUpdatePushOptions:(EMPushNotificationOptions *)options
                       error:(EMError *)error{
    if(options){
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        [dict setValue:options.nickname forKey:@"nickname"];
        [dict setValue:[NSString stringWithFormat:@"%lu",(unsigned long)options.noDisturbingStartH] forKey:@"noDisturbingStartH"];
        [dict setValue:[NSString stringWithFormat:@"%lu",(unsigned long)options.noDisturbingStartH] forKey:@"noDisturbingEndH"];
        NSString *noDisturbStatus;
        
        switch (options.noDisturbStatus) {
            case ePushNotificationNoDisturbStatusClose:
                noDisturbStatus = @"2";
                break;
            case ePushNotificationNoDisturbStatusCustom:
                noDisturbStatus = @"1";
                break;
                
            default://case ePushNotificationNoDisturbStatusDay
                noDisturbStatus = @"0";
                break;
        }
        NSString *displayStyle=@"";
        if(options.displayStyle == ePushNotificationDisplayStyle_simpleBanner){
            displayStyle=@"0";
        }else if(options.displayStyle == ePushNotificationDisplayStyle_messageSummary){
            displayStyle=@"1";
        }
        
        [dict setValue:displayStyle forKey:@"displayStyle"];
        [dict setValue:noDisturbStatus forKey:@"noDisturbingStyle"];
        [self callBackJsonWithFunction:@"cbUpdatePushOptions" parameter:dict];
    }
}


- (void)didIgnoreGroupPushNotification:(NSArray *)ignoredGroupList
                                 error:(EMError *)error{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:ignoredGroupList forKey:@"groupIds"];
    [self callBackJsonWithFunction:@"cbIgnoreGroupPushNotification" parameter:dict];
}



#pragma mark - EMCDDeviceManagerDelegate
- (void)proximitySensorChanged:(BOOL)isCloseToUser{

}

#pragma mark - CallBack Method
const static NSString *kPluginName=@"uexEasemob";
-(void)callBackJsonWithFunction:(NSString *)functionName parameter:(id)obj{
    
    
    
    NSString *paramStr=[obj JSONFragment];
    NSString *jsonStr = [NSString stringWithFormat:@"if(%@.%@ != null){%@.%@('%@');}",kPluginName,functionName,kPluginName,functionName,paramStr];
    dispatch_async(self.callBackDispatchQueue, ^(void){
        [EUtility evaluatingJavaScriptInRootWnd:jsonStr];
    });

}




- (NSDictionary *)analyzeEMMessage:(EMMessage *)message{
    
    NSMutableDictionary *result =[NSMutableDictionary dictionary];
    
    switch (message.messageType) {
        case eMessageTypeChat:
            [result setValue:message.from forKey:@"from"];
            [result setValue:message.to forKey:@"to"];

            break;
        case eMessageTypeGroupChat:
            [result setValue:message.groupSenderName forKey:@"from"];
            [result setValue:message.from forKey:@"to"];
            
            break;
            
        default:
            return nil;
            break;
    }

    [result setValue:message.messageId forKey:@"messageId"];
    [result setValue:[NSString stringWithFormat:@"%lld",message.timestamp] forKey:@"messageTime"];
    [result setValue:message.isDeliveredAcked?@(YES):@(NO) forKey:@"isDelievered"];
    [result setValue:message.isReadAcked?@(YES):@(NO) forKey:@"isAcked"];
    [result setValue:message.isRead?@(YES):@(NO) forKey:@"isRead"];
    switch (message.messageType) {
        case eMessageTypeChat:
            [result setValue:cEMChatTypeUser forKey:@"isGroup"];
            [result setValue:cEMChatTypeUser forKey:@"chatType"];
            break;
        case eMessageTypeGroupChat:
            [result setValue:cEMChatTypeGroup forKey:@"isGroup"];
            [result setValue:cEMChatTypeGroup forKey:@"chatType"];
            break;
        case eMessageTypeChatRoom:
            [result setValue:cEMChatTypeChatRoom forKey:@"chatType"];
            break;
            
        default:
            break;
    }
    
    NSString *type=@"";
    NSMutableDictionary *bodyDict = [NSMutableDictionary dictionary];
    id<IEMMessageBody> msgBody = message.messageBodies.firstObject;
    
    switch (msgBody.messageBodyType) {
        case eMessageBodyType_Text:
        {
            // 收到的文字消息
            type = @"text";
            NSString *txt = ((EMTextMessageBody *)msgBody).text;
            [bodyDict setValue:txt forKey:@"text"];
        }
            break;
        case eMessageBodyType_Image:
        {
            // 得到一个图片消息body
            type =@"image";
            EMImageMessageBody *body = ((EMImageMessageBody *)msgBody);
            [bodyDict setValue:body.remotePath forKey:@"remotePath"];
            [bodyDict setValue:body.secretKey forKey:@"secretKey"];
            [bodyDict setValue:body.thumbnailRemotePath forKey:@"thumbnailRemotePath"];
            [bodyDict setValue:body.thumbnailSecretKey forKey:@"thumbnailSecretKey"];
            [bodyDict setValue:body.displayName forKey:@"displayName"];
            
        }
            break;
        case eMessageBodyType_Location:
        {
            type = @"location";
            EMLocationMessageBody *body = (EMLocationMessageBody *)msgBody;
            [bodyDict setValue:[NSString stringWithFormat:@"%f",body.latitude] forKey:@"latitude"];
            [bodyDict setValue:[NSString stringWithFormat:@"%f",body.longitude] forKey:@"longitude"];
            [bodyDict setValue:body.address forKey:@"address"];
            
        }
            break;
        case eMessageBodyType_Voice:
        {
            
            type = @"audio";
            EMVoiceMessageBody *body = (EMVoiceMessageBody *)msgBody;
            [bodyDict setValue:body.remotePath forKey:@"remotePath"];
            [bodyDict setValue:body.secretKey forKey:@"secretKey"];
            [bodyDict setValue:body.displayName forKey:@"displayName"];
            [bodyDict setValue:[NSString stringWithFormat:@"%ld",(long)body.duration] forKey:@"length"];
        }
            break;
        case eMessageBodyType_Video:
        {
            type = @"video";
            EMVideoMessageBody *body = (EMVideoMessageBody *)msgBody;
            
            [bodyDict setValue:body.remotePath forKey:@"remotePath"];
            [bodyDict setValue:body.secretKey forKey:@"secretKey"];
            [bodyDict setValue:body.thumbnailRemotePath forKey:@"thumbnailRemotePath"];
            [bodyDict setValue:body.thumbnailSecretKey forKey:@"thumbnailSecretKey"];
            [bodyDict setValue:body.displayName forKey:@"displayName"];
            [bodyDict setValue:[NSString stringWithFormat:@"%ld",(long)body.duration] forKey:@"length"];
        }
            break;
        case eMessageBodyType_File:
        {
            type=@"file";
            EMFileMessageBody *body = (EMFileMessageBody *)msgBody;
            [bodyDict setValue:body.remotePath forKey:@"remotePath"];
            [bodyDict setValue:body.secretKey forKey:@"secretKey"];
            [bodyDict setValue:body.displayName forKey:@"displayName"];
        }
            break;
            
        case eMessageBodyType_Command:
        {
            type = @"cmd";
            EMCommandMessageBody *body = (EMCommandMessageBody *)msgBody;
            [bodyDict setValue:body.action forKey:@"action"];
        }
        default:
            break;
    }
    if(message.ext){
        [result setValue:[message.ext objectForKey:@"uexExtraString"] forKey:@"ext"];
    }
    [result setValue:type forKey:@"messageType"];
    [result setValue:bodyDict forKey:@"messageBody"];
    
    return result;
}

- (NSDictionary *)analyzeEMConversation:(EMConversation *)conversation{
    
    
    NSMutableDictionary *result =[NSMutableDictionary dictionary];
    [result setValue:conversation.chatter forKey:@"chatter"];
    switch (conversation.conversationType) {
        case eConversationTypeChat:
            [result setValue:cEMChatTypeUser forKey:@"isGroup"];
            [result setValue:cEMChatTypeUser forKey:@"chatType"];
            break;
        case eConversationTypeGroupChat:
            [result setValue:cEMChatTypeGroup forKey:@"isGroup"];
            [result setValue:cEMChatTypeGroup forKey:@"chatType"];
            break;
        case eConversationTypeChatRoom:
            [result setValue:cEMChatTypeChatRoom forKey:@"chatType"];
            break;
            
        default:
            break;
    }
    
    
    NSMutableArray *msgList = [NSMutableArray arrayWithCapacity:1];
    NSArray *messages = [conversation loadAllMessages];
    for(EMMessage *msg in messages){
        
        [msgList addObject:[self analyzeEMMessage:msg]];
        
        
    }
    
    if([msgList count]>0){
        [result setValue:msgList forKey:@"messages"];
        
    }
    
    
    
    
    
    
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
    NSMutableDictionary *result =[NSMutableDictionary dictionary];
    [result setValue:group.groupSubject forKey:@"groupSubject"];
    [result setValue:group.groupSubject forKey:@"groupName"];
    [result setValue:group.groupDescription forKey:@"groupDescription"];
    [result setValue:group.members forKey:@"members"];
    [result setValue:group.owner forKey:@"owner"];
    [result setValue:group.isPushNotificationEnabled?@(YES):@(NO) forKey:@"isPushNotificationEnabled"];
    [result setValue:group.isBlocked?@(YES):@(NO) forKey:@"isBlocked"];
    id isPublic =@"";
    id allowInvites =@"";
    id membersOnly =@"";

    switch (group.groupSetting.groupStyle) {
        case eGroupStyle_PrivateOnlyOwnerInvite:
            isPublic =@(NO);
            allowInvites =@(NO);
            membersOnly =@(YES);
            break;
        case eGroupStyle_PrivateMemberCanInvite:
            isPublic =@(NO);
            allowInvites =@(YES);
            membersOnly =@(YES);
            
            break;
        case eGroupStyle_PublicJoinNeedApproval:
            isPublic =@(YES);
            allowInvites =@(YES);
            membersOnly =@(YES);
            break;
        case eGroupStyle_PublicOpenJoin :
            isPublic =@(YES);
            allowInvites =@(YES);
            membersOnly =@(NO);
            break;
        case eGroupStyle_PublicAnonymous:
            isPublic =@(YES);
            allowInvites =@(YES);
            membersOnly =@(NO);
            break;
            
        default:
            break;
    }
    [result setValue:group.groupId forKey:@"groupId"];
    [result setValue:isPublic forKey:@"isPublic"];
    [result setValue:allowInvites forKey:@"allowInvites"];
    [result setValue:membersOnly forKey:@"membersOnly"];
    [result setValue:[NSString stringWithFormat: @"%ld", (long)group.groupSetting.groupMaxUsersCount] forKey:@"groupMaxUsersCount"];
    [result setValue:[NSString stringWithFormat: @"%ld", (long)group.groupSetting.groupStyle] forKey:@"groupStyle"];
    return result;
}




@end
