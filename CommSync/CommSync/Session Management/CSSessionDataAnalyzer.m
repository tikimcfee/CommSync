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
#import "CSRealmFactory.h"
#import "CSTaskRevisionRealmModel.h"

// Critical constants for building data transmission strings
#define kCSDefaultStringEncodingMethod NSUTF16StringEncoding
#define kCS_HEADER_NEW_TASK     @"NEW_TASK"
#define kCS_HEADER_TASK_REQUEST @"TASK_REQUEST"
#define kCS_STRING_SEPERATOR    @":"
#define kCS_USER_UPDATE_AVATAR  @"Avatar"
#define kCS_PRIVATE_MESSAGE     @"PrivateMessage"
#define kcs_CHAT_MESSAGE        @"ChatMessage"
#define kcs_CHAT_ARRAY          @"ChatArray"
#define kcs_TASK_ARRAY          @"TaskArray"
#define kcs_PM_ARRAY            @"PMArray"
#define kcs_USER_ARRAY          @"UserArray"
#define kCS_DISPLAY_NAME_CHANGE @"displayNameChange"

/** Revisions **/
#define kCS_REV_ID_ARRAY        @"REV_ID_ARRAY"
#define kCS_REV_MODEL_ARRAY     @"REV_MODEL_ARRAY"
#define kCS_REV_REQUEST         @"REV_REQUEST"
#define kCS_REV_RESPONSE        @"REV_RESPONSE"
#define kCS_REV_RESPONSE_MEDIA  @"REV_RESPONSE_MEDIA"

// Implementation of task information container
@implementation CSNewTaskResourceInformationContainer
@end

// Implementation of Data Analysis Operation
@implementation CSDataAnalysisOperation

- (void) main
{
    
    id receivedObject = [NSKeyedUnarchiver unarchiveObjectWithData:_dataToAnalyze];
        if([receivedObject valueForKey:kCS_USER_UPDATE_AVATAR] )
        {
            //number to change avatar
            NSNumber* test = [receivedObject valueForKey:@"Number"];
            NSDate *date = [receivedObject valueForKey:@"Time"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if([self updatePeerAvatar: [receivedObject valueForKey:kCS_USER_UPDATE_AVATAR] withNumber:test atTime: date])
                {
                    [_parentAnalyzer.globalManager sendDataPacketToPeers:_dataToAnalyze];
                }
            });
            
        }
        
        else if( [receivedObject valueForKey:kcs_CHAT_MESSAGE] )
        {
            CSChatMessageRealmModel* message = [receivedObject valueForKey:kcs_CHAT_MESSAGE];
            
            if(![self queueMessages:message]) return;
            //add the message and if we dont have it then propagate it
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if([self addPublicMessage:message]) [_parentAnalyzer.globalManager sendDataPacketToPeers:_dataToAnalyze];
            });
        }
    
        else if( [receivedObject valueForKey:kcs_CHAT_ARRAY])
        {
            dispatch_async(dispatch_get_main_queue(),^{
                NSMutableArray *differences = [[NSMutableArray alloc]init];
                
                for(CSChatMessageRealmModel* message in [receivedObject valueForKey:kcs_CHAT_ARRAY]){
                    if([self queueMessages:message] && [self addPublicMessage:message] ) {
                        [differences addObject:message];
                    }
                }
                //if there are any difference propagate them
                if([differences count] > 0){
                    NSDictionary *dataToSend = @{@"ChatArray"  :   differences};
                    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dataToSend];
                    [_parentAnalyzer.globalManager sendDataPacketToPeers:data];
                }
            });
        }
        
        else if( [receivedObject valueForKey:kCS_PRIVATE_MESSAGE] )
        {
            CSChatMessageRealmModel* message = [receivedObject valueForKey:kCS_PRIVATE_MESSAGE];
            
            if([self queueMessages:message] && [self addPrivateMessage:message])
                [_parentAnalyzer.globalManager sendDataPacketToPeers:_dataToAnalyze];
        }

        else if( [receivedObject valueForKey:kcs_PM_ARRAY])
        {
            NSMutableArray *differences = [[NSMutableArray alloc]init];
            
            for(CSChatMessageRealmModel * message in [receivedObject valueForKey:kcs_PM_ARRAY]){
                if([self queueMessages:message] && [self addPrivateMessage:message] ) {
                    [differences addObject:message];
                }
            }
            //if there are any difference propagate them
            if([differences count] > 0){
                NSDictionary *dataToSend = @{kcs_PM_ARRAY  :   differences};
                NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dataToSend];
                [_parentAnalyzer.globalManager sendDataPacketToPeers:data];
            }
        }
    
        else if ([receivedObject valueForKey:kcs_USER_ARRAY])
        {
            if ([[receivedObject valueForKey:kcs_USER_ARRAY] count] == 0) return;
            dispatch_async(dispatch_get_main_queue(),^{
                NSMutableArray* differences = [[NSMutableArray alloc]init];
                for(CSUserRealmModel *peer in [receivedObject valueForKey:kcs_USER_ARRAY])
                {
                    if(![peer.uniqueID isEqualToString: _parentAnalyzer.globalManager.myUniqueID]){
                       if( [self updatePeerHistory:peer] )[differences addObject:peer];
                    }
                }
                //if there were any diffrerences in the histories then send full history to all peers
                if([differences count] > 0){
                    NSDictionary *dataToSend = @{@"UserArray"  :   differences};
                    NSData *differenceData = [NSKeyedArchiver archivedDataWithRootObject:dataToSend];
                    [_parentAnalyzer.globalManager sendDataPacketToPeers:differenceData];
                 }
            });
        }
        
        else if ([receivedObject valueForKey:kcs_TASK_ARRAY] )
        {
            dispatch_sync(_parentAnalyzer.globalManager.taskRealmQueue,^{
                for(NSString* task in [receivedObject valueForKey:kcs_TASK_ARRAY])
                    [self propagateTasks:[[CSSessionDataAnalyzer sharedInstance:nil] buildNewTaskNotificationFromTaskID:task]];
            });
        }
    
        else if ([receivedObject valueForKey:kCS_DISPLAY_NAME_CHANGE] )
        {
            NSString *newName = [receivedObject valueForKey:kCS_DISPLAY_NAME_CHANGE];
            NSString *userUniqueID = [receivedObject valueForKey:@"uniqueID"];
            
            [self updateDisplayNameTo:newName ForUserID:userUniqueID propogate:_dataToAnalyze];
        }
    
        else [self propagateTasks:receivedObject];
    
}

