//
//  EUExEasemob.m
//  AppCanPlugin
//
//  Created by AppCan on 15/3/17.
//  Copyright (c) 2015年 zywx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMSDKFull.h"
#import "EUExBase.h"
#import "EUExEasemobBase.h"
#import "EUExEasemob.h"








@interface EUExEasemob()<IChatManagerDelegate,EMCallManagerDelegate>


@property (retain, nonatomic)EaseMob * sharedInstance;
@property (retain, nonatomic)EMSDKFull * sharedInstanceForCall;
@property (retain, nonatomic)EMCallSession *call;
@property (retain, nonatomic)EMPushNotificationOptions *apnsOptions;


@property (strong, nonatomic) NSDate *lastPlaySoundDate;
@property (assign, nonatomic) BOOL isPlaySound;
@property (assign, nonatomic) BOOL isPlayVibration;
@property (assign, nonatomic) BOOL messageNotification;
@property (assign, nonatomic) BOOL userSpeaker;
@property (assign, nonatomic) BOOL isInitialized;
@end


@implementation EUExEasemob

static UIApplication *app;
static NSDictionary *opt;

+(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    app=application;
    opt=launchOptions;
    return YES;
}


-(id)initWithBrwView:(EBrowserView *)eInBrwView{
    self=[super initWithBrwView:eInBrwView];
    if(self){
        self.isInitialized = NO;
    }
    return  self;
}

-(void)clean{
    if(self.sharedInstance){
        [self.sharedInstance release];
        self.sharedInstance=nil;
    }
    if(self.sharedInstanceForCall){
        [self.sharedInstanceForCall release];
        self.sharedInstanceForCall=nil;
    }
    if(self.apnsOptions){
        [self.apnsOptions release];
        self.apnsOptions=nil;
    }
    if(self.call){
        [self.call release];
        self.call=nil;
    }
    self.isInitialized = NO;
}

-(void)dealloc{
    [self clean];
    [super dealloc];
}

/*
 ###[1]Initialization
 ***
 */
/*
 #####[1.1] initEasemob(param) //初始化
 
 var param{
 
	appKey:,//区别app的标识
	apnsCertName:,//iOS中推送证书名称
 
 }
 */
-(void)initEasemob:(NSMutableArray *)array{
    if(!self.isInitialized){
        id initInfo =[self getDataFromJson:array[0]];
        self.sharedInstance =[EaseMob sharedInstance];
        self.sharedInstanceForCall = [EMSDKFull sharedInstance];
        
        
        [self.sharedInstance registerSDKWithAppKey:[initInfo objectForKey:@"appKey"]
                                      apnsCertName:[initInfo objectForKey:@"apnsCertName"]
                                       otherConfig:@{kSDKConfigEnableConsoleLogger:[NSNumber numberWithBool:YES]}];
        
        
        [self registerEaseMobNotification];//注册回调
        self.MainBrowserView =meBrwView;
        self.lastPlaySoundDate = [NSDate date];
        self.isPlayVibration = YES;
        self.isPlaySound = YES;
        self.messageNotification = YES;
        self.userSpeaker = YES;
        [self.sharedInstance.chatManager enableDeliveryNotification];//开启消息已送达回执
        self.isInitialized =YES;
        [self.sharedInstance application:app didFinishLaunchingWithOptions:opt];

        

        [self returnJSonWithName:@"cbInit" dictionary:@"init successfully!"];
    }else{
        [self returnJSonWithName:@"cbInit" dictionary:@"you have already initialized"];
    }

    
}




- (void)registerEaseMobNotification{
    [self unRegisterEaseMobNotification];
    // 将self 添加到SDK回调中，以便本类可以收到SDK回调
    [self.sharedInstance.chatManager addDelegate:self delegateQueue:nil];
    [self.sharedInstanceForCall.callManager addDelegate:self delegateQueue:nil];
}

- (void)unRegisterEaseMobNotification{
    [self.sharedInstance.chatManager removeDelegate:self];
    [self.sharedInstanceForCall.callManager removeDelegate:self];
}
/*
 #####[1.2]login(param) //登陆
 
 var param = {
 
	username:,//用户名
	password:,//密码
 };
 
 
 #####[1.3]cbLogin(param)//登陆回调
 
 var param = {
 
	result:,//1-成功，2-失败
	msg:,//提示信息
 };
 */
- (void)login:(NSMutableArray *)array{
    id user =[self getDataFromJson:array[0]];
    
    // 登录
    
    [self.sharedInstance.chatManager asyncLoginWithUsername:[user objectForKey:@"username"] password:[user objectForKey:@"password"] completion:^(NSDictionary *loginInfo, EMError *error) {
        //回调
        NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
        
        
        if (!error && loginInfo) {

            [self returnJSonWithName:@"onConnected" dictionary:nil];
            [dict setObject:@"1" forKey:@"result"];
            [dict setObject:@"登录成功" forKey:@"message"];
            self.apnsOptions =[self.sharedInstance.chatManager pushNotificationOptions];
            
        }else{
            [dict setObject:@"2" forKey:@"result"];
            [dict setObject:@"登录失败" forKey:@"message"];
            
        }
        [self returnJSonWithName:@"cbLogin" dictionary:dict];
    } onQueue:nil];
}

//自动登录回调
-(void)willAutoLoginWithInfo:(NSDictionary *)loginInfo
                       error:(EMError *)error{
       // NSLog(@"willAutoLoginWithInfo");
}


- (void)didAutoLoginWithInfo:(NSDictionary *)loginInfo error:(EMError *)error{
     if (!error && loginInfo) {
         [self returnJSonWithName:@"onConnected" dictionary:nil];

     }
}
 /*
 #####[1.4]logout() //退出登录
  */
 -(void)logout:(NSMutableArray *)array{

     [self.sharedInstance.chatManager asyncLogoffWithUnbindDeviceToken:YES completion:^(NSDictionary *info, EMError *error) {
 
         NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
         if (!error && !info) {
 
 
             [dict setObject:@"1" forKey:@"result"];
             [dict setObject:@"登出成功" forKey:@"message"];
         }else{
             [dict setObject:@"2" forKey:@"result"];
             [dict setObject:@"登出失败" forKey:@"message"];;
         }
         [self returnJSonWithName:@"cbLogout" dictionary:dict];
 
     } onQueue:nil];
}
 /*
 #####[1.5]registerUser(param)//注册
 
 var param = {
 
	username:,//用户名
	password:,//密码
 };
 
 #####[1.6]cbRegisterUser(param)//注册回调
 
 var param = {
 
	result:,//1-成功，2-失败
	msg:,//提示信息
 };
 */
-(void)registerUser:(NSMutableArray *)array{
    id user =[self getDataFromJson:array[0]];
    if(user != nil){
        [self.sharedInstance.chatManager asyncRegisterNewAccount:[user objectForKey:@"username"]
                                                        password:[user objectForKey:@"password"]
                                                  withCompletion:^(NSString *username, NSString *password, EMError *error) {
                                                      NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
                                                      if (!error) {
                                                          [dict setObject:@"1" forKey:@"result"];
                                                          [dict setObject:@"注册成功" forKey:@"msg"];
                                                      }else{
                                                          [dict setObject:@"2" forKey:@"result"];
                                                          [dict setObject:@"注册失败" forKey:@"msg"];
                                                      }
                                                      
                                                      
                                                      [self returnJSonWithName:@"cbRegisterUser" dictionary:dict];
                                                  } onQueue:nil];
    }
}

/*
 #####[1.7]updateCurrentUserNickname(param) // 更新当前用户的昵称
 
 var param = {
	
	nickname:,
 }
 
	注：此方法主要为了在苹果推送时能够推送昵称(nickname)而不是userid,一般可以在登陆成功后从自己服务器获取到个人信息，然后拿到nick更新到环信服务器。并且，在个人信息中如果更改个人的昵称，也要把环信服务器更新下nickname 防止显示差异。
 */
