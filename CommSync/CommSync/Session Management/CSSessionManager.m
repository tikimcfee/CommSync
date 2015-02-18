//
//  CSSessionManager.m
//  CommSync
//
//  Created by Ivan Lugo on 10/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSSessionManager.h"
#import <Realm/Realm.h>

#import "CSTaskRealmModel.h"
#import "CSTaskTransientObjectStore.h"
#import "AppDelegate.h"
#import "CSChatMessageRealmModel.h"
#import "CSSessionDataAnalyzer.h"

#define kUserNotConnectedNotification @"Not Connected"
#define kUserConnectedNotification @"Connected"
#define kUserConnectingNotification @"Is Connecting"

@interface CSSessionManager()

@property (nonatomic, strong) NSMutableDictionary* deferredConnectionsDisplayNamesToPeerIDs;
@property (nonatomic, strong) NSMutableDictionary* devicesThatDeferredToMeDisplayNamesToPeerIDs;
//@property (nonatomic, strong) NSMutableArray* sortedArrayOfPeers;
@property (nonatomic, strong) RLMRealm* realm;
@property (nonatomic, strong) CSSessionDataAnalyzer* dataAnalyzer;

@property (nonatomic, assign) BOOL isResponsibleForSendingInvites;

@end


@implementation CSSessionManager

