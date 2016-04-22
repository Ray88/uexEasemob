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
#import "EMCursorResult.h"
#import "JSON.h"






@interface EUExEasemob()

@property (nonatomic,weak) uexEasemobManager *mgr;


@property (nonatomic,weak)EMClient * sharedInstance;




@end


@implementation EUExEasemob



-(id)initWithBrwView:(EBrowserView *)eInBrwView{
    self = [super initWithBrwView:eInBrwView];
    if(self){
        self.mgr = [uexEasemobManager sharedInstance];
        self.sharedInstance = self.mgr.SDK;

        if(!self.sharedInstance){
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(initSettings)
                                                         name:@"uexEasemobInitSuccess"
                                                       object:nil];
        }
        
        
        if(_mgr.remoteLaunchDict){
            [self callBackJSONWithFunction:@"onApnsLaunch" parameter:_mgr.remoteLaunchDict];
            _mgr.remoteLaunchDict = nil;
        }
    }
    return  self;
}

- (void)clean{

}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self clean];
    
}
+(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    if (launchOptions) {
        [[uexEasemobManager sharedInstance] didFinishLaunchingWithOptions:(NSDictionary *)launchOptions];
    }
    return YES;
}
//从JSON字符串中获取数据
- (id)getDataFromJSON:(NSString *)jsonStr{
    NSError *error = nil;
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&error];
    if (jsonObject && !error ){
        return jsonObject;
    }else{
        // 解析錯誤
        return nil;
    }
}

#pragma mark - Plugin Method






#pragma mark - initialization
- (void)initEasemob:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id initInfo = [self getDataFromJSON:inArguments[0]];
    if([initInfo objectForKey:@"isAutoLoginEnabled"]){
        id autoLogin = [initInfo objectForKey:@"isAutoLoginEnabled"];
        if([autoLogin integerValue] == 1 ){
            _mgr.isAutoLoginEnabled = YES;
        }else if([autoLogin integerValue] == 2 ){
            _mgr.isAutoLoginEnabled = NO;
        }
    }
    [_mgr initEasemobWithAppKey:[initInfo objectForKey:@"appKey"] apnsCertName:[initInfo objectForKey:@"apnsCertName"]];
}



//- (void)login:(NSMutableArray *)inArguments{
//    id user = [self getDataFromJSON:inArguments[0]];
//    
//    // 登录
//    
//    [self.sharedInstance.chatManager asyncLoginWithUsername:[user objectForKey:@"username"] password:[user objectForKey:@"password"] completion:^(NSDictionary *loginInfo, EMError *error) {
//        //Block回调
//        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
//        
//        
//        if (!error && loginInfo) {
//            [dict setValue:@"1" forKey:@"result"];
//            [dict setValue:@"登录成功" forKey:@"msg"];
//            [self getAPNsOptions];
//            [_sharedInstance.chatManager importDataToNewDatabase];
//            [_sharedInstance.chatManager loadDataFromDatabase];
//            [self callBackJSONWithFunction:@"onConnected" parameter:nil];
//        }else{
//            [dict setValue:@"2" forKey:@"result"];
//            [dict setValue:[NSString stringWithFormat:@"登录失败:%@",error.description] forKey:@"msg"];
//            
//        }
//        [self callBackJSONWithFunction:@"cbLogin" parameter:dict];
//    } onQueue:nil];
//}
- (void)login:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id user = [self getDataFromJSON:inArguments[0]];

    // 登录
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error=[self.sharedInstance loginWithUsername:[user objectForKey:@"username"] password:[user objectForKey:@"password"]];
        //Block回调
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
        
        
        if (!error) {
            [dict setValue:@"1" forKey:@"result"];
            [dict setValue:@"登录成功" forKey:@"msg"];
            //[self getAPNsOptions];
            [_sharedInstance dataMigrationTo3];
            [self callBackJSONWithFunction:@"onConnected" parameter:nil];
        }else{
            [dict setValue:@"2" forKey:@"result"];
            [dict setValue:[NSString stringWithFormat:@"登录失败:%@%d",error.errorDescription,error.code] forKey:@"msg"];
            
        }
        [self callBackJSONWithFunction:@"cbLogin" parameter:dict];
    });
}

//- (void)getAPNsOptions{
//    EMPushOptions *tmp = [self.sharedInstance pushOptions];
//    EMPushOptions *options = [[EMPushOptions alloc]init];
//    options.nickname = tmp.nickname;
//    options.displayStyle = tmp.displayStyle;
//    options.noDisturbingEndH = tmp.noDisturbingEndH;
//    options.noDisturbingStartH = tmp.noDisturbingStartH;
//    options.noDisturbStatus = tmp.noDisturbStatus;
////    options.backupDataSize = tmp.backupDataSize;
////    options.backupPaths = tmp.backupPaths;
////    options.backupTimeInterval = tmp.backupTimeInterval;
////    options.backupType = tmp.backupType;
////    options.backupVersion = tmp.backupVersion;
//    _mgr.apnsOptions = options;
//
//}

 - (void)logout:(NSMutableArray *)inArguments{
     
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
         EMError *error=[self.sharedInstance logout:YES];
         
         NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
         if (!error) {
             [dict setValue:@"1" forKey:@"result"];
             [dict setValue:@"登出成功" forKey:@"message"];
         }else{
             [dict setValue:@"2" forKey:@"result"];
             [dict setValue:@"登出失败" forKey:@"message"];;
         }
         [self callBackJSONWithFunction:@"cbLogout" parameter:dict];
     });
}

- (void)registerUser:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id user = [self getDataFromJSON:inArguments[0]];
    if(!user){
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error=[self.sharedInstance registerWithUsername:[user objectForKey:@"username"]
                                                        password:[user objectForKey:@"password"]];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
        if (!error) {
            [dict setValue:@"1" forKey:@"result"];
            [dict setValue:@"注册成功" forKey:@"msg"];
        }else{
            [dict setValue:@"2" forKey:@"result"];
            [dict setValue:[NSString stringWithFormat:@"注册失败:%@%d",error.errorDescription,error.code] forKey:@"msg"];
        }
        
        [self callBackJSONWithFunction:@"cbRegisterUser" parameter:dict];
    });
    
}


- (void)updateCurrentUserNickname:(NSMutableArray *)inArguments{
    id nickname = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        [self.sharedInstance setApnsNickname:[nickname objectForKey:@"nickname"]];
    });
    
}


