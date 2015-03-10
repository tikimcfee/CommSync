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

// Implementation of task information container
@implementation CSNewTaskResourceInformationContainer
@end

// Implementation of Data Analysis Operation
@implementation CSDataAnalysisOperation

- (void) main
{
    
    id receivedObject = [NSKeyedUnarchiver unarchiveObjectWithData:_dataToAnalyze];
   
    if([receivedObject isKindOfClass:[NSMutableDictionary class]])
    {
        BOOL foundDifference = NO;
            for(MCPeerID *peerID in [receivedObject allValues])
            {
                if(![_parentAnalyzer.globalManager.peerHistory valueForKey:peerID.displayName] && ![peerID.displayName isEqualToString: _parentAnalyzer.globalManager.myPeerID.displayName]){
                    
                    [_parentAnalyzer.globalManager updatePeerHistory:peerID];
                    foundDifference = YES;
                }
            }
        
            //if there were any diffrerences in the histories then send full history to all peers
            if(foundDifference) [_parentAnalyzer.globalManager sendDataPacketToPeers:_dataToAnalyze];
        
    }

    else if ([receivedObject isKindOfClass:[NSDictionary class]])
    {
        // received new task request or task notification
        if ([receivedObject valueForKey:kCS_HEADER_NEW_TASK])
        {
            NSString* newTaskId = [receivedObject valueForKey:kCS_HEADER_NEW_TASK];
            
            // check to see if already made request from someone
            @synchronized (_requestPool){
                if([_requestPool valueForKey:newTaskId])
                {
                    NSLog(@"<.> Task ID %@ already requested; no action to be taken.",newTaskId);
                    return;
                }
            }
            
            // check to see if the task already exists
            CSTaskTransientObjectStore* model = [_parentAnalyzer getTransientModelFromQueueOrDatabaseWithID:newTaskId];
            if(model)
            {
                NSLog(@"<.> Task ID %@ already exists; no action to be taken.",newTaskId);
                return;
            }
            
            @synchronized (_requestPool){
                [_requestPool setValue:_peer forKey:newTaskId];
            }
            
            // build the request string
            NSDictionary* requestDictionary = [_parentAnalyzer buildTaskRequestFromTaskID:newTaskId];
            NSData* requestData = [NSKeyedArchiver archivedDataWithRootObject:requestDictionary];
            
            // send the request
            NSLog(@"<?> Sending request string [%@] to peer [%@]", requestDictionary, _peer.displayName);
            [_parentAnalyzer.globalManager sendSingleDataPacket:requestData toSinglePeer:_peer];
        }
        else if ([receivedObject valueForKey:kCS_HEADER_TASK_REQUEST])
        {
            NSString* requestedTaskID = [receivedObject valueForKey:kCS_HEADER_TASK_REQUEST];
            
            // check to see if the task exists
            CSTaskTransientObjectStore* model = [_parentAnalyzer getTransientModelFromQueueOrDatabaseWithID:requestedTaskID];
            if(!model)
            {
                NSLog(@"<?> Task request received, but not found in default database. Possibly a malformed dictionary?");
                return;
            }
            
            // Send the task to the peer
            NSLog(@"<?> Sending requested task with ID [%@] to peer [%@]", requestedTaskID, _peer.displayName);
            [_parentAnalyzer.globalManager sendSingleTask:model toSinglePeer:_peer];
        }
        else // unknown key sent in dictionary
        {
            // log some error here
        }
        
    }
    else if ([receivedObject isKindOfClass:[CSChatMessageRealmModel class]])
    {
        CSChatMessageRealmModel* temp = receivedObject;
        
        NSString* newTaskId =[temp.createdBy stringByAppendingString:(NSString*)temp.messageText];
        @synchronized (_requestPool){
            if([_requestPool valueForKey:newTaskId] || [temp.createdBy isEqualToString: _parentAnalyzer.globalManager.myPeerID.displayName])
            {
                NSLog(@"<.> Task ID %@ already requested; no action to be taken.",newTaskId);
                return;
            }
        }
        @synchronized (_requestPool){
            [_requestPool setValue:_peer forKey:newTaskId];
        }
        
        //if the message is a public message
        if([temp.recipient isEqualToString:@"ALL"] )
        {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
            NSString *url = [basePath stringByAppendingString:@"/chat.realm"];
        
            RLMRealm *chatRealm = [RLMRealm realmWithPath:url];
        
            //if the chat message already exists then exit otherwise add it and send it to all peers
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"createdBy = %@ AND createdAt = %@",
                             temp.createdBy, temp.createdAt];
            
            if([[CSChatMessageRealmModel objectsInRealm:chatRealm withPredicate:pred] count] != 0) return;
        
            [chatRealm beginWriteTransaction];
            [chatRealm addObject:receivedObject];
            [chatRealm commitWriteTransaction];
        
            [_parentAnalyzer.globalManager sendDataPacketToPeers:_dataToAnalyze];
            return;
        }
        //the message is a private message
        else{
            //if the message is meant for someone else then propagate it so they get it
            if(![temp.recipient isEqualToString:_parentAnalyzer.globalManager.myPeerID.displayName]){
                
                    if([_parentAnalyzer.globalManager.sessionLookupDisplayNamesToSessions valueForKey:temp.recipient])
                    {
                        //the user is connected to the target so we can send it directly
                        [_parentAnalyzer.globalManager sendSingleDataPacket:_dataToAnalyze toSinglePeer: [_parentAnalyzer.globalManager.peerHistory valueForKey:temp.recipient]];
                        return;
                    }
                
                [_parentAnalyzer.globalManager sendDataPacketToPeers:_dataToAnalyze];
            }
            
            else{
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
                NSString *url = [basePath stringByAppendingString:@"/privateMessage.realm"];
                
                //if the chat message already exists then exit otherwise add it and send it to all peers
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"createdBy = %@ AND createdAt = %@",
                                     temp.createdBy, temp.createdAt];
                
                 RLMRealm *privateMessageRealm = [RLMRealm realmWithPath:url];
                
                if([[CSChatMessageRealmModel objectsInRealm:privateMessageRealm withPredicate:pred] count] != 0) return;
                
                
                
                
                [privateMessageRealm beginWriteTransaction];
                [privateMessageRealm addObject:receivedObject];
                [privateMessageRealm commitWriteTransaction];
            }
        }
    }
    
}