-(void)updateCurrentUserNickname:(NSMutableArray *)array{
    id nickname =[self getDataFromJson:array[0]];
    
    [self.sharedInstance.chatManager setApnsNickname:[nickname objectForKey:@"nickname"]];
    
    
}
 /*
 #####[1.8]getLoginInfo()//获取当前登陆信息(仅iOS可用)
 
 #####[1.9]cbGetLoginInfo(param)//获取当前登陆信息的回调（仅iOS）
 
 var param={
 
	userInfo://当前登陆用户信息
	isLoggedIn://当前是否已有登录用户  1-是 2-否
	isConnected://是否连上聊天服务器   1-是 2-否
 }
  */

-(void)getLoginInfo:(NSMutableArray *)array{
    
    NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:3];
    
    
    
    
    [dict setObject:(self.sharedInstance.chatManager.isConnected?@"1":@"2")   forKey:@"isConnected"];
    [dict setObject:(self.sharedInstance.chatManager.isLoggedIn?@"1":@"2")  forKey:@"isLoggedIn"];
    if(self.sharedInstance.chatManager.isLoggedIn){
        NSMutableDictionary *userInfo = [self.sharedInstance.chatManager.loginInfo mutableCopy];
        
        
        if ([self.apnsOptions.nickname length]>0){
            [userInfo setObject:self.apnsOptions.nickname  forKey:@"nickname"];
        }
        
        
        
        
        
        [dict setObject:userInfo  forKey:@"userInfo"];
    }
    NSString *autologgin = self.sharedInstance.chatManager.isAutoLoginEnabled?@"1":@"2";
    [dict setObject:autologgin  forKey:@"isAutoLoginEnabled"];
    [self returnJSonWithName:@"cbGetLoginInfo" dictionary:dict];
    
}
/*
 #####[1.10]onConnected();//已连接上（仅Android可用）
 */
/*
 #####[1.11]onDisconnected(param)//链接断开
 var param = {
 
	error:,//1-账号被移除，2-账号其他设备登陆，3-连接不到聊天服务器，4-当前网络不可用
 };
 */
-(void)disconnectedError:(NSInteger)errorCode{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    [dict setObject:[NSString stringWithFormat: @"%ld", (long)errorCode] forKey:@"error"];
    
    [self returnJSonWithName:@"onDisconnected" dictionary:dict];
}


-(void)didRemovedFromServer{
    [self.sharedInstance.chatManager asyncLogoffWithUnbindDeviceToken:NO completion:^(NSDictionary *info, EMError *error) {
       
    } onQueue:nil];
    [self disconnectedError:1];
}

-(void)didLoginFromOtherDevice{
    [self.sharedInstance.chatManager asyncLogoffWithUnbindDeviceToken:NO completion:^(NSDictionary *info, EMError *error) {
       
    } onQueue:nil];
    [self disconnectedError:2];
}

- (void)didConnectionStateChanged:(EMConnectionState)connectionState{
    if (connectionState == eEMConnectionDisconnected){
        [self disconnectedError:3];
 
    }
}

/*
 #####[1.12]setIsAutoLoginEnabled(param);//设置是否自动登录
 var param={
 
	isAutoLoginEnabled://是否自动登录  1-是 2-否
 
 }
 
 */
-(void)setIsAutoLoginEnabled:(NSMutableArray *)array{
    id info =[self getDataFromJson:array[0]];
    if([[info objectForKey:@"isAutoLoginEnabled"] isEqual:@"1"] ){
        [self.sharedInstance.chatManager setIsAutoLoginEnabled:YES];
    }else if([[info objectForKey:@"isAutoLoginEnabled"] isEqual:@"2"] ){
        [self.sharedInstance.chatManager setIsAutoLoginEnabled:NO];
    }
    
}

 /*
 ###[2]Message
 ***
  */

/*
 
 #####[2.1]onNewMessage（param）//收到新消息监听
 
 
 
	注：param为EMMessage的json格式对象
	EMMessage具体结构见文末附录
	所有离线和在线时接受到的的非透传消息，都通过此回调传递
 */
-(void)didReceiveMessage:(EMMessage *)message{
    
    [self.sharedInstance.chatManager insertMessagesToDB:@[message] forChatter:message.conversationChatter append2Chat:NO];
    NSMutableDictionary *dict = [self convertEMMessageToDict:message];
    
    [self playSoundAndVibration];
    [self returnJSonWithName:@"onNewMessage" dictionary:dict];
    
}
- (void)didFinishedReceiveOfflineMessages:(NSArray *)offlineMessages{
    for(EMMessage *msg in offlineMessages){
        [self didReceiveMessage:msg];
    }
    
}
/*
 #####[2.2]onCmdMessageReceive(param)//透传消息监听
 var param = {
 
	msgId:,
	message:,//EMMessage 对象json格式
	action:,
 }
 */
- (void)didReceiveCmdMessage:(EMMessage *)cmdMessage{
    [self.sharedInstance.chatManager insertMessagesToDB:@[cmdMessage] forChatter:cmdMessage.conversationChatter append2Chat:NO];
    
    NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:3];
    NSDictionary *dictMessage =[self convertEMMessageToDict:cmdMessage];
    [dict setObject:cmdMessage.messageId forKey:@"msgId"];
    [dict setObject:dictMessage forKey:@"message"];
    EMCommandMessageBody *body = (EMCommandMessageBody *)cmdMessage.messageBodies.lastObject;
    [dict setObject:body.action forKey:@"action"];
    [self playSoundAndVibration];
    [self returnJSonWithName:@"onCmdMessageReceive" dictionary:dict];
}

//离线透传消息接收完成的回调
- (void)didFinishedReceiveOfflineCmdMessages:(NSArray *)offlineCmdMessages{
    for(EMMessage *msg in offlineCmdMessages){
        [self didReceiveCmdMessage:msg];
    }
    
}

/*
 #####[2.3]onAckMessage(param)//消息已读监听
 var param = {
 
	msgId:,//消息ID
	username:,//来源
 };
 */
-(void)didReceiveHasReadResponse:(EMReceipt *)resp{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
    [dict setObject:resp.chatId forKey:@"msgId"];
    [dict setObject:resp.from forKey:@"username"];
    
    [self returnJSonWithName:@"onAckMessage" dictionary:dict];
}

/*
 #####[2.4]onDeliveryMessage(param)//消息送达监听
 var param = {
 
	msgId:,//消息ID
	username:,//来源
 };
 */
-(void)didReceiveHasDeliveredResponse:(EMReceipt *)resp{
    
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
    [dict setObject:resp.chatId forKey:@"msgId"];
    [dict setObject:resp.from forKey:@"username"];
    [self returnJSonWithName:@"onDeliveryMessage" dictionary:dict];
}
/*
 #####[2.5]sendText(param)//发送文本消息及表情
 var param = {
 
	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	content:,//文本内容
 }
 */
-(void)sendText:(NSMutableArray *)array{
    
    
    id textData =[self getDataFromJson:array[0]];
    BOOL isGroup;
    if([[textData objectForKey:@"chatType"] isEqual:@"1"] ){
        isGroup =NO;
    }else if([[textData objectForKey:@"chatType"] isEqual:@"2"] ){
        isGroup =YES;
    }
    
    EMChatText *txtChat = [[EMChatText alloc] initWithText:[textData objectForKey:@"content"]];
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithChatObject:txtChat];
    
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[textData objectForKey:@"username"] bodies:@[body]];
    message.isGroup = isGroup; // 设置是否是群聊
    
    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
    
}
/*
 #####[2.6]sendVoice(param)//发送语音
 var param = {
	
	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	filePath:,//语音文件路径
	length:,//长度(仅Android需要)
	displayName：//对方接收时显示的文件名（仅iOS需要）
 }
 */
-(void)sendVoice:(NSMutableArray *)array{
    
    id voiceData =[self getDataFromJson:array[0]];
    BOOL isGroup;
    if([[voiceData objectForKey:@"chatType"] isEqual:@"1"] ){
        isGroup =NO;
    }else if([[voiceData objectForKey:@"chatType"] isEqual:@"2"] ){
        isGroup =YES;
    }
    
    EMChatVoice *voiceChat = [[EMChatVoice alloc] initWithFile:[self absPath:[voiceData objectForKey:@"filePath"]] displayName:[voiceData objectForKey:@"displayName"]];
    EMVoiceMessageBody *body = [[EMVoiceMessageBody alloc] initWithChatObject:voiceChat];
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[voiceData objectForKey:@"username"] bodies:@[body]];
    message.isGroup = isGroup; // 设置是否是群聊
    
    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
   // NSLog(@"testsendvoice");
    
}
/*
 #####[2.7]sendPicture(param)//发送图片
 var param = {
 
	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	filePath:,//图片文件路径
	displayName:,//对方接收时显示的文件名（仅iOS需要）
 }
 */