- (void)getLoginInfo:(NSMutableArray *)inArguments{
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    
    [dict setValue:(self.sharedInstance.isConnected?@"1":@"2")   forKey:@"isConnected"];
    [dict setValue:(self.sharedInstance.isLoggedIn?@"1":@"2")  forKey:@"isLoggedIn"];
    [dict setValue:(self.sharedInstance.isAutoLogin?@"1":@"2")  forKey:@"isAutoLoginEnabled"];
    if(self.sharedInstance.isLoggedIn){
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:@(self.sharedInstance.isConnected)   forKey:@"isConnected"];
        [userInfo setValue:@(self.sharedInstance.isLoggedIn)  forKey:@"isLoggedIn"];
        [userInfo setValue:@(self.sharedInstance.isAutoLogin)  forKey:@"isAutoLoginEnabled"];
        if ([self.sharedInstance.pushOptions.nickname length]>0){
            [userInfo setValue:self.sharedInstance.pushOptions.nickname  forKey:@"nickname"];
        }
        
        [dict setValue:userInfo  forKey:@"userInfo"];
    }
    [self callBackJSONWithFunction:@"cbGetLoginInfo" parameter:dict];
    
}



-(EMChatType)getMsgType:(id)info{
    EMChatType type = EMChatTypeChat;
    if([[info objectForKey:@"chatType"] integerValue] == 1){
        type = EMChatTypeGroupChat;
    }
    else if([[info objectForKey:@"chatType"] integerValue] == 2){
        type = EMChatTypeChatRoom;
    }
    
    return type;
}




#pragma mark - Message

-(void)sendMsgWithResult:(EMMessage *)message error:(EMError *)error{
    
    NSMutableDictionary *result=[NSMutableDictionary dictionary];
    if(error){
        [result setValue:@(NO) forKey:@"isSuccess"];
        [result setValue:error.errorDescription forKey:@"errorStr"];
        [result setValue:@"" forKey:@"message"];
    }
    else{
        [result setValue:@(YES) forKey:@"isSuccess"];
        [result setValue:error.errorDescription forKey:@"errorStr"];
        [result setValue:[self.mgr analyzeEMMessage:message] forKey:@"message"];
    }
    [self callBackJSONWithFunction:@"onMessageSent" parameter:result];
}
- (void)sendText:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    
    NSDictionary *extDic=nil;
    if([info objectForKey:@"ext"]){
        extDic=@{@"ext":[info objectForKey:@"ext"]};
    }
    if([info objectForKey:@"extObj"]){
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSString class]]){
            extDic=[[info objectForKey:@"extObj"] JSONValue];
        }
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSDictionary class]]){
            extDic=[info objectForKey:@"extObj"];
        }
    }
    EMTextMessageBody *msgBody = [[EMTextMessageBody alloc] initWithText:[info objectForKey:@"content"]];
    // 生成message
    EMMessage *msg = [[EMMessage alloc] initWithConversationID:[info objectForKey:@"username"] from:[[EMClient sharedClient] currentUsername] to:[info objectForKey:@"username"] body:msgBody ext:extDic];
    msg.chatType = [self getMsgType:info];

    [self.sharedInstance.chatManager asyncSendMessage:msg progress:^(int progress) {
        
    } completion:^(EMMessage *message, EMError *error) {
        [self sendMsgWithResult:message error:error];
    }];
    
}

- (void)sendVoice:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    
    NSDictionary *extDic=nil;
    if([info objectForKey:@"ext"]){
        extDic=@{@"ext":[info objectForKey:@"ext"]};
    }
    if([info objectForKey:@"extObj"]){
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSString class]]){
            extDic=[[info objectForKey:@"extObj"] JSONValue];
        }
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSDictionary class]]){
            extDic=[info objectForKey:@"extObj"];
        }
    }
    EMVoiceMessageBody *msgBody = [[EMVoiceMessageBody alloc] initWithLocalPath:[self absPath:[info objectForKey:@"filePath"]] displayName:[info objectForKey:@"displayName"]];
    if([info objectForKey:@"length"]){
        msgBody.duration = [[info objectForKey:@"length"] intValue];
    }
    // 生成message
    EMMessage *msg = [[EMMessage alloc] initWithConversationID:[info objectForKey:@"username"] from:[[EMClient sharedClient] currentUsername] to:[info objectForKey:@"username"] body:msgBody ext:extDic];
    msg.chatType = [self getMsgType:info];

    [self.sharedInstance.chatManager asyncSendMessage:msg progress:^(int progress) {
        
    } completion:^(EMMessage *message, EMError *error) {
        [self sendMsgWithResult:message error:error];
    }];
    
}

- (void)sendPicture:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    
    NSDictionary *extDic=nil;
    if([info objectForKey:@"ext"]){
        extDic=@{@"ext":[info objectForKey:@"ext"]};
    }
    if([info objectForKey:@"extObj"]){
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSString class]]){
            extDic=[[info objectForKey:@"extObj"] JSONValue];
        }
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSDictionary class]]){
            extDic=[info objectForKey:@"extObj"];
        }
    }
    
    EMImageMessageBody *msgBody = [[EMImageMessageBody alloc] initWithLocalPath:[self absPath:[info objectForKey:@"filePath"]] displayName:[info objectForKey:@"displayName"]];
    // 生成message
    EMMessage *msg = [[EMMessage alloc] initWithConversationID:[info objectForKey:@"username"] from:[[EMClient sharedClient] currentUsername] to:[info objectForKey:@"username"] body:msgBody ext:extDic];
    msg.chatType = [self getMsgType:info];
    
    [self.sharedInstance.chatManager asyncSendMessage:msg progress:^(int progress) {
        
    } completion:^(EMMessage *message, EMError *error) {
        [self sendMsgWithResult:message error:error];
    }];
    
}

- (void)sendLocationMsg:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    
    NSDictionary *extDic=nil;
    if([info objectForKey:@"ext"]){
        extDic=@{@"ext":[info objectForKey:@"ext"]};
    }
    if([info objectForKey:@"extObj"]){
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSString class]]){
            extDic=[[info objectForKey:@"extObj"] JSONValue];
        }
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSDictionary class]]){
            extDic=[info objectForKey:@"extObj"];
        }
    }

    EMLocationMessageBody *msgBody = [[EMLocationMessageBody alloc] initWithLatitude:[[info objectForKey:@"latitude"] doubleValue] longitude:[[info objectForKey:@"longitude"] doubleValue] address:[info objectForKey:@"locationAddress"]];
    
    // 生成message
    EMMessage *msg = [[EMMessage alloc] initWithConversationID:[info objectForKey:@"username"] from:[[EMClient sharedClient] currentUsername] to:[info objectForKey:@"username"] body:msgBody ext:extDic];
    msg.chatType = [self getMsgType:info];
    
    [self.sharedInstance.chatManager asyncSendMessage:msg progress:^(int progress) {
        
    } completion:^(EMMessage *message, EMError *error) {
        [self sendMsgWithResult:message error:error];
    }];
    
}

