//
//  CSSessionManager.m
//  CommSync
//
//  Created by Ivan Lugo on 10/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSSessionManager.h"
#import <Realm/Realm.h>

#include <libkern/OSAtomic.h>
#import "CSTaskRealmModel.h"
#import "AppDelegate.h"
#import "CSChatMessageRealmModel.h"
#import "CSSessionDataAnalyzer.h"
#import "CSUserRealmModel.h"
#import "CSChatViewController.h"

#define kUserNotConnectedNotification @"Not Connected"
#define kUserConnectedNotification @"Connected"
#define kUserConnectingNotification @"Is Connecting"

@interface CSSessionManager()

@property (nonatomic, strong) NSMutableDictionary* deferredConnectionsDisplayNamesToPeerIDs;
@property (nonatomic, strong) NSMutableDictionary* devicesThatDeferredToMeDisplayNamesToPeerIDs;
@property (nonatomic, strong) RLMRealm* realm;

// 1-1 session objects
@property (strong, nonatomic) NSMutableDictionary* sessionLookupDisplayNamesToSessions;

@property (nonatomic, strong) CSSessionDataAnalyzer* dataAnalyzer;
@property (nonatomic, strong) CSUserRealmModel *peers;

@end


@implementation CSSessionManager
{
    volatile int32_t _sentResourceCount;
    volatile int32_t _receivedResourceCount;
}

#pragma mark - Lifecycle
- (CSSessionManager*) initWithID:(NSString*)userID withDisplay:(NSString *)userName
{
    //
    // Session management objects
    //
    if(self = [super init])
    {
        _myPeerID = [[MCPeerID alloc] initWithDisplayName:userID];
        _myUniqueID = userID;
        _myDisplayName = userName;
        _dataAnalyzer = [CSSessionDataAnalyzer sharedInstance:self];
        _dataHandlingDelegate = _dataAnalyzer;
        
        // There will only ever be a single service browser and advertiser, but multiple sessions
        _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:_myPeerID serviceType:COMMSYNC_SERVICE_ID];
        _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_myPeerID
                                                               discoveryInfo:nil
                                                                 serviceType:COMMSYNC_SERVICE_ID];
        _serviceBrowser.delegate = self;
        _serviceAdvertiser.delegate = self;
        
        [_serviceBrowser startBrowsingForPeers];
        [_serviceAdvertiser startAdvertisingPeer];
        
        _sessionLookupDisplayNamesToSessions = [NSMutableDictionary new];
        _currentConnectedPeers = [NSMutableDictionary new];
        _unreadMessages = [NSMutableDictionary new];
        
        _allTags = [NSMutableDictionary new];
        
        // Connection deferrement
        self.deferredConnectionsDisplayNamesToPeerIDs = [NSMutableDictionary new];
        self.devicesThatDeferredToMeDisplayNamesToPeerIDs = [NSMutableDictionary new];
        
        // Getting default realm from disk
        _realm = [RLMRealm defaultRealm];
        _realm.autorefresh = YES;
       
        // set resource count
        _sentResourceCount = 0;

        _chatMessageQueue =  dispatch_queue_create("chatMessageQueue", NULL);
        _privateMessageQueue = dispatch_queue_create("privateMessageQueue", NULL);
        _taskRealmQueue =  dispatch_queue_create("taskRealmQueue", NULL);
        _peerHistoryQueue = dispatch_queue_create("peerHistoryQueue", NULL);
        
        dispatch_sync(self.peerHistoryQueue,^{
            _peerHistoryRealm = [CSRealmFactory peerHistoryRealm];
            _peerHistoryRealm.autorefresh = YES;
            
            self.myUserModel = [CSUserRealmModel objectInRealm:_peerHistoryRealm forPrimaryKey:_myUniqueID];
           
            if(!_myUserModel)
            {
                [self createUserModel];
            }
        });
        
        dispatch_sync(self.privateMessageQueue,^{
            _privateMessageRealm = [CSRealmFactory privateMessageRealm];
            _privateMessageRealm.autorefresh = YES;
        });

        
        dispatch_sync(self.chatMessageQueue,^{
            _chatMessageRealm = [CSRealmFactory chatMessageRealm];
            _chatMessageRealm.autorefresh = YES;
        });

		// Setting up concurrent send operations
        _mainTaskSendQueue = [NSOperationQueue new];
        _mainTaskSendQueue.maxConcurrentOperationCount = 3;

		[NSTimer scheduledTimerWithTimeInterval:300.0 target:self selector:@selector(validateDataWithRandomPeer) userInfo:nil repeats:YES];
    }
       
    return self;
}