- (CSSessionManager*) initWithID:(NSString*)userID
{
    //
    // Session management objects
    //
    _myPeerID = [[MCPeerID alloc] initWithDisplayName:userID];
    _dataAnalyzer = [CSSessionDataAnalyzer sharedInstance:self];
    
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
    
    // Connection deferrement
    self.deferredConnectionsDisplayNamesToPeerIDs = [NSMutableDictionary new];
    self.devicesThatDeferredToMeDisplayNamesToPeerIDs = [NSMutableDictionary new];
    self.isResponsibleForSendingInvites = YES;
    
    // Getting default realm from disk
    _realm = [RLMRealm defaultRealm];
    _realm.autorefresh = YES;
    
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
    NSString* pulseText = PULSE_STRING;
    NSData* newPulse = [pulseText dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    
//    for(MCPeerID* peer in _currentSession.connectedPeers)
//    {
//        [_currentSession sendData:newPulse
//                          toPeers:@[peer]
//                         withMode:MCSessionSendDataReliable
//                            error:&error];
//    }
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
            } else if (session.connectedPeers <= 0) {
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
        } else if (sessionToSendOn.connectedPeers <= 0) {
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
        MCSession* sessionToSendOn = [_sessionLookupDisplayNamesToSessions valueForKey:peer.displayName];
        if(!sessionToSendOn) {
            NSLog(@"! No active session found for peer [%@]", peer.displayName);
            return;
        }
        
        if(sessionToSendOn.connectedPeers.count > 1) {
            NSLog(@"! WARNING ! - Session with multiple users (%@)", sessionToSendOn.connectedPeers);
        } else if (sessionToSendOn.connectedPeers <= 0) {
            NSLog(@"! WARNING ! - Session with ZERO connected users (%@)", sessionToSendOn.connectedPeers);
            return;
        }
        
        NSData* newTaskDataBlob = [NSKeyedArchiver archivedDataWithRootObject:task];
        
        NSLog(@"Total size going out: %.2fkB (%tu Bytes)", newTaskDataBlob.length / 1024.0, newTaskDataBlob.length);
        
        NSURL* URLOfNewTask = [task temporarilyPersistTaskDataToDisk:newTaskDataBlob];
        
        MCPeerID* thisPeer = [sessionToSendOn.connectedPeers objectAtIndex:0];
        [sessionToSendOn sendResourceAtURL:URLOfNewTask
                                  withName:task.concatenatedID
                                    toPeer:thisPeer
                     withCompletionHandler:
         ^(NSError *error) {
             if(error) {
                 NSLog(@"Task sending FAILED with error: %@ to peer: %@", error, thisPeer.displayName);
             }
             else {
                 NSLog(@"Task sending COMPLETE with name: %@ to peer: %@", task.taskTitle, thisPeer.displayName);
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
    NSLog(@"Killing session");
    // stop all browsing and advertising activity
    [_serviceBrowser stopBrowsingForPeers];
    [_serviceAdvertiser stopAdvertisingPeer];
    
    // reset browser and advertiser objects
    _serviceBrowser = nil;
    _serviceAdvertiser = nil;
    
    // kill session
    
//    [_currentSession disconnect];
//    _currentSession = nil;
    
    NSLog(@"Restarting session");
    
    // start all connections over again
    _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:_myPeerID serviceType:COMMSYNC_SERVICE_ID];
    _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_myPeerID
                                                           discoveryInfo:nil
                                                             serviceType:COMMSYNC_SERVICE_ID];
    
    _serviceBrowser.delegate = self;
    _serviceAdvertiser.delegate = self;
    
    [_serviceBrowser startBrowsingForPeers];
    [_serviceAdvertiser startAdvertisingPeer];
    
//    _currentSession = [[MCSession alloc] initWithPeer:_myPeerID];
//    _currentSession.delegate = self;
    
    self.deferredConnectionsDisplayNamesToPeerIDs = [NSMutableDictionary new];
    self.isResponsibleForSendingInvites = YES;
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

    if([_sessionLookupDisplayNamesToSessions valueForKey:peerID.displayName])
    {
        NSLog(@"[%@] is already in a session.", peerID.displayName);
        return;
    }
    
    [self attemptPeerInvitationForPeer:peerID withDiscoveryInfo:info];
}

- (void) attemptPeerInvitationForPeer:(MCPeerID *)peerID
                    withDiscoveryInfo:(NSDictionary *)info {
    
    NSTimeInterval linkDeadTime = 15;
    MCSession* inviteSession = [_sessionLookupDisplayNamesToSessions valueForKey:peerID.displayName];
    if(!inviteSession) {
        inviteSession = [[MCSession alloc] initWithPeer:_myPeerID];
        inviteSession.delegate = self;
        [_sessionLookupDisplayNamesToSessions setValue:inviteSession forKey:peerID.displayName];
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

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    [_dataAnalyzer analyzeReceivedData:data fromPeer:peerID];
//    
//    NSString* stringFromData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    
//    id receivedObject = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//        
//    NSLog(@"~~~~~~~~~Received Data: [ %@ ]~~~~~~~~~", [receivedObject class]);
//    
//    if([receivedObject isKindOfClass:[CSTaskTransientObjectStore class]])
//    {
//        [self batchUpdateRealmWithTasks:@[receivedObject]];
//    }
//    else if([receivedObject isKindOfClass:[NSMutableArray class]])
//    {
//        [self batchUpdateRealmWithTasks:receivedObject];
//    }
//    else if([receivedObject isKindOfClass:[CSChatMessageRealmModel class]])
//    {
//        [self updateRealmWithChatMessage:receivedObject];
//    }
//    else if([receivedObject isKindOfClass:[NSDictionary class]])
//    {
//        
//    }
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSString* stateString;
    switch (state) {
        case MCSessionStateNotConnected:
            stateString = kUserNotConnectedNotification;
//            if([self.devicesThatDeferredToMeDisplayNamesToPeerIDs valueForKey:peerID.displayName])
//            {
//                NSLog(@"Retrying connection to [%@]", peerID.displayName);
//                NSMutableArray* taskDataStore = [CSTaskRealmModel getTransientTaskList];
//                
//                NSData* contextData = [NSKeyedArchiver archivedDataWithRootObject: taskDataStore];
//                [_serviceBrowser invitePeer:peerID toSession:_currentSession withContext:contextData timeout:30];
//                
//                [self.devicesThatDeferredToMeDisplayNamesToPeerIDs removeObjectForKey:peerID.displayName];
//            }
            break;
        case MCSessionStateConnecting:
            stateString = kUserConnectingNotification;
            break;
        case MCSessionStateConnected:
//            if([self.deferredConnectionsDisplayNamesToPeerIDs valueForKey:peerID.displayName])
//            {
//                NSMutableArray* taskList = [CSTaskRealmModel getTransientTaskList];
//                NSData* contextData = [NSKeyedArchiver archivedDataWithRootObject: taskList];
//                
////                [self sendDataPacketToPeers:contextData];
//                
//                [self.deferredConnectionsDisplayNamesToPeerIDs removeObjectForKey:peerID.displayName];
//                [self.devicesThatDeferredToMeDisplayNamesToPeerIDs removeObjectForKey:peerID.displayName];
//            }
            stateString = kUserConnectedNotification;
            break;
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

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    // Create a notification dictionary for resource progress tracking
    NSDictionary *dict = @{@"resourceName"  :   resourceName,
                           @"peerID"        :   peerID,
                           @"progress"      :   progress
                           };
    
    // Post notification globally
    // NOTE! Receivers of this notification must be intelligent in determining WHAT object has progressed!
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSDidStartReceivingResourceWithName
                                                        object:nil
                                                      userInfo:dict];
    
    // Register the sessiona manager as the observation delegate

    /**
     Use this code if you want to observe the progress of a data transfer from the 
     session manager and then send notifications out as progress changes
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [progress addObserver:self
//                   forKeyPath:@"fractionCompleted"
//                      options:NSKeyValueObservingOptionNew
//                      context:nil];
//    });
     **/
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
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
    
    // Post notification globally
    // NOTE! Receivers of this notification must be intelligent in determining WHAT object has progressed!
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSDidFinishReceivingResourceWithName
                                                        object:nil
                                                      userInfo:dict];
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Peer: [%@] is streaming", peerID.displayName);
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




#pragma mark - Database actions
- (void)updateRealmWithChatMessage:(CSChatMessageRealmModel *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        RLMResults *results = [CSTaskRealmModel allObjects];
        [_realm beginWriteTransaction];
        
        for(CSTaskTransientObjectStore* task in tasks)
        {
            NSPredicate *uniqueTaskPredicate = [NSPredicate predicateWithFormat:@"concatenatedID == %@", task.concatenatedID];
            if([results objectsWithPredicate:uniqueTaskPredicate].count == 0) {
                
                CSTaskRealmModel* newModel = [[CSTaskRealmModel alloc] init];
                [task setAndPersistPropertiesOfNewTaskObject:newModel inRealm:_realm withTransaction:NO];
                
            } else {
                NSLog(@"Duplicate task not being stored");
            }
        }
        [_realm commitWriteTransaction];
    });
}


@end