- (void)sendVideo:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    
    NSDictionary *extDic=nil;
    if([info objectForKey:@"ext"]){
        extDic=@{@"ext":[info objectForKey:@"ext"]};
    }
    if([info objectForKey:@"extObj"]){
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSString class]]){
            extDic=[[info objectForKey:@"extObj"] JSONValue];
        }
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSDictionary class]]){
            extDic=[info objectForKey:@"extObj"];
        }
    }
    
    EMVideoMessageBody *msgBody = [[EMVideoMessageBody alloc]  initWithLocalPath:[self absPath:[info objectForKey:@"filePath"]] displayName:[info objectForKey:@"displayName"]];
    if([info objectForKey:@"length"]){
        msgBody.duration = [[info objectForKey:@"length"] intValue];
    }
    // 生成message
    EMMessage *msg = [[EMMessage alloc] initWithConversationID:[info objectForKey:@"username"] from:[[EMClient sharedClient] currentUsername] to:[info objectForKey:@"username"] body:msgBody ext:extDic];
    msg.chatType = [self getMsgType:info];
    
    [self.sharedInstance.chatManager asyncSendMessage:msg progress:^(int progress) {
        
    } completion:^(EMMessage *message, EMError *error) {
        [self sendMsgWithResult:message error:error];
    }];
}

- (void)sendFile:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    
    NSDictionary *extDic=nil;
    if([info objectForKey:@"ext"]){
        extDic=@{@"ext":[info objectForKey:@"ext"]};
    }
    if([info objectForKey:@"extObj"]){
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSString class]]){
            extDic=[[info objectForKey:@"extObj"] JSONValue];
        }
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSDictionary class]]){
            extDic=[info objectForKey:@"extObj"];
        }
    }
    
    EMFileMessageBody *msgBody = [[EMFileMessageBody alloc] initWithLocalPath:[self absPath:[info objectForKey:@"filePath"]] displayName:[info objectForKey:@"displayName"]];
    // 生成message
    EMMessage *msg = [[EMMessage alloc] initWithConversationID:[info objectForKey:@"username"] from:[[EMClient sharedClient] currentUsername] to:[info objectForKey:@"username"] body:msgBody ext:extDic];
    msg.chatType = [self getMsgType:info];
    
    [self.sharedInstance.chatManager asyncSendMessage:msg progress:^(int progress) {
        
    } completion:^(EMMessage *message, EMError *error) {
        [self sendMsgWithResult:message error:error];
    }];

}
- (void)sendCmdMessage:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    
    NSDictionary *extDic=nil;
    if([info objectForKey:@"ext"]){
        extDic=@{@"ext":[info objectForKey:@"ext"]};
    }
    if([info objectForKey:@"extObj"]){
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSString class]]){
            extDic=[[info objectForKey:@"extObj"] JSONValue];
        }
        if([[info objectForKey:@"extObj"] isKindOfClass:[NSDictionary class]]){
            extDic=[info objectForKey:@"extObj"];
        }
    }
    
    EMCmdMessageBody *msgBody = [[EMCmdMessageBody alloc] initWithAction:[info objectForKey:@"action"]];
    // 生成message
    EMMessage *msg = [[EMMessage alloc] initWithConversationID:[info objectForKey:@"toUsername"] from:[[EMClient sharedClient] currentUsername] to:[info objectForKey:@"toUsername"] body:msgBody ext:extDic];
    msg.chatType = [self getMsgType:info];
    
    [self.sharedInstance.chatManager asyncSendMessage:msg progress:^(int progress) {
        
    } completion:^(EMMessage *message, EMError *error) {
        [self sendMsgWithResult:message error:error];
    }];
    
}

- (void)setNotifyBySoundAndVibrate:(NSMutableArray *)inArguments {
    if(inArguments.count<1){
        return;
    }
    id notifyInfo = [self getDataFromJSON:inArguments[0]];
    
    if ([[notifyInfo objectForKey:@"enable"] integerValue] == 0){
        _mgr.messageNotification = NO;
    }else if([[notifyInfo objectForKey:@"enable"] integerValue] == 1){
        _mgr.messageNotification = YES;
    }
    
    if ([[notifyInfo objectForKey:@"soundEnable"] integerValue] == 0){
        _mgr.isPlaySound = NO;
    }else if([[notifyInfo objectForKey:@"soundEnable"] integerValue] == 1){
        _mgr.isPlaySound = YES;
    }
    if ([[notifyInfo objectForKey:@"vibrateEnable"] integerValue] == 0){
        _mgr.isPlayVibration = NO;
    }else if([[notifyInfo objectForKey:@"vibrateEnable"] integerValue] == 1){
        _mgr.isPlayVibration = YES;
    }
    if ([[notifyInfo objectForKey:@"showNotificationInBackgroud"] integerValue] == 0){
        _mgr.isShowNotificationInBackgroud = NO;
    }else if([[notifyInfo objectForKey:@"showNotificationInBackgroud"] integerValue] == 1){
        _mgr.isShowNotificationInBackgroud = YES;
    }

    if ([[notifyInfo objectForKey:@"deliveryNotification"] integerValue] == 0){
        self.mgr.noDeliveryNotification=YES;
    }else if([[notifyInfo objectForKey:@"deliveryNotification"] integerValue] == 1){
        self.mgr.noDeliveryNotification=NO;
    }
    
}



-(EMMessage *)getMessage:(NSString *)msgId{
    
    //不需要从本来的会话里面去；
    EMConversation *conversation = [self.sharedInstance.chatManager getConversation:@"appcan" type:EMConversationTypeChat createIfNotExist:YES];
    EMMessage *message = [conversation loadMessageWithId:msgId];
    return message;
}


- (void)getMessageById:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    if ([info objectForKey:@"msgId"]){
        EMMessage *msg = [self getMessage:[info objectForKey:@"msgId"]];
        NSDictionary *messageDict = [_mgr analyzeEMMessage:msg];
        [self callBackJSONWithFunction:@"cbGetMessageById" parameter:messageDict];
    }
    
}





- (void)sendHasReadResponseForMessage:(NSMutableArray *)inArguments{
    
    
    id info = [self getDataFromJSON:inArguments[0]];
    if ([info objectForKey:@"msgId"]){
        EMMessage *msg = [self getMessage:[info objectForKey:@"msgId"]];
        [_sharedInstance.chatManager asyncSendReadAckForMessage:msg];
    }
    
}

