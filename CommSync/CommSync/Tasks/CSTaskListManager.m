//
//  CSTaskListManager.m
//  CommSync
//
//  Created by Ivan Lugo on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSTaskListManager.h"

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

- (void) insertTaskIntoList:(CSTask*)newTask
{
    if(_rootTask != nil)
    {
        [self insertTaskIntoList:newTask atNode:_rootTask];
    }
    else
    {
        _rootTask = newTask;
    }
    
    _listIsDirty = YES;
    return;
}

- (void) insertTaskIntoList:(CSTask*)newTask atNode:(CSTask*)node
{
    NSComparisonResult result = [node.concatenatedID compare:newTask.concatenatedID];
    
    if(result == NSOrderedAscending)
    {
        if(node.leftChild)
        {
            [self insertTaskIntoList:newTask atNode:node.leftChild];
        }
        else
        {
            node.leftChild = newTask;
        }
    }
    else if(result == NSOrderedDescending)
    {
        if(node.rightChild)
        {
            [self insertTaskIntoList:newTask atNode:node.rightChild];
        }
        else
        {
            node.rightChild = newTask;
        }
    }
    else
    {
        // ignore
    }
    
    return;
}

- (void) resetCurrentTaskList
{
    _currentTaskList = [[NSMutableArray alloc] initWithCapacity:[_currentTaskList count]];
    [self convertCurrentTreeIntoListAtNodeDescending:_rootTask];
}

- (void) convertCurrentTreeIntoListAtNodeAscending:(CSTask*)node
{
    if(node.leftChild == nil && node.rightChild == nil)
    {
        [_currentTaskList addObject:node];
        return;
    }
    
    if(node.leftChild)
        [self convertCurrentTreeIntoListAtNodeAscending:node.leftChild];
    
    [_currentTaskList addObject:node];

    if(node.rightChild)
        [self convertCurrentTreeIntoListAtNodeAscending:node.rightChild];
    
    return;
}

- (void) convertCurrentTreeIntoListAtNodeDescending:(CSTask*)node
{
    if(node.leftChild == nil && node.rightChild == nil)
    {
        [_currentTaskList addObject:node];
        return;
    }
    
    if(node.rightChild)
        [self convertCurrentTreeIntoListAtNodeDescending:node.rightChild];
    
    [_currentTaskList addObject:node];
    
    if(node.leftChild)
        [self convertCurrentTreeIntoListAtNodeDescending:node.leftChild];
    
    return;
}

- (NSMutableArray*)currentTaskList
{
    if(_listIsDirty)
    {
        [self resetCurrentTaskList];
        _listIsDirty = NO;
    }
    
    return _currentTaskList;
}



@end
