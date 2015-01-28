//
//  CSTaskListManager.m
//  CommSync
//
//  Created by Ivan Lugo on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSTaskListManager.h"
#import "CSTaskRealmModel.h"

#define kNewTaskNotification @"kNewTaskNotification"

@interface CSTaskListManager()

@property (nonatomic, assign) BOOL listIsDirty;

@end

@implementation CSTaskListManager

- (CSTaskListManager*) init
{
    self = [super init];
    
    if(self)
    {
        _currentTaskList = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void) insertTaskIntoList:(CSTaskRealmModel*)newTask
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewTaskNotification
                                                        object:self];
    _listIsDirty = YES;
    return;
}

- (NSMutableArray*)currentTaskList
{
    
    return _currentTaskList;
}



@end
