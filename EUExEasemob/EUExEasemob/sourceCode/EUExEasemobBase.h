//
//  EUExEasemobBase.h
//  AppCanPlugin
//
//  Created by AppCan on 15/3/19.
//  Copyright (c) 2015年 zywx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "EMSDKFull.h"
#import "EaseMob.h"
#import "EUExEasemob.h"
#import "EUExBaseDefine.h"
#import "EUtility.h"



// ObjectToDictionary
@interface NSObject (PropertyListing)

- (NSDictionary *)properties_aps;

@end



@interface EUExEasemob (JsonIO)


 //回调名为name 内容为dict的json字符串

-(void) returnJSonWithName:(NSString *)name dictionary:(id)dict;


//通过JSON获取数据
- (instancetype)getDataFromJson:(NSString *)jsonData;



@end

@interface  EUExEasemob (ObjectConverting)


//转换EMMessage对象为字典

- (NSMutableDictionary *)convertEMMessageToDict:(EMMessage *)message;

//转换EMConversation对象为字典
- (NSMutableDictionary *)convertEMConversationToDict:(EMConversation *)conversation;


//转换EMGroup对象为字典
- (NSMutableDictionary *)convertEMGroupToDict:(EMGroup *)group;
@end





