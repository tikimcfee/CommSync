//
//  CSSessionManager.m
//  CommSync
//
//  Created by Ivan Lugo on 10/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSSessionManager.h"

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
    
    NSArray* allSessions = [_userSessionsDisplayNamesToSessions allValues];
    for(MCSession* session in allSessions)
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

# pragma Session Helpers
- (MCSession*)createNewSessionToNewPeer:(MCPeerID*)peerID
{
    MCSession* newSession = [[MCSession alloc] initWithPeer:peerID];
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

# pragma MCBrowser Delegate
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
//    NSArray* allSessions = [_userSessionsDisplayNamesToSessions allValues];
//    for(MCSession* session in allSessions)
//    {
//        for(MCPeerID* connectedUser in [session connectedPeers])
//        {
//            if([connectedUser.displayName isEqualToString:peerID.displayName])
//            {
//                NSLog(@"[%@] is already connected.", peerID.displayName);
//            }
//        }
//    }
    if([_userSessionsDisplayNamesToSessions objectForKey:peerID.displayName])
    {
        NSLog(@"[%@] is already connected.", peerID.displayName);
        return;
    }
    
    NSTimeInterval linkDeadTime = 15;
    
    [browser invitePeer:peerID toSession:[self createNewSessionToNewPeer:_myPeerID] withContext:nil timeout:linkDeadTime];
    
    NSLog(@"Inviting PeerID:[%@] to session...", peerID.displayName);
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Lost connection to PeerID:[%@]", peerID.displayName);
    if([_userSessionsDisplayNamesToSessions objectForKey:peerID.displayName])
    {
        NSLog(@"--- Rebuilding services...");
        MCSession* killSession = (MCSession*)[_userSessionsDisplayNamesToSessions objectForKey:peerID.displayName];
        [killSession disconnect];
        [_userSessionsDisplayNamesToSessions removeObjectForKey:peerID.displayName];
        killSession = nil;
        
        [self resetPeerID];
        [self resetBrowserService];
        [self resetAdvertiserService];
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"Start browsing failed :: %@", error);
}

# pragma MCAdvertiser Delegate
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void (^)(BOOL accept,
                             MCSession *session))invitationHandler
{
    NSLog(@"PeerID:[%@] sent an invitation.", peerID.displayName);
    MCSession* session = [_userSessionsDisplayNamesToSessions objectForKey:peerID.displayName];
    
    if(session)
    {
        NSLog(@"Peer already in session; sending NO.");
        invitationHandler(NO, session);
        return;
    }
    
    NSLog(@"...Auto accepting...");
    invitationHandler(YES, [self createNewSessionToNewPeer:_myPeerID]);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"Start advertising failed :: %@", error);
}


# pragma MCSession Delegate
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
        if(! [_userSessionsDisplayNamesToSessions objectForKey:peerID.displayName])
        {
            [_userSessionsDisplayNamesToSessions setObject:session forKey:peerID.displayName];
        }
        [session sendData:[pulseBack dataUsingEncoding:NSUTF8StringEncoding] toPeers:@[peerID]
                    withMode:MCSessionSendDataReliable
                       error:&error];
    }
    else if([stringFromData isEqualToString:MANUAL_DISCONNECT_STRING])
    {
        [session disconnect];
        [_userSessionsDisplayNamesToSessions removeObjectForKey:peerID.displayName];
    }
}


- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSString* stateString;
    switch (state) {
        case 0:
            stateString = @"Not connected";
            break;
        case 1:
            stateString = @"Connecting";
            break;
        case 2:
            stateString = @"Connected";
            break;
        default:
            break;
    }
    
    NSLog(@"vvvvvvvvvvvvvvvvvvvvv");
    NSLog(@"Session peers: %@", session.connectedPeers);
    
    NSLog(@"Peer: [%@] --> New State: [%@]", peerID.displayName, stateString);
    NSLog(@"^^^^^^^^^^^^^^^^^^^^^");
    
    if(state == 0)
    {
        if([_userSessionsDisplayNamesToSessions objectForKey:peerID.displayName])
        {
            MCSession* my = [_userSessionsDisplayNamesToSessions objectForKey:peerID.displayName];
            [my disconnect];
            [_userSessionsDisplayNamesToSessions removeObjectForKey:peerID.displayName];
        }
        
        [session disconnect];
    }
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
