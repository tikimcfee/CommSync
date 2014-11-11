//
//  CSSessionManager.m
//  CommSync
//
//  Created by Ivan Lugo on 10/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSSessionManager.h"

#define kUserNotConnectedNotification @"Not Connected"
#define kUserConnectedNotification @"Connected"
#define kUserConnectingNotification @"Is Connecting"


@implementation CSSessionManager

- (CSSessionManager*) initWithID:(NSString*)userID
{
    _myPeerID = [[MCPeerID alloc] initWithDisplayName:userID];
    _userID = userID;
    
    _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:_myPeerID serviceType:COMMSYNC_SERVICE_ID];
    _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_myPeerID
                                                           discoveryInfo:nil
                                                             serviceType:COMMSYNC_SERVICE_ID];
    
    _serviceBrowser.delegate = self;
    _serviceAdvertiser.delegate = self;
    
    [_serviceBrowser startBrowsingForPeers];
    [_serviceAdvertiser startAdvertisingPeer];
    
    _userSessionsDisplayNamesToSessions = [[NSMutableDictionary alloc] init];
    
    _currentSession = [[MCSession alloc] initWithPeer:_myPeerID];
    [_userSessionsDisplayNamesToSessions setObject:_currentSession forKey:_userID];
    
    
    return self;
}

- (CSSessionManager*) initWithID:(NSString*)userID
                      securityID:(NSArray*)ID
         andEncryptionPreference:(MCEncryptionPreference*)encryption
{
    NSLog(@"--- WARNING --- USING THE WRONG INITIALIZER");
    return nil;
}

# pragma ITERATION

//NSArray* allSessions = [_userSessionsDisplayNamesToSessions allValues];
//for(MCSession* session in allSessions)
//{
//    for(MCPeerID* peer in session.connectedPeers)
//    {
//    }
//}

# pragma Heartbeat
- (void) sendPulseToPeers
{
    NSString* pulseText = PULSE_STRING;
    NSData* newPulse = [pulseText dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    
//    NSArray* allSessions = [_userSessionsDisplayNamesToSessions allValues];
    NSSet* uniqueSessions = [NSSet setWithArray:[_userSessionsDisplayNamesToSessions allValues]];
    
    for(MCSession* session in uniqueSessions)
    {
        for(MCPeerID* peer in session.connectedPeers)
        {
            NSLog(@"Sending a pulse to :: [%@]", peer.displayName);
            [session sendData:newPulse toPeers:@[peer]
                        withMode:MCSessionSendDataReliable
                           error:&error];
        }
    }
}

# pragma mark - Session Helpers
- (MCSession*)createNewSessionToNewPeer:(MCPeerID*)peerID
{
    MCSession* newSession = [[MCSession alloc] initWithPeer:_myPeerID];
    newSession.delegate = self;
    [_userSessionsDisplayNamesToSessions setObject:newSession forKey:peerID.displayName];
    
    return newSession;
}



- (void)tearDownConnectivityFramework
{
    _serviceBrowser.delegate = nil;
    [_serviceBrowser stopBrowsingForPeers];
    _serviceBrowser = nil;
    
    _serviceAdvertiser.delegate = nil;
    [_serviceAdvertiser stopAdvertisingPeer];
    _serviceAdvertiser = nil;

    NSString* disconnect = MANUAL_DISCONNECT_STRING;
    NSData* killData = [disconnect dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    
    NSArray* allSessions = [_userSessionsDisplayNamesToSessions allValues];
    for(MCSession* session in allSessions)
    {
        for(MCPeerID* peer in session.connectedPeers)
        {
            [session sendData:killData toPeers:@[peer]
                             withMode:MCSessionSendDataReliable
                                error:&error];
        }
    }
    
}

- (void)resetPeerID
{
    _myPeerID = nil;
    _myPeerID = [[MCPeerID alloc] initWithDisplayName:_userID];
}

- (void)resetBrowserService
{
    [_serviceBrowser stopBrowsingForPeers];
    _serviceBrowser = nil;
    
    _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:_myPeerID serviceType:COMMSYNC_SERVICE_ID];
    _serviceBrowser.delegate = self;
    
    [_serviceBrowser startBrowsingForPeers];
}

- (void)resetAdvertiserService
{
    [_serviceAdvertiser stopAdvertisingPeer];
    _serviceAdvertiser = nil;
    
    _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_myPeerID
                                                           discoveryInfo:nil
                                                             serviceType:COMMSYNC_SERVICE_ID];
    _serviceAdvertiser.delegate = self;
    
    [_serviceAdvertiser startAdvertisingPeer];
}

