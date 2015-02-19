//
//  CSSessionDataAnalyzer.m
//  CommSync
//
//  Created by CommSync on 2/18/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSSessionDataAnalyzer.h"
#import "CSChatMessageRealmModel.h"
#import "CSTaskTransientObjectStore.h"
#import "CSTaskRealmModel.h"


// Critical constants for building data transmission strings
#define kCSDefaultStringEncodingMethod NSUTF16StringEncoding
#define kCS_HEADER_NEW_TASK     @"NEW_TASK"
#define kCS_HEADER_TASK_REQUEST @"TASK_REQUEST"
#define kCS_STRING_SEPERATOR    @":"


@implementation CSSessionDataAnalyzer

#pragma mark - Shared instance initializer
+ (CSSessionDataAnalyzer*) sharedInstance:(CSSessionManager*)manager {
    static dispatch_once_t once;
    static CSSessionDataAnalyzer* sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.globalManager = manager;
        sharedInstance.realm = [RLMRealm defaultRealm];
    });
    
    return sharedInstance;
}

#pragma mark - Data transmission
- (void) sendMessageToAllPeersForNewTask:(CSTaskTransientObjectStore*)task
{
    NSString* newTaskString = [self buildNewTaskStringFromNewTaskID:task.concatenatedID];
    NSData* newTaskData = [newTaskString dataUsingEncoding:kCSDefaultStringEncodingMethod];
    
    [_globalManager sendDataPacketToPeers:newTaskData];
}

#pragma mark - Data analysis
- (void) analyzeReceivedData:(NSData*)receivedData fromPeer:(MCPeerID*)peer
{
    // Determine if data is a string / command
    NSString* stringFromData = [[NSString alloc] initWithData:receivedData encoding:kCSDefaultStringEncodingMethod];
    
    if(stringFromData)
    {
        // -- TASK CREATION --
        // Is the string a prompt of new task creation?
        // Check the task realm for the task; if it does not exist, send the peer a request for the task
        // +++!!!+++ IF IT NEEDS TO BE UPDATED, REQUEST!
        
        // Is the string a request for a task?
        // Make sure you have the requested task, and initiate a resource send of task to the requesting peer
        
        NSLog(@"<?> Data string received : [%@]", stringFromData);
        NSArray* stringComponents = [stringFromData componentsSeparatedByString:kCS_STRING_SEPERATOR];
        if(!stringComponents || stringComponents.count <= 1) {
            NSLog(@"<?> String parse failed - malformed string. [%@]", stringFromData);
            return;
        }
        
        if([[stringComponents objectAtIndex:0] isEqualToString:kCS_HEADER_NEW_TASK])
        {
            if(stringComponents.count > 2)
            {
                NSLog(@"<?> String parse failed - malformed string for NEW_TASK. [%@]", stringFromData);
                return;
            }
            
            // check to see if the task already exists
            CSTaskRealmModel* model = [CSTaskRealmModel objectForPrimaryKey:[stringComponents objectAtIndex:1]];
            if(model)
            {
                NSLog(@"<.> Task ID %@ already exists; no action to be taken.",[stringComponents objectAtIndex:1]);
                return;
            }
            
            // build the request string
            NSString* requestString = [self buildTaskRequestStringFromNewTaskID:(NSString*)[stringComponents objectAtIndex:1]];
            NSData* requestData = [requestString dataUsingEncoding:kCSDefaultStringEncodingMethod];
            
            // send the request
            NSLog(@"<?> Sending request string [%@] to peer [%@]", requestString, peer.displayName);
            [_globalManager sendSingleDataPacket:requestData toSinglePeer:peer];
        }
        else if ([[stringComponents objectAtIndex:0] isEqualToString:kCS_HEADER_TASK_REQUEST])
        {
            if(stringComponents.count > 2)
            {
                NSLog(@"<?> String parse failed - malformed string for TASK_REQUEST. [%@]", stringFromData);
                return;
            }
            
            // check to see if the task exists
            CSTaskRealmModel* model = [CSTaskRealmModel objectForPrimaryKey:[stringComponents objectAtIndex:1]];
            if(!model)
            {
                NSLog(@"<?> Task request received, but not found in default database. Possibly a malformed string?");
                return;
            }
            
            // Send the task to the peer
            NSLog(@"<?> Sending requested task with ID [%@] to peer [%@]", [stringComponents objectAtIndex:1], peer.displayName);
            CSTaskTransientObjectStore* transient = model.transientModel;
            [_globalManager sendSingleTask:transient toSinglePeer:peer];
        }
        
    }
    else
    {
        id receivedObject = [NSKeyedUnarchiver unarchiveObjectWithData:receivedData];
        
        if([receivedObject isKindOfClass:[CSChatMessageRealmModel class]])
        {
            // OP
        }
    }
    
}


#pragma mark - String builders
- (NSString*) buildTaskRequestStringFromNewTaskID:(NSString*)taskID
{
    if(!taskID) {
        NSLog(@"<?> String build failed - no taskID.");
        return nil;
    }
    
    NSString* requestString = [NSString stringWithFormat:@"%@%@%@",
                               kCS_HEADER_TASK_REQUEST,
                               kCS_STRING_SEPERATOR,
                               taskID];
    
    return requestString;
}

- (NSString*) buildNewTaskStringFromNewTaskID:(NSString*)taskID
{
    if(!taskID) {
        NSLog(@"<?> String build failed - no taskID.");
        return nil;
    }
    
    NSString* newTaskString = [NSString stringWithFormat:@"%@%@%@",
                               kCS_HEADER_NEW_TASK,
                               kCS_STRING_SEPERATOR,
                               taskID];
    
    return newTaskString;
}




@end