-(void)sendPicture:(NSMutableArray *)array{
    
    id pictureData =[self getDataFromJson:array[0]];
    BOOL isGroup;
    if([[pictureData objectForKey:@"chatType"] isEqual:@"1"] ){
        isGroup =NO;
    }else if([[pictureData objectForKey:@"chatType"] isEqual:@"2"] ){
        
        isGroup =YES;
    }
    UIImage  *img = [UIImage imageWithContentsOfFile:[self absPath:[pictureData objectForKey:@"filePath"]]];
    
    EMChatImage *imgChat = [[EMChatImage alloc] initWithUIImage:img displayName:[pictureData objectForKey:@"displayName"]];
    EMImageMessageBody *body = [[EMImageMessageBody alloc] initWithChatObject:imgChat];
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[pictureData objectForKey:@"username"] bodies:@[body]];
    message.isGroup = isGroup; // 设置是否是群聊
    
    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
}
/*
 
 #####[2.8]sendLocationMsg(param)//发送地理位置信息
 var param = {
 
	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	locationAddress:,//图片文件路径
	latitude:,
	longitude:,
 
 }
 */
-(void)sendLocationMsg:(NSMutableArray *)array{
    
    id locationData =[self getDataFromJson:array[0]];
    BOOL isGroup;
    if([[locationData objectForKey:@"chatType"] isEqual:@"1"] ){
        isGroup =NO;
    }else if([[locationData objectForKey:@"chatType"] isEqual:@"2"] ){
        isGroup =YES;
    }
    
    
    EMChatLocation *locChat = [[EMChatLocation alloc] initWithLatitude:[[locationData objectForKey:@"latitude"] doubleValue] longitude:[[locationData objectForKey:@"longtitude"] doubleValue] address:[locationData objectForKey:@"locationAddress"]];
    EMLocationMessageBody *body = [[EMLocationMessageBody alloc] initWithChatObject:locChat];
    
    
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[locationData objectForKey:@"username"] bodies:@[body]];
    message.isGroup = isGroup; // 设置是否是群聊
    
    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
}

/*
 #####[2.9]sendFile(param)//发送文件
 var param = {
 
	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	filePath:,//文件路径
	displayName:,//对方接收时显示的文件名（仅iOS需要）
 }
 */
-(void)sendFile:(NSMutableArray *)array{
    
    id fileData =[self getDataFromJson:array[0]];
    BOOL isGroup;
    if([[fileData objectForKey:@"chatType"] isEqual:@"1"] ){
        isGroup =NO;
    }else  if([[fileData objectForKey:@"chatType"] isEqual:@"1"] ){
        isGroup =YES;
    }
    
    
    EMChatFile *fileChat = [[EMChatFile alloc] initWithFile:[self absPath:[fileData objectForKey:@"filePath"]] displayName:[fileData objectForKey:@"displayName"]];
    EMFileMessageBody *body = [[EMFileMessageBody alloc] initWithChatObject:fileChat];
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[fileData objectForKey:@"username"] bodies:@[body]];
    message.isGroup = isGroup; // 设置是否是群聊
    
    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
}
/*
 #####[2.10]sendCmdMessage(param)//发送透传消息
	var param = {
	chatType:,//1-单聊，2-群聊
	action:,//
	toUsername:,//
 }
 */
-(void) sendCmdMessage:(NSMutableArray *)array{
    id cmdMsgData = [self getDataFromJson:array[0]];
    BOOL isGroup;
    if([[cmdMsgData objectForKey:@"chatType"] isEqual:@"1"] ){
        isGroup =NO;
    }else if([[cmdMsgData objectForKey:@"chatType"] isEqual:@"2"] ){
        isGroup =YES;
    }
    
    // 设置是否是群聊
    
    EMChatCommand *cmdChat = [[EMChatCommand alloc] init];
    cmdChat.cmd = [cmdMsgData objectForKey:@"action"];
    EMCommandMessageBody *body = [[EMCommandMessageBody alloc] initWithChatObject:cmdChat];
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[cmdMsgData objectForKey:@"toUsername"] bodies:@[body]];
    message.isGroup = isGroup; // 设置是否是群聊
    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
}

/*
 #####[2.11]setNotifyBySoundAndVibrate(param)//消息提醒相关配置
 var param = {
 
	enable:,//0-关闭，1-开启。默认为1 开启新消息提醒
	soundEnable:,// 0-关闭，1-开启。默认为1 开启声音提醒
	vibrateEnable:,// 0-关闭，1-开启。默认为1 开启震动提醒
	userSpeaker:,// 0-关闭，1-开启。默认为1 开启扬声器播放
	showNotificationInBackgroud:// 0-关闭，1-开启。默认为1。设置后台接收新消息时是否通过通知栏提示 （仅Android可用）
	acceptInvitationAlways:,// 0-关闭，1-开启。默认添加好友时为1，是不需要验证的，改成需要验证为0（仅Android可用）
	deliveryNotification:，// 0-关闭 1-开启  默认为1 开启消息送达通知	（仅iOS可用）
 }
 */
-(void) setNotifyBySoundAndVibrate:(NSMutableArray *)array {
    
    id notifyInfo = [self getDataFromJson:array[0]];
    
    if ([[notifyInfo objectForKey:@"enable"] isEqual:@"0"]){
        self.messageNotification = NO;
    }else if([[notifyInfo objectForKey:@"enable"] isEqual:@"1"]){
        self.messageNotification = YES;
    }
    
    if ([[notifyInfo objectForKey:@"soundEnable"] isEqual:@"0"]){
        self.isPlaySound = NO;
    }else if([[notifyInfo objectForKey:@"soundEnable"] isEqual:@"1"]){
        self.isPlaySound = YES;
    }
    if ([[notifyInfo objectForKey:@"vibrateEnable"] isEqual:@"0"]){
        self.isPlayVibration = NO;
    }else if([[notifyInfo objectForKey:@"vibrateEnable"] isEqual:@"1"]){
        self.isPlayVibration = YES;
    }
    if ([[notifyInfo objectForKey:@"userSpeaker"] isEqual:@"0"]){
        [self.sharedInstance.deviceManager switchAudioOutputDevice:eAudioOutputDevice_earphone];
    }else if([[notifyInfo objectForKey:@"enable"] isEqual:@"1"]){
        [self.sharedInstance.deviceManager switchAudioOutputDevice:eAudioOutputDevice_speaker];
    }
    if ([[notifyInfo objectForKey:@"acceptInvitationAlways"] isEqual:@"0"]){
        [self.sharedInstance.chatManager disableDeliveryNotification];
    }else if([[notifyInfo objectForKey:@"acceptInvitationAlways"] isEqual:@"1"]){
        [self.sharedInstance.chatManager enableDeliveryNotification];
    }
    
    //NSLog(@"SetNotifyBySoundAndVibrate");
    
}
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
        [self.sharedInstance.deviceManager asyncPlayNewMessageSound];
    }
    // 收到消息时，震动
    if(self.isPlayVibration){
        [self.sharedInstance.deviceManager asyncPlayVibration];
    }
}
/*
 #####[2.12]getMessageById(param)//根据id获取消息记录（仅Android可用）
 var param = {
 
	msgId:,//消息ID
 };
 #####[2.13]cbGetMessageById(param)//得到一条消息记录（仅Android可用）
 var param = {
 
	msg:,// EMMessage的json格式对象
 };
	*/

/*
	
 ###[3]Conversation
 ***
 */

/*
 #####[3.1]getConversationByName(param)//根据用户名获取conversation对象
 var param = {
 
	username:,
	isGroup:,//是否为群组 1-是 2-否(仅iOS需要)
 };
 #####[3.2]cbGetConversationByName(param)//回调
 var param = {
 
	conversation:,// EMConversation的json格式对象，格式见附录
 };
 */
