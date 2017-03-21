//
//  EUExEasemob.m
//  AppCanPlugin
//
//  Created by AppCan on 15/3/17.
//  Copyright (c) 2015年 zywx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUExEasemob.h"
#import "uexEasemobManager.h"
//#import "EMCursorResult.h"
#import <AppCanKit/ACEXTScope.h>






@interface EUExEasemob()
@property (nonatomic,readonly)uexEasemobManager *mgr;
@property (nonatomic,readonly)EMClient * sharedClient;
@end




@implementation EUExEasemob

static NSDictionary *apnsLaunchInfo = nil;
static NSString *const kUexEasemobUserDefaultsAPNSUsageKey = @"kUexEasemobUserDefaultsAPNSUsageKey";

- (EMClient *)sharedClient{
    return [uexEasemobManager sharedManager].SDK;
}

- (uexEasemobManager *)mgr{
    return [uexEasemobManager sharedManager];
}

- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine{
    self = [super initWithWebViewEngine:engine];
    if (self) {
    }
    return self;
}
- (void)clean{

}

- (void)dealloc{

    [self clean];
    
}




+ (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    apnsLaunchInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];

    return YES;
}


+ (void)rootPageDidFinishLoading{
    if (!apnsLaunchInfo || ![[NSUserDefaults standardUserDefaults]boolForKey:kUexEasemobUserDefaultsAPNSUsageKey]) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[uexEasemobManager sharedManager] callbackWithFunctionName:@"onApnsLaunch" obj:apnsLaunchInfo];
        apnsLaunchInfo = nil;

    });
}

#pragma mark - Plugin Method






#pragma mark - initialization
- (void)initEasemob:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *appKey = stringArg(info[@"appKey"]);
    
    EMOptions *options = [EMOptions optionsWithAppkey:appKey];
    options.usingHttpsOnly = YES;
    if (ACLogGlobalLogMode & ACLogLevelDebug) {
        options.logLevel = EMLogLevelDebug;
        options.enableConsoleLog = YES;
    }else{
        options.logLevel = EMLogLevelWarning;
    }
    options.apnsCertName = stringArg(info[@"apnsCertName"]);
    options.isAutoLogin = (numberArg(info[@"isAutoLoginEnabled"]).integerValue != 2);
    options.isAutoAcceptGroupInvitation = (numberArg(info[@"isAutoAcceptGroupInvitation"]).integerValue != 2);
    
    EMError *error = [self.mgr initializeEasemobWithOptions:options];
    if (error) {
        UEX_LOG_ERROR(error);
    }

}

- (void)registerCallback:(NSMutableArray *)inArguments{
    [self.mgr registerCallback:self.webViewEngine];
}

- (void)unRegisterCallback:(NSMutableArray *)inArguments{
    [self.mgr unregisterCallback:self.webViewEngine];
}

- (void)login:(NSMutableArray *)inArguments{
    

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
        NSString *username = stringArg(info[@"username"]);
        NSString *password = stringArg(info[@"password"]);
        EMError *error = [self.sharedClient loginWithUsername:username password:password];
        NSDictionary *dict = [NSMutableDictionary dictionary];

        if (error) {
            [dict setValue:@2 forKey:@"result"];
            [dict setValue:[NSString stringWithFormat:@"登录失败<%d>: %@",error.code,error.errorDescription] forKey:@"msg"];
            UEX_LOG_ERROR(error);
        }else{
            [dict setValue:@1 forKey:@"result"];
            [dict setValue:@"登录成功" forKey:@"msg"];
        }
        [self callbackWithFunctionName:@"cbLogin" obj:dict];
        [cb executeWithArguments:ACArgsPack(dict)];

    });
}



 - (void)logout:(NSMutableArray *)inArguments{
     ACArgsUnpack(ACJSFunctionRef *cb) = inArguments;
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
         EMError *error = [self.sharedClient logout:YES];
         NSMutableDictionary *dict = [NSMutableDictionary dictionary];
         UEX_ERROR err = kUexNoError;
         if (!error) {
             [dict setValue:@1 forKey:@"result"];
             [dict setValue:@"登出成功" forKey:@"message"];
         }else{
             [dict setValue:@2 forKey:@"result"];
             err = uexErrorMake(error.code,error.errorDescription);
             [dict setValue:[NSString stringWithFormat:@"登出失败<%d>: %@",error.code,error.errorDescription] forKey:@"msg"];
         }
         [self callbackWithFunctionName:@"cbLogin" obj:dict];
         [cb executeWithArguments:ACArgsPack(err)];

     });
}

- (void)registerUser:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSString *userName = stringArg(info[@"username"]);
        NSString *password = stringArg(info[@"password"]);
        EMError *error = [self.sharedClient registerWithUsername:userName password:password];
        UEX_ERROR err = kUexNoError;
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        if (!error) {
            [dict setValue:@1 forKey:@"result"];
            [dict setValue:@"注册成功" forKey:@"msg"];
        }else{
            err = uexErrorMake(error.code,error.errorDescription);
            [dict setValue:@2 forKey:@"result"];
            [dict setValue:[NSString stringWithFormat:@"注册失败<%d>:%@",error.code,error.errorDescription] forKey:@"msg"];
        }
        [self callbackWithFunctionName:@"cbRegisterUser" obj:dict];
        [cb executeWithArguments:ACArgsPack(dict)];
    });
    
}


- (void)updateCurrentUserNickname:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self.sharedClient setApnsNickname:stringArg(info[@"nickname"])];
    });
    
}