- (void) updateDisplayNameTo:(NSString*)name ForUserID:(NSString*)userID propogate:(NSData*)data {
    RLMRealm *peerHistoryRealm = [CSRealmFactory peerHistoryRealm];
    CSUserRealmModel* peer = [CSUserRealmModel objectInRealm:peerHistoryRealm forPrimaryKey:userID];
    
    if ([_parentAnalyzer.globalManager.myUniqueID isEqualToString:userID] || [peer.displayName isEqualToString:name]) {
        return;
    }
    
    [peerHistoryRealm beginWriteTransaction];
    peer.displayName = name;
    [peerHistoryRealm commitWriteTransaction];
    
    // propogate
    if (data) {
        [_parentAnalyzer.globalManager sendDataPacketToPeers:data];
    }
}

- (BOOL) updatePeerHistory:(CSUserRealmModel *)peer
{
    CSUserRealmModel* ownPeer = [CSUserRealmModel objectInRealm:[CSRealmFactory peerHistoryRealm] forPrimaryKey:peer.uniqueID];
    
    //if we dont have the user add them
    if(!ownPeer)
    {
        [_parentAnalyzer.globalManager.peerHistoryRealm beginWriteTransaction];
        [peer removeUnsent];
        [peer removeMessages];
        [_parentAnalyzer.globalManager.peerHistoryRealm addObject:peer];
        [_parentAnalyzer.globalManager.peerHistoryRealm commitWriteTransaction];
        return YES;
    }
    //hasnt been changed more rececntly return no
    if([ownPeer.lastUpdated compare:peer.lastUpdated] == NSOrderedDescending) return NO;
    //if the users avatar is different then change it
    else if( peer.avatar != ownPeer.avatar || ![peer.displayName isEqualToString:(ownPeer.displayName)])
    {
        [_parentAnalyzer.globalManager.peerHistoryRealm beginWriteTransaction];
        if(peer.avatar != ownPeer.avatar) ownPeer.avatar = peer.avatar;
        if(![peer.displayName isEqualToString:ownPeer.displayName]) ownPeer.displayName = peer.displayName;
        ownPeer.lastUpdated = peer.lastUpdated;
        [_parentAnalyzer.globalManager.peerHistoryRealm commitWriteTransaction];
        return YES;
    }
   //otherwise no differences
    return NO;
}