- (CSSessionManager*) initWithID:(NSString*)userID
                      securityID:(NSArray*)ID
         andEncryptionPreference:(MCEncryptionPreference*)encryption
{
    NSLog(@"--- WARNING --- USING THE WRONG INITIALIZER");
    return nil;
}

#pragma mark - Custom Setters
- (void)setState:(CSSessionManagerState)state {
    if (_state == state) {
        return;
    }
    
    _state = state;
    
    if (state == CSSessionManagerStateTransmittingTasks) {
        NSLog(@"Session Manager: State is now transmitting. Stopping browser and advertiser.");
        // stop all browsing and advertising activity
        [_serviceBrowser stopBrowsingForPeers];
        [_serviceAdvertiser stopAdvertisingPeer];
        
    } else {
        NSLog(@"Session Manager: State is now searching. Starting browser and advertiser.");
        // start browsing and advertising
        [_serviceBrowser startBrowsingForPeers];
        [_serviceAdvertiser startAdvertisingPeer];
    }
}

# pragma mark - Heartbeat
- (void) validateDataWithRandomPeer
{
    //    NSString* pulseText = PULSE_STRING;
    //    NSData* newPulse = [pulseText dataUsingEncoding:NSUTF8StringEncoding];
    //    NSError* error;
    
    //    for(MCPeerID* peer in _currentSession.connectedPeers)
    //    {
    //        [_currentSession sendData:newPulse
    //                          toPeers:@[peer]
    //                         withMode:MCSessionSendDataReliable
    //                            error:&error];
    //    }
    
    if([_currentConnectedPeers count] < 1) return;
    
    NSLog(@"validating data");
    NSMutableArray* send = [[NSMutableArray alloc]init];
    
    for(CSTaskRealmModel* task in [CSTaskRealmModel allObjectsInRealm:[RLMRealm defaultRealm]])
    {
        [send addObject:task.concatenatedID];
    }
    
    if([send count] > 0) {
        NSDictionary *dataToSend = @{@"TaskArray"  :   send};
        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dataToSend];
        NSNumber* t = [NSNumber numberWithInteger:[_currentConnectedPeers.allKeys count]];
        NSUInteger random = arc4random_uniform([t unsignedIntValue]);
        [self sendSingleDataPacket:data toSinglePeer:_currentConnectedPeers.allValues[random]];
    }
}

#pragma mark - Data transmission helpers
- (void) sendDataPacketToPeers:(NSData*)dataPacket
{
    NSError* error;
    
    if([_sessionLookupDisplayNamesToSessions allValues].count > 0)
    {
        NSArray* allSessions = [_sessionLookupDisplayNamesToSessions allValues];
        
        for(MCSession* session in allSessions) {
            if(session.connectedPeers.count > 1) {
                NSLog(@"! WARNING ! - Session with multiple users (%@)", session.connectedPeers);
                NSLog(@"! WARNING ! - ... will attempt to send to peer (%@)", [session.connectedPeers objectAtIndex:0]);
            } else if (session.connectedPeers.count <= 0) {
                NSLog(@"! WARNING ! - Session with ZERO connected users (%@)", session.connectedPeers);
                continue;
            }
            
            MCPeerID* thisPeer = [session.connectedPeers objectAtIndex:0];
            [session sendData:dataPacket toPeers:@[thisPeer]
                     withMode:MCSessionSendDataReliable
                        error:&error];
        }
    }
}