- (void)getLoginInfo:(NSMutableArray *)inArguments{
    ACArgsUnpack(ACJSFunctionRef *cb) = inArguments;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:(self.sharedClient.isConnected ? @1 : @2)   forKey:@"isConnected"];
    [dict setValue:(self.sharedClient.isLoggedIn ? @1 : @2)  forKey:@"isLoggedIn"];
    [dict setValue:(self.sharedClient.isAutoLogin ? @1 : @2)  forKey:@"isAutoLoginEnabled"];
    if(self.sharedClient.isLoggedIn){
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:self.sharedClient.currentUsername forKey:@"username"];
        [userInfo setValue:self.sharedClient.pushOptions.displayName  forKey:@"nickname"];
        [dict setValue:userInfo  forKey:@"userInfo"];
    }
    [self callbackWithFunctionName:@"cbGetLoginInfo" obj:dict];
    [cb executeWithArguments:ACArgsPack(dict)];
}






#pragma mark - Message



- (void)sendMessageWithBody:(EMMessageBody *)body
                   chatType:(EMChatType)chatType
                        ext:(NSDictionary *)ext
                         to:(NSString *)conversationID{
    EMMessage *message = [[EMMessage alloc]initWithConversationID:conversationID from:[self.sharedClient currentUsername] to:conversationID body:body ext:ext];
    message.chatType = chatType;
    
    
    [self.sharedClient.chatManager sendMessage:message progress:nil completion:^(EMMessage *message, EMError *error) {
        NSMutableDictionary *result=[NSMutableDictionary dictionary];
        if(error){
            [result setValue:UEX_FALSE forKey:@"isSuccess"];
            [result setValue:error.errorDescription forKey:@"errorStr"];
        }
        else{
            [result setValue:UEX_TRUE forKey:@"isSuccess"];
        }
        [result setValue:[self.mgr analyzeEMMessage:message] forKey:@"message"];
        [self callbackWithFunctionName:@"onMessageSent" obj:result];
    }];
    
}




static NSDictionary * getMessageExt(NSDictionary *info){
    NSString *ext = stringArg(info[@"ext"]);
    NSDictionary *extObj = dictionaryArg(info[@"extObj"]);
    if(!extObj && ext){
        extObj = @{@"ext":ext};
    }
    return extObj;

}




static EMChatType getMessageType(NSDictionary *info){
    
    EMChatType type = EMChatTypeChat;
    
    
    NSInteger inChatType = [info[@"chatType"] integerValue];
    
    if(inChatType == 1){
        type = EMChatTypeGroupChat;
    }
    if(inChatType == 2){
        type = EMChatTypeChatRoom;
    }

    return type;
}
        
        

        


        


- (void)sendText:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *username = stringArg(info[@"username"]);
    NSString *content = stringArg(info[@"content"]);
    EMTextMessageBody *msgBody = [[EMTextMessageBody alloc] initWithText:content];
    [self sendMessageWithBody:msgBody chatType:getMessageType(info) ext:getMessageExt(info) to:username];

    
}

- (void)sendVoice:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *username = stringArg(info[@"username"]);
    NSString *filePath = stringArg(info[@"filePath"]);
    NSString *displayName = stringArg(info[@"displayName"])?:[filePath lastPathComponent];
    NSNumber *length = numberArg(info[@"length"]);
    EMVoiceMessageBody *msgBody = [[EMVoiceMessageBody alloc] initWithLocalPath:filePath displayName:displayName];
    msgBody.duration = length.intValue;
    [self sendMessageWithBody:msgBody chatType:getMessageType(info) ext:getMessageExt(info) to:username];

    
}

- (void)sendPicture:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *username = stringArg(info[@"username"]);
    NSString *filePath = stringArg(info[@"filePath"]);
    NSString *displayName = stringArg(info[@"displayName"])?:[filePath lastPathComponent];
    EMImageMessageBody *msgBody = [[EMImageMessageBody alloc] initWithLocalPath:filePath displayName:displayName];

    [self sendMessageWithBody:msgBody chatType:getMessageType(info) ext:getMessageExt(info) to:username];

}

- (void)sendLocationMsg:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *username = stringArg(info[@"username"]);
    NSNumber *lat = numberArg(info[@"latitude"]);
    NSNumber *lon = numberArg(info[@"longitude"]);
    NSString *address = stringArg(info[@"locationAddress"]);

    EMLocationMessageBody *msgBody = [[EMLocationMessageBody alloc] initWithLatitude:lat.doubleValue longitude:lon.doubleValue address:address];
    [self sendMessageWithBody:msgBody chatType:getMessageType(info) ext:getMessageExt(info) to:username];
}

        
- (void)sendVideo:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *username = stringArg(info[@"username"]);
    NSString *filePath = stringArg(info[@"filePath"]);
    NSString *displayName = stringArg(info[@"displayName"])?:[filePath lastPathComponent];
    NSNumber *length = numberArg(info[@"length"]);
    EMVideoMessageBody *msgBody = [[EMVideoMessageBody alloc] initWithLocalPath:filePath displayName:displayName];
    msgBody.duration = length.intValue;
    [self sendMessageWithBody:msgBody chatType:getMessageType(info) ext:getMessageExt(info) to:username];

}

- (void)sendFile:(NSMutableArray *)inArguments{
    
    
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *username = stringArg(info[@"username"]);
    NSString *filePath = stringArg(info[@"filePath"]);
    NSString *displayName = stringArg(info[@"displayName"])?:[filePath lastPathComponent];
    EMFileMessageBody *msgBody = [[EMFileMessageBody alloc] initWithLocalPath:filePath displayName:displayName];
    [self sendMessageWithBody:msgBody chatType:getMessageType(info) ext:getMessageExt(info) to:username];
}
        