#pragma mark - Conversation

-(EMConversationType)parseConversationType:(NSDictionary *)dataDict{
    EMConversationType type = EMConversationTypeChat;
    if([[dataDict objectForKey:@"chatType"] integerValue] == 2 ){
        type = EMConversationTypeChatRoom;
    }else if([[dataDict objectForKey:@"chatType"] integerValue] == 0 ){
        type = EMConversationTypeChat;
    }else if([[dataDict objectForKey:@"isGroup"] integerValue] == 1 ||[[dataDict objectForKey:@"chatType"] integerValue] == 1){
        type = EMConversationTypeGroupChat;
    }
    return type;
    
}

-(EMConversation *) getConversation:(NSMutableArray *)inArguments{
    id conversationData = [self getDataFromJSON:inArguments[0]];
    if (conversationData){
        EMConversation *conversation = [self.sharedInstance.chatManager getConversation:[conversationData objectForKey:@"username"] type:[self parseConversationType:conversationData] createIfNotExist:YES];
        
        return conversation;
    }
    else {
        return nil;
    }
    
}
- (void)getConversationByName:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    EMConversation *conversation = [self getConversation:inArguments];
    [self cbGetConversationByName:conversation];
}


- (void)cbGetConversationByName:(EMConversation *)conversation{
    
    NSDictionary *dict = [_mgr analyzeEMConversation:conversation];
    
    [self callBackJSONWithFunction:@"cbGetConversationByName" parameter:dict];
    
}


- (void)getMessageHistory:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    NSString *username = [info objectForKey:@"username"];
    if(!username) return;
    EMConversation *conversation = [self getConversation:inArguments];
    if(!conversation) return;
    NSString *startMsgId = [info objectForKey:@"startMsgId"];
    NSMutableArray *msgList = [NSMutableArray array];
    NSArray *messages;
    int pagesize = 0;
    if([info objectForKey:@"pagesize"]){
        pagesize = [[info objectForKey:@"pagesize"] intValue];
    }
    
    messages = [conversation loadMoreMessagesFromId:startMsgId limit:pagesize];
    for(EMMessage *msg in messages){
        [msgList addObject:[_mgr analyzeEMMessage:msg]];
    }
    [self callBackJSONWithFunction:@"cbGetMessageHistory" parameter:@{@"messages":msgList}];
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
    if(inArguments.count<1){
        return;
    }
    EMConversation *conversation = [self getConversation:inArguments];
    NSUInteger unreadMessageCount = [conversation unreadMessagesCount];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:[NSString stringWithFormat:@"%lu",(unsigned long)unreadMessageCount] forKey:@"count"];
    
    [self callBackJSONWithFunction:@"cbGetUnreadMsgCount" parameter:dict];
    
}

/*
 #####[3.7]resetUnreadMsgCount(param)//指定会话未读消息数清零
 var param = {
 
	username:,//username|groupid
 isGroup:,//是否为群组 1-是 2-否(仅iOS需要)
 }
 */
- (void)resetUnreadMsgCount:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    EMConversation *conversation = [self getConversation:inArguments];
    [conversation markAllMessagesAsRead];
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
    if(inArguments.count<1){
        return;
    }
    EMConversation *conversation = [self getConversation:inArguments];
    [conversation deleteAllMessages];
}
/*
 #####[3.13]removeMessage(param)//删除当前会话的某条聊天记录
 var param = {
 
	username:,//username|groupid
	msgId:,
 isGroup:，//是否为群组 1-是 2-否(仅iOS需要)
 }
 */
- (void)removeMessage:(NSMutableArray*)inArguments{
    if(inArguments.count<1){
        return;
    }
    id conversationData = [self getDataFromJSON:inArguments[0]];

    EMConversation *conversation = [self getConversation:inArguments];
    [conversation deleteMessageWithId:[conversationData objectForKey:@"msgId"]];
    
}
/*
 #####[3.14]deleteAllConversation();//删除所有会话记录(包括本地)
 */
- (void)deleteAllConversation:(NSMutableArray*)array{
    [self.sharedInstance.chatManager deleteConversations:[self.sharedInstance.chatManager getAllConversations] deleteMessages:YES];
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

- (void)getChatterInfo:(NSMutableArray *)inArguments{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSMutableArray *usernamelist = [NSMutableArray array];
        EMError *error = nil;
        NSArray *buddyList = [self.sharedInstance.contactManager getContactsFromServerWithError:&error];
        
        if (!error) {
            for(NSString  *username in buddyList){
                [usernamelist addObject:username];
            }
            
            
        }else{
            return;
        }
        
        error = nil;
        NSMutableArray *grouplist = [NSMutableArray array];
        NSArray *groups = [self.sharedInstance.groupManager getMyGroupsFromServerWithError:&error];
        if (!error) {
            
            for (EMGroup  *group in groups){
                [grouplist addObject:group];
            }
            
        }else{
            return;
        }
        
        
        NSMutableArray *result = [NSMutableArray array];
        for(NSString *username in usernamelist){
            NSMutableDictionary *chatter = [NSMutableDictionary dictionary];
            EMConversation *conversation = [self.sharedInstance.chatManager getConversation:username type:EMConversationTypeChat createIfNotExist:YES];
            [chatter setValue:[_mgr analyzeEMMessage:[conversation latestMessage]]  forKey:@"lastMsg"];
            [chatter setValue:[NSString stringWithFormat:@"%ld",(unsigned long)conversation.unreadMessagesCount] forKey:@"unreadMsgCount"];
            [chatter setValue:username forKey:@"chatter"];
            [chatter setValue:cEMChatTypeUser forKey:@"isGroup"];
            [chatter setValue:cEMChatTypeUser forKey:@"chatType"];
            [result addObject:chatter];
        }
        for(EMGroup *group in grouplist){
            NSMutableDictionary *chatter = [NSMutableDictionary dictionary];
            EMConversation *conversation = [self.sharedInstance.chatManager getConversation:group.groupId type:EMConversationTypeGroupChat createIfNotExist:YES];
            [chatter setValue:[_mgr analyzeEMMessage:[conversation latestMessage]]  forKey:@"lastMsg"];
            [chatter setValue:[NSString stringWithFormat:@"%ld",(unsigned long)conversation.unreadMessagesCount] forKey:@"unreadMsgCount"];
            [chatter setValue:group.groupId forKey:@"chatter"];
            [chatter setValue:group.subject forKey:@"groupName"];
            [chatter setValue:cEMChatTypeGroup forKey:@"isGroup"];
            [chatter setValue:cEMChatTypeGroup forKey:@"chatType"];
            [result addObject:chatter];
        }
        
        [self callBackJSONWithFunction:@"cbGetChatterInfo" parameter:result];
    });
}


