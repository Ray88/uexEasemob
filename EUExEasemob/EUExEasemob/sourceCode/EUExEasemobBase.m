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
        NSString *jsSuccessStr = [NSString stringWithFormat:@"if(uexEasemob.%@ != null){uexEasemob.%@(\'%@');}",name,name,result];
    
        [meBrwView stringByEvaluatingJavaScriptFromString:jsSuccessStr];
    
}




//从json字符串中获取数据
- (instancetype)getDataFromJson:(NSString *)jsonData{
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
    NSMutableDictionary *dict =(NSMutableDictionary *)[message properties_aps];
    NSMutableDictionary *dictMsgBody =(NSMutableDictionary *)[message.messageBodies.firstObject properties_aps];
    
    [dict removeObjectForKey:@"messageBodies"];
    [dict removeObjectForKey:@"conversation"];
    NSError *error;
    
    NSString *bodyDescription =[dictMsgBody objectForKey:@"description"];
    NSData *bodyDescriptionData = [bodyDescription dataUsingEncoding:NSUTF8StringEncoding];
    
    
    id body = [NSJSONSerialization JSONObjectWithData:bodyDescriptionData
               
                                              options:NSJSONReadingMutableContainers
               
                                                error:&error];
    [dict setObject:body forKey:@"messageBodies"];
    
    return dict;
}
//转换EMConversation对象为字典
- (NSMutableDictionary *)convertEMConversationToDict:(EMConversation *)conversation{
    
    NSMutableDictionary *dict =(NSMutableDictionary *)[conversation properties_aps];
    
    [dict removeObjectForKey:@"superclass"];
    [dict removeObjectForKey:@"internal"];
    NSMutableArray *msgList = [NSMutableArray arrayWithCapacity:1];
    NSArray *messages = [conversation loadAllMessages];
    for(EMMessage *msg in messages){
        [msgList addObject:[self convertEMMessageToDict:msg]];
    }

    if([msgList count]>0){
        [dict setObject:msgList forKey:@"messages"];

    }
    
    
    
    

    
    return dict;
}

//转换EMGroup对象为字典
- (NSMutableDictionary *)convertEMGroupToDict:(EMGroup *)group{
    NSMutableDictionary *dict =(NSMutableDictionary *)[group properties_aps];
    [dict removeObjectForKey:@"superclass"];
    [dict removeObjectForKey:@"internal"];
    [dict removeObjectForKey:@"groupSetting"];
    [dict removeObjectForKey:@"isPublic"];
    [dict removeObjectForKey:@"groupOccupantsCount"];
    [dict setObject:[NSString stringWithFormat: @"%ld", (long)group.groupSetting.groupMaxUsersCount] forKey:@"groupMaxUsersCount"];
    [dict setObject:[NSString stringWithFormat: @"%ld", (long)group.groupSetting.groupStyle] forKey:@"groupStyle"];
    
    
        return dict;
}
@end