- (void)sendCmdMessage:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *username = stringArg(info[@"toUsername"]);
    NSString *action = stringArg(info[@"action"]);
    
    EMCmdMessageBody *msgBody = [[EMCmdMessageBody alloc] initWithAction:action];
    
    [self sendMessageWithBody:msgBody chatType:getMessageType(info) ext:getMessageExt(info) to:username];
    
}

        
- (void)setNotifyBySoundAndVibrate:(NSMutableArray *)inArguments {
    ACArgsUnpack(NSDictionary *notifyInfo) = inArguments;
    if ([[notifyInfo objectForKey:@"enable"] integerValue] == 0){
        self.mgr.messageNotification = NO;
    }else if([[notifyInfo objectForKey:@"enable"] integerValue] == 1){
        self.mgr.messageNotification = YES;
    }
    
    if ([[notifyInfo objectForKey:@"soundEnable"] integerValue] == 0){
        self.mgr.isPlaySound = NO;
    }else if([[notifyInfo objectForKey:@"soundEnable"] integerValue] == 1){
        self.mgr.isPlaySound = YES;
    }
    if ([[notifyInfo objectForKey:@"vibrateEnable"] integerValue] == 0){
        self.mgr.isPlayVibration = NO;
    }else if([[notifyInfo objectForKey:@"vibrateEnable"] integerValue] == 1){
        self.mgr.isPlayVibration = YES;
    }
    if ([[notifyInfo objectForKey:@"showNotificationInBackgroud"] integerValue] == 0){
        self.mgr.isShowNotificationInBackgroud = NO;
    }else if([[notifyInfo objectForKey:@"showNotificationInBackgroud"] integerValue] == 1){
        self.mgr.isShowNotificationInBackgroud = YES;
    }

    if ([[notifyInfo objectForKey:@"deliveryNotification"] integerValue] == 0){
        self.mgr.noDeliveryNotification=YES;
    }else if([[notifyInfo objectForKey:@"deliveryNotification"] integerValue] == 1){
        self.mgr.noDeliveryNotification=NO;
    }
    
}


        

- (EMMessage *)getMessage:(NSString *)msgId{
    if(!msgId){
        return nil;
    }
    
    //不需要从本来的会话里面去取
    EMConversation *conversation = [self.sharedClient.chatManager getConversation:@"appcan" type:EMConversationTypeChat createIfNotExist:YES];
    EMMessage *message = [conversation loadMessageWithId:msgId error:nil];
    return message;
}

        

- (void)getMessageById:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    NSString *msgId = stringArg(info[@"msgId"]);
    EMMessage *msg = [self getMessage:msgId];
    NSDictionary *dict = [self.mgr analyzeEMMessage:msg];
    [self callbackWithFunctionName:@"cbGetMessageById" obj:dict];
    [cb executeWithArguments:ACArgsPack(dict)];
    
}





- (void)sendHasReadResponseForMessage:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *msgId = stringArg(info[@"msgId"]);
    EMMessage *msg = [self getMessage:msgId];
    if(msg){
        [self.sharedClient.chatManager sendMessageReadAck:msg completion:nil];
        
    }

}
        
        
        

#pragma mark - Conversation

static EMConversationType getConversationType(NSDictionary *info){
    EMConversationType type = EMConversationTypeChat;
    NSInteger chatType = numberArg(info[@"chatType"]).integerValue;
    NSInteger isGroup = numberArg(info[@"isGroup"]).integerValue;
    if(chatType == 2 ){
        type = EMConversationTypeChatRoom;
    }else if(chatType == 0 ){
        type = EMConversationTypeChat;
    }else if(isGroup == 1 ||chatType == 1){
        type = EMConversationTypeGroupChat;
    }
    return type;
}

static EMConversation * getConversation(NSDictionary *info){
    return [[uexEasemobManager sharedManager].SDK.chatManager getConversation:stringArg(info[@"username"])
                                                                         type:getConversationType(info)
                                                             createIfNotExist:NO];

}
        


- (void)getConversationByName:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    [self.mgr asyncAnalyzeEMConversation:getConversation(info) completion:^(NSDictionary * dict) {
        [self callbackWithFunctionName:@"cbGetConversationByName" obj:dict];
        [cb executeWithArguments:ACArgsPack(dict)];
    }];

}


- (void)getMessageHistory:(NSMutableArray *)inArguments{
    
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    EMConversation *conversation = getConversation(info);
    
    NSString *startMsgId = stringArg(info[@"startMsgId"]);
    NSNumber *inPageSize = numberArg(info[@"pagesize"]);
    
    int pagesize = inPageSize ? inPageSize.intValue : 20;

    
    [conversation loadMessagesStartFromId:startMsgId count:pagesize searchDirection:EMMessageSearchDirectionUp completion:^(NSArray *aMessages, EMError *aError) {
        if (aError) {
            UEX_LOG_ERROR(aError);
        }
        NSMutableArray *msgList = [NSMutableArray array];
        for(EMMessage *msg in aMessages){
            NSDictionary *msgDict = [self.mgr analyzeEMMessage:msg];
            if (msgDict) {
                [msgList addObject:msgDict];
            }
        }
        NSDictionary *dict = @{@"messages":msgList};
        [self callbackWithFunctionName:@"cbGetMessageHistory" obj:dict];
        [cb executeWithArguments:ACArgsPack(dict)];
    }];
    

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

- (void)getUnreadMsgCount:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    EMConversation *conversation = getConversation(info);
    NSUInteger unreadMessageCount = [conversation unreadMessagesCount];
    NSDictionary *dict = @{@"count": @(unreadMessageCount)};
    [self callbackWithFunctionName:@"cbGetUnreadMsgCount" obj:dict];
    [cb executeWithArguments:ACArgsPack(dict)];
    
}

/*
 #####[3.7]resetUnreadMsgCount(param)//指定会话未读消息数清零
 var param = {
 
	username:,//username|groupid
 isGroup:,//是否为群组 1-是 2-否(仅iOS需要)
 }
 */
- (void)resetUnreadMsgCount:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    EMConversation *conversation = getConversation(info);
    EMError *error = nil;
    [conversation markAllMessagesAsRead:&error];
    if (error) {
        UEX_LOG_ERROR(error);
    }
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
- (void)deleteConversation:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    EMConversation *conversation = getConversation(info);
    EMError *error = nil;
    [conversation deleteAllMessages:&error];
    if (error) {
        UEX_LOG_ERROR(error);
    }
}
/*
 #####[3.13]removeMessage(param)//删除当前会话的某条聊天记录
 var param = {
 
	username:,//username|groupid
	msgId:,
 isGroup:，//是否为群组 1-是 2-否(仅iOS需要)
 }
 */
