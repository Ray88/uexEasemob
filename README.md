#uexEasemob插件接口文档
2015-04-17  初稿by:刘康立
2015-04-20	新增[2.12][2.13]方法
			修改了[2.1]的回调值的结构
			统一了Android和iOS返回的json对象的结构，对附录做了大量修订

###[1]Initialization
***
#####[1.1] initEasemob(param) //初始化

  var param{
  
	appKey:,//区别app的标识       
	apnsCertName:,//iOS中推送证书名称
    
	//Android 中此参数需要在AndroidManifest.xml中配置
}

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

#####[1.4]logout() //退出登录

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

#####[1.7]updateCurrentUserNickname(param) // 更新当前用户的昵称

var param = {	
	
	nickname:,
}

	注：此方法主要为了在苹果推送时能够推送昵称(nickname)而不是userid,一般可以在登陆成功后从自己服务器获取到个人信息，然后拿到nick更新到环信服务器。并且，在个人信息中如果更改个人的昵称，也要把环信服务器更新下nickname 防止显示差异。


#####[1.8]getLoginInfo()//获取当前登陆信息(仅iOS可用)

#####[1.9]cbGetLoginInfo(param)//获取当前登陆信息的回调（仅iOS）

 var param={
 
	userInfo://当前登陆用户信息
	isLoggedIn://当前是否已有登录用户  1-是 2-否
	isConnected://是否连上聊天服务器   1-是 2-否
}
#####[1.10]onConnected();//已连接上（仅Android可用）
#####[1.11]onDisconnected(param)//链接断开
var param = {

	error:,//1-账号被移除，2-账号其他设备登陆，3-连接不到聊天服务器，4-当前网络不可用 
};


###[2]Message
***
#####[2.1]onNewMessage（param）//收到新消息监听



	注：param为EMMessage的json格式对象
	EMMessage具体结构见文末附录
	所有离线和在线时接受到的的非透传消息，都通过此回调传递
	   
#####[2.2]onCmdMessageReceive(param)//透传消息监听
var param = {

	msgId:,
	message:,//EMMessage 对象json格式
	action:,
}
#####[2.3]onAckMessage(param)//消息已读监听
var param = {

	msgId:,//消息ID
	username:,//来源
};
#####[2.4]onDeliveryMessage(param)//消息送达监听
var param = {

	msgId:,//消息ID
	username:,//来源
};
#####[2.5]sendText(param)//发送文本消息及表情
var param = {

	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	content:,//文本内容
}
#####[2.6]sendVoice(param)//发送语音
var param = {
	
	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	filePath:,//语音文件路径
	length:,//长度(仅Android需要)
	displayName：//对方接收时显示的文件名（仅iOS需要）
}

#####[2.7]sendPicture(param)//发送图片
var param = {

	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	filePath:,//图片文件路径
	displayName:,//对方接收时显示的文件名（仅iOS需要）
}
#####[2.8]sendLocationMsg(param)//发送地理位置信息
var param = {

	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	locationAddress:,//图片文件路径
	latitude:,
	longitude:,

}
#####[2.9]sendFile(param)//发送文件
var param = {

	username:,//单聊时聊天人的userid或者群聊时groupid
	chatType:,//1-单聊，2-群聊
	filePath:,//文件路径
	displayName:,//对方接收时显示的文件名（仅iOS需要）
}
#####[2.10]sendCmdMessage(param)//发送透传消息
	var param = {
	chatType:,//1-单聊，2-群聊
	action:,//
	toUsername:,//
}
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
#####[2.12]getMessageById(param)//根据id获取消息记录（仅Android可用）
var param = {

	msgId:,//消息ID
};
#####[2.13]cbGetMessageById(param)//得到一条消息记录（仅Android可用）
var param = {

	msg:,// EMMessage的json格式对象
};
	
	
###[3]Conversation
***
#####[3.1]getConversationByName(param)//根据用户名获取conversation对象
var param = {

	username:,
	isGroup:,//是否为群组 1-是 2-否(仅iOS需要)
};
#####[3.2]cbGetConversationByName(param)//回调
var param = {

	conversation:,// EMConversation的json格式对象，格式见附录
};

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



#####[3.5]getUnreadMsgCount(param)//获取未读消息数量
var param = {

	username:,//username|groupid
    isGroup:,//是否为群组 1-是 2-否(仅iOS需要)
}
#####[3.6]cbGetUnReadMsgCount(param)//获取未读消息数量回调
var param = {

	count:,//未读消息数
}
#####[3.7]resetUnreadMsgCount(param)//指定会话未读消息数清零
var param = {

	username:,//username|groupid
    isGroup:,//是否为群组 1-是 2-否(仅iOS需要)
}


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