- (void) sendSingleDataPacket:(NSData*)dataPacket toSinglePeer:(MCPeerID*)peer
{
    if([_sessionLookupDisplayNamesToSessions allValues].count > 0)
    {
        MCSession* sessionToSendOn = [_sessionLookupDisplayNamesToSessions valueForKey:peer.displayName];
        if(!sessionToSendOn) {
            NSLog(@"! No active session found for peer [%@]", peer.displayName);
            return;
        }
        
        if(sessionToSendOn.connectedPeers.count > 1) {
            NSLog(@"! WARNING ! - Session with multiple users (%@)", sessionToSendOn.connectedPeers);
        } else if (sessionToSendOn.connectedPeers.count <= 0) {
            NSLog(@"! WARNING ! - Session with ZERO connected users (%@)", sessionToSendOn.connectedPeers);
            return;
        }
        MCPeerID* thisPeer = [sessionToSendOn.connectedPeers objectAtIndex:0];
        
        NSError* error;
        [sessionToSendOn sendData:dataPacket
                          toPeers:@[thisPeer]
                         withMode:MCSessionSendDataReliable error:&error];
    }
}

- (void) sendNewTaskToPeers:(CSTaskRealmModel*)newTask;
{
    if([_sessionLookupDisplayNamesToSessions allValues].count > 0)
    {
        // increment resource counter
        OSAtomicIncrement32(&_sentResourceCount);
        self.state = CSSessionManagerStateTransmittingTasks;

        // fixing models?
        CSTaskRealmModel* inMemoryModel = [CSTaskRealmModel taskModelWithModel:newTask];
        NSData* newTaskDataBlob = [NSKeyedArchiver archivedDataWithRootObject:inMemoryModel];
        
        NSLog(@"Total size going out: %.2fkB (%tu Bytes)", newTaskDataBlob.length / 1024.0, newTaskDataBlob.length);
        
        NSURL* URLOfNewTask = [newTask temporarilyPersistTaskDataToDisk:newTaskDataBlob];
        
        NSArray* allSessions = [_sessionLookupDisplayNamesToSessions allValues];
        
        for(MCSession* session in allSessions) {
            if(session.connectedPeers.count > 1) {
                NSLog(@"! WARNING ! - Session with multiple users (%@)", session.connectedPeers);
                NSLog(@"! WARNING ! - ... will attempt to send to peer (%@)", [session.connectedPeers objectAtIndex:0]);
            } else if (session.connectedPeers <= 0) {
                NSLog(@"! WARNING ! - Session with ZERO connected users (%@)", session.connectedPeers);
                continue;
            }
            
            MCPeerID* thisPeer = [session.connectedPeers objectAtIndex:0];
            [session sendResourceAtURL:URLOfNewTask
                              withName:newTask.concatenatedID
                                toPeer:thisPeer
                 withCompletionHandler:^(NSError *error) {
                    OSAtomicDecrement32(&_sentResourceCount);
                     NSLog(@"Session Manager: Decremented to %d", _sentResourceCount);
                     if (_sentResourceCount == 0) {
                         self.state = CSSessionManagerStateSearching;
                     }

                     if(error) {
                        NSLog(@"Task sending FAILED with error: %@ to peer: %@", error, thisPeer.displayName);
                     }
                     else {
                        NSLog(@"Task sending COMPLETE with name: %@ to peer: %@", newTask.taskTitle, thisPeer.displayName);
                     }
                 }];
        }
    }
    
    //    NSLog(@"Removing file from disk...");
    //    if([newTask removeTemporaryTaskDataFromDisk])
    //    {
    //        NSLog(@"Task %@ still exists on disk!", newTask);
    //    }
}