@end

/**
 END OF HEADER IMPLEMENTATIONS --  END OF HEADER IMPLEMENTATIONS --  END OF HEADER IMPLEMENTATIONS
 END OF HEADER IMPLEMENTATIONS --  END OF HEADER IMPLEMENTATIONS --  END OF HEADER IMPLEMENTATIONS
 END OF HEADER IMPLEMENTATIONS --  END OF HEADER IMPLEMENTATIONS --  END OF HEADER IMPLEMENTATIONS
 END OF HEADER IMPLEMENTATIONS --  END OF HEADER IMPLEMENTATIONS --  END OF HEADER IMPLEMENTATIONS
 **/

@interface CSSessionDataAnalyzer ()
@property (strong, nonatomic) NSOperationQueue* realmWriteQueue;
@property (strong, nonatomic) NSOperationQueue* dataAnalysisQueue;
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
        
        sharedInstance.dataAnalysisQueue = [NSOperationQueue new];
        sharedInstance.dataAnalysisQueue.maxConcurrentOperationCount = 1;
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
    @synchronized (_requestPool){
        [_requestPool setValue:peerID forKey:resourceName];
    }
    
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
    @synchronized (_requestPool){
        [_requestPool removeObjectForKey:resourceName];
    }
    
    
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
    NSDictionary* newTaskDictionary = [self buildNewTaskNotificationFromTaskID:task.concatenatedID];
    NSData* newTaskData = [NSKeyedArchiver archivedDataWithRootObject:newTaskDictionary];
    
    [_globalManager sendDataPacketToPeers:newTaskData];
}

#pragma mark - Data analysis
- (void) analyzeReceivedData:(NSData*)receivedData fromPeer:(MCPeerID*)peer
{
    CSDataAnalysisOperation* newOperation = [CSDataAnalysisOperation new];
    newOperation.dataToAnalyze = receivedData;
    newOperation.peer = peer;
    newOperation.requestPool = _requestPool;
    newOperation.parentAnalyzer = self;
    
    [_dataAnalysisQueue addOperation:newOperation];
}


#pragma mark - String builders
- (NSDictionary *) buildTaskRequestFromTaskID:(NSString*)taskID
{
    if(!taskID) {
        NSLog(@"DataAnalyzer(ERROR): String build failed - no taskID.");
        return nil;
    }
    
    return @{ kCS_HEADER_TASK_REQUEST: taskID };
}

- (NSDictionary*) buildNewTaskNotificationFromTaskID:(NSString*)taskID
{
    if(!taskID) {
        NSLog(@"DataAnalyzer(ERROR): String build failed - no taskID.");
        return nil;
    }
    
    return @{ kCS_HEADER_NEW_TASK: taskID };
}




@end