- (UEX_BOOL)removeMessage:(NSMutableArray*)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *msgId = stringArg(info[@"msgId"]);
    EMConversation *conversation = getConversation(info);
    EMError *error = nil;
    [conversation deleteMessageWithId:msgId error:&error];
    if (error) {
        UEX_LOG_ERROR(error);
        return UEX_FALSE;
    }
    return UEX_TRUE;
    
}
/*
 #####[3.14]deleteAllConversation();//删除所有会话记录(包括本地)
 */
- (void)deleteAllConversation:(NSMutableArray*)array{

    [self.sharedClient.chatManager deleteConversations:[self.sharedClient.chatManager getAllConversations] isDeleteMessages:YES completion:^(EMError *aError) {
        if (aError) {
            UEX_LOG_ERROR(aError);
        }
    }];
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

- (void)getChatterInfo:(NSMutableArray *)inArguments{
    
    ACJSFunctionRef *cb = JSFunctionArg(inArguments.lastObject);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        __block NSMutableArray *result = [NSMutableArray array];
        @onExit{
            [self callbackWithFunctionName:@"cbGetChatterInfo" obj:result];
            [cb executeWithArguments:ACArgsPack(result)];
        };
        
        
        
        NSMutableArray *usernamelist = [NSMutableArray array];
        EMError *error = nil;
        NSArray *buddyList = [self.sharedClient.contactManager getContactsFromServerWithError:&error];
        if (!error) {
            for(NSString  *username in buddyList){
                [usernamelist addObject:username];
            }
        }

        NSMutableArray *grouplist = [NSMutableArray array];
        NSArray *groups = [self.sharedClient.groupManager getMyGroupsFromServerWithError:&error];
        if (!error) {
            for (EMGroup  *group in groups){
                [grouplist addObject:group];
            }
        }
        for(NSString *username in usernamelist){
            NSMutableDictionary *chatter = [NSMutableDictionary dictionary];
            EMConversation *conversation = [self.sharedClient.chatManager getConversation:username type:EMConversationTypeChat createIfNotExist:YES];
            [chatter setValue:[self.mgr analyzeEMMessage:[conversation latestMessage]]  forKey:@"lastMsg"];
            [chatter setValue:@(conversation.unreadMessagesCount) forKey:@"unreadMsgCount"];
            [chatter setValue:username forKey:@"chatter"];
            [chatter setValue:cEMChatTypeUser forKey:@"isGroup"];
            [chatter setValue:cEMChatTypeUser forKey:@"chatType"];
            [result addObject:chatter];
        }
        for(EMGroup *group in grouplist){
            NSMutableDictionary *chatter = [NSMutableDictionary dictionary];
            EMConversation *conversation = [self.sharedClient.chatManager getConversation:group.groupId type:EMConversationTypeGroupChat createIfNotExist:YES];
            [chatter setValue:[self.mgr analyzeEMMessage:[conversation latestMessage]]  forKey:@"lastMsg"];
            [chatter setValue:@(conversation.unreadMessagesCount) forKey:@"unreadMsgCount"];
            [chatter setValue:group.groupId forKey:@"chatter"];
            [chatter setValue:group.subject forKey:@"groupName"];
            [chatter setValue:cEMChatTypeGroup forKey:@"isGroup"];
            [chatter setValue:cEMChatTypeGroup forKey:@"chatType"];
            [result addObject:chatter];
        }
        
       
    });
}


- (void)getRecentChatters:(NSMutableArray *)inArguments{
    ACJSFunctionRef *cb = JSFunctionArg(inArguments.lastObject);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        __block NSMutableArray *result = [NSMutableArray array];
        @onExit{
            [self callbackWithFunctionName:@"cbGetRecentChatters" obj:result];
            [cb executeWithArguments:ACArgsPack(result)];
        };
        
        
        
        NSArray *conversationArray = [self.sharedClient.chatManager getAllConversations];

        for(EMConversation *conversation in conversationArray){
            if (!conversation.conversationId || conversation.conversationId.length == 0) {
                continue;
            }
            NSMutableDictionary *chatter = [NSMutableDictionary dictionary];
            switch (conversation.type) {
                case EMConversationTypeChat:{
                    [chatter setValue:[self.mgr analyzeEMMessage:[conversation latestMessage]]  forKey:@"lastMsg"];
                    [chatter setValue:[NSString stringWithFormat:@"%ld",(unsigned long)conversation.unreadMessagesCount] forKey:@"unreadMsgCount"];
                    [chatter setValue:conversation.conversationId forKey:@"chatter"];
                    [chatter setValue:cEMChatTypeUser forKey:@"isGroup"];
                    [chatter setValue:cEMChatTypeUser forKey:@"chatType"];
                    [result addObject:chatter];
                }
                    break;
                case EMConversationTypeGroupChat:{
                    [chatter setValue:[self.mgr analyzeEMMessage:[conversation latestMessage]]  forKey:@"lastMsg"];
                    [chatter setValue:[NSString stringWithFormat:@"%ld",(unsigned long)conversation.unreadMessagesCount] forKey:@"unreadMsgCount"];
                    [chatter setValue:conversation.conversationId forKey:@"chatter"];
                    EMError *error = nil;
                    EMGroup *group = [self.sharedClient.groupManager searchPublicGroupWithId:conversation.conversationId error:&error];
                    if(!error)[chatter setValue:group.subject forKey:@"groupName"];
                    
                    [chatter setValue:cEMChatTypeGroup forKey:@"isGroup"];
                    [chatter setValue:cEMChatTypeGroup forKey:@"chatType"];
                    [result addObject:chatter];
                }
                    break;
                case EMConversationTypeChatRoom:
                    
                    break;
            }
        }
        [result sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            NSNumber *(^getTimestamp)(NSDictionary *obj) = ^(NSDictionary *obj){
                NSDictionary *lastMsg = dictionaryArg(obj[@"lastMsg"]);
                NSNumber *ts = numberArg(lastMsg[@"messageTime"]);
                return ts?:@(-1);
            };
            return [getTimestamp(obj1) compare:getTimestamp(obj2)];
        }];
    });
    
}




