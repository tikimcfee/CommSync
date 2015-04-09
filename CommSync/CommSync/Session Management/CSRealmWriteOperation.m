//
//  CSRealmWriteOperation.m
//  CommSync
//
//  Created by Ivan Lugo on 2/20/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSRealmWriteOperation.h"

#import <Realm/Realm.h>

@implementation CSRealmWriteOperation

- (void) main {
    [[RLMRealm defaultRealm] beginWriteTransaction];
    
    [[RLMRealm defaultRealm] addObject:self.pendingTask];
    
    [[RLMRealm defaultRealm] commitWriteTransaction];
}

@end