-(EMConversation *) getConversation:(NSMutableArray *)array{
    //获取conversation
    
    
    id conversationData =[self getDataFromJson:array[0]];
    
    //回调
    if (conversationData != nil){
        BOOL isGroup;
        if([[conversationData objectForKey:@"isGroup"] isEqual:@"1"] ){
            isGroup =YES;
        }else{
            isGroup =NO;
        }
        EMConversation *conversation = [self.sharedInstance.chatManager conversationForChatter:[conversationData objectForKey:@"username"] isGroup:isGroup];
        
        return conversation;
    }
    else {
        return nil;
    }
    
}
-(void) getConversationByName:(NSMutableArray *)array{
    
    EMConversation *conversation =[self getConversation:array];
    
    [self cbGetConversationByName:conversation];
}


-(void)cbGetConversationByName:(EMConversation *)conversation{
    
    NSDictionary *dict =[self convertEMConversationToDict:conversation];
    
    [self returnJSonWithName:@"cbGetConversationByName" dictionary:dict];
    
}

/*
 #####[3.3]getMessageHistory(param)//获取聊天记录(仅Android可用)
 var param = {
 
	username:,//单聊时聊天人的userName或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	startMsgId:,//获取startMsgId之前的pagesize条消息
	pagesize:,//分页大小，为0时获取所有消息，startMsgId可不传
 }
 #####[3.4]cbGetMessageHistory(param)//获取聊天记录回调（仅Android）
 var param = {
 
	messages:,//List<EMMessage>的json格式对象
 }
 */
 
 /*
 #####[3.5]getUnreadMsgCount(param)//获取未读消息数量
 var param = {
 
	username:,//username|groupid
 isGroup:,//是否为群组 1-是 2-否(仅iOS需要)
 }
 #####[3.6]cbGetUnReadMsgCount(param)//获取未读消息数量回调
 var param = {
 
	count:,//未读消息数
 }
 */

-(void)getUnreadMsgCount:(NSMutableArray *)array{
    
    EMConversation *conversation =[self getConversation:array];
    NSUInteger unreadMessageCount =[conversation unreadMessagesCount];
    [self cbGetUnreadMsgCount:unreadMessageCount];
    
}

-(void)cbGetUnreadMsgCount:(NSUInteger)unreadMsgCount{
    
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    [dict setObject:[NSString stringWithFormat:@"%lu",(unsigned long)unreadMsgCount] forKey:@"count"];
    
    [self returnJSonWithName:@"cbGetUnreadMsgCount" dictionary:dict];
}
/*
 #####[3.7]resetUnreadMsgCount(param)//指定会话未读消息数清零
 var param = {
 
	username:,//username|groupid
 isGroup:,//是否为群组 1-是 2-否(仅iOS需要)
 }
 */
-(void)resetUnreadMsgCount:(NSMutableArray *)array{
    EMConversation *conversation =[self getConversation:array];
    [conversation markAllMessagesAsRead:YES];
}

/*
 
 #####[3.8]resetAllUnreadMsgCount();//所有未读消息数清零（仅Android可用）
	
 #####[3.9]getMsgCount(param)//获取消息总数（仅Android可用）
 var param = {
 
	username:,//username|groupid
 }
 #####[3.10]cbGetMsgCount(param)//获取消息总数回调（仅Android可用）
 var param = {
 
	msgCount:,//消息总数
 }
 #####[3.11]clearConversation(param)//清空会话聊天记录（仅Android可用）
 var param = {
 
	username:,//username|groupid
 }
 */
 /*
 #####[3.12]deleteConversation(param)//删除和某个user的整个的聊天记录(包括本地)
 var param = {
 
	username:,//username|gr	oupid
 isGroup:,//是否为群组 1-是 2-否(仅iOS需要)
 }
  */
-(void)deleteConversation:(NSMutableArray *)array{
    EMConversation *conversation =[self getConversation:array];
    [conversation removeAllMessages];
}
/*
 #####[3.13]removeMessage(param)//删除当前会话的某条聊天记录
 var param = {
 
	username:,//username|groupid
	msgId:,
 isGroup:，//是否为群组 1-是 2-否(仅iOS需要)
 }
 */
-(void)removeMessage:(NSMutableArray*)array{
    id conversationData =[self getDataFromJson:array[0]];
    BOOL isGroup;
    if([[conversationData objectForKey:@"isGroup"] isEqual:@"1"] ){
        isGroup =YES;
    }else{
        isGroup =NO;
    }
    EMConversation *conversation = [self.sharedInstance.chatManager conversationForChatter:[conversationData objectForKey:@"username"] isGroup:isGroup];
    [conversation removeMessageWithId:[conversationData objectForKey:@"msgId"]];
    
}
/*
 #####[3.14]deleteAllConversation();//删除所有会话记录(包括本地)
 */
-(void)deleteAllConversation:(NSMutableArray*)array{
    [self.sharedInstance.chatManager removeAllConversationsWithDeleteMessages:YES append2Chat:YES];
   // NSLog(@"deleteAllConversation");
}
/*
##### [3.15]getChatterInfo();//获取聊天对象信息

##### [3.16]cbGetChatterInfo(param);//获取聊天对象信息回调
param为list<chatteInfo>,一个由chatterInfo结构组成的数组。

var chatterInfo = {
    
    chatter;// 联系人的username或群组的groupId
    groupName;// 群组名（仅群组有此值）
    isGroup;//是否为群组 1-是 2-否
    unreadMsgCount;//未读消息数
    lastMsg;//EMMessage格式的json字符串，最后一条消息
}*/

-(void) getChatterInfo:(NSMutableArray *)array{
    NSMutableArray *usernamelist = [NSMutableArray array];
    EMError *error=nil;
    NSArray *buddyList = [self.sharedInstance.chatManager fetchBuddyListWithError:&error];
    
    if (!error) {
        for(EMBuddy  *buddy in buddyList){
            if(buddy.followState == 3){
                [usernamelist addObject:buddy.username];
            }
        }
        
        
    }else{
        return;
    }

    error = nil;
    NSMutableArray *grouplist = [NSMutableArray array];
    
    NSArray *groups = [self.sharedInstance.chatManager fetchMyGroupsListWithError:&error];
    if (!error) {
        
        for (EMGroup  *group in groups){
            [grouplist addObject:group];
        }
        
    }else{
        return;
    }

    
    NSMutableArray *result =[NSMutableArray array];
    for(NSString *username in usernamelist){
        NSMutableDictionary *chatter =[NSMutableDictionary dictionary];
        EMConversation *conversation = [self.sharedInstance.chatManager conversationForChatter:username isGroup:NO];
        [chatter setValue:[self convertEMMessageToDict:[conversation latestMessage]]  forKey:@"lastMsg"];
        [chatter setValue:[NSString stringWithFormat:@"%ld",(unsigned long)conversation.unreadMessagesCount] forKey:@"unreadMsgCount"];
        [chatter setValue:username forKey:@"chatter"];
        [chatter setValue:@"2" forKey:@"isGroup"];
        [result addObject:chatter];
    }
    for(EMGroup *group in grouplist){
        NSMutableDictionary *chatter =[NSMutableDictionary dictionary];
        EMConversation *conversation = [self.sharedInstance.chatManager conversationForChatter:group.groupId isGroup:YES];
        [chatter setValue:[self convertEMMessageToDict:[conversation latestMessage]]  forKey:@"lastMsg"];
        [chatter setValue:[NSString stringWithFormat:@"%ld",(unsigned long)conversation.unreadMessagesCount] forKey:@"unreadMsgCount"];
        [chatter setValue:group.groupId forKey:@"chatter"];
        [chatter setValue:group.groupSubject forKey:@"groupName"];
        [chatter setValue:@"1" forKey:@"isGroup"];
        [result addObject:chatter];
    }
    
    
    [self returnJSonWithName:@"cbGetChatterInfo" dictionary:result];
    
    
}
 /*
 ###[4]Friend
 ***
 #####[4.1]onContactAdded(param)//新增联系人监听（仅Android）
 var param = {
 
	userNameList:,//json格式的List<String>
 };
 #####[4.2]onContactDeleted(param)//删除联系人监听（仅Android）
 var param = {
 
	userNameList:,//json格式的List<String>
 };
  */