- (void) sendSingleTask:(CSTaskRealmModel*)task toSinglePeer:(MCPeerID*)peer
{
    
    if([_sessionLookupDisplayNamesToSessions allValues].count > 0)
    {
        // increment resource counter
        OSAtomicIncrement32(&_sentResourceCount);
        self.state = CSSessionManagerStateTransmittingTasks;
        
        CSTaskRealmModel* inMemoryModel = [CSTaskRealmModel taskModelWithModel:task];
        MCSession* sessionToSendOn = [_sessionLookupDisplayNamesToSessions valueForKey:peer.displayName];
        if(!sessionToSendOn) {
            NSLog(@"! No active session found for peer [%@]", peer.displayName);
            return;
        }
          
        if(sessionToSendOn.connectedPeers.count > 1) {
            NSLog(@"! WARNING ! - Session with multiple users (%@)", sessionToSendOn.connectedPeers);
        } else if (sessionToSendOn.connectedPeers.count <= 0) {
            NSLog(@"! WARNING ! - Session with ZERO connected users (%@)", sessionToSendOn.connectedPeers);
            return;
        }
        
//        CSTaskResourceSendOperation* newOperation = [CSTaskResourceSendOperation new];
//        [newOperation configureWithModel:inMemoryModel
//                               recipient:peer
//                               inSession:sessionToSendOn];
        
//        [_mainTaskSendQueue addOperation:newOperation];
        
        NSData* newTaskDataBlob = [NSKeyedArchiver archivedDataWithRootObject:inMemoryModel];

        NSLog(@"Total size going out: %.2fkB (%tu Bytes)", newTaskDataBlob.length / 1024.0, newTaskDataBlob.length);

        NSURL* URLOfNewTask = [inMemoryModel temporarilyPersistTaskDataToDisk:newTaskDataBlob];
        
        MCPeerID* thisPeer = [sessionToSendOn.connectedPeers objectAtIndex:0];
        [sessionToSendOn sendResourceAtURL:URLOfNewTask
                                  withName:inMemoryModel.concatenatedID
                                    toPeer:thisPeer
                     withCompletionHandler:^(NSError *error) {
                         OSAtomicDecrement32(&_sentResourceCount);
                         NSLog(@"Session Manager: Decremented to %d", _sentResourceCount);
                         if (_sentResourceCount == 0) {
                             self.state = CSSessionManagerStateSearching;
                         }
                         if(error) {
                             NSLog(@"Task sending FAILED with error: %@ to peer: %@", error, thisPeer.displayName);
                         }
                         else {
                             NSLog(@"Task sending COMPLETE with name to peer: %@", thisPeer.displayName);
                         }
                     }];
    }
}

# pragma mark - Session Helpers
//- (MCSession*)setAndReturnNewSessionForPeer:(MCPeerID*)peer {
//    MCSession* newSession = [[MCSession alloc] initWithPeer:_myPeerID];
//    newSession.delegate = self;
//    
//    if([_sessionLookupDisplayNamesToSessions valueForKey:peer.displayName]) {
//        NSLog(@"[!] A session already exists for this peer. Disconnecting from that session and RESETTING value to new session.");
//        MCSession* oldSession = [_sessionLookupDisplayNamesToSessions valueForKey:peer.displayName];
//        [oldSession disconnect];
//        oldSession.delegate = nil;
//    }
//    
//    [_sessionLookupDisplayNamesToSessions setValue:newSession forKey:peer.displayName];
//    
//    return newSession;
//}
- (MCSession*)synchronizedWithLookup:(NSString*)toLookup
                        withAddition:(NSString*)toAdd
                          forSession:(MCSession*)sessionToAdd
                          orDeletion:(NSString*)toDelete {
    if (toLookup) {
        @synchronized (_sessionLookupDisplayNamesToSessions) {
            return [_sessionLookupDisplayNamesToSessions valueForKey:toLookup];
        }
    } else if (toAdd && sessionToAdd) {
        @synchronized (_sessionLookupDisplayNamesToSessions) {
            [_sessionLookupDisplayNamesToSessions setObject:sessionToAdd forKey:toAdd];
        }
        return sessionToAdd;
        
    } else if (toDelete) {
        @synchronized (_sessionLookupDisplayNamesToSessions) {
            [_sessionLookupDisplayNamesToSessions removeObjectForKey:toDelete];
        }
        return nil;
    }
    
    return nil;
}

