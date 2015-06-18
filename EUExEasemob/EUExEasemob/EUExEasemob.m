//
//  EUExEasemob.m
//  AppCanPlugin
//
//  Created by AppCan on 15/3/17.
//  Copyright (c) 2015年 zywx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUExBase.h"
#import "EUExEasemob.h"
#import "uexEasemobManager.h"







@interface EUExEasemob()

@property (nonatomic,weak) uexEasemobManager *mgr;


@property (nonatomic,weak)EaseMob * sharedInstance;




@end


@implementation EUExEasemob



-(id)initWithBrwView:(EBrowserView *)eInBrwView{
    self=[super initWithBrwView:eInBrwView];
    if(self){
        self.mgr=[uexEasemobManager sharedInstance];
        self.sharedInstance=self.mgr.SDK;

        if(!self.sharedInstance){
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(initSettings)
                                                         name:@"uexEasemobInitSuccess"
                                                       object:nil];
        }
        
        
        if(_mgr.remoteLaunchDict){
            [self callBackJsonWithFunction:@"onApnsLaunch" parameter:_mgr.remoteLaunchDict];
            _mgr.remoteLaunchDict=nil;
        }
    }
    return  self;
}

-(void)clean{

}

-(void)dealloc{
    [self clean];
    
}
+(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    if (launchOptions) {
        [[uexEasemobManager sharedInstance] didFinishLaunchingWithOptions:(NSDictionary *)launchOptions];
    }
    return YES;
}
//从json字符串中获取数据
- (id)getDataFromJson:(NSString *)jsonData{
    NSError *error = nil;
    NSData *jsonData2= [jsonData dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData2
                                                    options:NSJSONReadingMutableContainers
                                                      error:&error];
    if (jsonObject != nil && error == nil){
        return jsonObject;
    }else{
        // 解析錯誤
        return nil;
    }
}

#pragma mark - Plugin Method






#pragma mark - initialization
-(void)initEasemob:(NSMutableArray *)inArguments{
    id initInfo =[self getDataFromJson:inArguments[0]];
    [_mgr initEasemobWithAppKey:[initInfo objectForKey:@"appKey"] apnsCertName:[initInfo objectForKey:@"apnsCertName"]];
    if([initInfo objectForKey:@"isAutoLoginEnabled"]){
        id autoLogin =[initInfo objectForKey:@"isAutoLoginEnabled"];
        if([autoLogin integerValue]==1 ){
            _mgr.isAutoLoginEnabled= YES;
        }else if([autoLogin integerValue]==2 ){
            _mgr.isAutoLoginEnabled= NO;
        }
    }
}



- (void)login:(NSMutableArray *)inArguments{
    id user =[self getDataFromJson:inArguments[0]];
    
    // 登录
    
    [self.sharedInstance.chatManager asyncLoginWithUsername:[user objectForKey:@"username"] password:[user objectForKey:@"password"] completion:^(NSDictionary *loginInfo, EMError *error) {
        //Block回调
        NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
        
        
        if (!error && loginInfo) {
            [dict setValue:@"1" forKey:@"result"];
            [dict setValue:@"登录成功" forKey:@"message"];
            _mgr.apnsOptions =[self.sharedInstance.chatManager pushNotificationOptions];
            [_sharedInstance.chatManager importDataToNewDatabase];
            [_sharedInstance.chatManager loadDataFromDatabase];
            [self callBackJsonWithFunction:@"onConnected" parameter:nil];
        }else{
            [dict setValue:@"2" forKey:@"result"];
            [dict setValue:@"登录失败" forKey:@"message"];
            
        }
        [self callBackJsonWithFunction:@"cbLogin" parameter:dict];
    } onQueue:nil];
}


 -(void)logout:(NSMutableArray *)inArguments{

     [self.sharedInstance.chatManager asyncLogoffWithUnbindDeviceToken:YES completion:^(NSDictionary *info, EMError *error) {
 
         NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
         if (!error && !info) {
 
 
             [dict setValue:@"1" forKey:@"result"];
             [dict setValue:@"登出成功" forKey:@"message"];
         }else{
             [dict setValue:@"2" forKey:@"result"];
             [dict setValue:@"登出失败" forKey:@"message"];;
         }
         [self callBackJsonWithFunction:@"cbLogout" parameter:dict];
 
     } onQueue:nil];
}