/*
 #####[4.3]onContactInvited(param)//接到好友申请
 var param = {
 
	username:,//
	reason:,//
 };
 */
-(void)didReceiveBuddyRequest:(NSString *)username message:(NSString *)message{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
    [dict setObject:message forKey:@"reason"];
    [dict setObject:username forKey:@"username"];
    [self returnJSonWithName:@"onContactInvited" dictionary:dict];
}
/*
 #####[4.4]onContactAgreed(param)//好友请求被同意
 var param = {
 
	username:,//
 };
 
 */
 -(void)didAcceptedByBuddy:(NSString *)username{
 
 NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
 [dict setObject:username forKey:@"username"];
 
 [self returnJSonWithName:@"onContactAgreed" dictionary:dict];
 }
 
 /*
 #####[4.5]onContactRefused(param)//好友请求被拒绝
 var param = {
 
	username:,//
 };
  */
-(void)didRejectedByBuddy:(NSString *)username{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    [dict setObject:username forKey:@"username"];
    
    [self returnJSonWithName:@"onContactRefused" dictionary:dict];
    
}
/*
 #####[4.6]getContactUserNames();//获取好友列表
 
 
 #####[4.7]cbGetContactUserNames(param)//获取好友列表回调
 var param = {
 
	usernames:,//用户姓名字符串构成的数组
	
 }
*/
-(void)getContactUserNames:(NSMutableArray*)array{
     NSMutableArray *usernames = [NSMutableArray arrayWithCapacity:1];
    [self.sharedInstance.chatManager asyncFetchBuddyListWithCompletion:^(NSArray *buddyList, EMError *error) {
        if (!error) {
            for(EMBuddy  *buddy in buddyList){
                if(buddy.followState == 3){
                    [usernames addObject:buddy.username];
                }
            }
            [self returnJSonWithName:@"cbGetContactUserNames" dictionary:usernames];

        }
    } onQueue:nil];
    

    
}



/*
 
 
 
 #####[4.8]addContact(param)//添加好友
 var param = {
 
	toAddUsername:,//要添加的好友
	reason:
 }
 */
-(void) addContact:(NSMutableArray *)array{
    id contactInfo =[self getDataFromJson:array[0]];
    
    
    EMError *error = nil;
    BOOL isSuccess = [self.sharedInstance.chatManager addBuddy:[contactInfo objectForKey:@"toAddUsername"] message:[contactInfo objectForKey:@"reason"] error:&error];
    if (isSuccess && !error) {
        //NSLog(@"添加成功");
    }
}
/*
 #####[4.9]deleteContact(param)//删除好友
 var param = {
 
	username:,//
 }
 */
-(void) deleteContact:(NSMutableArray *)array{
    id contactInfo =[self getDataFromJson:array[0]];
    
    
    
    EMError *error = nil;
    // 删除好友
    BOOL isSuccess = [self.sharedInstance.chatManager removeBuddy:[contactInfo objectForKey:@"username"] removeFromRemote:YES error:&error];
    if (isSuccess && !error) {
        //NSLog(@"删除成功");
    }
}
/*
 #####[4.10]acceptInvitation(param)//同意username的好友请求
 var param = {
 
	username:,//
 }
 #####[4.11]refuseInvitation(param)//拒绝username的好友请求
 var param = {
 
	username:,//
	reason:,//拒绝好友请求原因（仅iOS需要）
 }
 */
-(void) acceptInvitation:(NSMutableArray *)array{
    id contactInfo =[self getDataFromJson:array[0]];
    
    EMError *error = nil;
    BOOL isSuccess = [self.sharedInstance.chatManager acceptBuddyRequest:[contactInfo objectForKey:@"username"] error:&error];
    if (isSuccess && !error) {
        //NSLog(@"发送同意成功");
    }
}

-(void) refuseInvitation:(NSMutableArray *)array{
    id contactInfo =[self getDataFromJson:array[0]];
    
    
    EMError *error = nil;
    BOOL isSuccess = [self.sharedInstance.chatManager rejectBuddyRequest:[contactInfo objectForKey:@"username"] reason:[contactInfo objectForKey:@"reason"] error:&error];
    if (isSuccess && !error) {
       // NSLog(@"发送拒绝成功");
    }
}
/*
 #####[4.12]getBlackListUsernames();//获取黑名单列表
 #####[4.13]cbGetBlackListUsernames(param)//获取黑名单列表回调
 var param = {
 
	usernames:,//List<String> json格式
 }
 */
-(void) getBlackListUsernames:(NSMutableArray *)array{
    NSArray * BlockedList=[self.sharedInstance.chatManager fetchBlockedList:nil];
    
    [self cbGetBlackListUsernames:BlockedList];
    
}

-(void) cbGetBlackListUsernames:(NSArray *)blockedList{
    
    [self returnJSonWithName:@"cbGetBlackListUsernames" dictionary:blockedList];
    
}
/*
 #####[4.14]addUserToBlackList(param)//把用户加入到黑名单
 var param = {
 
	username:,//
 }
 #####[4.15]deleteUserFromBlackList(param)//把用户从黑名单中移除
 var param = {
 
	username:,//
 }
 
 */
-(void) addUserToBlackList:(NSMutableArray *)array{
    
    id contactInfo =[self getDataFromJson:array[0]];
    EMError *error = [self.sharedInstance.chatManager blockBuddy:[contactInfo objectForKey:@"username"] 	relationship:eRelationshipBoth];
    if (!error) {
        //   NSLog(@"发送成功");
    }
}


-(void) deleteUserFromBlackList:(NSMutableArray *)array{
    
    id contactInfo =[self getDataFromJson:array[0]];
    EMError *error = [self.sharedInstance.chatManager unblockBuddy:[contactInfo objectForKey:@"username"]];
    if (!error) {
        //   NSLog(@"发送成功");
    }
}


/*
 ###[5]Group
 ***
 */
/*
 #####[5.1]onInvitationDeclined(param)//群聊邀请被拒绝
 var param = {
 
	groupId:,
	invitee:,
	reason:,
 }
 */

-(void)didReceiveGroupRejectFrom:(NSString *)groupId
                         invitee:(NSString *)username
                          reason:(NSString *)reason
                           error:(EMError *)error{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:3];
    [dict setObject:groupId forKey:@"groupId"];
    [dict setObject:username forKey:@"invitee"];
    [dict setObject:reason forKey:@"reason"];
    [self returnJSonWithName:@"onInvitationDeclined" dictionary:dict];
    
}
/*
 
 
 
 #####[5.2]onUserRemoved(param)//当前用户被管理员移除出群聊
 var param = {
 
	groupId:,
	groupName:,
 }
 
 #####[5.3]onGroupDestroy(param)//群聊被创建者解散
 var param = {
 
	groupId:,
	groupName:,
 }
 
 */


- (void)group:(EMGroup *)group didLeave:(EMGroupLeaveReason)reason error:(EMError *)error{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    [dict setObject:group.groupId forKey:@"groupId"];
    [dict setObject:group.groupSubject forKey:@"groupName"];
    
    //群组被销毁
    if(reason == eGroupLeaveReason_Destroyed){
        [self returnJSonWithName:@"onGroupDestroy" dictionary:dict];
        
    }else if(reason == eGroupLeaveReason_BeRemoved){
        //用户被移除
        [self returnJSonWithName:@"onUserRemoved" dictionary:dict];
    }
}

/*
 
 #####[5.4]onApplicationReceived(param)//用户申请加入群聊，收到加群申请
 var param = {
 
	groupId:,
	groupName:,
	applyer:,
	reason:,
 }
 */
 -(void)didReceiveApplyToJoinGroup:(NSString *)groupId
                         groupname:(NSString *)groupname
                     applyUsername:(NSString *)username
                            reason:(NSString *)reason
                             error:(EMError *)error{
     if(!error){
         NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:3];
         [dict setObject:groupId forKey:@"groupId"];
         [dict setObject:groupname forKey:@"groupName"];
         [dict setObject:username forKey:@"applyer"];
         [dict setObject:reason forKey:@"reason"];
         [self playSoundAndVibration];
         [self returnJSonWithName:@"onApplicationReceived" dictionary:dict];
     }
 
 
 }
 /*
 #####[5.5]onApplicationAccept(param)// // 加群申请被同意
 var param = {
 
	groupId:,
	groupName:,
	accepter:,
 }
 */