- (void)getRecentChatters:(NSMutableArray *)inArguments{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSArray *conversationArray = [_sharedInstance.chatManager loadAllConversationsFromDB];
        NSMutableArray *tmp = [NSMutableArray array];
        for(EMConversation *conversation in conversationArray){
            
            NSMutableDictionary *chatter = [NSMutableDictionary dictionary];
            
            switch (conversation.type) {
                    
                case EMConversationTypeChat:{
                    [chatter setValue:[_mgr analyzeEMMessage:[conversation latestMessage]]  forKey:@"lastMsg"];
                    [chatter setValue:[NSString stringWithFormat:@"%ld",(unsigned long)conversation.unreadMessagesCount] forKey:@"unreadMsgCount"];
                    [chatter setValue:conversation.conversationId forKey:@"chatter"];
                    [chatter setValue:cEMChatTypeUser forKey:@"isGroup"];
                    [chatter setValue:cEMChatTypeUser forKey:@"chatType"];
                    [tmp addObject:chatter];
                }
                    break;
                case EMConversationTypeGroupChat:{
                    [chatter setValue:[_mgr analyzeEMMessage:[conversation latestMessage]]  forKey:@"lastMsg"];
                    [chatter setValue:[NSString stringWithFormat:@"%ld",(unsigned long)conversation.unreadMessagesCount] forKey:@"unreadMsgCount"];
                    [chatter setValue:conversation.conversationId forKey:@"chatter"];
                    EMError *error = nil;
                    EMGroup *group = [_sharedInstance.groupManager searchPublicGroupWithId:conversation.conversationId error:&error];
                    if(!error)[chatter setValue:group.subject forKey:@"groupName"];
                    
                    [chatter setValue:cEMChatTypeGroup forKey:@"isGroup"];
                    [chatter setValue:cEMChatTypeGroup forKey:@"chatType"];
                    [tmp addObject:chatter];
                }
                    break;
                case EMConversationTypeChatRoom:
                    
                    break;
            }
        }
        NSMutableArray *result = [NSMutableArray array];
        for(NSDictionary *dict in tmp){
            if([result count] == 0){
                [result addObject:dict];
            }else{
                NSInteger cTime = [self getTimeStampInChatterInfo:dict];
                BOOL isInsert = NO;
                for(int i = 0;i<[result count];i++){
                    NSDictionary *cpDict = result[i];
                    if(cTime>[self getTimeStampInChatterInfo:cpDict]){
                        [result insertObject:dict atIndex:i];
                        isInsert = YES;
                        break;
                    }
                }
                if(!isInsert)[result addObject:dict];
            }
        }
        [self callBackJSONWithFunction:@"cbGetRecentChatters" parameter:result];
        

    });
    
}


-(NSInteger)getTimeStampInChatterInfo:(NSDictionary*)dict{
    if([dict objectForKey:@"lastMsg"]&&[[dict objectForKey:@"lastMsg"] isKindOfClass:[NSDictionary class]]){
        NSDictionary *msg = [dict objectForKey:@"lastMsg"];
        if([msg objectForKey:@"messageTime"]){
            return [[msg objectForKey:@"messageTime"] integerValue];
        }
    }
    return -1;
}

- (void)getTotalUnreadMsgCount:(NSMutableArray *)inArguments{
    NSInteger count = 0;
    
    NSArray *convs=[self.sharedInstance.chatManager getAllConversations];
    for (EMConversation *conv in convs) {
        count=count+conv.unreadMessagesCount;
    }
    NSDictionary *result = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%ld",(long)count] forKey:@"count"];
    [self callBackJSONWithFunction:@"cbGetTotalUnreadMsgCount" parameter:result];
    
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
- (void)getContactUserNames:(NSMutableArray*)array{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error;
        NSMutableArray *usernames = [NSMutableArray arrayWithCapacity:1];
        NSArray *users=[self.sharedInstance.contactManager getContactsFromServerWithError:&error];
        if (!error) {
            for( NSString *buddy in users){
                [usernames addObject:buddy];
            }
            [self callBackJSONWithFunction:@"cbGetContactUserNames" parameter:usernames];
            
        }
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
    if(inArguments.count<1){
        return;
    }
    id contactInfo = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error = [self.sharedInstance.contactManager addContact:[contactInfo objectForKey:@"toAddUsername"] message:[contactInfo objectForKey:@"reason"]];
        if (!error) {
            //NSLog(@"添加成功");
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
    if(inArguments.count<1){
        return;
    }
    id contactInfo = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error = [self.sharedInstance.contactManager deleteContact:[contactInfo objectForKey:@"username"]];
        if (!error) {
            //NSLog(@"删除成功");
        }
    });
}

- (void)acceptInvitation:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id contactInfo = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error = [self.sharedInstance.contactManager acceptInvitationForUsername:[contactInfo objectForKey:@"username"]];
        if (!error) {
            //NSLog(@"发送同意成功");
        }
    });
}

- (void)refuseInvitation:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id contactInfo = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error = [self.sharedInstance.contactManager declineInvitationForUsername:[contactInfo objectForKey:@"username"]];
        if (!error) {
            // NSLog(@"发送拒绝成功");
        }
    });
}

- (void)getBlackListUsernames:(NSMutableArray *)inArguments{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error;
        NSArray * BlockedList = [self.sharedInstance.contactManager getBlackListFromServerWithError:&error];
        
        [self cbGetBlackListUsernames:BlockedList];
    });
    
}

- (void)cbGetBlackListUsernames:(NSArray *)blockedList{
    
    [self callBackJSONWithFunction:@"cbGetBlackListUsernames" parameter:blockedList];
    
}


- (void)addUserToBlackList:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id contactInfo = [self getDataFromJSON:inArguments[0]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error = [self.sharedInstance.contactManager addUserToBlackList:[contactInfo objectForKey:@"username"] relationshipBoth:YES];
        if (!error) {
            //   NSLog(@"发送成功");
        }
    });
}