-(void)registerUser:(NSMutableArray *)inArguments{
    id user =[self getDataFromJson:inArguments[0]];
    if(user != nil){
        [self.sharedInstance.chatManager asyncRegisterNewAccount:[user objectForKey:@"username"]
                                                        password:[user objectForKey:@"password"]
                                                  withCompletion:^(NSString *username, NSString *password, EMError *error) {
                                                      NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
                                                      if (!error) {
                                                          [dict setValue:@"1" forKey:@"result"];
                                                          [dict setValue:@"注册成功" forKey:@"msg"];
                                                      }else{
                                                          [dict setValue:@"2" forKey:@"result"];
                                                          [dict setValue:@"注册失败" forKey:@"msg"];
                                                      }
                                                      
                                                      
                                                      [self callBackJsonWithFunction:@"cbRegisterUser" parameter:dict];
                                                  } onQueue:nil];
    }
}


-(void)updateCurrentUserNickname:(NSMutableArray *)inArguments{
    id nickname =[self getDataFromJson:inArguments[0]];
    
    [self.sharedInstance.chatManager setApnsNickname:[nickname objectForKey:@"nickname"]];
    
    
}


-(void)getLoginInfo:(NSMutableArray *)inArguments{
    
    NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:3];
    
    
    
    
    [dict setValue:(self.sharedInstance.chatManager.isConnected?@"1":@"2")   forKey:@"isConnected"];
    [dict setValue:(self.sharedInstance.chatManager.isLoggedIn?@"1":@"2")  forKey:@"isLoggedIn"];
    if(self.sharedInstance.chatManager.isLoggedIn){
        NSMutableDictionary *userInfo = [self.sharedInstance.chatManager.loginInfo mutableCopy];
        
        
        if ([_mgr.apnsOptions.nickname length]>0){
            [userInfo setValue:_mgr.apnsOptions.nickname  forKey:@"nickname"];
        }
        
        
        
        
        
        [dict setValue:userInfo  forKey:@"userInfo"];
    }
    NSString *autologgin = self.sharedInstance.chatManager.isAutoLoginEnabled?@"1":@"2";
    [dict setValue:autologgin  forKey:@"isAutoLoginEnabled"];
    [self callBackJsonWithFunction:@"cbGetLoginInfo" parameter:dict];
    
}



-(EMMessageType)getMsgType:(id)info{
    EMMessageType type = eMessageTypeChat;
    if([[info objectForKey:@"chatType"] integerValue]==1){
        type = eMessageTypeGroupChat;
    }
    if([[info objectForKey:@"chatType"] integerValue]==2){
        type = eMessageTypeChatRoom;
    }
    
    return type;
}



#pragma mark - Message

-(void)sendText:(NSMutableArray *)inArguments{
    
    
    id info =[self getDataFromJson:inArguments[0]];

    
    EMChatText *txtChat = [[EMChatText alloc] initWithText:[info objectForKey:@"content"]];
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithChatObject:txtChat];
    
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[info objectForKey:@"username"] bodies:@[body]];

    if([[info objectForKey:@"ext"] isKindOfClass:[NSString class]]){
        message.ext=[NSDictionary dictionaryWithObject:[info objectForKey:@"ext"] forKey:@"uexExtraString"];
    }
    message.messageType=[self getMsgType:info];

    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
    

    
}

-(void)sendVoice:(NSMutableArray *)inArguments{
    
    id info =[self getDataFromJson:inArguments[0]];

    
    EMChatVoice *voiceChat = [[EMChatVoice alloc] initWithFile:[self absPath:[info objectForKey:@"filePath"]] displayName:[info objectForKey:@"displayName"]];
    
    if([info objectForKey:@"length"]){
        voiceChat.duration=[[info objectForKey:@"length"] integerValue];
    }
    EMVoiceMessageBody *body = [[EMVoiceMessageBody alloc] initWithChatObject:voiceChat];
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[info objectForKey:@"username"] bodies:@[body]];

    
    
    if([[info objectForKey:@"ext"] isKindOfClass:[NSString class]]){
        message.ext=[NSDictionary dictionaryWithObject:[info objectForKey:@"ext"] forKey:@"uexExtraString"];
    }
    message.messageType=[self getMsgType:info];

    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
    



    
}

-(void)sendPicture:(NSMutableArray *)inArguments{
    
    id info =[self getDataFromJson:inArguments[0]];

    UIImage  *img = [UIImage imageWithContentsOfFile:[self absPath:[info objectForKey:@"filePath"]]];
    
    EMChatImage *imgChat = [[EMChatImage alloc] initWithUIImage:img displayName:[info objectForKey:@"displayName"]];
    EMImageMessageBody *body = [[EMImageMessageBody alloc] initWithChatObject:imgChat];
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[info objectForKey:@"username"] bodies:@[body]];

    
    if([[info objectForKey:@"ext"] isKindOfClass:[NSString class]]){
        message.ext=[NSDictionary dictionaryWithObject:[info objectForKey:@"ext"] forKey:@"uexExtraString"];
    }
    message.messageType=[self getMsgType:info];

    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
    
}

