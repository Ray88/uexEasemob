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
@end


@implementation EUExEasemob






-(id)initWithBrwView:(EBrowserView *)eInBrwView{
    self=[super initWithBrwView:eInBrwView];
    if(self){
    
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
}

-(void)dealloc{
    [self clean];
    [super dealloc];
}


/*

1.initEasemob(param);//初始化
  var param{
       appKey:,//区别app的标识
       apnsCertName:,//iOS中推送证书名称
       deliveryNotification:,//是否开启消息送达通知 1-开启 2-不开启 默认不开启   暂时不用
 
 };
 */




-(void)initEasemob:(NSMutableArray *)array{
    
    
    id initInfo =[self getDataFromJson:array[0]];
    self.sharedInstance =[EaseMob sharedInstance];
    self.sharedInstanceForCall = [EMSDKFull sharedInstance];

    
    [self.sharedInstance registerSDKWithAppKey:[initInfo objectForKey:@"appKey"]
                                       apnsCertName:[initInfo objectForKey:@"apnsCertName"]
                                        otherConfig:@{kSDKConfigEnableConsoleLogger:[NSNumber numberWithBool:YES]}];
    
    
    [self registerEaseMobNotification];//注册回调
    self.lastPlaySoundDate = [NSDate date];
    self.isPlayVibration = YES;
    self.isPlaySound = YES;
    self.messageNotification = YES;
    self.userSpeaker = YES;
    [self.sharedInstance.chatManager enableDeliveryNotification];//开启消息已送达回执
    NSLog(@"init");

    
    
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


/*2 登陆
 login(param)
 var param = {
	username:,//用户名
	password;,//密码
 };
*/
/*3 cbLogin(param)//登陆回调
var param = {
result:,//1-成功，2-失败
msg:,提示信息
};
*/

/*  微信的例子
 (void)isSupportPay:(NSMutableArray *)inArguments {
 BOOL isSupportApi = [WXApi isWXAppSupportApi];
 if (isSupportApi) {
 [self jsSuccessWithName:@"uexWeiXin.cbIsSupportPay" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:0];
 }else {
 [self jsSuccessWithName:@"uexWeiXin.cbIsSupportPay" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:1];
 }
 }*/





// 2 3的合并
- (void)login:(NSMutableArray *)array{
    id user =[self getDataFromJson:array[0]];

    // 登录
   
    [self.sharedInstance.chatManager asyncLoginWithUsername:[user objectForKey:@"username"] password:[user objectForKey:@"password"] completion:^(NSDictionary *loginInfo, EMError *error) {
        //回调
        NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];

        
        if (!error && loginInfo) {
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

//4 退出登录

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

/*5 registerUser(param)//注册
 var param = {
	username:,//用户名
	password;,//密码
 };
 6 cbRegisterUser()//注册回调
 var param = {
	result:,//1-成功，2-失败
	msg:,提示信息
 };
 
 ‘registeruser 是上述的合并
 
 */
-(void)registerUser:(NSMutableArray *)array{
    id user =[self getDataFromJson:array[0]];
    NSLog(@"testReg%@",user);
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
 7 onNewMessage(param)//收到新消息
 var param = {
	msgId:,//消息ID
	username;,//发送方
 };
 
 8 getMessageById(param)//根据id获取消息记录
 var param = {
	msgId:,//消息ID
 };
 
 9 cbGetMessageById(param)//得到一条消息记录
 var param = {
	msg:,// EMMessage的json格式对象
 };
 
 7' onNewMessage(message）  是上述的合并
 
 
*/




//收到新信息
-(void)didReceiveMessage:(EMMessage *)message{

    NSMutableDictionary *dict = [self convertEMMessageToDict:message];

    [self playSoundAndVibration];
    [self returnJSonWithName:@"onNewMessage" dictionary:dict];

}



-(void) callBackTest:(NSMutableArray *)array{
    
    
    NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:@"123",@"456", nil];
    
    
    [self returnJSonWithName:@"cbTest" dictionary:dict];

}


/*
//收到透传消息
- (void)didReceiveCmdMessage:(EMMessage *)cmdMessage;
}
 
 见85
*/
//将要接收离线消息的回调
- (void)willReceiveOfflineMessages{}




//离线非透传消息接收完成的回调
- (void)didFinishedReceiveOfflineMessages:(NSArray *)offlineMessages{
    for(EMMessage *msg in offlineMessages){
        [self didReceiveMessage:msg];
    }

}



/*
 10 getConversationByName(param)//根据用户名获取conversation
 var param = {
	username:，//用户名
 '  isGroup:，//新增参数 是否为群组 1-是 2-否
 };
 
 
 11 cbGetConversationByName(param)
 var param = {
	conversation:,// 回调 EMConversation的json格式对象
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
12 onAckMessage(param)//回执消息
var param = {
msgId:,//消息ID
    username;,//发送方
};
  
 '消息已读的回调
 
 */

/*
 // 发送已读回执.在app中具体在哪里发送需要开发者自己决定。
 [[EaseMob sharedInstance].chatManager sendHasReadResponseForMessage:message];
 */

-(void)didReceiveHasReadResponse:(EMReceipt *)resp{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
        [dict setObject:resp.chatId forKey:@"msgId"];
        [dict setObject:resp.from forKey:@"username"];

    [self returnJSonWithName:@"onAckMessage" dictionary:dict];
}


 /*
13onDeliveryMessage(param)//消息送达
var param = {
msgId:,//消息ID
    username;,//
};
 */





-(void)didReceiveHasDeliveredResponse:(EMReceipt *)resp{

    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
    [dict setObject:resp.chatId forKey:@"msgId"];
    [dict setObject:resp.from forKey:@"username"];
   [self returnJSonWithName:@"onDeliveryMessage" dictionary:dict];
}


/*
 14 onContactAdded(param)//新增联系人
 var param = {
	userNameList:,//json格式的List<String>
 };
 15 onContactDeleted(param)//删除的联系人
 var param = {
	userNameList:,//json格式的List<String>
 };
*/

/*
 16 onContactInvited(param)//接到邀请的消息
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
 17 onContactAgreed(param)//同意好友请求 (被）
 var param = {
	username:,//
 };
 
 ’发出的好友请求被同意的回调
 */
/*!
 @method
 @brief 好友请求被接受时的回调
 @discussion
 @param username 之前发出的好友请求被用户username接受了
 */



-(void)didAcceptedByBuddy:(NSString *)username{
    
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    [dict setObject:username forKey:@"username"];
    
    [self returnJSonWithName:@"onContactAgreed" dictionary:dict];
}

/* 
 18 onContactRefused(param)//拒绝好友请求
	var param = {
	username:,//
 };
 */
/*!
 @method
 @brief 好友请求被拒绝时的回调
 @discussion
 @param username 之前发出的好友请求被用户username拒绝了
 */

-(void)didRejectedByBuddy:(NSString *)username{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    [dict setObject:username forKey:@"username"];
    
    [self returnJSonWithName:@"onContactRefused" dictionary:dict];
    
}

/*
 19 onDisconnected(param)//链接断开
var param = {
error:,//1-账号被移除，2-账号其他设备登陆，3-网络连接失败（连接不到聊天服务器，或者当前网络不可用）
};
*/

-(void)disconnectedError:(NSInteger)errorCode{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    [dict setObject:[NSString stringWithFormat: @"%ld", (long)errorCode] forKey:@"error"];
    
    [self returnJSonWithName:@"onContactInvited" dictionary:dict];
}


-(void)didRemovedFromServer{
    [[EaseMob sharedInstance].chatManager asyncLogoffWithUnbindDeviceToken:NO completion:^(NSDictionary *info, EMError *error) {
        if (!error && info) {
            [self disconnectedError:1];
        }
    } onQueue:nil];

}

-(void)didLoginFromOtherDevice{
    [[EaseMob sharedInstance].chatManager asyncLogoffWithUnbindDeviceToken:NO completion:^(NSDictionary *info, EMError *error) {
        if (!error && info) {
           [self disconnectedError:2];
        }
    } onQueue:nil];
    
}

- (void)didConnectionStateChanged:(EMConnectionState)connectionState{
    if (connectionState == eEMConnectionDisconnected){
        [self disconnectedError:3];
    }
}



/*
 20 onConnected(param);//服务器连接状态
 var param = {
 isConnected:,//  1-连接服务器成功  2-连接服务器失败
 }
 //每次成功登陆都会触发此回调
 //集成在2 login()中
 */


/* 
 21 onInvitationAccpted(param) //群聊邀请被接受   作为owner发送邀请，被接受
	var param = {
	groupId:,//
	inviter:,//
    reason:,
 
 ' 没有此接口
 群聊邀请被接受时，群组人数增加，可通过onGroupUpdateInfo获得相关信息
 };
 
 */




/*
22 onInvitationDeclined(param)//群聊邀请被拒绝
var param = {
groupId:,//
invitee:,//
reason:,//
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
 
 
23 onUserRemoved(param)//当前用户被管理员移除出群聊
	var param = {
	groupId:,//
	groupName:,//
 }
 
24 onGroupDestroy(param)//群聊被创建者解散
	var param = {
	groupId:,//
	groupName:,//
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
 25 onApplicationReceived(param)//用户申请加入群聊，收到加群申请
	var param = {
	groupId:,//
	groupName:,//
	applyer:,//
	reason:,//
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
 26 onApplicationAccept(param)// // 加群申请被同意
	var param = {
	groupId:,//
	groupName:,//
	accepter:,//
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
 27 
 onApplicationDeclined(param)//加群申请被拒绝
	var param = {
	groupId:,//SDK回调没有相应信息 此条删去
	groupName:,//
	decliner:,//
	reason:,//
 }
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
28 sendText(param)//发送文本消息及表情
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
29 sendVoice(param)//发送语音
var param = {
username:,//单聊时聊天人的userid或者群聊时groupid
chatType:,//1-单聊，2-群聊
filePath:,//语音文件路径
length:,//长度  

’ 视频文件也可以通过此方法发送
‘ length 长度 在iOS中没有用到！ 换为参数displayName 显示名
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

    EMChatVideo *videoChat = [[EMChatVideo alloc] initWithFile:[voiceData objectForKey:@"filePath"] displayName:[voiceData objectForKey:@"displayName"]];
    EMVideoMessageBody *body = [[EMVideoMessageBody alloc] initWithChatObject:videoChat];
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[voiceData objectForKey:@"username"] bodies:@[body]];
    message.isGroup = isGroup; // 设置是否是群聊

    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
    NSLog(@"testsendvoice");
    
}


/*
 30 sendPicture(param)//发送图片
	var param = {
	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	filePath:,//图片文件路径
    
 '  displayName//新增参数 显示名
 
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
    UIImage  *img = [UIImage imageWithContentsOfFile:[pictureData objectForKey:@"filePath"]];
    
    EMChatImage *imgChat = [[EMChatImage alloc] initWithUIImage:img displayName:[pictureData objectForKey:@"displayName"]];
    EMImageMessageBody *body = [[EMImageMessageBody alloc] initWithChatObject:imgChat];
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[pictureData objectForKey:@"username"] bodies:@[body]];
    message.isGroup = isGroup; // 设置是否是群聊

    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
}

/*
 31 sendLocationMsg(param)//发送地理位置信息
	var param = {
	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	locationAddress:,//地址
	latitude:,//维度
	longitude:,//经度
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
 32 sendFile(param)//发送文件
	var param = {
	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	filePath:,//文件路径
 
 '  displayName://新增参数 显示名
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
    
    
    EMChatFile *fileChat = [[EMChatFile alloc] initWithFile:[fileData objectForKey:@"filePath"] displayName:[fileData objectForKey:@"displayName"]];
    EMFileMessageBody *body = [[EMFileMessageBody alloc] initWithChatObject:fileChat];
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[fileData objectForKey:@"username"] bodies:@[body]];
    message.isGroup = isGroup; // 设置是否是群聊

    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
}


/*
 33 getMessageHistory(param)//获取聊天记录
	var param = {
	username:,//单聊时聊天人的userName或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	startMsgId:,//获取startMsgId之前的pagesize条消息
	pagesize:,//分页大小，为0时获取所有消息，startMsgId可不传
 }
 
 34 cbGetMessageHistory(param)//获取聊天记录
	var param = {
	messages:,//List<EMMessage>的json格式对象
 }
 
 '没有类似功能！...
 
 */



/*
 35 getUnreadMsgCount(param)//获取未读消息数量
	var param = {
	username:,//用户名
 '  isGroup:,//是否为群组 1-是 2-否
 }
 36 cbGetUnReadMsgCount(param)//获取未读消息数量回调
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
37 resetUnreadMsgCount(param)//未读消息数清零(指定会话消息未读数清零)
var param = {
    username:,//username|groupid
 '  isGroup:，//新增参数 是否为群组 1-是 2-否
}
*/
-(void)resetUnreadMsgCount:(NSMutableArray *)array{
    EMConversation *conversation =[self getConversation:array];
    [conversation markAllMessagesAsRead:YES];
}

/*
 38 resetAllUnreadMsgCount();//所有未读消息数清零
*/

/*
 39 getMsgCount(param)//获取消息总数
	var param = {
	username:,//username|groupid
 }
 40 cbGetMsgCount(param)//获取消息总数回调
	var param = {
	msgCount:,//消息总数
 }
 */


/*
 41 clearConversation(param)//清空会话聊天记录
	var param = {
	username:,//username|groupid
 }
 
 ‘没找到相应接口
 */


/*
 42 deleteConversation(param)//删除和某个user的整个的聊天记录(包括本地)
	var param = {
	username:,//username|groupid
'   isGroup:，//新增参数 是否为群组 1-是 2-否
 }
 */


-(void)deleteConversation:(NSMutableArray *)array{
    EMConversation *conversation =[self getConversation:array];
    [conversation removeAllMessages];
}


/*
43 removeMessage(param)//删除当前会话的某条聊天记录
var param = {
    username:,//username|groupid
    msgId:,
'   isGroup:，//新增参数 是否为群组 1-是 2-否
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
44 deleteAllConversation();//删除所有会话记录(包括本地)
*/
-(void)deleteAllConversation:(NSMutableArray*)array{
    [self.sharedInstance.chatManager removeAllConversationsWithDeleteMessages:YES append2Chat:YES];
    NSLog(@"deleteAllConversation");
}




/*
 45 setNotifyBySoundAndVibrate(param)//消息提醒相关配置
	var param = {
	enable:,//0-关闭，1-开启。默认为1 开启新消息提醒
	soundEnable:,// 0-关闭，1-开启。默认为1 开启声音提醒
	vibrateEnable:,// 0-关闭，1-开启。默认为1 开启震动提醒
	userSpeaker:,// 0-关闭，1-开启。默认为1 开启扬声器播放
	showNotificationInBackgroud:// 0-关闭，1-开启。默认为1。设置后台接收新消息时是否通过通知栏提示
                             SDK没有提供相关接口 删去
	acceptInvitationAlways:,// 0-关闭，1-开启。默认添加好友时为1，是不需要验证的，改成需要验证为0)
                             SDK没有提供相关接口 删去
 deliveryNotification:，//新增参数   0-关闭 1-开启  默认为1 开启消息送达通知
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
    
    NSLog(@"SetNotifyBySoundAndVibrate");
    
}

//两次提示的默认间隔
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
        [[EaseMob sharedInstance].deviceManager asyncPlayNewMessageSound];
    }
    // 收到消息时，震动
    if(self.isPlayVibration){
        [[EaseMob sharedInstance].deviceManager asyncPlayVibration];
    }
}

/*
 46 getContactUserNames();//获取好友列表
 47 cbGetContactUserNames(param)//获取好友列表回调
	var param = {
	userNames:,//List<String> json格式字符串
 }
 
’ 合并
 */

-(void)getContactUserNames:(NSMutableArray*)array{
    
    EMError *error = nil;
    NSArray *buddyList = [self.sharedInstance.chatManager fetchBuddyListWithError:&error];
    
    NSMutableArray *buddies = [NSMutableArray arrayWithCapacity:1];
    for(EMBuddy  *buddy in buddyList){
        [buddies addObject:[buddy properties_aps]];
    }
    
    [self returnJSonWithName:@"cbGetContactUserNames" dictionary:buddies];
}




/* 
 48 addContact(param)//添加好友
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
 49 deleteContact(param)//删除好友
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
 50 acceptInvitation(param)//同意username的好友请求
	var param = {
	username:,//
 }
 51 refuseInvitation(param)//拒绝username的好友请求
	var param = {
	username:,//
 ‘  reason:,//新增参数 拒绝好友请求原因
 }
 */
-(void) acceptInvitation:(NSMutableArray *)array{
    id contactInfo =[self getDataFromJson:array[0]];

    EMError *error = nil;
    BOOL isSuccess = [self.sharedInstance.chatManager acceptBuddyRequest:[contactInfo objectForKey:@"username"] error:&error];
    if (isSuccess && !error) {
        NSLog(@"发送同意成功");
    }
}

-(void) refuseInvitation:(NSMutableArray *)array{
    id contactInfo =[self getDataFromJson:array[0]];
    

    EMError *error = nil;
    BOOL isSuccess = [self.sharedInstance.chatManager rejectBuddyRequest:[contactInfo objectForKey:@"username"] reason:[contactInfo objectForKey:@"reason"] error:&error];
    if (isSuccess && !error) {
        NSLog(@"发送拒绝成功");
    }
}


/*
 52 getBlackListUsernames();//获取黑名单列表
 53 cbGetBlackListUsernames(param)//获取黑名单列表回调
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
 54 addUserToBlackList(param)//把用户加入到黑名单
	var param = {
	username:,//
 }
 55 deleteUserFromBlackList(param)//把用户从黑名单中移除
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
56 createPrivateGroup(param)//创建私有群
   var param = {
   groupName:,//要创建的群聊的名称
   desc://群聊简介
   members://群聊成员,为空时这个创建的群组只包含自己
   allowInvite://是否允许群成员邀请人进群  true false
   maxUsers://最大群聊用户数，可选参数，默认为200，最大为2000
'  initialWelcomeMessage:// 新增参数 群组欢迎信息
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
 57 createPublicGroup(param)//创建公开群
	var param = {
	groupName:,//要创建的群聊的名称
	desc://群聊简介
	members://群聊成员,为空时这个创建的群组只包含自己
	needApprovalRequired://如果创建的公开群用需要户自由加入，就传false。否则需要申请，等群主批准后才能加入，传true
    maxUsers://最大群聊用户数，可选参数，默认为200，最大为2000
 
    
'   initialWelcomeMessage:// 新增参数 群组欢迎信息
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
 58 addUsersToGroup(param)//群聊加人
	var param = {
	isGroupOwner:,//是否群主
	groupId://
	newmembers://群聊新成员，List<String> Json格式
 
 ’  inviteMessage:// 新增参数 邀请信息
 '  isGroupOwner  没有用到
 }
 */

/*
 被添加的人会收到回调 
 (void)didAcceptInvitationFromGroup:(EMGroup *)group error:(EMError *)error;
 @method
 @brief 接受群组邀请并加入群组后的回调
 @param group 所接受的群组
 @param error 错误信息
 */





-(void)addUsersToGroup:(NSMutableArray *)array{
    id groupInfo = [self getDataFromJson:array[0]];
    
    
    [self.sharedInstance.chatManager asyncAddOccupants:[groupInfo objectForKey:@"newmembers"] toGroup:[groupInfo objectForKey:@"groupId"] welcomeMessage:[groupInfo objectForKey:@"inviteMessage"]];

}

/*
59 removeUserFromGroup(param)//群聊减人
	var param = {
	groupId://
	username://  \

 }
 */

//只有owner权限才能调用
//函数执行完, 回调groupDidUpdateInfo:error:会被触发

-(void) removeUserFromGroup:(NSMutableArray *)array{
    id removeUser =[self getDataFromJson:array[0]];
    NSArray * usernames =[[NSArray alloc] initWithObjects:[removeUser objectForKey:@"username"],nil];
    
    [self.sharedInstance.chatManager asyncRemoveOccupants:usernames fromGroup:[removeUser objectForKey:@"groupId"]];
    
    
}

/*
 60 joinGroup(param)//加入某个群聊，只能用于加入公开群
	var param = {
	groupId://
	reason:// //如果群开群是自由加入的，即group.isMembersOnly()为false，此参数不传
'   groupName://群组名称
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
 61 exitFromGroup(param)//退出群聊
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
 62 exitAndDeleteGroup(param)//解散群聊
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
 63 getGroupsFromServer(param)//从服务器获取自己加入的和创建的群聊列表
	var param = {
	loadCache://是否从本地加载缓存，（默认为false，从网络获取）
 }
 
 64 cbGetGroupsFromServer(param)//从服务器获取自己加入的和创建的群聊列表回调
	var param = {
	result://0-成功，1-失败
	grouplist:List<EMGroup> json格式
	errorMsg:  
 
 ‘实际没有errorMsg值返回
 }
 */

-(void) getGroupsFromServer:(NSMutableArray *)array{
    
    id getGroup =[self getDataFromJson:array[0]];
    
    EMError *error = nil;
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
        
        groups = [self.sharedInstance.chatManager fetchMyGroupsListWithError:&error];
        if (!error) {
            [dict setObject:@"0" forKey:@"result"];
            for (EMGroup  *group in groups){
                [grouplist addObject:[self convertEMGroupToDict:group]];
            }
            [dict setObject:grouplist forKey:@"grouplist"];
            
        }else{
            [dict setObject:@"1" forKey:@"result"];
        }
    }
    
    [self returnJSonWithName:@"cbGetGroupsFromServer" dictionary:dict];

    
}


/*
 65 getAllPublicGroupsFromServer();//获取所有公开群列表
 66 cbGetAllPublicGroupsFromServer(param)//获取所有公开群列表回调
	var param = {
	result://0-成功，1-失败
	grouplist:List< EMGroupInfo> json格式
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
 67 getGroup(param)//获取单个群聊信息
	var param = {
    groupId:,//
	loadCache://是否从本地加载缓存，（默认为false，从网络获取）
 
 
 ‘ 无法从本地加载缓存 loadCache参数无效
 }
 68 cbGetGroup(param)//获取单个群聊信息回调
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
 69 blockGroupMessage(param)//屏蔽群消息
	var param = {
	groupId://
 }
 70 unblockGroupMessage(param)//解除屏蔽群
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
 71 changeGroupName(param)//修改群组名称
	var param = {
	groupId://
	changedGroupName:,//改变后的群组名称
 }
 */

//函数执行完, 回调groupDidUpdateInfo:error:会被触发
-(void) changeGroupName:(NSMutableArray *)array{
    
    id groupInfo =[self getDataFromJson:array[0]];
    
    [self.sharedInstance.chatManager asyncChangeGroupSubject:[groupInfo objectForKey:@"changedGroupName"] 	forGroup:[groupInfo objectForKey:@"groupId"]];
}


/*
 72 setReceiveNotNoifyGroup(param)//群聊不提醒只显示数目
	var param = {
	groupIds:// List<String>
 }
 73 blockUser(param)//将群成员拉入群组的黑名单
	var param = {
	groupId:,//
	username://待屏蔽的用户名
 }
 74 unblockUser(param)//将拉入黑名单的群成员移除
	var param = {
	groupId:,//
	username://待解除屏蔽的 用户名
 }
 75 getBlockedUsers(param)//获取群组的黑名单用户列表
	var param = {
	groupId:,//
 }
 
 
 'ios没有提供相应接口 无法实现
 */


/*
 77 importMessage(param)//导入消息到环信DB
	var param = {
	chatType:,//1-单聊，2-群聊
	sendType:,//1-发送消息，2-接收消息
	textContent:,//文本内容
	from:,//发送人
	to:,//接收人
	msgTime://消息时间
 }
 */

/*
 
 //message 生成之后 如何操作？
-(void) importMessage:(NSMutableArray *)array{
    id importInfo =[self getDataFromJson:array[0]];
    EMChatText *txtChat = [[EMChatText alloc] initWithText:[importInfo objectForKey:@"textContent"]];
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithChatObject:txtChat];
    
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[importInfo objectForKey:@"to"] bodies:@[body]];
    message.from =[importInfo objectForKey:@"from"];
    message.timestamp = [[importInfo objectForKey:@"msgTime"] longLongValue];
    BOOL isGroup;
    if ([[importInfo objectForKey:@"chatType"] isEqual:@"1"]){
        isGroup = NO;
    }else if ([[importInfo objectForKey:@"chatType"] isEqual:@"2"]){
        isGroup = YES;
    }
    message.isGroup=isGroup;
    EMConversation *conversation;
    if([[importInfo objectForKey:@"sendType"] isEqual:@"1"]){
        conversation = [[EaseMob sharedInstance].chatManager conversationForChatter:[importInfo objectForKey:@"to"] isGroup:isGroup];
    }else {
        conversation = [[EaseMob sharedInstance].chatManager conversationForChatter:[importInfo objectForKey:@"from"] isGroup:isGroup];
    }
    
    [[EaseMob sharedInstance].chatManager insertMessageToDB:message];
 }
 */
 

/*
 78 onCallReceive(param)// 实时语音
	var param = {
	from:,//拨打方username
    callType:,
 '  callId,://本次通话的Id  新增参数
 
 
 
 '    callType包含以下3种情况
 eCallSessionTypeAudio=0
 eCallSessionTypeVideo=1,
 eCallSessionTypeContent=2,

 }
 79 onCallStateChanged(param)//设置通话状态监听
	var param = {
‘	state:,//1-正在连接对方，2-双方已经建立连接，3-同意语音申请，建立语音通话中，4-连接中断 5-电话暂停中 6-电话等待对方同意接听 7-通话中
'          // state 有变化
‘          例子：一个成功的语音通话流程为 ，A发送通话请求给B ==> AB建立语音通话连接 ==> B同意语音通话 ==> 开始语音通话
 
 
 }
 80 makeVoiceCall(param)//拨打语音通话
	var param = {
	username:,//
 }
 81 answerCall(param);//接听通话
    var param = {
    callId:,//通话Id
 }
 82 rejectCall(param);//拒绝接听
 var param = {
 callId:,//通话Id
 }
 83 endCall(param);//挂断通话
 var param = {
 callId:,//通话Id
 }

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
 84 sendCmdMessage(param)//发送透传消息
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
 85 onCmdMessageReceive(param)//透传消息监听
	var param = {
	msgId:,//
	message:,//EMMessage 对象json格式
	action:,//  ‘原文档为aciton 为笔误
 }
 */

- (void)didReceiveCmdMessage:(EMMessage *)cmdMessage{
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
 86 updateCurrentUserNickname(param)// 更新当前用户的昵称
	var param = {
	nickname:,// //此方法主要为了在苹果推送时能够推送昵称(nickname)而不是userid,一般可以在登陆成功后从自己服务器获取到个人信息，然后拿到nick更新到环信服务器。并且，在个人信息中如果更改个人的昵称，也要把环信服务器更新下nickname 防止显示差异。
 
 }
 */

-(void)updateCurrentUserNickname:(NSMutableArray *)array{
    id nickname =[self getDataFromJson:array[0]];
    
    [self.sharedInstance.chatManager setApnsNickname:[nickname objectForKey:@"nickname"]];
    
    
}





/*
 [New1] onGroupUpdateInfo(param)//
 var param={
 group:,//EMGroup对象的json格式字符串
 }
 //群组信息更新的回调
 //当添加/移除/更改角色/更改主题/更改群组信息之后,都会触发此回调
 */
- (void)groupDidUpdateInfo:(EMGroup *)group error:(EMError *)error{
    
    if(!error){
        NSDictionary *dict =[self convertEMGroupToDict:group];
        [self returnJSonWithName:@"onGroupUpdateInfo" dictionary:dict];
        
    }
}

/*
 [NEW2] getLogInfo()//获取当前登陆信息
 [NEW3] cbGetLogInfo(param)//获取当前登陆信息的回调
 var param={
 userInfo://当前登陆用户信息
 isLogged://当前是否已有登录用户
 isConnected://是否连上聊天服务器
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
    
    [self returnJSonWithName:@"cbGetLoginInfo" dictionary:dict];

}

/*
 
 [NEW4]registerRemoteNotification();//注册Apns推送
 [NEW5]cbRegisterRemoteNotification(param);//回调
 var param{
 result;//1-成功 2-失败
 errorInfo;//注册失败时的推送信息

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
 [NEW6]updatePushOptions（param);//设置apns全局属性
 var param{
 nickname;//昵称
 noDisturbStatus;//是否开启免打扰模式 1-开启 2-不开启
 noDisturbingStartH;//免打扰模式开始时间  小时（int）
 noDisturbingEndH;//免打扰模式结束时间  小时（int）
 }
 [NEW7]cbUpdatePushOptions（param);//设置apns全局属性回调
 var param{
 nickname;//昵称
noDisturbStatus;//是否开启免打扰模式 1-开启 2-不开启
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
 [NEW8]ignoreGroupPushNotification(param)://设置指定群组是否接收
	var param{
 groupId;//指定的群组Id
 isIgnore;//1-屏蔽  2-取消屏蔽
	}
 
 [NEW9]cbIgnoreGroupPushNotification(param)://回调
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