- (void)deleteUserFromBlackList:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id contactInfo = [self getDataFromJSON:inArguments[0]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error = [self.sharedInstance.contactManager removeUserFromBlackList:[contactInfo objectForKey:@"username"]];
        if (!error) {
            //   NSLog(@"发送成功");
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
    if(inArguments.count<1){
        return;
    }
    id groupInfo = [self getDataFromJSON:inArguments[0]];
    if(![groupInfo isKindOfClass:[NSDictionary class]]) return;
    
    EMGroupOptions *groupStyleSetting = [[EMGroupOptions alloc] init];
    NSInteger userNumber = [[groupInfo objectForKey:@"maxUsers"] integerValue];
    if (userNumber > 0){
        groupStyleSetting.maxUsersCount = userNumber;
    }
    if ([[groupInfo objectForKey:@"allowInvite"] isEqual:@"true"] || [[groupInfo objectForKey:@"allowInvite"] integerValue] == 1){  /// 创建不同类型的群组，这里需要才传入不同的类型
        groupStyleSetting.style = EMGroupStylePrivateMemberCanInvite;  //所有群成员都可以邀请非成员进群
    }else{
        groupStyleSetting.style = EMGroupStylePrivateOnlyOwnerInvite;  //有创建者可以邀请非成员进群
    }
    
    NSArray *members=[groupInfo objectForKey:@"members"];
    if(![members isKindOfClass:[NSArray class]]){
        members=[[groupInfo objectForKey:@"members"] JSONValue];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error;
        EMGroup *group=[self.sharedInstance.groupManager createGroupWithSubject:[groupInfo objectForKey:@"groupName"] description:[groupInfo objectForKey:@"desc"] invitees:members message:[groupInfo objectForKey:@"initialWelcomeMessage"] setting:groupStyleSetting error:&error];
        
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
    if(inArguments.count<1){
        return;
    }
    id groupInfo = [self getDataFromJSON:inArguments[0]];
     if(![groupInfo isKindOfClass:[NSDictionary class]]) return;
    
    EMGroupOptions *groupStyleSetting = [[EMGroupOptions alloc] init];
    NSInteger userNumber = [[groupInfo objectForKey:@"maxUsers"] integerValue];
    if (userNumber > 0){
        groupStyleSetting.maxUsersCount = userNumber;
    }
    if ([[groupInfo objectForKey:@"needApprovalRequired"] isEqual:@"true"] || [[groupInfo objectForKey:@"needApprovalRequired"] integerValue] == 1){  /// 创建不同类型的群组，这里需要才传入不同的类型
        groupStyleSetting.style = EMGroupStylePublicJoinNeedApproval;  //所有群成员都可以邀请非成员进群
    }else{
        groupStyleSetting.style = EMGroupStylePublicOpenJoin;  //有创建者可以邀请非成员进群
    }
    
    NSArray *members=[groupInfo objectForKey:@"members"];
    if(![members isKindOfClass:[NSArray class]]){
        members=[[groupInfo objectForKey:@"members"] JSONValue];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error;
        EMGroup *group = [self.sharedInstance.groupManager createGroupWithSubject:[groupInfo objectForKey:@"groupName"] description:[groupInfo objectForKey:@"desc"] invitees:members message:[groupInfo objectForKey:@"initialWelcomeMessage"] setting:groupStyleSetting error:&error];
        
        [self onGroupCreatedWithGroup:group andError:error];
    });
}

- (void)onGroupCreatedWithGroup:(EMGroup *)group andError:(EMError *)error{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if(error){
        [dict setValue:@(NO) forKey:@"isSuccess"];
        [dict setValue:error.description forKey:@"errorStr"];
        
    }else{
        [dict setValue:@(YES) forKey:@"isSuccess"];
        [dict setValue:[_mgr analyzeEMGroup:group] forKey:@"group"];
    }
    [self callBackJSONWithFunction:@"onGroupCreated" parameter:dict];
}

- (void)addUsersToGroup:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
  id groupInfo = [self getDataFromJSON:inArguments[0]];
  if(![groupInfo isKindOfClass:[NSDictionary class]]) return;
    
    NSArray *newmembers=[groupInfo objectForKey:@"newmembers"];
    if(![newmembers isKindOfClass:[NSArray class]]){
        newmembers=[[groupInfo objectForKey:@"newmembers"] JSONValue];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error=nil;
        EMGroup *group=[self.sharedInstance.groupManager addOccupants:newmembers toGroup:[groupInfo objectForKey:@"groupId"] welcomeMessage:[groupInfo objectForKey:@"inviteMessage"] error:&error];
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
    if(inArguments.count<1){
        return;
    }
    id removeUser = [self getDataFromJSON:inArguments[0]];
    if(![removeUser isKindOfClass:[NSDictionary class]]) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error=nil;
        if([[removeUser objectForKey:@"username"] isKindOfClass:[NSArray class]]){
            [self.sharedInstance.groupManager removeOccupants:[removeUser objectForKey:@"username"] fromGroup:[removeUser objectForKey:@"groupId"] error:&error];
        }
        if([[removeUser objectForKey:@"username"] isKindOfClass:[NSString class]]){
            error=nil;
            [self.sharedInstance.groupManager removeOccupants:@[[removeUser objectForKey:@"username"]] fromGroup:[removeUser objectForKey:@"groupId"] error:&error];
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
    if(inArguments.count<1){
        return;
    }
    id joinGroupInfo = [self getDataFromJSON:inArguments[0]];
    if(![joinGroupInfo isKindOfClass:[NSDictionary class]]) return;
    NSString *groupId = joinGroupInfo[@"groupId"];
    NSString *groupName = joinGroupInfo[@"groupName"];
    NSString *reason = joinGroupInfo[@"reason"];
//    if (!reason) {
//        [self.sharedInstance.groupManager joinPublicGroup:groupId error:&error];
//    }else{
//        [self.sharedInstance.groupManager applyJoinPublicGroup:groupId message:reason error:&error];
    //    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error=nil;
        EMGroup *group=[self.sharedInstance.groupManager searchPublicGroupWithId:groupId error:&error];
        if(!error){
            if(group.setting.style==EMGroupStylePublicOpenJoin){
                [self.sharedInstance.groupManager joinPublicGroup:groupId error:&error];
            }
            else{
                [self.sharedInstance.groupManager applyJoinPublicGroup:groupId message:reason error:&error];
            }
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
    if(inArguments.count<1){
        return;
    }
    
    id exitInfo = [self getDataFromJSON:inArguments[0]];
    if(![exitInfo isKindOfClass:[NSDictionary class]]) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error=nil;
        [self.sharedInstance.groupManager leaveGroup:[exitInfo objectForKey:@"groupId"] error:&error];
    });
    
}
/*
 #####[5.13]exitAndDeleteGroup(param)//解散群聊
 var param = {
 
	groupId://
 }
 */

- (void)exitAndDeleteGroup:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id exitAndDeleteInfo = [self getDataFromJSON:inArguments[0]];
     if(![exitAndDeleteInfo isKindOfClass:[NSDictionary class]]) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error=nil;
        [self.sharedInstance.groupManager destroyGroup:[exitAndDeleteInfo objectForKey:@"groupId"] error:&error];
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
    if(inArguments.count<1){
        return;
    }
    
    id getGroup = [self getDataFromJSON:inArguments[0]];
    

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    NSArray *groups;
    NSMutableArray *grouplist = [NSMutableArray arrayWithCapacity:10] ;
    
    if ([[getGroup objectForKey:@"loadCache"] isEqual:@"true"]||[[getGroup objectForKey:@"loadCache"] integerValue] == 1){
        [dict setValue:@"0" forKey:@"result"];
        groups = [self.sharedInstance.groupManager loadAllMyGroupsFromDB];
        
        for (EMGroup  *group in groups){
            [grouplist addObject:[_mgr analyzeEMGroup:group]];
        }
        [dict setValue:grouplist forKey:@"grouplist"];
        [self callBackJSONWithFunction:@"cbGetGroupsFromServer" parameter:dict];
    }else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            
            EMError *error=nil;
            NSArray *groups = [self.sharedInstance.groupManager getMyGroupsFromServerWithError:&error];
            if (!error) {
                [dict setValue:@"0" forKey:@"result"];
                for (EMGroup  *group in groups){
                    [grouplist addObject:[_mgr analyzeEMGroup:group]];
                }
                [dict setValue:grouplist forKey:@"grouplist"];
                
            }else{
                [dict setValue:@"1" forKey:@"result"];
            }
            [self callBackJSONWithFunction:@"cbGetGroupsFromServer" parameter:dict];
        });
    }
    
}
/*
 
 #####[5.16]getAllPublicGroupsFromServer();//获取所有公开群列表
 #####[5.17]cbGetAllPublicGroupsFromServer(param)//获取所有公开群列表回调

 */