-(void)sendLocationMsg:(NSMutableArray *)inArguments{
    
    id info =[self getDataFromJson:inArguments[0]];

    
    EMChatLocation *locChat = [[EMChatLocation alloc] initWithLatitude:[[info objectForKey:@"latitude"] doubleValue] longitude:[[info objectForKey:@"longtitude"] doubleValue] address:[info objectForKey:@"locationAddress"]];
    EMLocationMessageBody *body = [[EMLocationMessageBody alloc] initWithChatObject:locChat];
    
    
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[info objectForKey:@"username"] bodies:@[body]];
    message.messageType=[self getMsgType:info];
    if([[info objectForKey:@"ext"] isKindOfClass:[NSString class]]){
        message.ext=[NSDictionary dictionaryWithObject:[info objectForKey:@"ext"] forKey:@"uexExtraString"];
    }
    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息
   }

-(void)sendFile:(NSMutableArray *)inArguments{
    
    id info =[self getDataFromJson:inArguments[0]];

    
    
    EMChatFile *fileChat = [[EMChatFile alloc] initWithFile:[self absPath:[info objectForKey:@"filePath"]] displayName:[info objectForKey:@"displayName"]];
    EMFileMessageBody *body = [[EMFileMessageBody alloc] initWithChatObject:fileChat];
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:[info objectForKey:@"username"] bodies:@[body]];
    
    if([[info objectForKey:@"ext"] isKindOfClass:[NSString class]]){
        message.ext=[NSDictionary dictionaryWithObject:[info objectForKey:@"ext"] forKey:@"uexExtraString"];
    }
    message.messageType=[self getMsgType:info];
    [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息

}

-(void) setNotifyBySoundAndVibrate:(NSMutableArray *)inArguments {
    
    id notifyInfo = [self getDataFromJson:inArguments[0]];
    
    if ([[notifyInfo objectForKey:@"enable"] integerValue]==0){
        _mgr.messageNotification = NO;
    }else if([[notifyInfo objectForKey:@"enable"] integerValue]==1){
        _mgr.messageNotification = YES;
    }
    
    if ([[notifyInfo objectForKey:@"soundEnable"] integerValue]==0){
        _mgr.isPlaySound = NO;
    }else if([[notifyInfo objectForKey:@"soundEnable"] integerValue]==1){
        _mgr.isPlaySound = YES;
    }
    if ([[notifyInfo objectForKey:@"vibrateEnable"] integerValue]==0){
        _mgr.isPlayVibration = NO;
    }else if([[notifyInfo objectForKey:@"vibrateEnable"] integerValue]==1){
        _mgr.isPlayVibration = YES;
    }
#warning useSpeaker
    if ([[notifyInfo objectForKey:@"userSpeaker"] integerValue]==0){
        _mgr.useSpeaker=NO;
    }else if([[notifyInfo objectForKey:@"userSpeaker"] integerValue]==1){
        _mgr.useSpeaker=YES;
    }
    if ([[notifyInfo objectForKey:@"deliveryNotification"] integerValue]==0){
        [self.sharedInstance.chatManager disableDeliveryNotification];
    }else if([[notifyInfo objectForKey:@"deliveryNotification"] integerValue]==1){
        [self.sharedInstance.chatManager enableDeliveryNotification];
    }
    
    //NSLog(@"SetNotifyBySoundAndVibrate");
    
}



-(EMMessage *)getMessage:(NSString *)msgId{

    

    EMConversation *conversation = [self.sharedInstance.chatManager conversationForChatter:@"appcan" conversationType:eConversationTypeChat];
    EMMessage *message = [conversation loadMessageWithId:msgId];
    return message;
}


-(void)getMessageById:(NSMutableArray *)inArguments{
    
    
    id info =[self getDataFromJson:inArguments[0]];
    if ([info objectForKey:@"msgId"]){
        EMMessage *msg=[self getMessage:[info objectForKey:@"msgId"]];
        NSDictionary *messageDict=[_mgr analyzeEMMessage:msg];
        [self callBackJsonWithFunction:@"cbGetMessageById" parameter:messageDict];
    }
    
}
 

 -(void)sendVideo:(NSMutableArray *)inArguments{
 
     id info =[self getDataFromJson:inArguments[0]];

 
     EMChatVideo *videoChat = [[EMChatVideo alloc] initWithFile:[self absPath:[info objectForKey:@"filePath"]] displayName:[info objectForKey:@"displayName"]];
 
     if([info objectForKey:@"length"]){
         videoChat.duration=[[info objectForKey:@"length"] integerValue];
     }
     EMVideoMessageBody *body = [[EMVideoMessageBody alloc] initWithChatObject:videoChat];
     // 生成message
     EMMessage *message = [[EMMessage alloc] initWithReceiver:[info objectForKey:@"username"] bodies:@[body]];

 
 
 
     if([[info objectForKey:@"ext"] isKindOfClass:[NSString class]]){
         message.ext=[NSDictionary dictionaryWithObject:[info objectForKey:@"ext"] forKey:@"uexExtraString"];
     }
 
     message.messageType=[self getMsgType:info];
     [self.sharedInstance.chatManager asyncSendMessage:message progress:nil];//异步方法发送消息

 
 
 
 
}