- (BOOL) updatePeerAvatar:(NSString*)uniqueID withNumber:(NSNumber*)number atTime: (NSDate*) time
{
    CSUserRealmModel* peer = [CSUserRealmModel objectInRealm:_parentAnalyzer.globalManager.peerHistoryRealm forPrimaryKey:uniqueID];
    if(peer.avatar == [number integerValue] || [peer.uniqueID isEqualToString:_parentAnalyzer.globalManager.myUniqueID]) return NO;
    if([peer.lastUpdated compare:time] == NSOrderedDescending) return NO;
    
    [_parentAnalyzer.globalManager.peerHistoryRealm beginWriteTransaction];
    peer.avatar = [number integerValue];
    peer.lastUpdated = time;
    [_parentAnalyzer.globalManager.peerHistoryRealm commitWriteTransaction];
    return YES;
}

-(bool) queueMessages:(CSChatMessageRealmModel*) message
{
    NSString* messageID =[message.createdBy stringByAppendingString:(NSString*)message.messageText];
    @synchronized (_messagePool){
        if([_messagePool valueForKey:messageID] || [message.createdBy isEqualToString: _parentAnalyzer.globalManager.myPeerID.displayName])
        {
            NSLog(@"<.> message %@ already requested; no action to be taken.",messageID);
            return false;
        }
    }
    @synchronized (_messagePool){
        [_messagePool setValue:_peer forKey:messageID];
        [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(removeMessageRequest:) userInfo:messageID repeats:NO];
    }
    return true;
}

-(BOOL) addPrivateMessage:(CSChatMessageRealmModel*) message
{

    RLMRealm *privateRealm = [CSRealmFactory privateMessageRealm];
    
    if([CSChatMessageRealmModel objectInRealm:privateRealm forPrimaryKey:message.uniqueID]) return NO;
    
    //we tell ourselves that we have a new message from the sender
    if([_parentAnalyzer.globalManager.myUniqueID isEqualToString:message.recipient])
        [_parentAnalyzer.globalManager addMessage:message.createdBy];
    
    [privateRealm beginWriteTransaction];
    [privateRealm addObject:message];
    [privateRealm commitWriteTransaction];
    return YES;
}

-(BOOL) addPublicMessage:(CSChatMessageRealmModel*) message
{
        RLMRealm *chatRealm = [CSRealmFactory chatMessageRealm];
        //if the chat message already exists then exit otherwise add it and send it to all peers
        if([CSChatMessageRealmModel objectInRealm:chatRealm forPrimaryKey:message.uniqueID]) return NO;
    
        [chatRealm beginWriteTransaction];
        [chatRealm addObject:message];
        [chatRealm commitWriteTransaction];
        return YES;
}

-(void) removeMessageRequest:(NSString*) message
{
    [_messagePool removeObjectForKey:message];
}