- (void)getAllPublicGroupsFromServer:(NSMutableArray*)inArguments{
    
    NSInteger pageSize = -1;
    NSString *cursor = nil;
    if([inArguments count]>0){
        id info = [self getDataFromJSON:inArguments[0]];
        if([info objectForKey:@"pageSize"]&&[[info objectForKey:@"pageSize"] length]>0) pageSize = [[info objectForKey:@"pageSize"] integerValue];
        if([info objectForKey:@"cursor"] &&[[info objectForKey:@"cursor"] length]>0) cursor = [info objectForKey:@"cursor"];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error=nil;
        EMCursorResult *result=[self.sharedInstance.groupManager getPublicGroupsFromServerWithCursor:cursor pageSize:pageSize error:&error];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        if(error){
            [dict setValue:@"1" forKey:@"result"];
            [dict setValue:error.description forKey:@"errorMsg"];
        }else{
            [dict setValue:@"0" forKey:@"result"];
            NSMutableArray *grouplist = [NSMutableArray array];
            for(EMGroup *group in result.list){
                [grouplist addObject:[_mgr analyzeEMGroup:group]];
            }
            [dict setValue:grouplist forKey:@"grouplist"];
            [dict setValue:result.cursor forKey:@"cursor"];
        }
        [self callBackJSONWithFunction:@"cbGetAllPublicGroupsFromServer" parameter:dict];
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
    if(inArguments.count<1){
        return;
    }
    id groupInfo = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        EMError *error=nil;
        EMGroup *group= [self.sharedInstance.groupManager fetchGroupInfo:[groupInfo objectForKey:@"groupId"] includeMembersList:YES error:&error];
        [self cbGetGroup:group error:error];
    });
}

- (void)cbGetGroup:(EMGroup *)group
             error:(EMError *)error{
    if(!error){
        [self callBackJSONWithFunction:@"cbGetGroup" parameter:[_mgr analyzeEMGroup:group]];
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
- (void)blockGroupMessage:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id groupInfo = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *pError = nil;
        [self.sharedInstance.groupManager blockGroup:[groupInfo objectForKey:@"groupId"] error:&pError];
    });
    
}
- (void)unblockGroupMessage:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id groupInfo = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *pError = nil;
        [self.sharedInstance.groupManager unblockGroup:[groupInfo objectForKey:@"groupId"] error:&pError];
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
    if(inArguments.count<1){
        return;
    }
    id groupInfo = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error;
        [self.sharedInstance.groupManager changeGroupSubject:[groupInfo objectForKey:@"changedGroupName"] forGroup:[groupInfo objectForKey:@"groupId"] error:&error];
    });
}

- (void)blockUser:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    NSArray *users=[[NSArray alloc]initWithObjects:[info objectForKey:@"username"], nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error = nil;
        [self.sharedInstance.groupManager blockOccupants:users fromGroup:[info objectForKey:@"groupId"] error:&error];
    });
    
}
- (void)unblockUser:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    NSArray *users=[[NSArray alloc]initWithObjects:[info objectForKey:@"username"], nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error = nil;
        [self.sharedInstance.groupManager unblockOccupants:users forGroup:[info objectForKey:@"groupId"] error:&error];
    });
    
}
- (void)getBlockedUsers:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error = nil;
        NSArray *users= [self.sharedInstance.groupManager fetchGroupBansList:[info objectForKey:@"groupId"] error:&error];
        if(!error){
            [self callBackJSONWithFunction:@"cbGetBlockedUsers" parameter:@{@"usernames":users}];
        }
    });
}

- (void)acceptJoinApplication:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error = [self.sharedInstance.groupManager acceptJoinApplication:[info objectForKey:@"groupId"] applicant:[info objectForKey:@"username"]];
    });
}
- (void)declineJoinApplication:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error = [self.sharedInstance.groupManager declineJoinApplication:[info objectForKey:@"groupId"] applicant:[info objectForKey:@"username"] reason:[info objectForKey:@"reason"]];
    });
}

- (void)acceptInvitationFromGroup:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error=nil;
        EMGroup *group = [self.sharedInstance.groupManager acceptInvitationFromGroup:[info objectForKey:@"groupId"] inviter:[info objectForKey:@"username"] error:&error];
    });
}
- (void)declineInvitationFromGroup:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error= [self.sharedInstance.groupManager declineInvitationFromGroup:[info objectForKey:@"groupId"] inviter:[info objectForKey:@"username"] reason:[info objectForKey:@"reason"]];
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
    if(inArguments.count<1){
        return;
    }
    id callInfo = [self getDataFromJSON:inArguments[0]];
    EMError *error;
    _mgr.callSession = [self.sharedInstance.callManager makeVoiceCall:[callInfo objectForKey:@"username"] error:&error];
}