-(void)sendHasReadResponseForMessage:(NSMutableArray *)inArguments{
    
    
    id info =[self getDataFromJson:inArguments[0]];
    if ([info objectForKey:@"msgId"]){
        EMMessage *msg=[self getMessage:[info objectForKey:@"msgId"]];
        [_sharedInstance.chatManager sendReadAckForMessage:msg];
    }
    
}

#pragma mark - Conversation

-(EMConversationType)parseConversationType:(NSDictionary *)dataDict{
    EMConversationType type=eConversationTypeChat;
    if([[dataDict objectForKey:@"chatType"] integerValue]==2 ){
        type=eConversationTypeChatRoom;
    }else if([[dataDict objectForKey:@"chatType"] integerValue]==0 ){
        type=eConversationTypeChat;
    }else if([[dataDict objectForKey:@"isGroup"] integerValue]==1 ||[[dataDict objectForKey:@"chatType"] integerValue]==1){
        type=eConversationTypeGroupChat;
    }
    return type;
    
}

-(EMConversation *) getConversation:(NSMutableArray *)inArguments{
    //获取conversation
    
    
    id conversationData =[self getDataFromJson:inArguments[0]];
    
    //回调
    if (conversationData != nil){

        EMConversation *conversation = [self.sharedInstance.chatManager conversationForChatter:[conversationData objectForKey:@"username"] conversationType:[self parseConversationType:conversationData]];
        return conversation;
    }
    else {
        return nil;
    }
    
}
-(void) getConversationByName:(NSMutableArray *)inArguments{
    
    EMConversation *conversation =[self getConversation:inArguments];
    
    [self cbGetConversationByName:conversation];
}


-(void)cbGetConversationByName:(EMConversation *)conversation{
    
    NSDictionary *dict =[_mgr analyzeEMConversation:conversation];
    
    [self callBackJsonWithFunction:@"cbGetConversationByName" parameter:dict];
    
}


-(void)getMessageHistory:(NSMutableArray *)inArguments{
    id info =[self getDataFromJson:inArguments[0]];
    NSString *username = [info objectForKey:@"username"];
    if(!username) return;
    EMConversation *conversation =[self getConversation:inArguments];
    if(!conversation) return;
    NSString *startMsgId = [info objectForKey:@"startMsgId"];
    NSMutableArray *msgList =[NSMutableArray array];
    NSArray *messages;
    if([startMsgId length]>0){
        NSInteger  pagesize=[[info objectForKey:@"pagesize"] integerValue];
        messages = [conversation loadNumbersOfMessages:pagesize withMessageId:startMsgId];
    }else{
        messages = [conversation loadAllMessages];
       

    }
    
    for(EMMessage *msg in messages){
        
        [msgList addObject:[_mgr analyzeEMMessage:msg]];
        
        
    }
    [self callBackJsonWithFunction:@"cbGetMessageHistory" parameter:@{@"messages":msgList}];
    
    
}







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

-(void)getUnreadMsgCount:(NSMutableArray *)inArguments{
    
    EMConversation *conversation =[self getConversation:inArguments];
    NSUInteger unreadMessageCount =[conversation unreadMessagesCount];
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:[NSString stringWithFormat:@"%lu",(unsigned long)unreadMessageCount] forKey:@"count"];
    
    [self callBackJsonWithFunction:@"cbGetUnreadMsgCount" parameter:dict];
    
}

/*
 #####[3.7]resetUnreadMsgCount(param)//指定会话未读消息数清零
 var param = {
 
	username:,//username|groupid
 isGroup:,//是否为群组 1-是 2-否(仅iOS需要)
 }
 */