# pragma mark - MCBrowser Delegate
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    BOOL shouldInvite = [_myPeerID.displayName compare:peerID.displayName] == NSOrderedDescending;

    if(!shouldInvite)
    {
        NSLog(@"Deferring connection from %@", peerID.displayName);
        return;
    }
    
    if( [_userSessionsDisplayNamesToSessions objectForKey:peerID.displayName] )
    {
        NSLog(@"[%@] is already connected.", peerID.displayName);
        return;
    }
    
    NSTimeInterval linkDeadTime = 15;
    
    MCSession* session;
    if([_currentSession.connectedPeers count] == 8)
    {
        session = [self createNewSessionToNewPeer:peerID];
        _currentSession = session;
    }
    else
    {
        session = _currentSession;
    }
    
    [browser invitePeer:peerID toSession:session withContext:nil timeout:linkDeadTime];
    
    NSLog(@"Inviting PeerID:[%@] to session...", peerID.displayName);
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Lost connection to PeerID:[%@]", peerID.displayName);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"lostPeer" object:self];
    
    if([_userSessionsDisplayNamesToSessions objectForKey:peerID.displayName])
    {
        [_userSessionsDisplayNamesToSessions removeObjectForKey:peerID.displayName];
        [self resetBrowserService];
    }
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
    MCSession* session = [_userSessionsDisplayNamesToSessions objectForKey:peerID.displayName];
    
    if(session)
    {
        NSLog(@"Peer already in session; sending NO.");
        invitationHandler(NO, session);
        return;
    }
    else if ([session.connectedPeers count] == 8)
    {
        session = [self createNewSessionToNewPeer:peerID];
        _currentSession = session;
    }
    
    NSLog(@"...Auto accepting...");
    invitationHandler(YES, _currentSession);
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
    NSString* stringFromData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"~~~~~~~~~Received Data: [ %@ ]~~~~~~~~~", stringFromData);
    
    if([stringFromData isEqualToString:PULSE_STRING])
    {
        NSError* error;
        NSString* pulseBack = PULSE_BACK_STRING;
        
//        if(! [_userSessionsDisplayNamesToSessions objectForKey:peerID.displayName])
//        {
//            [_userSessionsDisplayNamesToSessions setObject:session forKey:peerID.displayName];
//        }
        
        [session sendData:[pulseBack dataUsingEncoding:NSUTF8StringEncoding] toPeers:@[peerID]
                    withMode:MCSessionSendDataReliable
                       error:&error];
    }
    else if([stringFromData isEqualToString:MANUAL_DISCONNECT_STRING])
    {
//        [session disconnect];
        [_userSessionsDisplayNamesToSessions removeObjectForKey:peerID.displayName];
    }
}


- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSString* stateString;
    switch (state) {
        case MCSessionStateNotConnected:
            stateString = kUserNotConnectedNotification;
            break;
        case MCSessionStateConnecting:
            stateString = kUserConnectingNotification;
            break;
        case MCSessionStateConnected:
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
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"Started receiving resource: %@", resourceName);
}


- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSLog(@"Finished receiving resource: %@", resourceName);
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Peer: [%@] is streaming", peerID.displayName);
}


@end