- (void)getTotalUnreadMsgCount:(NSMutableArray *)inArguments{
    ACArgsUnpack(ACJSFunctionRef *cb) = inArguments;
    NSInteger count = 0;
    NSArray *allConversations = [self.sharedClient.chatManager getAllConversations];
    for (EMConversation *conversation in allConversations) {
        count += conversation.unreadMessagesCount;
    }
    NSDictionary *dict = @{@"count": @(count)};
    [self callbackWithFunctionName:@"cbGetTotalUnreadMsgCount" obj:dict];
    [cb executeWithArguments:ACArgsPack(dict)];

    
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
- (void)getContactUserNames:(NSMutableArray*)inArguments{
    
   
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
         ACArgsUnpack(ACJSFunctionRef *cb) = inArguments;
        EMError *error;
        UEX_ERROR err = kUexNoError;
        NSArray *users = [self.sharedClient.contactManager getContactsFromServerWithError:&error];
        if (error) {
            err = uexErrorMake(error.code,error.errorDescription);
        }
        
        [self callbackWithFunctionName:@"cbGetContactUserNames" obj:users];
        [cb executeWithArguments:ACArgsPack(users)];
    });
    
}



/*
 
 
 
 #####[4.8]addContact(param)//添加好友
 var param = {
 
	toAddUsername:,//要添加的好友
	reason:
 }
 */
- (void)addContact:(NSMutableArray *)inArguments{
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *username = stringArg(info[@"toAddUsername"]);
        NSString *msg = stringArg(info[@"reason"]);
        EMError *error = [self.sharedClient.contactManager addContact:username message:msg];
        if (error) {
            UEX_LOG_ERROR(error);
        }
        
    });
}
/*
 #####[4.9]deleteContact(param)//删除好友
 var param = {
 
	username:,//
 }
 */
- (void)deleteContact:(NSMutableArray *)inArguments{
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *username = stringArg(info[@"username"]);
        EMError *error = [self.sharedClient.contactManager deleteContact:username isDeleteConversation:YES];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
}

- (void)acceptInvitation:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *username = stringArg(info[@"username"]);
        EMError *error = [self.sharedClient.contactManager acceptInvitationForUsername:username];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
}

- (void)refuseInvitation:(NSMutableArray *)inArguments{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *username = stringArg(info[@"username"]);
        EMError *error = [self.sharedClient.contactManager declineInvitationForUsername:username];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
}

- (void)getBlackListUsernames:(NSMutableArray *)inArguments{
    ACArgsUnpack(ACJSFunctionRef *cb) = inArguments;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error;
        NSArray *blockedList = [self.sharedClient.contactManager getBlackListFromServerWithError:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
        [self callbackWithFunctionName:@"cbGetBlackListUsernames" obj:blockedList];
        [cb executeWithArguments:ACArgsPack(blockedList)];
    });
    
}




- (void)addUserToBlackList:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *username = stringArg(info[@"username"]);
        EMError *error = [self.sharedClient.contactManager addUserToBlackList:username relationshipBoth:YES];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
}


- (void)deleteUserFromBlackList:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *username = stringArg(info[@"username"]);
        EMError *error = [self.sharedClient.contactManager removeUserFromBlackList:username];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
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

- (void)createPrivateGroup:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        EMGroupOptions *groupStyleSetting = [[EMGroupOptions alloc] init];
        NSInteger userNumber = [numberArg(info[@"maxUsers"]) integerValue];
        if (userNumber > 0){
            groupStyleSetting.maxUsersCount = userNumber;
        }
        BOOL allowInvite = numberArg(info[@"allowInvite"]).boolValue;
        groupStyleSetting.style = allowInvite ? EMGroupStylePrivateMemberCanInvite : EMGroupStylePrivateOnlyOwnerInvite;
        NSArray *members = arrayArg(info[@"members"]);
        NSString *groupName = stringArg(info[@"groupName"]);
        NSString *desc = stringArg(info[@"desc"]);
        NSString *msg = stringArg(info[@"initialWelcomeMessage"]);
        EMError *error;
        EMGroup *group=[self.sharedClient.groupManager createGroupWithSubject:groupName description:desc invitees:members message:msg setting:groupStyleSetting error:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
        [self onGroupCreatedWithGroup:group andError:error];
    });
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
- (void)createPublicGroup:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        EMGroupOptions *groupStyleSetting = [[EMGroupOptions alloc] init];
        NSInteger userNumber = [numberArg(info[@"maxUsers"]) integerValue];
        if (userNumber > 0){
            groupStyleSetting.maxUsersCount = userNumber;
        }
        BOOL needApprovalRequired = [stringArg(info[@"needApprovalRequired"]) isEqual:@"true"] || numberArg(info[@"needApprovalRequired"]).boolValue;
        groupStyleSetting.style = needApprovalRequired ? EMGroupStylePublicJoinNeedApproval : EMGroupStylePublicOpenJoin;
        NSArray *members = arrayArg(info[@"members"]);
        NSString *groupName = stringArg(info[@"groupName"]);
        NSString *desc = stringArg(info[@"desc"]);
        NSString *msg = stringArg(info[@"initialWelcomeMessage"]);
        EMError *error;
        EMGroup *group=[self.sharedClient.groupManager createGroupWithSubject:groupName description:desc invitees:members message:msg setting:groupStyleSetting error:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
        [self onGroupCreatedWithGroup:group andError:error];
    });
}