- (NSMutableDictionary*) buildResponseDictionaryForRevisionRequest:(NSDictionary*)revisionRequest {
    NSMutableDictionary* responseDictionary = [NSMutableDictionary new];
    NSString* taskID = [revisionRequest valueForKey:kCS_REV_REQUEST];
    [responseDictionary setObject:taskID forKey:kCS_REV_RESPONSE];
    
    
    NSLog(@"--- Building response dictionary..");
    NSMutableArray* taskMedia = [NSMutableArray new];
    NSMutableArray* requestedRevisions = [revisionRequest valueForKey:kCS_REV_ID_ARRAY];
    NSLog(@"--- REQUESTED REVISIONS: %@", requestedRevisions);
    
    NSMutableArray* revisionsToSend = [NSMutableArray new];
    RLMRealm* taskRealm = [CSRealmFactory taskRealm];
    CSTaskRealmModel* requestedTask = [CSTaskRealmModel objectInRealm:taskRealm forPrimaryKey:taskID];
    for (CSTaskRevisionRealmModel* rev in requestedTask.revisions) {
        NSLog(@"--- Comparing %@", rev.revisionID);
        if ([requestedRevisions containsObject:rev.revisionID]) {
            NSLog(@"--- Requested revisions contained the ID.");
            CSTaskRevisionRealmModel* memoryRev = [CSTaskRevisionRealmModel revisionModelWithModel:rev];
            [revisionsToSend addObject:memoryRev];
            
            NSMutableDictionary* unarchivedChanges = [NSKeyedUnarchiver unarchiveObjectWithData:memoryRev.changesDictionary];
            NSMutableDictionary* potentialAudio = [unarchivedChanges
                                                   valueForKey:[CSTaskRealmModel stringForProperty:CSTaskProperty_taskAudio_CHANGE]];
            if (potentialAudio) {
                NSMutableArray* audioIDs = [potentialAudio valueForKey:@"to"];
                for (NSString* audioID in audioIDs) {
                    CSTaskMediaRealmModel* memoryMedia = [CSTaskMediaRealmModel
                                                          mediaModelWithModel:
                                                          [CSTaskMediaRealmModel objectInRealm:taskRealm
                                                                                 forPrimaryKey:audioID]];
                    [taskMedia addObject:memoryMedia];
                }
            }
            NSMutableDictionary* potentialImages = [unarchivedChanges
                                                   valueForKey:[CSTaskRealmModel stringForProperty:CSTaskProperty_taskImages_ADD]];
            if (potentialImages) {
                NSMutableArray* imageIDs = [potentialImages valueForKey:@"to"];
                for (NSString* imageID in imageIDs) {
                    CSTaskMediaRealmModel* memoryMedia = [CSTaskMediaRealmModel
                                                          mediaModelWithModel:
                                                          [CSTaskMediaRealmModel objectInRealm:taskRealm
                                                                                 forPrimaryKey:imageID]];
                    [taskMedia addObject:memoryMedia];
                }
            }
        }
    }
    
    if (taskMedia.count != 0) {
        [responseDictionary setObject:taskMedia forKey:kCS_REV_RESPONSE_MEDIA];
    }
    if (revisionsToSend.count != 0) {
        [responseDictionary setObject:revisionsToSend forKey:kCS_REV_MODEL_ARRAY];
    }
    
    return  responseDictionary;
}

- (void) fastForwardTask:(CSTaskRealmModel*)task WithRevisions:(NSMutableArray*)revisions {
//    NSLog(@"+++ Revisions before sorting: %@", revisions);
    [revisions sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        CSTaskRevisionRealmModel* revRef1 = obj1;
        CSTaskRevisionRealmModel* revRef2 = obj2;
        if ([revRef1.revisionDate compare:revRef2.revisionDate] == NSOrderedDescending) {
            return (NSComparisonResult)NSOrderedDescending;
        } else if ([revRef1.revisionDate compare:revRef2.revisionDate] == NSOrderedAscending){
            return (NSComparisonResult)NSOrderedAscending;
        } else {
            return (NSComparisonResult)NSOrderedSame;
        }
    }];
//    NSLog(@"+++ Revisions after sorting: %@", revisions);
    CSTaskRevisionRealmModel* oldestRev = [revisions objectAtIndex:0];
    
    NSMutableArray* currentRevisions = [NSMutableArray new];
    for (CSTaskRevisionRealmModel* rev in task.revisions) {
        [currentRevisions addObject:rev];
    }
    [revisions addObjectsFromArray:currentRevisions];
    
