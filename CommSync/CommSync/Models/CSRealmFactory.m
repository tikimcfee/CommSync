//
//  CSRealmFactory.m
//  CommSync
//
//  Created by CommSync on 4/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSRealmFactory.h"

@implementation CSRealmFactory

+ (RLMRealm*)peerHistoryRealm {
    return [RLMRealm realmWithPath:[CSRealmFactory peerHistoryRealmDirectory]];
}

+ (RLMRealm*)incomingTaskRealm {
    return [RLMRealm realmWithPath:[CSRealmFactory incomingTaskRealmDirectory]];
}
+ (RLMRealm*)chatMessageRealm {
    return [RLMRealm realmWithPath:[CSRealmFactory chatMessageRealmDirectory]];
}

+ (RLMRealm*)privateMessageRealm {
    return [RLMRealm realmWithPath:[CSRealmFactory privateMessageRealmDirectory]];
}

+ (RLMRealm*)taskRealm {
    return [RLMRealm defaultRealm];
}

+ (NSString *)peerHistoryRealmDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:@"/peers.realm"];
}

+ (NSString*)incomingTaskRealmDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:@"/incomingTasks.realm"];
}

+ (NSString *)chatMessageRealmDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:@"/chat.realm"];
}

+ (NSString *)privateMessageRealmDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:@"/privateMessage.realm"];
}

@end