- (void)onGroupCreatedWithGroup:(EMGroup *)group andError:(EMError *)error{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if(error){
        [dict setValue:@(NO) forKey:@"isSuccess"];
        [dict setValue:error.description forKey:@"errorStr"];
        UEX_LOG_ERROR(error);
        
    }else{
        [dict setValue:@(YES) forKey:@"isSuccess"];
        [dict setValue:[self.mgr analyzeEMGroup:group] forKey:@"group"];
    }
    [self callbackWithFunctionName:@"onGroupCreated" obj:dict];
}

- (void)addUsersToGroup:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSArray *newMembers = arrayArg(info[@"newmembers"]);
        NSString *groupId = stringArg(info[@"groupId"]);
        NSString *message = stringArg(info[@"inviteMessage"]);
        EMError *error = nil;
        [self.sharedClient.groupManager addOccupants:newMembers toGroup:groupId welcomeMessage:message error:&error];
        if(error){
            UEX_LOG_ERROR(error);
        }
    });

}
 
 /*
 #####[5.10]removeUserFromGroup(param)//群聊减人
 var param = {
 
	groupId://
	username://
 }
  */

- (void)removeUserFromGroup:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSArray *usernames = arrayArg(info[@"username"]);
        if (!usernames) {
            NSString *username = stringArg(info[@"username"]);
            if (username) {
                usernames = @[username];
            }
        }
        NSString *groupId = stringArg(info[@"groupId"]);
        EMError *error = nil;
        [self.sharedClient.groupManager removeOccupants:usernames fromGroup:groupId error:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
}

/*
 
 #####[5.11]joinGroup(param)//加入某个群聊，只能用于加入公开群
 var param = {
 
	groupId://
	reason:// //如果群开群是自由加入的，即group.isMembersOnly()为false，此参数不传
 groupName://群组名称
 }
 */
- (void)joinGroup:(NSMutableArray *)inArguments{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        NSString *reason = stringArg(info[@"reason"]);
        
        EMError *error = nil;
        EMGroup *group = [self.sharedClient.groupManager searchPublicGroupWithId:groupId error:&error];
        if(!error){
            if(group.setting.style == EMGroupStylePublicOpenJoin){
                [self.sharedClient.groupManager joinPublicGroup:groupId error:&error];
            }else{
                [self.sharedClient.groupManager applyJoinPublicGroup:groupId message:reason error:&error];
            }
        }
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
}

/*
 #####[5.12]exitFromGroup(param)//退出群聊
 var param = {
 
	groupId://
 }
 */
- (void)exitFromGroup:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        EMError *error = nil;
        [self.sharedClient.groupManager leaveGroup:groupId error:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
    
}
/*
 #####[5.13]exitAndDeleteGroup(param)//解散群聊
 var param = {
 
	groupId://
 }
 */

- (void)exitAndDeleteGroup:(NSMutableArray *)inArguments{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        EMError *error = nil;
        [self.sharedClient.groupManager destroyGroup:groupId error:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
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
- (void)getGroupsFromServer:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        NSArray *(^getGrouplist)(NSArray *groups) = ^(NSArray *groups){
            NSMutableArray *grouplist = [NSMutableArray array];
            for (EMGroup  *group in groups){
                NSDictionary *groupDict = [self.mgr analyzeEMGroup:group];
                if (groupDict) {
                    [grouplist addObject:groupDict];
                }
            }
            return grouplist;
        };
        
        
        
        
        
        BOOL loadCache = [stringArg(info[@"loadCache"]) isEqual:@"true"] || numberArg(info[@"loadCache"]).boolValue;
        if (loadCache) {
            NSArray *groups = [self.sharedClient.groupManager getJoinedGroups];
            [dict setValue:@0 forKey:@"result"];
            [dict setValue:getGrouplist(groups) forKey:@"grouplist"];
        }else{
            EMError *error=nil;
            NSArray *groups = [self.sharedClient.groupManager getMyGroupsFromServerWithError:&error];
            if (!error) {
                [dict setValue:@0 forKey:@"result"];
                [dict setValue:getGrouplist(groups) forKey:@"grouplist"];
            }else{
                [dict setValue:@1 forKey:@"result"];
                [dict setValue:error.errorDescription forKey:@"errorMsg"];
                UEX_LOG_ERROR(error);
            }
        }
        [self callbackWithFunctionName:@"cbGetGroupsFromServer" obj:dict];
        [cb executeWithArguments:ACArgsPack(dict)];
        
    });

    
}
/*
 
 #####[5.16]getAllPublicGroupsFromServer();//获取所有公开群列表
 #####[5.17]cbGetAllPublicGroupsFromServer(param)//获取所有公开群列表回调

 */
- (void)getAllPublicGroupsFromServer:(NSMutableArray*)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
        NSString *cursor = stringArg(info[@"cursor"]);
        NSNumber *inPageSize = numberArg(info[@"pageSize"]);
        NSInteger pageSize = inPageSize ? inPageSize.integerValue : -1;
        EMError *error=nil;
        EMCursorResult *result=[self.sharedClient.groupManager getPublicGroupsFromServerWithCursor:cursor pageSize:pageSize error:&error];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        if(error){
            [dict setValue:@1 forKey:@"result"];
            [dict setValue:error.description forKey:@"errorMsg"];
            UEX_LOG_ERROR(error);
        }else{
            [dict setValue:@0 forKey:@"result"];
            NSMutableArray *grouplist = [NSMutableArray array];
            for(EMGroup *group in result.list){
                NSDictionary *groupDict = [self.mgr analyzeEMGroup:group];
                if(groupDict){
                   [grouplist addObject:group];
                }
                
            }
            [dict setValue:grouplist forKey:@"grouplist"];
            [dict setValue:result.cursor forKey:@"cursor"];
        }
        [self callbackWithFunctionName:@"cbGetAllPublicGroupsFromServer" obj:dict];
        [cb executeWithArguments:ACArgsPack(dict)];
    });
    
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
- (void)getGroup:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        
        EMError *error = nil;
        EMGroup *group = [self.sharedClient.groupManager fetchGroupInfo:groupId includeMembersList:YES error:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
        NSDictionary *dict = [self.mgr analyzeEMGroup:group];
        [self callbackWithFunctionName:@"cbGetGroup" obj:dict];
        [cb executeWithArguments:ACArgsPack(dict)];
    });
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
- (void)blockGroupMessage:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        EMError *error = nil;
        [self.sharedClient.groupManager blockGroup:groupId error:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
    
}
- (void)unblockGroupMessage:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        EMError *error = nil;
        [self.sharedClient.groupManager unblockGroup:groupId error:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
    
}