//    NSLog(@"+++ Revisions after adding all task revisions: %@", revisions);
    
    [revisions sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        CSTaskRevisionRealmModel* revRef1 = obj1;
        CSTaskRevisionRealmModel* revRef2 = obj2;
        if ([revRef1.revisionDate compare:revRef2.revisionDate] == NSOrderedDescending) {
            return (NSComparisonResult)NSOrderedDescending;
        } else if ([revRef1.revisionDate compare:revRef2.revisionDate] == NSOrderedAscending){
            return (NSComparisonResult)NSOrderedAscending;
        } else {
            return (NSComparisonResult)NSOrderedSame;
        }
    }];
    
    NSInteger startAt = [revisions indexOfObject:oldestRev];
//    NSLog(@"!__! Fast forwarding task with revisions %@", revisions);
    for (; startAt < revisions.count; startAt++) {
        CSTaskRevisionRealmModel* thisRev = [revisions objectAtIndex:startAt];
        [thisRev updateTaskModel:task];
    }
    
    [revisions removeObjectsInArray:currentRevisions];
}

- (NSMutableArray*) handleRevisionAdditionsForNewRevisionResponse:(NSDictionary*)response {
    NSString* taskID = [response valueForKey:kCS_REV_RESPONSE];
//    NSLog(@"--- Parsing response dictionary: %@", response);
    
    RLMRealm* taskRealm = [CSRealmFactory taskRealm];
    CSTaskRealmModel* modelToUpdate = [CSTaskRealmModel objectInRealm:taskRealm forPrimaryKey:taskID];

    [taskRealm beginWriteTransaction];
    NSMutableArray* revisionsToAdd = [response valueForKey:kCS_REV_MODEL_ARRAY];
    if (!revisionsToAdd) {
        NSLog(@"<!> WARNING : Received revision response with 0 revisions! leaving method.");
        return nil;
    }
    NSMutableArray* revisionIDs = [NSMutableArray new];
    for (CSTaskRevisionRealmModel* rev in revisionsToAdd) {
        [revisionIDs addObject:rev.revisionID];
    }
    [self fastForwardTask:modelToUpdate WithRevisions:revisionsToAdd];
    
//    NSLog(@"+++ Adding to revisions %@", [response valueForKey:kCS_REV_MODEL_ARRAY]);
    [modelToUpdate.revisions addObjects:[response valueForKey:kCS_REV_MODEL_ARRAY]];
    
    NSMutableArray* mediaToAdd = [response valueForKey:kCS_REV_RESPONSE_MEDIA];
    if (mediaToAdd) {
        [modelToUpdate.taskMedia addObjects:mediaToAdd];
    }
    
    [taskRealm commitWriteTransaction];
    
    return revisionIDs;
}

