//
//  CSSessionManager.m
//  CommSync
//
//  Created by Ivan Lugo on 10/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSSessionManager.h"


#import "CSTaskRealmModel.h"
#import "CSTaskTransientObjectStore.h"
#import "AppDelegate.h"
#import "CSChatMessageRealmModel.h"
#import "CSSessionDataAnalyzer.h"
#import "CSUserRealmModel.h"
#import "SlackTestViewController.h"

#define kUserNotConnectedNotification @"Not Connected"
#define kUserConnectedNotification @"Connected"
#define kUserConnectingNotification @"Is Connecting"

@interface CSSessionManager()

@property (nonatomic, strong) NSMutableDictionary* deferredConnectionsDisplayNamesToPeerIDs;
@property (nonatomic, strong) NSMutableDictionary* devicesThatDeferredToMeDisplayNamesToPeerIDs;
@property (nonatomic, strong) RLMRealm* realm;

@property (nonatomic, strong) CSSessionDataAnalyzer* dataAnalyzer;
@property (nonatomic, strong) CSUserRealmModel *peers;

@property (strong, nonatomic) AppDelegate *app;

@end


@implementation CSSessionManager

- (CSSessionManager*) initWithID:(NSString*)userID
{
    //
    // Session management objects
    //
    if(self = [super init])
    {
        
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _myPeerID = [[MCPeerID alloc] initWithDisplayName:userID];
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
       

        _chatMessageQueue =  dispatch_queue_create("chatMessageQueue", NULL);
        _privateMessageQueue = dispatch_queue_create("privateMessageQueue", NULL);
        _taskRealmQueue =  dispatch_queue_create("taskRealmQueue", NULL);
       _peerHistoryQueue = dispatch_queue_create("peerHistoryQueue", NULL);
        
        dispatch_sync(self.peerHistoryQueue,^{
            _peerHistoryRealm = [RLMRealm realmWithPath:[CSSessionManager peerHistoryRealmDirectory]];
            _peerHistoryRealm.autorefresh = YES;
        });
        
        dispatch_sync(self.privateMessageQueue,^{
            _privateMessageRealm = [RLMRealm realmWithPath :[CSSessionManager privateMessageRealmDirectory]];
            _privateMessageRealm.autorefresh = YES;
        });
        
        dispatch_sync(self.chatMessageQueue,^{
            _chatMessageRealm = [RLMRealm realmWithPath :[CSSessionManager chatMessageRealmDirectory]];
            _chatMessageRealm.autorefresh = YES;
        });
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

# pragma mark - Heartbeat
- (void) sendPulseToPeers
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
    
    for( CSTaskRealmModel *temp in [CSTaskRealmModel allObjectsInRealm:[RLMRealm defaultRealm]])
    {
        [[CSSessionDataAnalyzer sharedInstance:nil] validateDataWithRandomPeer:temp.transientModel];
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

- (void) sendNewTaskToPeers:(CSTaskTransientObjectStore*)newTask;
{
    if([_sessionLookupDisplayNamesToSessions allValues].count > 0)
    {
        NSData* newTaskDataBlob = [NSKeyedArchiver archivedDataWithRootObject:newTask];
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
                 withCompletionHandler:
             ^(NSError *error) {
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

- (void) sendSingleTask:(CSTaskTransientObjectStore*)task toSinglePeer:(MCPeerID*)peer
{
    
    if([_sessionLookupDisplayNamesToSessions allValues].count > 0)
    {
        CSTaskTransientObjectStore* strongTask = task;
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
        
        NSData* newTaskDataBlob = [NSKeyedArchiver archivedDataWithRootObject:strongTask];
        
        NSLog(@"Total size going out: %.2fkB (%tu Bytes)", newTaskDataBlob.length / 1024.0, newTaskDataBlob.length);
        
        NSURL* URLOfNewTask = [strongTask temporarilyPersistTaskDataToDisk:newTaskDataBlob];
        
        MCPeerID* thisPeer = [sessionToSendOn.connectedPeers objectAtIndex:0];
        [sessionToSendOn sendResourceAtURL:URLOfNewTask
                                  withName:strongTask.concatenatedID
                                    toPeer:thisPeer
                     withCompletionHandler:
         ^(NSError *error) {
             if(error) {
                 NSLog(@"Task sending FAILED with error: %@ to peer: %@", error, thisPeer.displayName);
             }
             else {
                 NSLog(@"Task sending COMPLETE with name: %@ to peer: %@", strongTask.taskTitle, thisPeer.displayName);
             }
         }];
        
        //        NSLog(@"Removing file from disk...");
        //        if([task removeTemporaryTaskDataFromDisk])
        //        {
        //            NSLog(@"Task %@ still exists on disk!", task);
        //        }
    }
}

# pragma mark - Session Helpers
- (MCSession*)setAndReturnNewSessionForPeer:(MCPeerID*)peer {
    MCSession* newSession = [[MCSession alloc] initWithPeer:_myPeerID];
    newSession.delegate = self;
    
    if([_sessionLookupDisplayNamesToSessions valueForKey:peer.displayName]) {
        NSLog(@"[!] A session already exists for this peer. Disconnecting from that session and RESETTING value to new session.");
        MCSession* oldSession = [_sessionLookupDisplayNamesToSessions valueForKey:peer.displayName];
        [oldSession disconnect];
        oldSession.delegate = nil;
    }
    
    [_sessionLookupDisplayNamesToSessions setValue:newSession forKey:peer.displayName];
    
    return newSession;
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


- (void)nukeRealm
{
    [_realm beginWriteTransaction];
    [_realm deleteAllObjects];
    [_realm commitWriteTransaction];
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
    if([_sessionLookupDisplayNamesToSessions valueForKey:peerID.displayName])
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
    MCSession* inviteSession = [_sessionLookupDisplayNamesToSessions valueForKey:peerID.displayName];
    if(!inviteSession) {
        inviteSession = [[MCSession alloc] initWithPeer:_myPeerID];
        inviteSession.delegate = self;
        [_sessionLookupDisplayNamesToSessions setValue:inviteSession forKey:peerID.displayName];
    } else if (recreate) {
        MCSession* newSession = [[MCSession alloc] initWithPeer:_myPeerID];
        newSession.delegate = self;
        inviteSession.delegate = nil;
        [_sessionLookupDisplayNamesToSessions removeObjectForKey:peerID.displayName];
        [_sessionLookupDisplayNamesToSessions setValue:newSession forKey:peerID.displayName];
        inviteSession = newSession;
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
    
    if([_sessionLookupDisplayNamesToSessions valueForKey:peerID.displayName])
    {
        NSLog(@"Peer already in session; sending NO.");
        invitationHandler(NO, nil);
        return;
    }
    
    NSLog(@"...Auto accepting...");
    
    MCSession* acceptSession = [[MCSession alloc] initWithPeer:_myPeerID];
    acceptSession.delegate = self;
    [_sessionLookupDisplayNamesToSessions setValue:acceptSession forKey:peerID.displayName];
    
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
            if([_sessionLookupDisplayNamesToSessions valueForKey:peerID.displayName])
            {
                NSLog(@"Removing peer [%@] from known session.", peerID.displayName);
                MCSession* badSession = [_sessionLookupDisplayNamesToSessions valueForKey:peerID.displayName];
                [badSession disconnect];
                badSession.delegate = nil;
                [_sessionLookupDisplayNamesToSessions removeObjectForKey:peerID.displayName];
            }
            
            [self resetBrowserAndAdvertiser];
            break;
        case MCSessionStateConnecting:
            stateString = kUserConnectingNotification;
            break;
        case MCSessionStateConnected:
        {
            stateString = kUserConnectedNotification;
            [_currentConnectedPeers setValue:peerID forKey:peerID.displayName];
            
            
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                //if this is a direct connection then propagate peer history and tasks of both users
                if([_sessionLookupDisplayNamesToSessions valueForKey:peerID.displayName])
                {
                    
                    NSMutableArray *peers = [[NSMutableArray alloc]init];
                    [peers addObjectsFromArray:[CSUserRealmModel allObjectsInRealm:_peerHistoryRealm]];
                    NSData *historyData = [NSKeyedArchiver archivedDataWithRootObject:peers];
                    [self sendDataPacketToPeers:historyData];
                }
                
                NSArray* peers = [CSUserRealmModel objectsInRealm:_peerHistoryRealm where:@"displayName = %@", peerID.displayName];
               
                //add the user to a the peer history if weve never met
                if([peers count] == 0)
                {
                    [self updatePeerHistory:peerID withID:nil];
                }
                
                else{
                     CSUserRealmModel *peer = peers[0];
                    NSPredicate* pred = [NSPredicate predicateWithFormat:@"createdBy = %@ OR recipient = %@",
                                         peerID.displayName, peerID.displayName];
                    
                    int number = peer.unsetMessages;
                    if(number > 0)
                    {
                    
                        RLMArray* messages = [CSChatMessageRealmModel objectsInRealm:_privateMessageRealm withPredicate:pred];
                    
                        NSMutableArray* send = [[NSMutableArray alloc]init];
                    


                        //add unsent messages
                        for(int i = 0; i < number; i++ )
                        {
                            [send addObject: messages[[messages count] - 1 - i]];
                        }
                        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:send];
                        [self sendSingleDataPacket:data toSinglePeer:peerID];
                    
                    }
                }
                
                
            });
            
            dispatch_async(_taskRealmQueue, ^{
                NSMutableArray* send = [[NSMutableArray alloc]init];
            
                for(CSTaskRealmModel* task in [CSTaskRealmModel allObjectsInRealm:[RLMRealm defaultRealm]])
                {
                    [send addObject:task.concatenatedID];
                }
                NSData* data = [NSKeyedArchiver archivedDataWithRootObject:send];
            
                if([send count] > 0) {
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
    if(_dataHandlingDelegate && [_dataHandlingDelegate conformsToProtocol:@protocol(MCSessionDataHandlingDelegate)])
    {
        [_dataHandlingDelegate session:session didStartReceivingResourceWithName:resourceName fromPeer:peerID withProgress:progress];
    }
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
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
- (void)updatePeerHistory:(MCPeerID *)peerID withID:(NSString *)UUID
{
    
    
    
    if([peerID.displayName isEqualToString:_myPeerID.displayName]) return;
    
    
    NSData *historyData = [NSKeyedArchiver archivedDataWithRootObject:peerID];
    CSUserRealmModel *peerToUse = [[CSUserRealmModel alloc] initWithMessage:historyData withDisplayName:peerID.displayName];
    
    //if we are getting this from somewhere else then set the UUID to the same
    if(UUID) peerToUse.UUID = UUID;
    
    [_peerHistoryRealm beginWriteTransaction];
    [_peerHistoryRealm addObject:peerToUse];
    [_peerHistoryRealm commitWriteTransaction];
    
}


-(void)nukeHistory
{
    _peerHistoryRealm = [RLMRealm realmWithPath:[CSSessionManager peerHistoryRealmDirectory]];
    //add all current connected peers to database
    [_peerHistoryRealm beginWriteTransaction];
    [_peerHistoryRealm deleteAllObjects];
    [_peerHistoryRealm commitWriteTransaction];
}

- (void)updateRealmWithChatMessage:(CSChatMessageRealmModel *)message
{
    dispatch_sync(_chatMessageQueue, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        NSString *chatRealmPath = [basePath stringByAppendingString:@"/chat.realm"];
        
        RLMRealm *chatRealm = [RLMRealm realmWithPath:chatRealmPath];
        
        [chatRealm beginWriteTransaction];
        [chatRealm addObject:message];
        [chatRealm commitWriteTransaction];
    });
}

- (void)batchUpdateRealmWithTasks:(NSArray*)tasks {
    
    dispatch_sync(_taskRealmQueue, ^{
        
        [_realm beginWriteTransaction];
        
        for(CSTaskTransientObjectStore* task in tasks)
        {
            CSTaskRealmModel*  foundTask = [CSTaskRealmModel objectInRealm:[RLMRealm defaultRealm] forPrimaryKey:task.concatenatedID];
            
            if(!foundTask) {
                [self addTag:task.tag];
                CSTaskRealmModel* newModel = [[CSTaskRealmModel alloc] init];
                [task setAndPersistPropertiesOfNewTaskObject:newModel inRealm:_realm withTransaction:NO];
                
            } else {
                NSLog(@"Duplicate task not being stored");
            }
        }
        [_realm commitWriteTransaction];
    });
}


+ (NSString *)peerHistoryRealmDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:@"/peers.realm"];
}

-(void) addTag:(NSString*) tag
{
    if ([tag isEqualToString:@""]) return;
    if(![_allTags valueForKey:tag]) [_allTags setValue:tag forKey:tag];
}

-(void) addMessage:(NSString *)peer
{
    
    dispatch_sync(_peerHistoryQueue, ^{
        CSUserRealmModel* user = [CSUserRealmModel objectsInRealm:_peerHistoryRealm where:@"displayName = %@", peer][0];
        NSLog(user.displayName);
        [_peerHistoryRealm beginWriteTransaction];
        user.addMessage;
        [_peerHistoryRealm commitWriteTransaction];
    });
}

-(void) removeMessage:(NSString *)peer
{
    if([_unreadMessages objectForKey:peer]) [_unreadMessages removeObjectForKey:peer];
}


+ (NSString *)chatMessageRealmDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:@"/chat.realm"];
}

+ (NSString *)privateMessageRealmDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:@"/privateMessage.realm"];
}
@end