-(void)resetUnreadMsgCount:(NSMutableArray *)inArguments{
    EMConversation *conversation =[self getConversation:inArguments];
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
-(void)deleteConversation:(NSMutableArray *)inArguments{
    EMConversation *conversation =[self getConversation:inArguments];
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
-(void)removeMessage:(NSMutableArray*)inArguments{
    id conversationData =[self getDataFromJson:inArguments[0]];

    EMConversation *conversation = [self.sharedInstance.chatManager conversationForChatter:[conversationData objectForKey:@"username"] conversationType:[self parseConversationType:conversationData]];
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

-(void) getChatterInfo:(NSMutableArray *)inArguments{
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
        EMConversation *conversation = [self.sharedInstance.chatManager conversationForChatter:username conversationType:eConversationTypeChat];
        [chatter setValue:[_mgr analyzeEMMessage:[conversation latestMessage]]  forKey:@"lastMsg"];
        [chatter setValue:[NSString stringWithFormat:@"%ld",(unsigned long)conversation.unreadMessagesCount] forKey:@"unreadMsgCount"];
        [chatter setValue:username forKey:@"chatter"];
        [chatter setValue:@"1" forKey:@"isGroup"];
        [chatter setValue:@"1" forKey:@"chatType"];
        [result addObject:chatter];
    }
    for(EMGroup *group in grouplist){
        NSMutableDictionary *chatter =[NSMutableDictionary dictionary];
        EMConversation *conversation = [self.sharedInstance.chatManager conversationForChatter:group.groupId conversationType:eConversationTypeGroupChat];
        [chatter setValue:[_mgr analyzeEMMessage:[conversation latestMessage]]  forKey:@"lastMsg"];
        [chatter setValue:[NSString stringWithFormat:@"%ld",(unsigned long)conversation.unreadMessagesCount] forKey:@"unreadMsgCount"];
        [chatter setValue:group.groupId forKey:@"chatter"];
        [chatter setValue:group.groupSubject forKey:@"groupName"];
        [chatter setValue:@"0" forKey:@"isGroup"];
        [chatter setValue:@"0" forKey:@"chatType"];
        [result addObject:chatter];
    }
    
    
    [self callBackJsonWithFunction:@"cbGetChatterInfo" parameter:result];
    
#warning chatroom待添加
}



-(void)getTotalUnreadMsgCount:(NSMutableArray *)inArguments{
    NSInteger count =[self.sharedInstance.chatManager loadTotalUnreadMessagesCountFromDatabase];
    NSDictionary *result = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%ld",(long)count] forKey:@"count"];
    [self callBackJsonWithFunction:@"cbGetTotalUnreadMsgCount" parameter:result];
    
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

/*
 #####[4.4]onContactAgreed(param)//好友请求被同意
 var param = {
 
	username:,//
 };
 
 */

 /*
 #####[4.5]onContactRefused(param)//好友请求被拒绝
 var param = {
 
	username:,//
 };
  */

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
            [self callBackJsonWithFunction:@"cbGetContactUserNames" parameter:usernames];

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
-(void) addContact:(NSMutableArray *)inArguments{
    id contactInfo =[self getDataFromJson:inArguments[0]];
    
    
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
-(void) deleteContact:(NSMutableArray *)inArguments{
    id contactInfo =[self getDataFromJson:inArguments[0]];
    
    
    
    EMError *error = nil;
    // 删除好友
    BOOL isSuccess = [self.sharedInstance.chatManager removeBuddy:[contactInfo objectForKey:@"username"] removeFromRemote:YES error:&error];
    if (isSuccess && !error) {
        //NSLog(@"删除成功");
    }
}

-(void) acceptInvitation:(NSMutableArray *)inArguments{
    id contactInfo =[self getDataFromJson:inArguments[0]];
    
    EMError *error = nil;
    BOOL isSuccess = [self.sharedInstance.chatManager acceptBuddyRequest:[contactInfo objectForKey:@"username"] error:&error];
    if (isSuccess && !error) {
        //NSLog(@"发送同意成功");
    }
}

-(void) refuseInvitation:(NSMutableArray *)inArguments{
    id contactInfo =[self getDataFromJson:inArguments[0]];
    
    
    EMError *error = nil;
    BOOL isSuccess = [self.sharedInstance.chatManager rejectBuddyRequest:[contactInfo objectForKey:@"username"] reason:[contactInfo objectForKey:@"reason"] error:&error];
    if (isSuccess && !error) {
       // NSLog(@"发送拒绝成功");
    }
}

-(void) getBlackListUsernames:(NSMutableArray *)inArguments{
    NSArray * BlockedList=[self.sharedInstance.chatManager fetchBlockedList:nil];
    
    [self cbGetBlackListUsernames:BlockedList];
    
}

-(void) cbGetBlackListUsernames:(NSArray *)blockedList{
    
    [self callBackJsonWithFunction:@"cbGetBlackListUsernames" parameter:blockedList];
    
}


-(void) addUserToBlackList:(NSMutableArray *)inArguments{
    
    id contactInfo =[self getDataFromJson:inArguments[0]];
    EMError *error = [self.sharedInstance.chatManager blockBuddy:[contactInfo objectForKey:@"username"] 	relationship:eRelationshipBoth];
    if (!error) {
        //   NSLog(@"发送成功");
    }
}


-(void) deleteUserFromBlackList:(NSMutableArray *)inArguments{
    
    id contactInfo =[self getDataFromJson:inArguments[0]];
    EMError *error = [self.sharedInstance.chatManager unblockBuddy:[contactInfo objectForKey:@"username"]];
    if (!error) {
        //   NSLog(@"发送成功");
    }
}

#pragma mark - Group


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

-(void) createPrivateGroup:(NSMutableArray *)inArguments{

    id groupInfo = [self getDataFromJson:inArguments[0]];
    
    
    EMError *error = nil;
    EMGroupStyleSetting *groupStyleSetting = [[EMGroupStyleSetting alloc] init];
    
    NSInteger userNumber=[[groupInfo objectForKey:@"maxUsers"] integerValue];
    if (userNumber > 0){
        groupStyleSetting.groupMaxUsersCount = userNumber;
    }
    if ([[groupInfo objectForKey:@"allowInvite"] isEqual:@"true"] || [[groupInfo objectForKey:@"allowInvite"] integerValue] == 1){  /// 创建不同类型的群组，这里需要才传入不同的类型
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
 initialWelcomeMessage://群组创建时发送给每个初始成员的欢迎信息（仅iOS）
 }
 */
-(void) createPublicGroup:(NSMutableArray *)inArguments{
    id groupInfo = [self getDataFromJson:inArguments[0]];
    
    
    EMError *error = nil;
    EMGroupStyleSetting *groupStyleSetting = [[EMGroupStyleSetting alloc] init];
    
    NSInteger userNumber=[[groupInfo objectForKey:@"maxUsers"] integerValue];
    if (userNumber > 0){
        groupStyleSetting.groupMaxUsersCount = userNumber;
    }
    if ([[groupInfo objectForKey:@"allowInvite"] isEqual:@"true"] || [[groupInfo objectForKey:@"allowInvite"] boolValue] == YES){  /// 创建不同类型的群组，这里需要才传入不同的类型
        groupStyleSetting.groupStyle = eGroupStyle_PublicOpenJoin;  //所有群成员都可以邀请非成员进群
    }else{
        groupStyleSetting.groupStyle = eGroupStyle_PublicJoinNeedApproval;  //有创建者可以邀请非成员进群
    }
    [self.sharedInstance.chatManager createGroupWithSubject:[groupInfo objectForKey:@"groupName"] description:[groupInfo objectForKey:@"desc"] invitees:[groupInfo objectForKey:@"members"] initialWelcomeMessage:[groupInfo objectForKey:@"initialWelcomeMessage"] styleSetting:groupStyleSetting error:&error];
    if(!error){
        // NSLog(@"创建成功 -- %@",group);
    }

}
 

  -(void)addUsersToGroup:(NSMutableArray *)inArguments{
  id groupInfo = [self getDataFromJson:inArguments[0]];
  
  
  [self.sharedInstance.chatManager asyncAddOccupants:[groupInfo objectForKey:@"newmembers"] toGroup:[groupInfo objectForKey:@"groupId"] welcomeMessage:[groupInfo objectForKey:@"inviteMessage"]];
  
  }
 
 /*
 #####[5.10]removeUserFromGroup(param)//群聊减人
 var param = {
 
	groupId://
	username://
 }
  */

-(void) removeUserFromGroup:(NSMutableArray *)inArguments{
    id removeUser =[self getDataFromJson:inArguments[0]];
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
-(void) joinGroup:(NSMutableArray *)inArguments{
    id joinGroupInfo =[self getDataFromJson:inArguments[0]];
    
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
-(void) exitFromGroup:(NSMutableArray *)inArguments{
    
    id exitInfo =[self getDataFromJson:inArguments[0]];
    
    
    
    
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

-(void) exitAndDeleteGroup:(NSMutableArray *)inArguments{
    
    
    id exitAndDeleteInfo =[self getDataFromJson:inArguments[0]];
    
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
-(void) getGroupsFromServer:(NSMutableArray *)inArguments{
    
    id getGroup =[self getDataFromJson:inArguments[0]];
    

    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:2];
    NSArray *groups;
    NSMutableArray *grouplist=[NSMutableArray arrayWithCapacity:10] ;
    
    if ([[getGroup objectForKey:@"loadCache"] isEqual:@"true"]||[[getGroup objectForKey:@"loadCache"] integerValue] ==1){
        [dict setValue:@"0" forKey:@"result"];
        groups = [self.sharedInstance.chatManager loadAllMyGroupsFromDatabaseWithAppend2Chat:YES];
        
        for (EMGroup  *group in groups){
            [grouplist addObject:[_mgr analyzeEMGroup:group]];
        }
        [dict setValue:grouplist forKey:@"grouplist"];
        
    }else{
        
        [self.sharedInstance.chatManager asyncFetchMyGroupsListWithCompletion:^(NSArray *groups, EMError *error) {
            if (!error) {
                [dict setValue:@"0" forKey:@"result"];
                for (EMGroup  *group in groups){
                    [grouplist addObject:[_mgr analyzeEMGroup:group]];
                }
                [dict setValue:grouplist forKey:@"grouplist"];
                
            }else{
                [dict setValue:@"1" forKey:@"result"];
            }
            [self callBackJsonWithFunction:@"cbGetGroupsFromServer" parameter:dict];
        } onQueue:nil];
       
    }
    
    
    
    
}
/*
 
 #####[5.16]getAllPublicGroupsFromServer();//获取所有公开群列表
 #####[5.17]cbGetAllPublicGroupsFromServer(param)//获取所有公开群列表回调

 */
-(void) getAllPublicGroupsFromServer:(NSMutableArray*)inArguments{
  /*
   - (void)asyncFetchPublicGroupsFromServerWithCursor:(NSString *)cursor
   pageSize:(NSInteger)pageSize
   andCompletion:(void (^)(EMCursorResult *result, EMError *error))completion;
   
   */
    
    
    NSInteger pageSize=-1;
    NSString *cursor=nil;
    if([inArguments count]>0){
        id info =[self getDataFromJson:inArguments[0]];
        if([info objectForKey:@"pageSize"]&&[[info objectForKey:@"pageSize"] length]>0) pageSize=[[info objectForKey:@"pageSize"] integerValue];
        if([info objectForKey:@"cursor"] &&[[info objectForKey:@"cursor"] length]>0) cursor=[info objectForKey:@"cursor"];
    }
    dispatch_queue_t queue = dispatch_queue_create("gcd.uexEasemobFetchPublicGroupsQueue",NULL);
    dispatch_async(queue,^{
        [self.sharedInstance.chatManager asyncFetchPublicGroupsFromServerWithCursor:cursor pageSize:pageSize andCompletion:^(EMCursorResult *result, EMError *error) {
            NSMutableDictionary *dict =[NSMutableDictionary dictionary];
            if(error){
                [dict setValue:@"1" forKey:@"result"];
                [dict setValue:error.description forKey:@"errorMsg"];
            }else{
                [dict setValue:@"0" forKey:@"result"];
                NSMutableArray *grouplist =[NSMutableArray array];
                for(EMGroup *group in result.list){
                    [grouplist addObject:[_mgr analyzeEMGroup:group]];
                }
                [dict setValue:grouplist forKey:@"grouplist"];
                [dict setValue:result.cursor forKey:@"cursor"];
            }
            [self callBackJsonWithFunction:@"cbGetAllPublicGroupsFromServer" parameter:dict];
        }];
    });

    //[self.sharedInstance.chatManager asyncFetchAllPublicGroups];
    
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
-(void)getGroup:(NSMutableArray *)inArguments{
    id groupInfo =[self getDataFromJson:inArguments[0]];
    [self.sharedInstance.chatManager asyncFetchGroupInfo:[groupInfo objectForKey:@"groupId"]
                                              completion:^(EMGroup *group, EMError *error){
                                                  [self cbGetGroup:group error:error];
                                              } onQueue:nil];
}

- (void)cbGetGroup:(EMGroup *)group
             error:(EMError *)error{
    NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:1];
    if(!error){
        [dict setValue:[_mgr analyzeEMGroup:group] forKey:@"group"];
        [self callBackJsonWithFunction:@"cbGetGroup" parameter:dict];
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
-(void) blockGroupMessage:(NSMutableArray *)inArguments{
    id groupInfo =[self getDataFromJson:inArguments[0]];
    EMError *pError = nil;
    [self.sharedInstance.chatManager blockGroup:[groupInfo objectForKey:@"groupId"] error:&pError];
    
}
-(void) unblockGroupMessage:(NSMutableArray *)inArguments{
    id groupInfo =[self getDataFromJson:inArguments[0]];
    EMError *pError = nil;
    [self.sharedInstance.chatManager unblockGroup:[groupInfo objectForKey:@"groupId"] error:&pError];
    
}

/*
 #####[5.22]changeGroupName(param)//修改群组名称
 var param = {
 
	groupId://
	changedGroupName:,//改变后的群组名称
 }
 */
-(void) changeGroupName:(NSMutableArray *)inArguments{
    
    id groupInfo =[self getDataFromJson:inArguments[0]];
    
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


-(void) makeVoiceCall:(NSMutableArray *)inArguments{
    id callInfo =[self getDataFromJson:inArguments[0]];
    EMError *error;
    _mgr.callSession=[self.sharedInstance.callManager asyncMakeVoiceCall:[callInfo objectForKey:@"username"] timeout:50 error:&error];
}


-(void) answerCall:(NSMutableArray *)inArguments{
    
    
    [self.sharedInstance.callManager asyncAnswerCall:_mgr.callSession.sessionId];
}

-(void) rejectCall:(NSMutableArray *)inArguments{
    
    [self.sharedInstance.callManager asyncEndCall:_mgr.callSession.sessionId reason:eCallReason_Reject];
}

-(void) endCall:(NSMutableArray *)inArguments{
    
    [self.sharedInstance.callManager asyncEndCall:_mgr.callSession.sessionId reason:eCallReason_Hangup];
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
-(void)registerRemoteNotification:(NSMutableArray *)inArguments{
    UIApplication *application = [UIApplication sharedApplication];
    application.applicationIconBadgeNumber = 0;
    
    if([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationType notificationTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    
#if !TARGET_IPHONE_SIMULATOR

    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        [application registerForRemoteNotifications];
    }else{
        UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeBadge |
        UIRemoteNotificationTypeSound |
        UIRemoteNotificationTypeAlert;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
    }
#endif
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(EasemobAPNsFail:) name:@"EasemobAPNsFail" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(EasemobAPNsSucceed:) name:@"EasemobAPNsSucceed" object:nil];
    
}

-(void)EasemobAPNsSucceed:(NSNotification *)notif{
    NSData *deviceToken = [notif.userInfo objectForKey:@"deviceToken"];
    [_sharedInstance application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@"1" forKey:@"result"];
    [self callBackJsonWithFunction:@"cbRegisterRemoteNotification" parameter:dict];
}
-(void)EasemobAPNsFail:(NSNotification *)notif{
    NSError *error =[notif.userInfo objectForKey:@"error"];
    [_sharedInstance application:[UIApplication sharedApplication] didFailToRegisterForRemoteNotificationsWithError:error];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@"2" forKey:@"result"];
    [dict setValue:error forKey:@"errorInfo"];
    [self callBackJsonWithFunction:@"cbRegisterRemoteNotification" parameter:dict];
}

// 将得到的deviceToken传给SDK
+ (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:deviceToken forKey:@"deviceToken"];

    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EasemobAPNsSucceed" object:nil userInfo:dict];
    
}

// 注册deviceToken失败
+ (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:error forKey:@"error"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EasemobAPNsFail" object:nil userInfo:dict];

    
}


-(void)updatePushOptions:(NSMutableArray *)inArguments{
    
    id info = [self getDataFromJson:inArguments[0]];
    if([[info objectForKey:@"nickname"] length]>0){
        _mgr.apnsOptions.nickname =[info objectForKey:@"nickname"];
    }
    if([[info objectForKey:@"displayStyle"] length]>0){
        NSInteger displayStyle=[[info objectForKey:@"displayStyle"] integerValue];
        if(displayStyle == 0){
            _mgr.apnsOptions.displayStyle=ePushNotificationDisplayStyle_simpleBanner;
        }else if(displayStyle == 1){
            _mgr.apnsOptions.displayStyle=ePushNotificationDisplayStyle_messageSummary;
        }
        
    }
    if([[info objectForKey:@"noDisturbingStyle"] length]>0 ){
        NSInteger noDisturbingStyle =[[info objectForKey:@"noDisturbingStyle"] integerValue];
        if(noDisturbingStyle== 0){
            _mgr.apnsOptions.noDisturbStatus =ePushNotificationNoDisturbStatusDay ;
        }else if(noDisturbingStyle== 1){
            _mgr.apnsOptions.noDisturbStatus =ePushNotificationNoDisturbStatusCustom;
        }else if(noDisturbingStyle== 2){
            _mgr.apnsOptions.noDisturbStatus =ePushNotificationNoDisturbStatusClose;
        }
    }
    if([[info objectForKey:@"noDisturbingStartH"] length]>0){
        _mgr.apnsOptions.noDisturbingStartH =[[info objectForKey:@"noDisturbingStartH"] integerValue];
    }
    if([[info objectForKey:@"noDisturbingEndH"] length]>0){
        _mgr.apnsOptions.noDisturbingEndH =[[info objectForKey:@"noDisturbingEndH"] integerValue];
    }
    
    [self.sharedInstance.chatManager asyncUpdatePushOptions:_mgr.apnsOptions];
}










#pragma mark - private method
-(void) callBackJsonWithFunction:(NSString *)functionName parameter:(id)obj{
    [_mgr callBackJsonWithFunction:functionName parameter:obj];
}

-(void)initSettings{
    self.mgr=[uexEasemobManager sharedInstance];
    self.sharedInstance=self.mgr.SDK;

    _mgr.apnsOptions=self.mgr.apnsOptions;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"uexEasemobInitSuccess" object:nil];
}





@end
