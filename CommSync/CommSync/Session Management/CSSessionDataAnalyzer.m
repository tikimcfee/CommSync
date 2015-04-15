//
//  CSSessionDataAnalyzer.m
//  CommSync
//
//  Created by CommSync on 2/18/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSSessionDataAnalyzer.h"
#import "CSChatMessageRealmModel.h"
#import "CSTaskRealmModel.h"
#import "CSIncomingTaskRealmModel.h"
#import "CSRealmWriteOperation.h"

// Critical constants for building data transmission strings
#define kCSDefaultStringEncodingMethod NSUTF16StringEncoding
#define kCS_HEADER_NEW_TASK     @"NEW_TASK"
#define kCS_HEADER_TASK_REQUEST @"TASK_REQUEST"
#define kCS_STRING_SEPERATOR    @":"
#define kCS_User_UpdateAvatar   @"Avatar"

// Implementation of task information container
@implementation CSNewTaskResourceInformationContainer
@end

// Implementation of Data Analysis Operation
@implementation CSDataAnalysisOperation

- (void) main
{
    
    id receivedObject = [NSKeyedUnarchiver unarchiveObjectWithData:_dataToAnalyze];
    
    
    if([receivedObject isKindOfClass:[NSMutableArray class]])
    {
        if([receivedObject count] == 0) return;
        
            if([receivedObject[0] isKindOfClass:[NSString class]])
            {
                dispatch_sync(_parentAnalyzer.globalManager.taskRealmQueue,^{
                    for(NSString* task in receivedObject)
                        [self propagateTasks:[[CSSessionDataAnalyzer sharedInstance:nil] buildTaskRequestFromTaskID:task]];
                });
            }
            
            else if([receivedObject[0]isKindOfClass:[CSUserRealmModel class]])
            {
                dispatch_async(dispatch_get_main_queue(),^{
                    NSMutableArray* differences = [[NSMutableArray alloc]init];
                    for(CSUserRealmModel *peer in receivedObject)
                    {
                        if(![CSUserRealmModel objectInRealm:_parentAnalyzer.globalManager.peerHistoryRealm forPrimaryKey:peer.displayName] && ![peer.displayName isEqualToString: _parentAnalyzer.globalManager.myPeerID.displayName]){
                    
                            [self updatePeerHistory:peer];
                            [differences addObject:peer];
                        }
                    }
                     //if there were any diffrerences in the histories then send full history to all peers
                    if([differences count] > 0)
                        [_parentAnalyzer.globalManager sendDataPacketToPeers:[NSKeyedArchiver archivedDataWithRootObject:differences]];
                });
            }
            
            else if([receivedObject[0] isKindOfClass:[CSChatMessageRealmModel class]]){
                dispatch_sync(_parentAnalyzer.globalManager.peerHistoryQueue,^{
                for(CSChatMessageRealmModel* message in receivedObject) [self addPrivateMessage:message];
                });
            }
    }
    
    else if ([receivedObject isKindOfClass:[NSDictionary class]])
    {
        
        if([receivedObject valueForKey:kCS_User_UpdateAvatar] )
        {
            //number to change avatar
            NSNumber* test = [receivedObject valueForKey:@"number"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if([self updatePeerAvatar: [receivedObject valueForKey:kCS_User_UpdateAvatar] withNumber:test])
                {
                    [_parentAnalyzer.globalManager sendDataPacketToPeers:_dataToAnalyze];
                }
            });
            
        }
        
        else [self propagateTasks:receivedObject];
    }
    
    else if ([receivedObject isKindOfClass:[CSChatMessageRealmModel class]])
    {
        CSChatMessageRealmModel* temp = receivedObject;
        
        NSString* messageID =[temp.createdBy stringByAppendingString:(NSString*)temp.messageText];
        @synchronized (_messagePool){
            if([_messagePool valueForKey:messageID] || [temp.createdBy isEqualToString: _parentAnalyzer.globalManager.myPeerID.displayName])
            {
                NSLog(@"<.> message %@ already requested; no action to be taken.",messageID);
                return;
            }
        }
        @synchronized (_messagePool){
            [_messagePool setValue:_peer forKey:messageID];
            [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(removeMessageRequest:) userInfo:messageID repeats:NO];
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
                    [_parentAnalyzer.globalManager sendSingleDataPacket:_dataToAnalyze toSinglePeer: [_parentAnalyzer.globalManager.currentConnectedPeers valueForKey:temp.recipient]];
                    return;
                }
                
                [_parentAnalyzer.globalManager sendDataPacketToPeers:_dataToAnalyze];
            }
            
            else{
                [self addPrivateMessage:temp];
            }
        }
    }
    
}

