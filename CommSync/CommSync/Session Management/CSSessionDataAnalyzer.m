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
#import "CSRealmWriteOperation.h"

// Critical constants for building data transmission strings
#define kCSDefaultStringEncodingMethod NSUTF16StringEncoding
#define kCS_HEADER_NEW_TASK     @"NEW_TASK"
#define kCS_HEADER_TASK_REQUEST @"TASK_REQUEST"
#define kCS_STRING_SEPERATOR    @":"

@implementation CSNewTaskResourceInformationContainer
@end

@interface CSSessionDataAnalyzer ()

//@property (strong, nonatomic) dispatch_queue_t realmAccessThread;
@property (strong, nonatomic) NSOperationQueue* realmWriteQueue;

@end


@implementation CSSessionDataAnalyzer

#pragma mark - Shared instance initializer
+ (CSSessionDataAnalyzer*) sharedInstance:(CSSessionManager*)manager {
    static dispatch_once_t once;
    static CSSessionDataAnalyzer* sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.globalManager = manager;
        sharedInstance.requestPool = [NSMutableDictionary new];
        sharedInstance.realmWriteQueue = [[NSOperationQueue alloc] init];
        sharedInstance.realmWriteQueue.maxConcurrentOperationCount = 1;
    });
    
    return sharedInstance;
}

#pragma mark - Data handling
- (void)session:(MCSession *)session
 didReceiveData:(NSData *)data
       fromPeer:(MCPeerID *)peerID
{
    [self analyzeReceivedData:data fromPeer:peerID];
}

- (void)session:(MCSession *)session
didStartReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
   withProgress:(NSProgress *)progress
{
    // Create a notification dictionary for resource progress tracking
    CSNewTaskResourceInformationContainer* container = [CSNewTaskResourceInformationContainer new];
    container.resourceName = resourceName;
    container.peerID = peerID;
    container.progressObject = progress;
    
    NSDictionary *containerDictionary = @{kCSNewTaskResourceInformationContainer:container};
    
    // Post notification globally
    // NOTE! Receivers of this notification must be intelligent in determining WHAT object has progressed!
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSDidStartReceivingResourceWithName
                                                        object:nil
                                                      userInfo:containerDictionary];
    
    // we have made a request and been served - add it to our pool
    [_requestPool setValue:peerID forKey:resourceName];
    
    /**
     Use this code if you want to observe the progress of a data transfer from the
     data analyzer and then send notifications out as progress changes
     //    dispatch_async(dispatch_get_main_queue(), ^{
     //        [progress addObserver:self
     //                   forKeyPath:@"fractionCompleted"
     //                      options:NSKeyValueObservingOptionNew
     //                      context:nil];
     //    });
     **/
}



- (void)session:(MCSession *)session
didFinishReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
          atURL:(NSURL *)localURL
      withError:(NSError *)error
{
    if (error) {
        NSLog(@"%@",error);
        return;
    }
 
    // Create a notification dictionary for final location and name
    NSDictionary *dict = @{@"resourceName"  :   resourceName,
                           @"peerID"        :   peerID,
                           @"localURL"      :   localURL
                           };
    
    // We have finished our request - get rid out of it
    // TODO
    // PERHAPS MAKE A REQUEST QUEUE?
    [_requestPool removeObjectForKey:resourceName];
    
    // create the task and set up the write for it
    NSData* taskData = [NSData dataWithContentsOfURL:localURL];
    id newTask = [NSKeyedUnarchiver unarchiveObjectWithData:taskData];
    
    if([newTask isKindOfClass:[CSTaskTransientObjectStore class]])
    {
        [self addTaskToWriteQueue:(CSTaskTransientObjectStore*)newTask withID:resourceName];
        [self sendMessageToAllPeersForNewTask:(CSTaskTransientObjectStore*)newTask];
    }
    
    // Post notification globally
    // NOTE! Receivers of this notification must be intelligent in determining WHAT object has progressed!
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSDidFinishReceivingResourceWithName
                                                        object:nil
                                                      userInfo:dict];
}

#pragma mark - Data persistence
- (void) addTaskToWriteQueue:(CSTaskTransientObjectStore*)newTask withID:(NSString*)identifier{
    
    CSRealmWriteOperation* newWriteOperation = [CSRealmWriteOperation new];
    newWriteOperation.pendingTransientTask = newTask;
    [self.realmWriteQueue addOperation:newWriteOperation];
    
}

- (CSTaskTransientObjectStore*) getTransientModelFromQueueOrDatabaseWithID:(NSString*)taskID
{
    // TODO
    // RETURN TASK FROM OPERATION QUEUE
    NSArray* currentWriteQueue = _realmWriteQueue.operations;
    for(CSRealmWriteOperation* operation in currentWriteQueue) {
        if([operation.pendingTransientTask.concatenatedID isEqualToString:taskID]) {
            return operation.pendingTransientTask;
        }
    }
    
    
    
    CSTaskRealmModel* model = [CSTaskRealmModel objectForPrimaryKey:taskID];
    if(model)
        return [CSTaskRealmModel objectForPrimaryKey:taskID].transientModel;

    return nil;
}

#pragma mark - OBSERVATION CALLBACK
/**
 -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
 // Post global notification that the progress of a resource stream has changed.
 // NOTE! Receivers of this notification must be intelligent in determining WHAT object has progressed!
 NSLog(@"Task progress: %f", ((NSProgress *)object).fractionCompleted);
 
 [[NSNotificationCenter defaultCenter] postNotificationName:kCSReceivingProgressNotification
 object:nil
 userInfo:@{@"progress": (NSProgress *)object}];
 }
 **/

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
            
            NSString* newTaskId = [stringComponents objectAtIndex:1];
            
            // check to see if already made request from someone
            BOOL MUST_RETURN = NO;

            if([_requestPool valueForKey:newTaskId])
            {
                NSLog(@"<.> Task ID %@ already requested; no action to be taken.",newTaskId);
                MUST_RETURN = YES;
            }
            
            // check to see if the task already exists
            CSTaskTransientObjectStore* model = [self getTransientModelFromQueueOrDatabaseWithID:newTaskId];
            if(model)
            {
                NSLog(@"<.> Task ID %@ already exists; no action to be taken.",newTaskId);
                MUST_RETURN = YES;
            }
            if(MUST_RETURN)
                return;
            
            // build the request string
            NSString* requestString = [self buildTaskRequestStringFromNewTaskID:newTaskId];
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
            
            NSString* requestedTaskID = [stringComponents objectAtIndex:1];
            
            // check to see if the task exists
            CSTaskTransientObjectStore* model = [self getTransientModelFromQueueOrDatabaseWithID:requestedTaskID];
            if(!model)
            {
                NSLog(@"<?> Task request received, but not found in default database. Possibly a malformed string?");
                return;
            }
            
            // Send the task to the peer
            NSLog(@"<?> Sending requested task with ID [%@] to peer [%@]", requestedTaskID, peer.displayName);
            [_globalManager sendSingleTask:model toSinglePeer:peer];
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