/*
 #####[5.22]changeGroupName(param)//修改群组名称
 var param = {
 
	groupId://
	changedGroupName:,//改变后的群组名称
 }
 */
- (void)changeGroupName:(NSMutableArray *)inArguments{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        NSString *newGroupName = stringArg(info[@"changedGroupName"]);
        EMError *error = nil;
        [self.sharedClient.groupManager changeGroupSubject:newGroupName forGroup:groupId error:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
}

- (void)blockUser:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        NSArray *usernames = arrayArg(info[@"username"]);
        if (!usernames) {
            NSString *username = stringArg(info[@"username"]);
            if(username){
                usernames = @[username];
            }
        }
        EMError *error = nil;
        [self.sharedClient.groupManager blockOccupants:usernames fromGroup:groupId error:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
    
}
- (void)unblockUser:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        NSArray *usernames = arrayArg(info[@"username"]);
        if (!usernames) {
            NSString *username = stringArg(info[@"username"]);
            if(username){
                usernames = @[username];
            }
        }
        EMError *error = nil;
        [self.sharedClient.groupManager unblockOccupants:usernames forGroup:groupId error:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
    });
    
}
- (void)getBlockedUsers:(NSMutableArray *)inArguments{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);

        EMError *error = nil;
        NSArray *usernames = [self.sharedClient.groupManager fetchGroupBansList:groupId error:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
        NSDictionary *dict = usernames ? @{@"usernames": usernames} : nil;
        [self callbackWithFunctionName:@"cbGetBlockedUsers" obj:dict];
        [cb executeWithArguments: ACArgsPack(dict)];
    });
}
//3.0.22新增接口
- (void)acceptJoinApplication:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        NSString *username = stringArg(info[@"username"]);
        EMError *error = [self.sharedClient.groupManager acceptJoinApplication:groupId applicant:username];
        if(error){
            UEX_LOG_ERROR(error);
        }
    });
}
//3.0.22新增接口
- (void)declineJoinApplication:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        NSString *username = stringArg(info[@"username"]);
        NSString *reason = stringArg(info[@"reason"]);
        EMError *error = [self.sharedClient.groupManager declineJoinApplication:groupId applicant:username reason:reason];
        if(error){
            UEX_LOG_ERROR(error);
        }
    });
}
//3.0.22新增接口
- (void)acceptInvitationFromGroup:(NSMutableArray *)inArguments{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        NSString *username = stringArg(info[@"username"]);
        EMError *error = nil;
        [self.sharedClient.groupManager acceptInvitationFromGroup:groupId inviter:username error:&error];
        if(error){
            UEX_LOG_ERROR(error);
        }
    });
}
//3.0.22新增接口
- (void)declineInvitationFromGroup:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        ACArgsUnpack(NSDictionary *info) = inArguments;
        NSString *groupId = stringArg(info[@"groupId"]);
        NSString *username = stringArg(info[@"username"]);
        NSString *reason = stringArg(info[@"reason"]);
        EMError *error= [self.sharedClient.groupManager declineInvitationFromGroup:groupId inviter:username reason:reason];
        if(error){
            UEX_LOG_ERROR(error);
        }
    });
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
 var param = {
 
 group:,//EMGroup对象的json格式字符串
 }
 
	每当添加/移除/更改角色/更改主题/更改群组信息之后,都会触发此回调
 
 */



#pragma mark - CALL
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
 
 
	eg. 一个成功的语音通话流程为 ：A发送通话请求给B == > AB建立语音通话连接 == > B同意语音通话 == > 开始语音通话
 
 
 
 #####[6.3]makeVoiceCall(param)//拨打语音通话
 var param = {
 
	username:,//
 }
 #####[6.4]answerCall();//接听通话
 #####[6.5]rejectCall();//拒绝接听
 #####[6.6]endCall();//挂断通话
 */


- (void)makeVoiceCall:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;

    NSString *username = stringArg(info[@"username"]);
    @weakify(self);
    [self.sharedClient.callManager startCall:EMCallTypeVoice remoteName:username ext:nil completion:^(EMCallSession *aCallSession, EMError *aError) {
        @strongify(self);
        if (aError) {
            UEX_LOG_ERROR(aError);
        }else{
            [self callbackWithFunctionName:@"onCallStateChanged" obj:@{@"state": @1}];
            self.mgr.callSession = aCallSession;
        }
    }];

}


- (void)answerCall:(NSMutableArray *)inArguments{
    [self.sharedClient.callManager answerIncomingCall:self.mgr.callSession.callId];

}

- (void)rejectCall:(NSMutableArray *)inArguments{
    
    [self.sharedClient.callManager endCall:self.mgr.callSession.callId reason:EMCallEndReasonDecline];
}

- (void)endCall:(NSMutableArray *)inArguments{
    
    [self.sharedClient.callManager endCall:self.mgr.callSession.callId reason:EMCallEndReasonHangup];
}

#pragma mark - APNS
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
static ACJSFunctionRef *regAPNSFunc = nil;
static BOOL isEasemobRegisterRemoteNofitication = NO;
- (void)registerRemoteNotification:(NSMutableArray *)inArguments{

    isEasemobRegisterRemoteNofitication = YES;
    regAPNSFunc = JSFunctionArg(inArguments.lastObject);
#if !TARGET_IPHONE_SIMULATOR

    UIUserNotificationSettings *uns = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound) categories:nil];
    //注册推送
    [[UIApplication sharedApplication] registerUserNotificationSettings:uns];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