- (void) updatePeerHistory:(CSUserRealmModel *) peer
{
    if([peer.displayName isEqualToString:_parentAnalyzer.globalManager.myPeerID.displayName])
        return;
    [peer removeUnsent];
    [peer removeMessages];
    
    [_parentAnalyzer.globalManager.peerHistoryRealm beginWriteTransaction];
    if(![CSUserRealmModel objectInRealm:_parentAnalyzer.globalManager.peerHistoryRealm forPrimaryKey:peer.displayName])
        [_parentAnalyzer.globalManager.peerHistoryRealm addObject:peer];
    [_parentAnalyzer.globalManager.peerHistoryRealm commitWriteTransaction];
    
}

- (bool) updatePeerAvatar:(NSString*) displayName withNumber: (NSNumber*) number
{
    CSUserRealmModel* peer = [CSUserRealmModel objectInRealm:_parentAnalyzer.globalManager.peerHistoryRealm forPrimaryKey:displayName];
    if(peer.avatar == [number integerValue]) return false;
    
    [_parentAnalyzer.globalManager.peerHistoryRealm beginWriteTransaction];
    peer.avatar = [number integerValue];
    [_parentAnalyzer.globalManager.peerHistoryRealm commitWriteTransaction];
    return true;
}

-(void) addPrivateMessage:(CSChatMessageRealmModel*) message
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *url = [basePath stringByAppendingString:@"/privateMessage.realm"];
    
    //if the chat message already exists then exit otherwise add it and send it to all peers
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"createdBy = %@ AND createdAt = %@",
                         message.createdBy, message.createdAt];
    
    RLMRealm *privateMessageRealm = [RLMRealm realmWithPath:url];
    
    if([[CSChatMessageRealmModel objectsInRealm:privateMessageRealm withPredicate:pred] count] != 0) return;
    
    
    [_parentAnalyzer.globalManager addMessage:message.senderDisplayName];
    
    
    [privateMessageRealm beginWriteTransaction];
    [privateMessageRealm addObject:message];
    [privateMessageRealm commitWriteTransaction];
}

-(void) removeMessageRequest:(NSString*) message
{
    [_messagePool removeObjectForKey:message];
}