- (void)didReceiveAcceptApplyToJoinGroup:(NSString *)groupId
                               groupname:(NSString *)groupname
                                   error:(EMError *)error
{
    if(!error){
        NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:3];
        EMError *error2=nil;
        EMGroup *group=[self.sharedInstance.chatManager fetchGroupInfo:groupId error:&error2];
        [dict setObject:groupId forKey:@"groupId"];
        [dict setObject:groupname forKey:@"groupName"];
        [dict setObject:group.owner forKey:@"accepter"];
        [self returnJSonWithName:@"onApplicationAccept" dictionary:dict];
    }
}

/*
 
 #####[5.6]onApplicationDeclined(param)//加群申请被拒绝
 var param = {
 
	groupId:,//（仅Android）
	groupName:,
	decliner:,
	reason:,
 }
 */
-(void)didReceiveRejectApplyToJoinGroupFrom:(NSString *)fromId
                                  groupname:(NSString *)groupname
                                     reason:(NSString *)reason
                                      error:(EMError *)error{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:3];
    [dict setObject:fromId forKey:@"decliner"];
    [dict setObject:groupname forKey:@"groupName"];
    [dict setObject:reason forKey:@"reason"];
    [self returnJSonWithName:@"onApplicationDeclined" dictionary:dict];
    
}

/*
 
 #####[5.7]createPrivateGroup(param)//创建私有群
 var param = {
 
	groupName:,//要创建的群聊的名称
	desc://群聊简介
	members://群聊成员,为空时这个创建的群组只包含自己
	allowInvite://是否允许群成员邀请人进群
	maxUsers://最大群聊用户数，可选参数，默认为200，最大为2000
	initialWelcomeMessage://群组创建时发送给每个初始成员的欢迎信息（仅iOS需要）
 }
 */

-(void) createPrivateGroup:(NSMutableArray *)array{
    
    id groupInfo = [self getDataFromJson:array[0]];
    
    
    EMError *error = nil;
    EMGroupStyleSetting *groupStyleSetting = [[EMGroupStyleSetting alloc] init];
    
    NSInteger userNumber=[[groupInfo objectForKey:@"maxUsers"] intValue];
    if (userNumber != 0){
        groupStyleSetting.groupMaxUsersCount = userNumber;
    }
    if ([[groupInfo objectForKey:@"groupName"] isEqual:@"true" ]){  /// 创建不同类型的群组，这里需要才传入不同的类型
        groupStyleSetting.groupStyle = eGroupStyle_PrivateMemberCanInvite;  //所有群成员都可以邀请非成员进群
    }else{
        groupStyleSetting.groupStyle = eGroupStyle_PrivateOnlyOwnerInvite;  //有创建者可以邀请非成员进群
    }
    [self.sharedInstance.chatManager createGroupWithSubject:[groupInfo objectForKey:@"groupName"] description:[groupInfo objectForKey:@"desc"] invitees:[groupInfo objectForKey:@"members"] initialWelcomeMessage:@"initialWelcomeMessage" styleSetting:groupStyleSetting error:&error];
    if(!error){
        // NSLog(@"创建成功 -- %@",group);
    }
}


/*
 #####[5.8]createPublicGroup(param)//创建公开群
 var param = {
 
	groupName:,//要创建的群聊的名称
	desc://群聊简介
	members://群聊成员,为空时这个创建的群组只包含自己
	needApprovalRequired://如果创建的公开群用需要户自由加入，就传false。否则需要申请，等群主批准后才能加入，传true
	maxUsers://最大群聊用户数，可选参数，默认为200，最大为2000
 initialWelcomeMessage://群组创建时发送给每个初始成员的欢迎信息（仅iOS需要）
 }
 */
-(void) createPublicGroup:(NSMutableArray *)array{
    id groupInfo = [self getDataFromJson:array[0]];
    
    
    EMError *error = nil;
    EMGroupStyleSetting *groupStyleSetting = [[EMGroupStyleSetting alloc] init];
    NSInteger userNumber=[[groupInfo objectForKey:@"maxUsers"] intValue];
    
    if (userNumber != 0){
        groupStyleSetting.groupMaxUsersCount = userNumber;
    }
    
    if ([[groupInfo objectForKey:@"groupName"] isEqual:@"true" ]){  // 创建不同类型的群组，这里需要才传入不同的类型
        groupStyleSetting.groupStyle = eGroupStyle_PublicJoinNeedApproval;  //需要创建者同意才能进入(创建者可以邀请非成员进群)
    }else{
        groupStyleSetting.groupStyle = eGroupStyle_PublicOpenJoin;  // 不需要同意可以直接进入()
    }
    [self.sharedInstance.chatManager createGroupWithSubject:[groupInfo objectForKey:@"groupName"] description:[groupInfo objectForKey:@"desc"] invitees:[groupInfo objectForKey:@"members"] initialWelcomeMessage:@"initialWelcomeMessage" styleSetting:groupStyleSetting error:&error];
    
    if(!error){
        // NSLog(@"创建成功 -- %@",group);
    }
}
 
 
 /*
 #####[5.9]addUsersToGroup(param)//群聊加人
 var param = {
 
	isGroupOwner:,//是否群主(仅Android需要)
	groupId://
	newmembers://群聊新成员，List<String> Json格式
 inviteMessage:// 新增参数 邀请信息
 
 
 }
 */
  -(void)addUsersToGroup:(NSMutableArray *)array{
  id groupInfo = [self getDataFromJson:array[0]];
  
  
  [self.sharedInstance.chatManager asyncAddOccupants:[groupInfo objectForKey:@"newmembers"] toGroup:[groupInfo objectForKey:@"groupId"] welcomeMessage:[groupInfo objectForKey:@"inviteMessage"]];
  
  }
 
 /*
 #####[5.10]removeUserFromGroup(param)//群聊减人
 var param = {
 
	groupId://
	username://
 }
  */

-(void) removeUserFromGroup:(NSMutableArray *)array{
    id removeUser =[self getDataFromJson:array[0]];
    NSArray * usernames =[[NSArray alloc] initWithObjects:[removeUser objectForKey:@"username"],nil];
    
    [self.sharedInstance.chatManager asyncRemoveOccupants:usernames fromGroup:[removeUser objectForKey:@"groupId"]];
    
    
}

/*
 
 #####[5.11]joinGroup(param)//加入某个群聊，只能用于加入公开群
 var param = {
 
	groupId://
	reason:// //如果群开群是自由加入的，即group.isMembersOnly()为false，此参数不传
 groupName://群组名称
 }
 */
-(void) joinGroup:(NSMutableArray *)array{
    id joinGroupInfo =[self getDataFromJson:array[0]];
    
    [self.sharedInstance.chatManager asyncApplyJoinPublicGroup:[joinGroupInfo objectForKey:@"groupId"]  withGroupname:[joinGroupInfo objectForKey:@"groupName"] message:[joinGroupInfo objectForKey:@"reason"] completion:^(EMGroup *group, EMError *error) {
        if (!error) {
            // NSLog(@"申请成功");
        }
    } onQueue:nil];
}

/*
 #####[5.12]exitFromGroup(param)//退出群聊
 var param = {
 
	groupId://
 }
 */
-(void) exitFromGroup:(NSMutableArray *)array{
    
    id exitInfo =[self getDataFromJson:array[0]];
    
    
    
    
    [self.sharedInstance.chatManager asyncLeaveGroup:[exitInfo objectForKey:@"groupId"] completion:^(EMGroup *group, EMGroupLeaveReason reason, EMError *error) {
        if (!error) {
            //NSLog(@"退出群组成功");
        }
    } onQueue:nil];
    
    
}
/*
 #####[5.13]exitAndDeleteGroup(param)//解散群聊
 var param = {
 
	groupId://
 }
 */

