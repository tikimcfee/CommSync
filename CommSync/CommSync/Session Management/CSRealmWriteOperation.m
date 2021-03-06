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

@interface CSRealmWriteOperation()

//@property (strong, nonatomic) RLMNotificationToken* changeToken;

@end

@implementation CSRealmWriteOperation

- (void) main {
    
    RLMRealm* taskRealm = [RLMRealm defaultRealm];
   
    if (!_pendingRevision) {
        RLMRealm* incomingTaskRealm = [CSRealmFactory incomingTaskRealm];
        
        [taskRealm beginWriteTransaction];
        [taskRealm addObject:self.pendingTask];
        [taskRealm commitWriteTransaction];
        
        NSString* string = [NSString stringWithFormat:@"%@_INCOMING", _pendingTask.concatenatedID];
        CSIncomingTaskRealmModel* toDelete = [CSIncomingTaskRealmModel objectInRealm:incomingTaskRealm
                                                                       forPrimaryKey:string];
        [incomingTaskRealm beginWriteTransaction];
        [incomingTaskRealm deleteObject:toDelete];
        [incomingTaskRealm commitWriteTransaction];
    } else {
        CSTaskRealmModel* modelToUpdate = [CSTaskRealmModel objectInRealm:taskRealm forPrimaryKey:_taskID];
        [taskRealm beginWriteTransaction];
        [modelToUpdate.revisions addObject:_pendingRevision];
        [taskRealm commitWriteTransaction];
    }
    
}

@end
