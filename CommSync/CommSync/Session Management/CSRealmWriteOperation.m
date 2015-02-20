//
//  CSRealmWriteOperation.m
//  CommSync
//
//  Created by Ivan Lugo on 2/20/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSRealmWriteOperation.h"
#import "CSTaskRealmModel.h"
#import "CSTaskTransientObjectStore.h"
#import <Realm/Realm.h>

@implementation CSRealmWriteOperation

- (void) main {
    [[RLMRealm defaultRealm] beginWriteTransaction];
    
    CSTaskRealmModel* newTask = [[CSTaskRealmModel alloc] init];
    [self.pendingTransientTask setAndPersistPropertiesOfNewTaskObject:newTask
                                                              inRealm:[RLMRealm defaultRealm]
                                                      withTransaction:NO];
    
    [[RLMRealm defaultRealm] commitWriteTransaction];
}

@end