- (void) propagateTasks:(NSDictionary *)taskData
{
    // received a response from a revision request
    if ([taskData valueForKey:kCS_REV_RESPONSE]) {
        NSMutableArray* revisionIDs = [self handleRevisionAdditionsForNewRevisionResponse:taskData];
        if (!revisionIDs) {
            return;
        }
        NSMutableDictionary* newPost = [_parentAnalyzer buildNewRevisionRequestFromTaskID:[taskData valueForKey:kCS_REV_RESPONSE] andRevisions:revisionIDs];
        NSData* responseData = [NSKeyedArchiver archivedDataWithRootObject:newPost];
        
        [_parentAnalyzer.globalManager sendSingleDataPacket:responseData toSinglePeer:_peer];
        return;
    }
    
    // received a request for revisions; service it
    else if ([taskData valueForKey:kCS_REV_REQUEST]) {
        NSMutableDictionary* responseDictionary = [self buildResponseDictionaryForRevisionRequest:taskData];
        NSLog(@"--- Final response dictionary: %@", responseDictionary);
        NSData* responseData = [NSKeyedArchiver archivedDataWithRootObject:responseDictionary];
        
        [_parentAnalyzer.globalManager sendSingleDataPacket:responseData toSinglePeer:_peer];
        return;
     }
    
    // received new task request or task notification
    else if ([taskData valueForKey:kCS_HEADER_NEW_TASK])
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
            // check for existence of revs on dictionary
            if ([taskData valueForKey:kCS_REV_ID_ARRAY]) {
                NSMutableArray* revs = [taskData valueForKey:kCS_REV_ID_ARRAY];
                for (CSTaskRevisionRealmModel* rev in model.revisions) {
                    [revs removeObject:rev.revisionID];
                }
                // if there are revs we need, make a request for them
                if (revs.count != 0) {
                    NSMutableDictionary* revisionRequest = [_parentAnalyzer buildNewRevisionRequestFromTaskID:model.concatenatedID
                                                                                                 andRevisions:revs];
                    NSData* revisionRequestData = [NSKeyedArchiver archivedDataWithRootObject:revisionRequest];
                    NSLog(@"<?> Sending revision request [%@] to peer [%@]", revisionRequest, _peer.displayName);
                    
                    [_parentAnalyzer.globalManager sendSingleDataPacket:revisionRequestData toSinglePeer:_peer];
                    return;
                } else {
                    NSLog(@"<.> Task ID %@ already exists; no NEW revisions; no action to be taken.",newTaskId);
                    return;
                }
            }
            else {
                NSLog(@"<.> Task ID %@ already exists; no revisions to process; no action to be taken.",newTaskId);
                return;
            }
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
@property (strong, nonatomic, readwrite) NSOperationQueue* dataAnalysisQueue;
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
    
    RLMRealm* incomingTaskRealm = [CSRealmFactory incomingTaskRealm];
    CSIncomingTaskRealmModel* newIncomingTask = [CSIncomingTaskRealmModel new];
    
    
    newIncomingTask.taskObservationString = taskObservationName;
    newIncomingTask.trueTaskName = resourceName;
    
    RLMRealm* users = [CSRealmFactory peerHistoryRealm];
    CSUserRealmModel* user = [CSUserRealmModel objectInRealm:users forPrimaryKey:peerID.displayName];
    NSString* name = user ? user.displayName : @"Unknown User!";
    newIncomingTask.peerDisplayName = name;
    
    [incomingTaskRealm beginWriteTransaction];
    [incomingTaskRealm addOrUpdateObject:newIncomingTask];
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
    NSDictionary* newTaskDictionary = [self buildNewTaskNotificationFromTaskID:task.concatenatedID];
    NSData* newTaskData = [NSKeyedArchiver archivedDataWithRootObject:newTaskDictionary];

    [_globalManager sendDataPacketToPeers:newTaskData];
}

- (void) sendTaskRevisionsToAllPeerForTask:(CSTaskRealmModel*)revisedTask {
    NSMutableDictionary* newRevisionDictionary = [self buildNewRevisionNotificationFromTaskID:revisedTask];
    NSData* revisionData = [NSKeyedArchiver archivedDataWithRootObject:newRevisionDictionary];
    
    [_globalManager sendDataPacketToPeers:revisionData];
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


#pragma mark - Dictionary builders
- (NSDictionary*) buildTaskRequestFromTaskID:(NSString*)taskID
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

- (NSMutableDictionary*) buildNewRevisionRequestFromTaskID:(NSString*)taskID andRevisions:(NSArray*)revisions{
    if(!revisions) {
        NSLog(@"DataAnalyzer(ERROR): Dictionary build failed - no revisions to request.");
        return nil;
    }
    
    NSMutableDictionary* revisionRequest = [NSMutableDictionary new];
    [revisionRequest setObject:taskID forKey:kCS_REV_REQUEST];
    
    [revisionRequest setObject:revisions forKey:kCS_REV_ID_ARRAY];
    
    return revisionRequest;
}

- (NSMutableDictionary*) buildNewRevisionNotificationFromTaskID:(CSTaskRealmModel*)revisedTask {
    if(!revisedTask) {
        NSLog(@"DataAnalyzer(ERROR): Dictionary build failed - no revised task.");
        return nil;
    }
    
    NSMutableDictionary* taskAndRevisions = [NSMutableDictionary new];
    [taskAndRevisions setObject:revisedTask.concatenatedID forKey:kCS_HEADER_NEW_TASK];
    
    NSMutableArray* allRevs = [NSMutableArray new];
    for (CSTaskRevisionRealmModel* rev in revisedTask.revisions) {
        [allRevs addObject:rev.revisionID];
    }
    
    [taskAndRevisions setObject:allRevs forKey:kCS_REV_ID_ARRAY];
    
    return taskAndRevisions;
}

@end