- (void)answerCall:(NSMutableArray *)inArguments{
    
    [self.sharedInstance.callManager answerCall:_mgr.callSession.sessionId];
}

- (void)rejectCall:(NSMutableArray *)inArguments{
    
    [self.sharedInstance.callManager endCall:_mgr.callSession.sessionId reason:EMCallEndReasonDecline];
}

- (void)endCall:(NSMutableArray *)inArguments{
    
    [self.sharedInstance.callManager endCall:_mgr.callSession.sessionId reason:EMCallEndReasonHangup];
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
- (void)registerRemoteNotification:(NSMutableArray *)inArguments{
    UIApplication *application = [UIApplication sharedApplication];
    application.applicationIconBadgeNumber = 0;
    

    
#if !TARGET_IPHONE_SIMULATOR

    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        [application registerForRemoteNotifications];
    }else{
        UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeBadge |
        UIRemoteNotificationTypeSound |
        UIRemoteNotificationTypeAlert;
        [application registerForRemoteNotificationTypes:notificationTypes];
    }
#endif
    
    
    self.mgr.hasRegisteredAPNs = YES;
    
}

// 将得到的deviceToken传给SDK
+ (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    if (![uexEasemobManager sharedInstance].hasRegisteredAPNs) {
        return;
    }
    [[EMClient sharedClient] bindDeviceToken:deviceToken];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@"1" forKey:@"result"];
    [[uexEasemobManager sharedInstance] callBackJSONWithFunction:@"cbRegisterRemoteNotification" parameter:dict];
}

// 注册deviceToken失败
+ (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    if (![uexEasemobManager sharedInstance].hasRegisteredAPNs) {
        return;
    }
    //[[uexEasemobManager sharedInstance].SDK application:application didFailToRegisterForRemoteNotificationsWithError:error];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@"2" forKey:@"result"];
    [dict setValue:[error localizedDescription] forKey:@"errorInfo"];
    [[uexEasemobManager sharedInstance] callBackJSONWithFunction:@"cbRegisterRemoteNotification" parameter:dict];
    
}


- (void)updatePushOptions:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    
    id info = [self getDataFromJSON:inArguments[0]];
    EMError *error;
    //EMPushOptions *options=[self.sharedInstance getPushOptionsFromServerWithError:&error];
    EMPushOptions *options = [self.sharedInstance pushOptions];
    
    if([[info objectForKey:@"nickname"] length]>0){
        options.nickname = [info objectForKey:@"nickname"];
    }
    if([[info objectForKey:@"displayStyle"] length]>0){
        NSInteger displayStyle = [[info objectForKey:@"displayStyle"] integerValue];
        if(displayStyle == 0){
            options.displayStyle = EMPushDisplayStyleSimpleBanner;
        }else if(displayStyle == 1){
            options.displayStyle = EMPushDisplayStyleMessageSummary;
        }
        
    }
    if([[info objectForKey:@"noDisturbingStyle"] length]>0 ){
        NSInteger noDisturbingStyle = [[info objectForKey:@"noDisturbingStyle"] integerValue];
        if(noDisturbingStyle == 0){
            options.noDisturbStatus = EMPushNoDisturbStatusDay ;
        }else if(noDisturbingStyle == 1){
            options.noDisturbStatus = EMPushNoDisturbStatusCustom;
        }else if(noDisturbingStyle == 2){
            options.noDisturbStatus = EMPushNoDisturbStatusClose;
        }
    }
    if([[info objectForKey:@"noDisturbingStartH"] length]>0){
        options.noDisturbingStartH = [[info objectForKey:@"noDisturbingStartH"] integerValue];
    }
    if([[info objectForKey:@"noDisturbingEndH"] length]>0){
        options.noDisturbingEndH = [[info objectForKey:@"noDisturbingEndH"] integerValue];
    }
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error=[self.sharedInstance updatePushOptionsToServer];
        if(!error){
            //        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            //
            //        [dict setValue:options.nickname forKey:@"nickname"];
            //        [dict setValue:[NSString stringWithFormat:@"%lu",(unsigned long)options.noDisturbingStartH] forKey:@"noDisturbingStartH"];
            //        [dict setValue:[NSString stringWithFormat:@"%lu",(unsigned long)options.noDisturbingStartH] forKey:@"noDisturbingEndH"];
            //        NSString *noDisturbStatus;
            //
            //        switch (options.noDisturbStatus) {
            //            case EMPushNoDisturbStatusClose:
            //                noDisturbStatus = @"2";
            //                break;
            //            case EMPushNoDisturbStatusCustom:
            //                noDisturbStatus = @"1";
            //                break;
            //            case EMPushNoDisturbStatusDay:
            //                noDisturbStatus = @"0";
            //            default:
            //                break;
            //        }
            //        NSString *displayStyle = @"";
            //        if(options.displayStyle == EMPushDisplayStyleSimpleBanner){
            //            displayStyle = @"0";
            //        }else if(options.displayStyle == EMPushDisplayStyleMessageSummary){
            //            displayStyle = @"1";
            //        }
            //
            //        [dict setValue:displayStyle forKey:@"displayStyle"];
            //        [dict setValue:noDisturbStatus forKey:@"noDisturbingStyle"];
            //        [self callBackJSONWithFunction:@"cbUpdatePushOptions" parameter:dict];
            [self callBackJSONWithFunction:@"cbUpdatePushOptions" parameter:info];
        }
    });
}
- (void)ignoreGroupPushNotification:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info = [self getDataFromJSON:inArguments[0]];
    BOOL isIgnore=NO;
    if([info objectForKey:@"isIgnore"]){
        if([[info objectForKey:@"isIgnore"] boolValue]==YES){
            isIgnore=YES;
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        EMError *error=[self.sharedInstance.groupManager ignoreGroupPush:[info objectForKey:@"groupId"] ignore:isIgnore];
        if(!error){
            NSArray *groups=[self.sharedInstance.groupManager getAllIgnoredGroupIds];
            [self callBackJSONWithFunction:@"cbIgnoreGroupPushNotification" parameter:@{@"groupIds":groups}];
        }
    });
}




#pragma mark - private method
- (void)callBackJSONWithFunction:(NSString *)functionName parameter:(id)obj{
    [_mgr callBackJSONWithFunction:functionName parameter:obj];
}

- (void)initSettings{
    self.mgr = [uexEasemobManager sharedInstance];
    self.sharedInstance = self.mgr.SDK;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"uexEasemobInitSuccess" object:nil];
}





@end