- (MCSession*)synchronizedPeerRetrievalForDisplayName:(NSString*)displayName {
    @synchronized (_sessionLookupDisplayNamesToSessions) {
        return [_sessionLookupDisplayNamesToSessions valueForKey:displayName];
    }
}

- (void)nukeSession
{
    NSLog(@"Restarting all Session Objects");
    [self resetBrowserAndAdvertiser];
    
    // reset all MCSessions on local device
    if([_sessionLookupDisplayNamesToSessions allValues].count > 0)
    {
        NSArray* allSessions = [_sessionLookupDisplayNamesToSessions allValues];
        for(MCSession* session in allSessions) {
            [session disconnect];
            session.delegate = nil;
        }
    }
    _sessionLookupDisplayNamesToSessions = [NSMutableDictionary new];
    
    self.deferredConnectionsDisplayNamesToPeerIDs = [NSMutableDictionary new];
}

- (void) resetBrowserAndAdvertiser
{
    // stop all browsing and advertising activity
    [_serviceBrowser stopBrowsingForPeers];
    [_serviceAdvertiser stopAdvertisingPeer];
    
    // reset browser and advertiser objects
    _serviceBrowser = nil;
    _serviceAdvertiser = nil;
    
    // start all connections over again
    _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:_myPeerID serviceType:COMMSYNC_SERVICE_ID];
    _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_myPeerID
                                                           discoveryInfo:nil
                                                             serviceType:COMMSYNC_SERVICE_ID];
    
    _serviceBrowser.delegate = self;
    _serviceAdvertiser.delegate = self;
    
    [_serviceBrowser startBrowsingForPeers];
    [_serviceAdvertiser startAdvertisingPeer];
}

- (void)nukeChatHistory {
    [_chatMessageRealm beginWriteTransaction];
    [_chatMessageRealm deleteAllObjects];
    [_chatMessageRealm commitWriteTransaction];
}

- (void)nukeRealm
{
    [_realm beginWriteTransaction];
    [_realm deleteAllObjects];
    [_realm commitWriteTransaction];
}

- (void)changeUserDisplayNameTo:(NSString *)name {
    [self.peerHistoryRealm beginWriteTransaction];
    self.myUserModel.displayName = name;
    [self.peerHistoryRealm commitWriteTransaction];
    
    NSDictionary *dict = @{
                           @"uniqueID": self.myUserModel.uniqueID,
                           @"displayNameChange": name
                           };
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    [self sendDataPacketToPeers:data];
}

# pragma mark - MCBrowser Delegate
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    BOOL shouldInvite = [_myPeerID.displayName compare:peerID.displayName] == NSOrderedAscending;
    
    if(!shouldInvite)
    {
        NSLog(@"Deferring connection from %@", peerID.displayName);
        // on deferall, we must send the current task list to the new peer we connect to,
        // should the connection be successful; at the moment, just add to them to a dict
        [self.deferredConnectionsDisplayNamesToPeerIDs setObject:peerID forKey:peerID.displayName];
        return;
    }
    else
    {
        [self.devicesThatDeferredToMeDisplayNamesToPeerIDs setObject:peerID forKey:peerID.displayName];
    }
    
    //#warning THIS MAY BE TERRIBLE BEHAVIOR... HOPE NOT!
    BOOL shouldRecreate = NO;
    if([self synchronizedWithLookup:peerID.displayName withAddition:nil forSession:nil orDeletion:nil])
    {
        NSLog(@"[%@] is already in a session.", peerID.displayName);
        //        NSLog(@"Assuming a reconnection attempt needs to be made... rebuilding session for peer [%@]", peerID.displayName);
        return;
        //        shouldRecreate = YES;
    }
    
    [self attemptPeerInvitationForPeer:peerID withDiscoveryInfo:nil shouldRecreate:shouldRecreate];
}