- (void) propagateTasks:(NSDictionary *)taskData
{
    // received new task request or task notification
    if ([taskData valueForKey:kCS_HEADER_NEW_TASK])
    {
        NSString* newTaskId = [taskData valueForKey:kCS_HEADER_NEW_TASK];
        
        // check to see if already made request from someone
        @synchronized (_requestPool){
            if([_requestPool valueForKey:newTaskId])
            {
                NSLog(@"<.> Task ID %@ already requested; no action to be taken.",newTaskId);
                return;
            }
        }
        
        // check to see if the task already exists
        CSTaskRealmModel* model = [_parentAnalyzer getModelFromQueueOrDatabaseWithID:newTaskId];
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
    else if ([taskData valueForKey:kCS_HEADER_TASK_REQUEST])
    {
        NSString* requestedTaskID = [taskData valueForKey:kCS_HEADER_TASK_REQUEST];
        
        // check to see if the task exists
        CSTaskRealmModel* model = [_parentAnalyzer getModelFromQueueOrDatabaseWithID:requestedTaskID];
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
    NSString* taskObservationName = [NSString stringWithFormat:@"%@_INCOMING", resourceName];
    [progress setUserInfoObject:taskObservationName forKey:kCSTaskObservationID];
    
    RLMRealm* incomingTaskRealm = [RLMRealm realmWithPath:[CSSessionManager incomingTaskRealmDirectory]];
    CSIncomingTaskRealmModel* newIncomingTask = [CSIncomingTaskRealmModel new];
    
    
    newIncomingTask.taskObservationString = taskObservationName;
    newIncomingTask.trueTaskName = resourceName;
    newIncomingTask.peerDisplayName = peerID.displayName;
    
    [incomingTaskRealm beginWriteTransaction];
    [incomingTaskRealm addObject:newIncomingTask];
    [incomingTaskRealm commitWriteTransaction];
    
    // Post notification globally
    // NOTE! Receivers of this notification must be intelligent in determining WHAT object has progressed!
//    [[NSNotificationCenter defaultCenter] postNotificationName:kCSDidStartReceivingResourceWithName
//                                                        object:nil
//                                                      userInfo:containerDictionary];
    
    
    
    // we have made a request and been served - add it to our pool
    @synchronized (_requestPool){
        [_requestPool setValue:peerID forKey:resourceName];
    }
    
//     Use this code if you want to observe the progress of a data transfer from the
//     data analyzer and then send notifications out as progress changes
    dispatch_async(dispatch_get_main_queue(), ^{
        [progress addObserver:self
                   forKeyPath:@"fractionCompleted"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    });
}



- (void)session:(MCSession *)session
didFinishReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
          atURL:(NSURL *)localURL
      withError:(NSError *)error
{
    if (error || localURL == nil) {
        NSLog(@"%@",error);
        return;
    }
    
    // We have finished our request - get rid out of it
    // TODO
    // PERHAPS MAKE A REQUEST QUEUE?
    @synchronized (_requestPool){
        [_requestPool removeObjectForKey:resourceName];
    }
    
    
    // create the task and set up the write for it
    NSData* taskData = [NSData dataWithContentsOfURL:localURL];
    id newTask = [NSKeyedUnarchiver unarchiveObjectWithData:taskData];
    
    if([newTask isKindOfClass:[CSTaskRealmModel class]])
    {
        CSTaskRealmModel* untouchedModel = [CSTaskRealmModel taskModelWithModel:newTask];
        [self addTaskToWriteQueue:(CSTaskRealmModel*)newTask withID:resourceName];
        [self sendMessageToAllPeersForNewTask:untouchedModel];
        
        // Create a notification dictionary for final location and name
        NSDictionary *dict = @{@"resourceName"  :   resourceName,
                               @"peerID"        :   peerID,
                               @"localURL"      :   localURL
                               };
        
        // Post notification globally
        // NOTE! Receivers of this notification must be intelligent in determining WHAT object has progressed!
        [[NSNotificationCenter defaultCenter] postNotificationName:kCSDidFinishReceivingResourceWithName
                                                            object:nil
                                                          userInfo:dict];
    }
}

#pragma mark - Data persistence
- (void) addTaskToWriteQueue:(CSTaskRealmModel*)newTask withID:(NSString*)identifier{
    NSLog(@"I recieved a new task");
    
    CSRealmWriteOperation* newWriteOperation = [CSRealmWriteOperation new];
    newWriteOperation.pendingTask = newTask;
    newWriteOperation.untouchedPendingTask = [CSTaskRealmModel taskModelWithModel:newTask];
    
    [self.realmWriteQueue addOperation:newWriteOperation];
}

- (CSTaskRealmModel*) getModelFromQueueOrDatabaseWithID:(NSString*)taskID
{
    NSArray* currentWriteQueue = _realmWriteQueue.operations;
    for(CSRealmWriteOperation* operation in currentWriteQueue) {
        if([operation.untouchedPendingTask.concatenatedID isEqualToString:taskID]) {
            return operation.untouchedPendingTask;
        }
    }
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"concatenatedID = %@", taskID];
    RLMResults* results = [CSTaskRealmModel objectsInRealm:[RLMRealm defaultRealm] withPredicate:pred];
    if (results.count == 1) {
        return [CSTaskRealmModel taskModelWithModel:[results objectAtIndex:0]];
    }
    
    return nil;
}

#pragma mark - OBSERVATION CALLBACK
 -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
//  Post global notification that the progress of a resource stream has changed.
//  NOTE! Receivers of this notification must be intelligent in determining WHAT object has progressed!
 
 [[NSNotificationCenter defaultCenter] postNotificationName:kCSReceivingProgressNotification
                                                     object:nil
                                                   userInfo:@{@"progress": (NSProgress *)object}];
 }

#pragma mark - Data transmission
- (void) sendMessageToAllPeersForNewTask:(CSTaskRealmModel*)task
{
    NSDictionary* newTaskDictionary = [self buildTaskRequestFromTaskID:task.concatenatedID];
    NSData* newTaskData = [NSKeyedArchiver archivedDataWithRootObject:newTaskDictionary];

    [_globalManager sendDataPacketToPeers:newTaskData];
}

- (void) validateDataWithRandomPeer:(CSTaskRealmModel*)task
{
    NSDictionary* newTaskDictionary = [self buildTaskRequestFromTaskID:task.concatenatedID];
    NSData* newTaskData = [NSKeyedArchiver archivedDataWithRootObject:newTaskDictionary];
    
    NSNumber* t = [NSNumber numberWithInteger:[_globalManager.currentConnectedPeers.allKeys count]];
    NSUInteger random = arc4random_uniform([t unsignedIntValue]);
    [_globalManager sendSingleDataPacket:newTaskData
                            toSinglePeer: _globalManager.currentConnectedPeers.allValues[random]];
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


+ (NSString *)chatMessageRealmDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:@"/chat.realm"];
}
@end