#endif
    
    
}

// 将得到的deviceToken传给SDK
+ (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    if (!isEasemobRegisterRemoteNofitication) {
        return;
    }
    isEasemobRegisterRemoteNofitication = NO;
    [[EMClient sharedClient] bindDeviceToken:deviceToken];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUexEasemobUserDefaultsAPNSUsageKey];
    if (regAPNSFunc) {
        [regAPNSFunc executeWithArguments:ACArgsPack(kUexNoError)];
        regAPNSFunc = nil;
    }
    [[uexEasemobManager sharedManager] callbackWithFunctionName:@"cbRegisterRemoteNotification" obj:@{@"result": @1}];
    
}

// 注册deviceToken失败
+ (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    if (!isEasemobRegisterRemoteNofitication) {
        return;
    }
    isEasemobRegisterRemoteNofitication = NO;
    [[NSUserDefaults standardUserDefaults]setBool:NO forKey:kUexEasemobUserDefaultsAPNSUsageKey];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@2 forKey:@"result"];
    [dict setValue:[error localizedDescription] forKey:@"errorInfo"];
    if (regAPNSFunc) {
        [regAPNSFunc executeWithArguments:ACArgsPack(uexErrorMake(error.code,error.localizedDescription))];
        regAPNSFunc = nil;
    }
    [[uexEasemobManager sharedManager] callbackWithFunctionName:@"cbRegisterRemoteNotification" obj:@{@"result": @2}];
    
}


- (void)updatePushOptions:(NSMutableArray *)inArguments{

    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    EMPushOptions *options = [self.sharedClient getPushOptionsFromServerWithError:nil];
    NSString *nickname = stringArg(info[@"nickname"]);
    if (nickname) {
        options.displayName = nickname;
    }
    NSNumber *inDisplayStyle = numberArg(info[@"displayStyle"]);
    if (inDisplayStyle) {
        NSInteger displayStyle = inDisplayStyle.integerValue;
        if(displayStyle == 0){
            options.displayStyle = EMPushDisplayStyleSimpleBanner;
        }else if(displayStyle == 1){
            options.displayStyle = EMPushDisplayStyleMessageSummary;
        }
    }
    
    NSNumber *inNoDisturbingStyle = numberArg(info[@"noDisturbingStyle"]);
    if (inNoDisturbingStyle) {
        NSInteger noDisturbingStyle = inNoDisturbingStyle.integerValue;
        if(noDisturbingStyle == 0){
            options.noDisturbStatus = EMPushNoDisturbStatusDay ;
        }else if(noDisturbingStyle == 1){
            options.noDisturbStatus = EMPushNoDisturbStatusCustom;
        }else if(noDisturbingStyle == 2){
            options.noDisturbStatus = EMPushNoDisturbStatusClose;
        }
    }
    NSNumber *noDisturbingStartH = numberArg(info[@"noDisturbingStartH"]);
    if (noDisturbingStartH) {
        options.noDisturbingStartH = noDisturbingStartH.integerValue;
    }
    NSNumber *noDisturbingEndH = numberArg(info[@"noDisturbingEndH"]);
    if (noDisturbingEndH) {
        options.noDisturbingEndH = noDisturbingEndH.integerValue;
    }
    EMError *error = [self.sharedClient updatePushOptionsToServer];
    if (error) {
        UEX_LOG_ERROR(error);
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:options.displayName forKey:@"nickname"];
    [dict setValue:@(options.noDisturbingStartH) forKey:@"noDisturbingStartH"];
    [dict setValue:@(options.noDisturbingEndH) forKey:@"noDisturbingEndH"];
    NSNumber *noDisturbStatus;
    switch (options.noDisturbStatus) {
        case EMPushNoDisturbStatusClose:
            noDisturbStatus = @2;
            break;
        case EMPushNoDisturbStatusCustom:
            noDisturbStatus = @1;
            break;
        case EMPushNoDisturbStatusDay:
            noDisturbStatus = @0;
        default:
            break;
    }
    [dict setValue:noDisturbStatus forKey:@"noDisturbingStyle"];
    NSNumber *displayStyle;
    switch (options.displayStyle) {
        case EMPushDisplayStyleSimpleBanner:
            displayStyle = @0;
            break;
        case EMPushDisplayStyleMessageSummary:
            displayStyle = @1;
            break;
        default:
            break;
    }
    [dict setValue:displayStyle forKey:@"displayStyle"];
    
    [self callbackWithFunctionName:@"cbUpdatePushOptions" obj:dict];
    [cb executeWithArguments:ACArgsPack(dict)];

}
- (void)ignoreGroupPushNotification:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    NSString *groupId = stringArg(info[@"groupId"]);
    NSInteger inFlag = numberArg(info[@"isIgnore"]).integerValue;
    EMError *error = nil;
    switch (inFlag) {
        case 1:
            error = [self.sharedClient.groupManager ignoreGroupPush:groupId ignore:YES];
            break;
        case 2:
            error = [self.sharedClient.groupManager ignoreGroupPush:groupId ignore:NO];
            break;
        default:
            break;
    }

    if (error) {
        UEX_LOG_ERROR(error);
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error = nil;
        NSArray *groups = [self.sharedClient.groupManager getGroupsWithoutPushNotification:&error];
        if (error) {
            UEX_LOG_ERROR(error);
        }
        NSDictionary *dict = groups ? @{@"groupIds": groups} : nil;
        [self callbackWithFunctionName:@"cbIgnoreGroupPushNotification" obj:dict];
        [cb executeWithArguments:ACArgsPack(dict)];
    });
}




#pragma mark - private method

- (void)callbackWithFunctionName:(NSString *)funcName obj:(id)obj{
    [self.mgr callbackWithFunctionName:funcName obj:obj];
}






@end