-(void) exitAndDeleteGroup:(NSMutableArray *)array{
    
    
    id exitAndDeleteInfo =[self getDataFromJson:array[0]];
    
    [self.sharedInstance.chatManager asyncDestroyGroup:[exitAndDeleteInfo objectForKey:@"groupId"] completion:^(EMGroup *group, EMGroupLeaveReason reason, EMError *error) {
        if (!error) {
            // NSLog(@"解散成功");
        }
    } onQueue:nil];
    
}
/*
 #####[5.14]getGroupsFromServer(param)//从服务器获取自己加入的和创建的群聊列表
 var param = {
 
	loadCache://是否从本地加载缓存，（默认为false，从网络获取）
 }
 
 #####[5.15]cbGetGroupsFromServer(param)//从服务器获取自己加入的和创建的群聊列表回调
 var param = {
 
	result://0-成功，1-失败
	grouplist://List<EMGroup> json格式
	errorMsg:
 }
 */
-(void) getGroupsFromServer:(NSMutableArray *)array{
    
    id getGroup =[self getDataFromJson:array[0]];
    

    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
    NSArray *groups;
    NSMutableArray *grouplist=[NSMutableArray arrayWithCapacity:10] ;
    
    if ([[getGroup objectForKey:@"loadCache"] isEqual:@"true"]){
        [dict setObject:@"0" forKey:@"result"];
        groups = [self.sharedInstance.chatManager loadAllMyGroupsFromDatabaseWithAppend2Chat:YES];
        
        for (EMGroup  *group in groups){
            [grouplist addObject:[self convertEMGroupToDict:group]];
        }
        [dict setObject:grouplist forKey:@"grouplist"];
        
    }else{
        
        [self.sharedInstance.chatManager asyncFetchMyGroupsListWithCompletion:^(NSArray *groups, EMError *error) {
            if (!error) {
                [dict setObject:@"0" forKey:@"result"];
                for (EMGroup  *group in groups){
                    [grouplist addObject:[self convertEMGroupToDict:group]];
                }
                [dict setObject:grouplist forKey:@"grouplist"];
                
            }else{
                [dict setObject:@"1" forKey:@"result"];
            }
            [self returnJSonWithName:@"cbGetGroupsFromServer" dictionary:dict];
        } onQueue:nil];
       
    }
    
    
    
    
}
/*
 
 #####[5.16]getAllPublicGroupsFromServer();//获取所有公开群列表
 #####[5.17]cbGetAllPublicGroupsFromServer(param)//获取所有公开群列表回调
 var param = {
	
	result://0-成功，1-失败
	grouplist:List< EMGroup> json格式 见附录
	errorMsg:
 }
 */
-(void) getAllPublicGroupsFromServer:(NSMutableArray*)array{
    [self.sharedInstance.chatManager asyncFetchAllPublicGroups];
    
}

-(void)didFetchAllPublicGroups:(NSArray *)groups
                         error:(EMError *)error{
    
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
    if(!error){
        [dict setObject:@"0" forKey:@"result"];
        NSMutableArray *grouplist=[NSMutableArray arrayWithCapacity:10] ;
        for (EMGroup  *group in groups){
            [grouplist addObject:[self convertEMGroupToDict:group]];
        }
        
        [dict setObject:grouplist forKey:@"grouplist"];
    }else{
        [dict setObject:@"1" forKey:@"result"];
    }
    [self returnJSonWithName:@"cbGetAllPublicGroupsFromServer" dictionary:dict];
}

/*
 
 #####[5.18]getGroup(param)//获取单个群聊信息
 var param = {
 
	groupId:,//
	loadCache://是否从本地加载缓存，（默认为false，从网络获取）
 }
 
	注：当系统为iOS时，loadCache参数无效只能从网络获取，
 
 #####[5.19]cbGetGroup(param)//获取单个群聊信息回调
 var param = {
 
	group://EMGroup 对象json格式
 }
 */
-(void)getGroup:(NSMutableArray *)array{
    id groupInfo =[self getDataFromJson:array[0]];
    [self.sharedInstance.chatManager asyncFetchGroupInfo:[groupInfo objectForKey:@"groupId"]
                                              completion:^(EMGroup *group, EMError *error){
                                                  [self cbGetGroup:group error:error];
                                              } onQueue:nil];
}

- (void)cbGetGroup:(EMGroup *)group
             error:(EMError *)error{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    if(!error){
        [dict setObject:[self convertEMGroupToDict:group] forKey:@"group"];
        [self returnJSonWithName:@"cbGetGroup" dictionary:dict];
    }
}

/*
 #####[5.20]blockGroupMessage(param)//屏蔽群消息
 var param = {
 
	groupId://
 }
 
 #####[5.21]unblockGroupMessage(param)//解除屏蔽群
 var param = {
 
	groupId://
 }
 */
-(void) blockGroupMessage:(NSMutableArray *)array{
    id groupInfo =[self getDataFromJson:array[0]];
    EMError *pError = nil;
    [self.sharedInstance.chatManager blockGroup:[groupInfo objectForKey:@"groupId"] error:(EMError **)pError];
    
}
-(void) unblockGroupMessage:(NSMutableArray *)array{
    id groupInfo =[self getDataFromJson:array[0]];
    EMError *pError = nil;
    [self.sharedInstance.chatManager unblockGroup:[groupInfo objectForKey:@"groupId"] error:(EMError **)pError];
    
}

/*
 #####[5.22]changeGroupName(param)//修改群组名称
 var param = {
 
	groupId://
	changedGroupName:,//改变后的群组名称
 }
 */
-(void) changeGroupName:(NSMutableArray *)array{
    
    id groupInfo =[self getDataFromJson:array[0]];
    
    [self.sharedInstance.chatManager asyncChangeGroupSubject:[groupInfo objectForKey:@"changedGroupName"] 	forGroup:[groupInfo objectForKey:@"groupId"]];
}


/*
 #####[5.23]setReceiveNotNoifyGroup(param)//群聊不提醒只显示数目（仅Android可用）
 var param = {
 
	groupIds:// List<String>
 }
 #####[5.24]blockUser(param)//将群成员拉入群组的黑名单（仅Android可用）
 var param = {
 
	groupId:,//
	username://待屏蔽的用户名
 }
 #####[5.25]unblockUser(param)//将拉入黑名单的群成员移除（仅Android可用）
 var param = {
 
	groupId:,//
	username://待解除屏蔽的 用户名
 }
 #####[5.26]getBlockedUsers(param)//获取群组的黑名单用户列表（仅Android可用）
 var param = {
 
	groupId:,//
 }
 
 
 #####[5.27]cbGetBlockedUsers(param)//获取群组的黑名单用户列表回调（仅Android）
	var param = {
	usernames:,// List<String> json格式
 }
 */
/*
 #####[5.28]onGroupUpdateInfo(param)//群组信息更新的监听（仅iOS）
 var param={
 
 group:,//EMGroup对象的json格式字符串
 }
 
	每当添加/移除/更改角色/更改主题/更改群组信息之后,都会触发此回调
 
 */
- (void)groupDidUpdateInfo:(EMGroup *)group error:(EMError *)error{
    
    if(!error){
        NSDictionary *dict =[self convertEMGroupToDict:group];
        [self returnJSonWithName:@"onGroupUpdateInfo" dictionary:dict];
        
    }
}
/*
 ###[6]Call
 ***
 #####[6.1]onCallReceive(param)// 实时语音监听
 var param = {
	
	from;//拨打方username
	callType;//0-语音电话 1-视频电话
 callId;//新增参数 本次通话的EMSessionId
 }
 
 #####[6.2]onCallStateChanged(param)//通话状态监听
 var param = {
 
	state:,//1-正在连接对方，2-双方已经建立连接，3-同意语音申请，建立语音通话中，4-连接中断 5-电话暂停中 6-电话等待对方同意接听 7-通话中
 }
 
 
	eg. 一个成功的语音通话流程为 ：A发送通话请求给B ==> AB建立语音通话连接 ==> B同意语音通话 ==> 开始语音通话
 
 
 
 #####[6.3]makeVoiceCall(param)//拨打语音通话
 var param = {
 
	username:,//
 }
 #####[6.4]answerCall();//接听通话
 #####[6.5]rejectCall();//拒绝接听
 #####[6.6]endCall();//挂断通话
 */