- (void) attemptPeerInvitationForPeer:(MCPeerID *)peerID
                    withDiscoveryInfo:(NSDictionary *)info
                       shouldRecreate:(BOOL)recreate
{
    
    NSTimeInterval linkDeadTime = 15;
    MCSession* inviteSession = [self synchronizedWithLookup:peerID.displayName
                                               withAddition:nil
                                                 forSession:nil
                                                 orDeletion:nil];
    if(!inviteSession) {
        inviteSession = [[MCSession alloc] initWithPeer:_myPeerID];
        inviteSession.delegate = self;
        [self synchronizedWithLookup:nil
                        withAddition:peerID.displayName
                          forSession:inviteSession
                          orDeletion:nil];
    }
    
    [_serviceBrowser invitePeer:peerID toSession:inviteSession withContext:nil timeout:linkDeadTime];
    
    NSLog(@"Inviting PeerID:[%@] to session...", peerID.displayName);
    
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Lost connection to PeerID:[%@]", peerID.displayName);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"lostPeer" object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PEER_CHANGED_STATE" object:self];
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"Start browsing failed :: %@", error);
}


# pragma mark - MCAdvertiser Delegate
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"PeerID:[%@] sent an invitation.", peerID.displayName);
    
    if([self synchronizedWithLookup:peerID.displayName withAddition:nil forSession:nil orDeletion:nil])
    {
        NSLog(@"Peer already in session; sending NO.");
        invitationHandler(NO, nil);
        return;
    }
    
    NSLog(@"...Auto accepting...");
    
    MCSession* acceptSession = [[MCSession alloc] initWithPeer:_myPeerID];
    acceptSession.delegate = self;
    
    invitationHandler(YES, acceptSession);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"Start advertising failed :: %@", error);
}


# pragma mark - MCSession Delegate
- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    certificateHandler(YES);
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSString* stateString;
    
    switch (state) {
        case MCSessionStateNotConnected:
            stateString = kUserNotConnectedNotification;
            
            if([_currentConnectedPeers valueForKey:peerID.displayName])
            {
                [_currentConnectedPeers removeObjectForKey:peerID.displayName];
            }
            
            // We never connected, or lost a connection to, the peer.
            // Reset connection browsing and move on.
            if([self synchronizedWithLookup:peerID.displayName withAddition:nil forSession:nil orDeletion:nil])
            {
                NSLog(@"Removing peer [%@] from known session.", peerID.displayName);
                MCSession* badSession = [self synchronizedWithLookup:peerID.displayName
                                                        withAddition:nil
                                                          forSession:nil
                                                          orDeletion:nil];
                [badSession disconnect];
                badSession.delegate = nil;
                [self synchronizedWithLookup:nil withAddition:nil forSession:nil orDeletion:peerID.displayName];
            }
            
            [self resetBrowserAndAdvertiser];
            break;
        case MCSessionStateConnecting:
            stateString = kUserConnectingNotification;
            [self synchronizedWithLookup:nil withAddition:peerID.displayName forSession:session orDeletion:nil];
            break;
        case MCSessionStateConnected:
        {
            stateString = kUserConnectedNotification;
            [_currentConnectedPeers setValue:peerID forKey:peerID.displayName];
            
            dispatch_async(_peerHistoryQueue, ^{
                
                //send all peer data to eachother
                NSMutableArray *peers = [[NSMutableArray alloc]init];
                RLMRealm* peerHistoryRealm = [CSRealmFactory peerHistoryRealm];
                for (CSUserRealmModel* user in [CSUserRealmModel allObjectsInRealm:peerHistoryRealm]) {
                    [peers addObject:user];
                }
                
                NSDictionary *dataToSend = @{@"UserArray"  :   peers};
                NSData *historyData = [NSKeyedArchiver archivedDataWithRootObject:dataToSend];
                [self sendSingleDataPacket:historyData toSinglePeer:peerID];
                
                //if there are any unsent messages then send them
               // CSUserRealmModel *peer = [CSUserRealmModel objectInRealm:peerHistoryRealm forPrimaryKey:peerID.displayName];
               // NSInteger number = peer.unsentMessages;
                //if(number > 0)
               // {
                    dispatch_async(_chatMessageQueue, ^{
                       // NSPredicate* pred = [NSPredicate predicateWithFormat:@"createdBy = %@ OR recipient = %@", peerID.displayName, peerID.displayName];
                        RLMRealm* privateMessageRealm = [CSRealmFactory privateMessageRealm];
                        RLMResults* messages = [CSChatMessageRealmModel allObjectsInRealm:privateMessageRealm];
                        NSMutableArray* send = [[NSMutableArray alloc] init];
                       
                        //add unsent messages
//                        for(int i = 0; i < number; i++ ) {
//                            [send addObject: messages[[messages count] - 1 - i]];
//                        }
                        for(CSChatMessageRealmModel* message in messages)
                        {
                            [send addObject:message];
                        }
                        if([send count]> 0)
                        {
                            NSDictionary *dataToSend = @{@"PMArray"  :   send};
                            NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dataToSend];
                            [self sendSingleDataPacket:data toSinglePeer:peerID];
                        }
                    });
                    
              //  }
            });
            
            dispatch_async(_chatMessageQueue, ^{
                NSMutableArray* send = [[NSMutableArray alloc]init];
                RLMRealm* chatRealm = [CSRealmFactory chatMessageRealm];
                for(CSChatMessageRealmModel* message in [CSChatMessageRealmModel allObjectsInRealm:chatRealm]) {
                    [send addObject:message];
                }
                if([send count] > 0) {
                    NSDictionary *dataToSend = @{@"ChatArray"  :   send};
                    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dataToSend];
                    [self sendSingleDataPacket:data toSinglePeer:peerID];
                }
            });
            
            dispatch_async(_taskRealmQueue, ^{
                NSMutableArray* send = [[NSMutableArray alloc]init];
            
                for(CSTaskRealmModel* task in [CSTaskRealmModel allObjectsInRealm:[RLMRealm defaultRealm]]) {
                    [send addObject:task.concatenatedID];
                }
            
                if([send count] > 0) {
                    NSDictionary *dataToSend = @{@"TaskArray"  :   send};
                    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dataToSend];
                    [self sendSingleDataPacket:data toSinglePeer:peerID];
                }
            });

            break;
        }
        default:
            break;
    }
    
    NSLog(@"\t\t-- --");
    NSLog(@"\t\tSession peers: \n%@", session.connectedPeers);
    
    NSLog(@"\t\tPeer: [%@] --> New State: [%@]", peerID.displayName, stateString);
    NSLog(@"\t\t-- --");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:stateString object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PEER_CHANGED_STATE" object:self];
}

