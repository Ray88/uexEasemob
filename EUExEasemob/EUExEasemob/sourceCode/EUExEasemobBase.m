//
//  EUExEasemobBase.m
//  AppCanPlugin
//
//  Created by AppCan on 15/3/19.
//  Copyright (c) 2015年 zywx. All rights reserved.
//

#import "EUExEasemobBase.h"
#import "JSON.h"
#import "EUExBase.h"

@implementation NSObject (PropertyListing)
//一般对象转化为字典
- (NSMutableDictionary *)properties_aps {
    NSMutableDictionary *props = [NSMutableDictionary dictionaryWithCapacity:2];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        id propertyValue = [self valueForKey:(NSString *)propertyName];
        if (propertyValue) [props setValue:propertyValue forKey:propertyName];
    }
    free(properties);
    return props;
}





@end








@implementation EUExEasemob (JsonIO)

/*
 回调方法name(data)  方法名为name，参数为 字典dict的转成的json字符串
 
 */
-(void) returnJSonWithName:(NSString *)name dictionary:(id)dict{
/*

    
    
    if([NSJSONSerialization isValidJSONObject:dict]){
       NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error
                            ];
 
      NSString *result = [[NSString alloc] initWithData:jsonData  encoding:NSUTF8StringEncoding];
 */
        NSString *result=[dict JSONFragment];
        NSString *jsSuccessStr = [NSString stringWithFormat:@"if(uexEasemob.%@ != null){uexEasemob.%@('%@');}",name,name,result];
    
        [self performSelectorOnMainThread:@selector(callBack:) withObject:jsSuccessStr waitUntilDone:YES];
    
}
-(void)callBack:(NSString *)str{
    [self performSelector:@selector(delayedCallBack:) withObject:str afterDelay:0.01];
    //[meBrwView stringByEvaluatingJavaScriptFromString:str];
}

-(void)delayedCallBack:(NSString *)str{
    [EUtility evaluatingJavaScriptInRootWnd:str];
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

    
@end

@implementation EUExEasemob (ObjectConverting)




//转换EMMessage对象为字典

- (NSMutableDictionary *)convertEMMessageToDict:(EMMessage *)message{

    NSMutableDictionary *result =[NSMutableDictionary dictionary];


    
    [result setValue:message.from forKey:@"from"];
    [result setValue:message.to forKey:@"to"];
    [result setValue:message.messageId forKey:@"messageId"];
    [result setValue:[NSString stringWithFormat:@"%lld",message.timestamp] forKey:@"messageTime"];
    [result setValue:message.isDeliveredAcked?@"1":@"0" forKey:@"isDelievered"];
    [result setValue:message.isReadAcked?@"1":@"0" forKey:@"isAcked"];
    [result setValue:message.isRead?@"1":@"0" forKey:@"isRead"];
    [result setValue:message.isGroup?@"1":@"0" forKey:@"isGroup"];
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
            // 音频sdk会自动下载
            type = @"audio";
            EMVoiceMessageBody *body = (EMVoiceMessageBody *)msgBody;
            [bodyDict setValue:body.remotePath forKey:@"remotePath"];
            [bodyDict setValue:body.secretKey forKey:@"secretKey"];
            [bodyDict setValue:body.displayName forKey:@"displayName"];
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
        }
            break;
        case eMessageBodyType_File:
        {
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
    [result setValue:type forKey:@"messageType"];
    [result setValue:bodyDict forKey:@"messageBody"];
    
    return result;
}
//转换EMConversation对象为字典
- (NSMutableDictionary *)convertEMConversationToDict:(EMConversation *)conversation{
    

    NSMutableDictionary *result =[NSMutableDictionary dictionary];
    [result setValue:conversation.chatter forKey:@"chatter"];
    [result setValue:conversation.isGroup?@"1":@"0" forKey:@"isGroup"];

    NSMutableArray *msgList = [NSMutableArray arrayWithCapacity:1];
    NSArray *messages = [conversation loadAllMessages];
    for(EMMessage *msg in messages){
        
        [msgList addObject:[self convertEMMessageToDict:msg]];

        
    }

    if([msgList count]>0){
        [result setValue:msgList forKey:@"messages"];

    }
    
    
    
    

    
    return result;
}

//转换EMGroup对象为字典
- (NSMutableDictionary *)convertEMGroupToDict:(EMGroup *)group{
    NSMutableDictionary *result =[NSMutableDictionary dictionary];
    [result setValue:group.groupSubject forKey:@"groupSubject"];
    [result setValue:group.members forKey:@"members"];
    [result setValue:group.owner forKey:@"owner"];
    [result setValue:group.isPushNotificationEnabled?@"1":@"0" forKey:@"isPushNotificationEnabled"];
    [result setValue:group.isBlocked?@"1":@"0" forKey:@"isBlocked"];
    NSString *isPublic =@"";
    NSString *allowInvites =@"";
    NSString *membersOnly =@"";
  /*  @constant eGroupStyle_PrivateOnlyOwnerInvite 私有群组，只能owner权限的人邀请人加入
    @constant eGroupStyle_PrivateMemberCanInvite 私有群组，owner和member权限的人可以邀请人加入
    @constant eGroupStyle_PublicJoinNeedApproval 公开群组，允许非群组成员申请加入，需要管理员同意才能真正加入该群组
    @constant eGroupStyle_PublicOpenJoin         公开群组，允许非群组成员加入，不需要管理员同意
    @constant eGroupStyle_PublicAnonymous        公开匿名群组，允许非群组成员加入，不需要管理员同意
    @constant eGroupStyle_Default                默认群组类型*/
    switch (group.groupSetting.groupStyle) {
        case eGroupStyle_PrivateOnlyOwnerInvite:
            isPublic =@"0";
            allowInvites =@"0";
            membersOnly =@"1";
            break;
        case eGroupStyle_PrivateMemberCanInvite:
            isPublic =@"0";
            allowInvites =@"1";
            membersOnly =@"1";

            break;
        case eGroupStyle_PublicJoinNeedApproval:
            isPublic =@"1";
            allowInvites =@"1";
            membersOnly =@"1";
            break;
        case eGroupStyle_PublicOpenJoin :
            isPublic =@"1";
            allowInvites =@"1";
            membersOnly =@"0";
            break;
        case eGroupStyle_PublicAnonymous:
            isPublic =@"1";
            allowInvites =@"1";
            membersOnly =@"0";
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