-(void)callSessionStatusChanged:(EMCallSession *)callSession
                   changeReason:(EMCallStatusChangedReason)reason
                          error:(EMError *)error{
    
    
    if(!error){
        
        
        self.call = callSession;
        NSMutableDictionary *dictCallReceive =[NSMutableDictionary dictionaryWithCapacity:2];
        [dictCallReceive setObject:callSession.sessionId forKey:@"callId"];
        [dictCallReceive setObject:callSession.sessionChatter forKey:@"from"];
        NSString *callType;
        if (callSession.type ==eCallSessionTypeAudio) {
            callType = @"0";
        }else if(callSession.type ==eCallSessionTypeVideo){
            callType = @"1";
        }else{//callSession.type ==eCallSessionTypeContent
            callType = @"2";
        }
        [dictCallReceive setObject:callType forKey:@"callType"];
        [self returnJSonWithName:@"onCallReceive" dictionary:dictCallReceive];
        
        NSMutableDictionary *dictCallStateChanged =[NSMutableDictionary dictionaryWithCapacity:1];
        NSString *callState;
        if (callSession.status == eCallSessionStatusDisconnected){
            callState =@"4";
        }else if(callSession.status == eCallSessionStatusRinging){
            callState =@"6";
        }else if(callSession.status == eCallSessionStatusAnswering){
            callState =@"7";
        }else if(callSession.status == eCallSessionStatusPausing){
            callState =@"5";
        }else if(callSession.status == eCallSessionStatusConnected){
            callState =@"2";
        }else if(callSession.status == eCallSessionStatusAccepted){
            callState =@"3";
        }else{  //callSession.status == eCallSessionStatusConnecting)
            callState =@"1";
        }
        
        [dictCallStateChanged setObject:callState forKey:@"state"];
        
        [self returnJSonWithName:@"onCallStateChanged" dictionary:dictCallStateChanged];
    }
}

-(void) makeVoiceCall:(NSMutableArray *)array{
    id callInfo =[self getDataFromJson:array[0]];
    EMError *error;
    self.call=[self.sharedInstanceForCall.callManager asyncMakeVoiceCall:[callInfo objectForKey:@"username"] timeout:50 error:&error];
}


-(void) answerCall:(NSMutableArray *)array{
    
    
    [self.sharedInstanceForCall.callManager asyncAnswerCall:self.call.sessionId];
}

-(void) rejectCall:(NSMutableArray *)array{
    
    [self.sharedInstanceForCall.callManager asyncEndCall:self.call.sessionId reason:eCallReason_Reject];
}

-(void) endCall:(NSMutableArray *)array{
    
    [self.sharedInstanceForCall.callManager asyncEndCall:self.call.sessionId reason:eCallReason_Hangup];
}
/*
 ###[7]APNs(仅iOS)
 ***
 */
/*
 #####[7.1]registerRemoteNotification();//注册Apns推送
 #####[7.2]cbRegisterRemoteNotification(param);//回调
 var param{
 
	result;//1-成功 2-失败
	errorInfo;//注册失败时的推送信息
 }
 */
-(void)registerRemoteNotification:(NSMutableArray *)array{
    
    UIApplication *application = [UIApplication sharedApplication];
    application.applicationIconBadgeNumber = 0;
    
    if([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationType notificationTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    
    
#if !TARGET_IPHONE_SIMULATOR
    //iOS8 注册APNS
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings
                                                                             settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
                                                                             categories:nil]];
        
        
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }else{
        if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
            [application registerForRemoteNotifications];
        }else{
            UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeBadge |
            UIRemoteNotificationTypeSound |
            UIRemoteNotificationTypeAlert;
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
        }
    }
#endif
    
}
// 将得到的deviceToken传给SDK
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    [self.sharedInstance application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@"1" forKey:@"result"];
    [self returnJSonWithName:@"cbRegisterRemoteNotification" dictionary:dict];
}

// 注册deviceToken失败
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    [self.sharedInstance application:application didFailToRegisterForRemoteNotificationsWithError:error];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@"2" forKey:@"result"];
    [dict setObject:error forKey:@"errorInfo"];
    [self returnJSonWithName:@"cbRegisterRemoteNotification" dictionary:dict];
    
}
 /*
 #####[7.3]updatePushOptions(param);//设置apns全局属性
 var param{
 
	nickname;//昵称
	noDisturbing;//是否开启免打扰模式 1-开启 2-不开启
	noDisturbingStartH;//免打扰模式开始时间  小时（int）
	noDisturbingEndH;//免打扰模式结束时间  小时（int）
 }
 #####[7.4]cbUpdatePushOptions(param);//设置apns全局属性回调
 var param{
 
	nickname;//昵称
	noDisturbing;//是否开启免打扰模式 1-开启 2-不开启
	noDisturbingStartH;//免打扰模式开始时间  小时（int）
	noDisturbingEndH;//免打扰模式结束时间  小时（int）
 }
 
	说明：updatePushOptions全为可选参数，当传入空值时，即可通过回调获得当前apns全局属性
 */

-(void)updatePushOptions:(NSMutableArray *)array{
    
    id info = [self getDataFromJson:array[0]];
    if([info objectForKey:@"nickname"]){
        self.apnsOptions.nickname =[info objectForKey:@"nickname"];
    }
    if([info objectForKey:@"noDisturbing"]){
        if([[info objectForKey:@"noDisturbing"] isEqual:@"1"]){
            self.apnsOptions.noDisturbStatus =YES;
        }else if([[info objectForKey:@"noDisturbing"] isEqual:@"2"]){
            self.apnsOptions.noDisturbStatus =NO;
        }
    }
    if([info objectForKey:@"noDisturbingStartH"]){
        self.apnsOptions.noDisturbingStartH =[[info objectForKey:@"noDisturbingStartH"] integerValue];
    }
    if([info objectForKey:@"noDisturbingEndH"]){
        self.apnsOptions.noDisturbingEndH =[[info objectForKey:@"noDisturbingEndH"] integerValue];
    }
    
    [self.sharedInstance.chatManager asyncUpdatePushOptions:self.apnsOptions];
}
- (void)didUpdatePushOptions:(EMPushNotificationOptions *)options
                       error:(EMError *)error{
    if(options){
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:options.nickname forKey:@"nickname"];
        [dict setObject:[NSString stringWithFormat:@"%lu",(unsigned long)options.noDisturbingStartH] forKey:@"noDisturbingStartH"];
        [dict setObject:[NSString stringWithFormat:@"%lu",(unsigned long)options.noDisturbingStartH] forKey:@"noDisturbingEndH"];
        NSString *noDisturbStatus;
        if(options.noDisturbStatus){
            noDisturbStatus = @"1";
        }else{
            noDisturbStatus = @"2";
        }
        [dict setObject:noDisturbStatus forKey:@"noDisturbing"];
        [self returnJSonWithName:@"cbUpdatePushOptions" dictionary:dict];
    }
}

/*
 
 #####[7.5]ignoreGroupPushNotification(param)://设置指定群组是否接收
 var param{
 
	groupId;//指定的群组Id
	isIgnore;//1-屏蔽  2-取消屏蔽
 }
 
 #####[7.6]cbIgnoreGroupPushNotification(param)://回调
 var param{
 
	groups;//已屏蔽接收推送消息的群列表
 }
*/

-(void) ignoreGroupPushNotification:(NSMutableArray *)array{
    id info = [self getDataFromJson:array[0]];
    NSString *groupId = [info objectForKey:@"groupId"];
    NSString *ignore = [info objectForKey:@"isIgnore"];
    BOOL isIgnore;
    if(ignore){
        if([ignore isEqual:@"1"]){
            isIgnore =YES;
        }else if([ignore isEqual:@"2"]){
            isIgnore =NO;
        }else{
            return;
        }
        [self.sharedInstance.chatManager asyncIgnoreGroupPushNotification:groupId isIgnore:isIgnore];
    }
}

- (void)didIgnoreGroupPushNotification:(NSArray *)ignoredGroupList
                                 error:(EMError *)error{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:ignoredGroupList forKey:@"groups"];
    [self returnJSonWithName:@"cbIgnoreGroupPushNotification" dictionary:dict];
}


















@end