/**
 An invitation switch is not necessary for a one-to-one session management system; a simple deferment is
 needed between two devices so as not to cause issues with the so-fragile MCSession object
 
 - (void)setInvitationSwitch {
 
 // Set invitation switched based on new connected peers
 NSSortDescriptor *displayNameSortDecriptor = [NSSortDescriptor sortDescriptorWithKey:@"displayName"
 ascending:YES
 selector:@selector(localizedStandardCompare:)];
 //    NSArray* sorted = [self.currentSession.connectedPeers sortedArrayUsingDescriptors:@[displayNameSortDecriptor]];
 NSArray* sorted = nil;
 if(!sorted || !sorted.count > 0){
 _isResponsibleForSendingInvites = YES;
 return;
 }
 
 MCPeerID* firstPeer = [sorted objectAtIndex:0];
 BOOL shouldInvite = [_myPeerID.displayName compare:firstPeer.displayName] == NSOrderedAscending;
 if(shouldInvite){
 _isResponsibleForSendingInvites = YES;
 } else {
 _isResponsibleForSendingInvites = NO;
 }
 
 }
 **/
#pragma mark - Data handling delegate passthroughs

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    if(_dataHandlingDelegate && [_dataHandlingDelegate conformsToProtocol:@protocol(MCSessionDataHandlingDelegate)])
    {
        [_dataHandlingDelegate session:session didReceiveData:data fromPeer:peerID];
    }
}


- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    // increment counter
    OSAtomicIncrement32(&_receivedResourceCount);
    
    // set state to transmitting to stop browsing/advertising
    self.state = CSSessionManagerStateTransmittingTasks;
    
    if(_dataHandlingDelegate && [_dataHandlingDelegate conformsToProtocol:@protocol(MCSessionDataHandlingDelegate)])
    {
        [_dataHandlingDelegate session:session didStartReceivingResourceWithName:resourceName fromPeer:peerID withProgress:progress];
    }
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    // decrement counter
    OSAtomicDecrement32(&_receivedResourceCount);
    
    // if no more incoming tasks, set state to searching
    if (_receivedResourceCount == 0) {
        self.state = CSSessionManagerStateSearching;
    }
    
    if(_dataHandlingDelegate && [_dataHandlingDelegate conformsToProtocol:@protocol(MCSessionDataHandlingDelegate)])
    {
        [_dataHandlingDelegate session:session didFinishReceivingResourceWithName:resourceName fromPeer:peerID atURL:localURL withError:error];
    }
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Peer: [%@] is streaming", peerID.displayName);
}


#pragma mark - Database actions


- (void)createUserModel
{
    
    NSData *historyData = [NSKeyedArchiver archivedDataWithRootObject:self.myPeerID];
    CSUserRealmModel *peerToUse = [[CSUserRealmModel alloc] initWithMessage:historyData withDisplayName:_myDisplayName withID:_myUniqueID lastChanged:[NSDate date]];
    
    peerToUse.avatar = -1;
    _myUserModel = peerToUse;
    [_peerHistoryRealm beginWriteTransaction];
    [_peerHistoryRealm addObject:peerToUse];
    [_peerHistoryRealm commitWriteTransaction];
    
}

-(void)updateAvatar: (NSInteger) number
{
    dispatch_async(dispatch_get_main_queue(), ^{
        CSUserRealmModel *myself = [CSUserRealmModel objectInRealm:_peerHistoryRealm forPrimaryKey:_myUniqueID];
        [_peerHistoryRealm beginWriteTransaction];
        [myself updateChangeTime];
        myself.avatar = number;
        self.myUserModel = myself;
        [_peerHistoryRealm commitWriteTransaction];
        
        NSDictionary *dict = @{@"Avatar"  :   _myPeerID.displayName,
                               @"Number"  :   [NSNumber numberWithInteger:number],
                               @"Time"    :    myself.lastUpdated
                               };
        NSData* requestData = [NSKeyedArchiver archivedDataWithRootObject:dict];
        [self sendDataPacketToPeers:requestData];
    });
}


-(void)nukeHistory
{
    _peerHistoryRealm = [CSRealmFactory peerHistoryRealm];
    NSLog(@"%lu", (unsigned long)[[CSUserRealmModel allObjectsInRealm:_peerHistoryRealm] count]);
    RLMResults* allButMe = [CSUserRealmModel objectsInRealm:_peerHistoryRealm where:@"uniqueID != %@", _myUniqueID];
    
    [_peerHistoryRealm beginWriteTransaction];
    [_peerHistoryRealm deleteObjects:allButMe];
    [_peerHistoryRealm commitWriteTransaction];
    NSLog(@"%lu", (unsigned long)[[CSUserRealmModel allObjectsInRealm:_peerHistoryRealm] count]);
}

- (void)updateRealmWithChatMessage:(CSChatMessageRealmModel *)message
{
    dispatch_sync(_chatMessageQueue, ^{
        RLMRealm *chatRealm = [CSRealmFactory chatMessageRealm];
        
        [chatRealm beginWriteTransaction];
        [chatRealm addObject:message];
        [chatRealm commitWriteTransaction];
    });
}

-(void) addMessage:(NSString *)peer
{
        RLMRealm *peerRealm = [CSRealmFactory peerHistoryRealm];
        CSUserRealmModel* user = [CSUserRealmModel objectInRealm:peerRealm forPrimaryKey:peer];
        [peerRealm beginWriteTransaction];
        [user addMessage];
        [peerRealm commitWriteTransaction];
}

-(void) removeMessage:(NSString *)peer
{
    if([_unreadMessages objectForKey:peer]) [_unreadMessages removeObjectForKey:peer];
}

@end