#####[3.12]deleteConversation(param)//删除和某个user的整个的聊天记录(包括本地)
var param = {

	username:,//username|gr	oupid
    isGroup:,//是否为群组 1-是 2-否(仅iOS需要)
}
#####[3.13]removeMessage(param)//删除当前会话的某条聊天记录
var param = {

	username:,//username|groupid
	msgId:,
    isGroup:，//是否为群组 1-是 2-否(仅iOS需要)
}
#####[3.14]deleteAllConversation();//删除所有会话记录(包括本地)

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
#####[4.3]onContactInvited(param)//接到好友申请
var param = {

	username:,//
	reason:,//
};
#####[4.4]onContactAgreed(param)//好友请求被同意
var param = {

	username:,//
};



#####[4.5]onContactRefused(param)//好友请求被拒绝
var param = {

	username:,//
};
#####[4.6]getContactUserNames();//获取好友列表


#####[4.7]cbGetContactUserNames(param)//获取好友列表回调
var param = {

	usernames:,//用户姓名字符串构成的数组	
	
}
	

    		
    		
#####[4.8]addContact(param)//添加好友
var param = {

	toAddUsername:,//要添加的好友
	reason:
}
#####[4.9]deleteContact(param)//删除好友
var param = {

	username:,//
}
#####[4.10]acceptInvitation(param)//同意username的好友请求
var param = {

	username:,//
}
#####[4.11]refuseInvitation(param)//拒绝username的好友请求
var param = {

	username:,//
	reason:,//拒绝好友请求原因（仅iOS需要）
}
#####[4.12]getBlackListUsernames();//获取黑名单列表
#####[4.13]cbGetBlackListUsernames(param)//获取黑名单列表回调
var param = {

	usernames:,//List<String> json格式
}
#####[4.14]addUserToBlackList(param)//把用户加入到黑名单
var param = {

	username:,//
}
#####[4.15]deleteUserFromBlackList(param)//把用户从黑名单中移除
var param = {

	username:,//
}


###[5]Group
***
#####[5.1]onInvitationDeclined(param)//群聊邀请被拒绝
var param = {

	groupId:,
	invitee:,
	reason:,
}




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



#####[5.4]onApplicationReceived(param)//用户申请加入群聊，收到加群申请
var param = {

	groupId:,
	groupName:,
	applyer:,
	reason:,
}


#####[5.5]onApplicationAccept(param)// // 加群申请被同意
var param = {

	groupId:,
	groupName:,
	accepter:,
}


#####[5.6]onApplicationDeclined(param)//加群申请被拒绝
var param = {

	groupId:,//（仅Android）
	groupName:,
	decliner:,
	reason:,
}

#####[5.7]createPrivateGroup(param)//创建私有群
var param = {

	groupName:,//要创建的群聊的名称
	desc://群聊简介
	members://群聊成员,为空时这个创建的群组只包含自己
	allowInvite://是否允许群成员邀请人进群
	maxUsers://最大群聊用户数，可选参数，默认为200，最大为2000
	initialWelcomeMessage://群组创建时发送给每个初始成员的欢迎信息（仅iOS需要）
}
#####[5.8]createPublicGroup(param)//创建公开群
var param = {

	groupName:,//要创建的群聊的名称
	desc://群聊简介
	members://群聊成员,为空时这个创建的群组只包含自己
	needApprovalRequired://如果创建的公开群用需要户自由加入，就传false。否则需要申请，等群主批准后才能加入，传true
	maxUsers://最大群聊用户数，可选参数，默认为200，最大为2000
  	initialWelcomeMessage://群组创建时发送给每个初始成员的欢迎信息（仅iOS需要）
}





#####[5.9]addUsersToGroup(param)//群聊加人
var param = {

	isGroupOwner:,//是否群主(仅Android需要)
	groupId://
	newmembers://群聊新成员，List<String> Json格式
    inviteMessage:// 新增参数 邀请信息
 

}




#####[5.10]removeUserFromGroup(param)//群聊减人
var param = {

	groupId://
	username://
} 

	只有owner才有权限进行此操作
#####[5.11]joinGroup(param)//加入某个群聊，只能用于加入公开群
var param = {

	groupId://
	reason:// //如果群开群是自由加入的，即group.isMembersOnly()为false，此参数不传
    groupName://群组名称
}
#####[5.12]exitFromGroup(param)//退出群聊
var param = {

	groupId://
}
#####[5.13]exitAndDeleteGroup(param)//解散群聊
var param = {

	groupId://
}
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


