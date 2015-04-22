//
//  CSRealmWriteOperation.m
//  CommSync
//
//  Created by Ivan Lugo on 2/20/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSRealmWriteOperation.h"
#import "CSSessionManager.h"
#import "CSIncomingTaskRealmModel.h"

#import <Realm/Realm.h>

@interface CSRealmWriteOperation()

//@property (strong, nonatomic) RLMNotificationToken* changeToken;

@end

@implementation CSRealmWriteOperation

- (void) main {
    
    RLMRealm* taskRealm = [RLMRealm defaultRealm];
    RLMRealm* incomingTaskRealm = [RLMRealm realmWithPath:[CSSessionManager incomingTaskRealmDirectory]];

    [taskRealm beginWriteTransaction];
    [taskRealm addObject:self.pendingTask];
    [taskRealm commitWriteTransaction];
    
    NSString* string = [NSString stringWithFormat:@"%@_INCOMING", _pendingTask.concatenatedID];
    CSIncomingTaskRealmModel* toDelete = [CSIncomingTaskRealmModel objectInRealm:incomingTaskRealm
                                                                   forPrimaryKey:string];
    [incomingTaskRealm beginWriteTransaction];
    [incomingTaskRealm deleteObject:toDelete];
    [incomingTaskRealm commitWriteTransaction];
    
}

@end