#####[5.16]getAllPublicGroupsFromServer();//获取所有公开群列表
#####[5.17]cbGetAllPublicGroupsFromServer(param)//获取所有公开群列表回调
var param = {
	
	result://0-成功，1-失败
	grouplist:List< EMGroup> json格式 见附录
	errorMsg:
}


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

#####[5.20]blockGroupMessage(param)//屏蔽群消息
var param = {

	groupId:// 
}

#####[5.21]unblockGroupMessage(param)//解除屏蔽群
var param = {

	groupId:// 
}
#####[5.22]changeGroupName(param)//修改群组名称
var param = {

	groupId:// 
	changedGroupName:,//改变后的群组名称
}

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
#####[5.28]onGroupUpdateInfo(param)//群组信息更新的监听（仅iOS）
var param={

        group:,//EMGroup对象的json格式字符串
   }

	每当添加/移除/更改角色/更改主题/更改群组信息之后,都会触发此回调
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

###[7]APNs(仅iOS)
***
#####[7.1]registerRemoteNotification();//注册Apns推送
#####[7.2]cbRegisterRemoteNotification(param);//回调
var param{

	result;//1-成功 2-失败
	errorInfo;//注册失败时的推送信息
}

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


#####[7.5]ignoreGroupPushNotification(param)://设置指定群组是否接收
var param{

	groupId;//指定的群组Id
	isIgnore;//1-屏蔽  2-取消屏蔽
}

#####[7.6]cbIgnoreGroupPushNotification(param)://回调
var param{

	groups;//已屏蔽接收推送消息的群列表
}


##附录

####EMMessage json字符串返回值结构  


key |说明         
------------ | ------------- 
from| 发送者        
to | 接受者  
messageId|消息id
messageTime|消息发送或接收的时间
isAcked|是否接收到了接收方的阅读回执, 或是否已发送了阅读回执给对方
isDelivered|对于发送方来说, 该值表示:接收方是否已收到了消息, 对于接收方来说, 表示:接收方是否已发送了"已接收回执" 给对方
isRead	|是否已读
isGroup|是否来源于群组
messageType|消息类型  text/video/audio/image/location/file/cmd
messageBody|消息主体json

messageBody的结构为

#####普通文本消息
	
key |说明         
-------- | ------
text| 文本内容

#####透传消息
	
key |说明         
-------- | ------
action| 具体命令 

#####位置消息
key |说明         
-------- | ------ 
longitute| 经度
latitude|纬度
address|地理位置信息


#####视频/语音/图片/文件消息
	
	
key |说明         
-------- | ------
displayName|显示名
remotePath	|服务器远程文件路径	
secretKey	|远端文件的密钥	
thumbnailRemotePath|预览图文件的服务器远程路径(仅视频/图片消息)
thumbnailSecretKey|预览图文件的密钥(仅视频/图片消息)
 


 





	返回的json数据中会包含除上述属性之外的一些其他信息，均可以忽略

####EMConversation json字符串返回值结构 


key |说明         
------------ | -------------
chatter	|conversation识别名
isGroup	|是否为群组
messages	|"conversation所包含的message列表，表内元素为EMMessage的json字符串"
	
	



	返回的json数据中会包含除上述属性之外的一些其他信息，均可以忽略
#### EMGroup json字符串返回值结构 


key |说明         
------------ | -------------
groupSubject	|群组名
members	|包含的成员
owner	|群主
isPushNotificationEnable	|是否允许推送提醒
isBlock	|是否被用户屏蔽
groupMaxUserCount	|群组最大人数
groupId	|群组Id
isPublic|群组类型
allowInvites|是否允许群成员邀请人进群
membersOnly|需要申请和验证才能加入



## android混淆配置
如果应用进行混淆，需要加上如下配置：
~~~
##---------------Begin: proguard configuration for Gson  ----------
# Gson uses generic type information stored in a class file when working with fields. Proguard
# removes such information by default, so configure it to keep all of it.
-keepattributes Signature

# For using GSON @Expose annotation
-keepattributes *Annotation*

# Gson specific classes
-keep class sun.misc.Unsafe { *; }
#-keep class com.google.gson.stream.** { *; }

# Application classes that will be serialized/deserialized over Gson
-keep class org.zywx.wbpalmstar.widgetone.uexEasemob.vo.** { *; }
-keep class com.google.gson.** {*;}
-keep class * implements java.io.Serializable {*;}
##---------------End: proguard configuration for Gson  ----------
~~~