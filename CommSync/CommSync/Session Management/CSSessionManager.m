//
//  CSSessionManager.m
//  CommSync
//
//  Created by Ivan Lugo on 10/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSSessionManager.h"
#import "AppDelegate.h"

#define kUserNotConnectedNotification @"Not Connected"
#define kUserConnectedNotification @"Connected"
#define kUserConnectingNotification @"Is Connecting"


@implementation CSSessionManager

- (CSSessionManager*) initWithID:(NSString*)userID
{
    _myPeerID = [[MCPeerID alloc] initWithDisplayName:userID];
    
    _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:_myPeerID serviceType:COMMSYNC_SERVICE_ID];
    _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_myPeerID
                                                           discoveryInfo:nil
                                                             serviceType:COMMSYNC_SERVICE_ID];
    
    _serviceBrowser.delegate = self;
    _serviceAdvertiser.delegate = self;
    
    [_serviceBrowser startBrowsingForPeers];
    [_serviceAdvertiser startAdvertisingPeer];
    
    _currentSession = [[MCSession alloc] initWithPeer:_myPeerID];
    _currentSession.delegate = self;
    
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
    
    for(MCPeerID* peer in _currentSession.connectedPeers)
    {
        [_currentSession sendData:newPulse
                          toPeers:@[peer]
                         withMode:MCSessionSendDataReliable
                            error:&error];
    }
}

- (void) sendDataPacketToPeers:(NSData*)dataPacket
{
    NSError* error;
    
//    for(MCPeerID* peer in _currentSession.connectedPeers)
//    {
//        [_currentSession sendData:dataPacket
//                          toPeers:@[peer]
//                         withMode:MCSessionSendDataReliable
//                            error:&error];
//    }
    
    [_currentSession sendData:dataPacket
                      toPeers:_currentSession.connectedPeers
                     withMode:MCSessionSendDataReliable
                        error:&error];
}

# pragma mark - Session Helpers
- (MCSession*)addPeerToSession:(MCPeerID*)peerID
{
    MCSession* newSession = [[MCSession alloc] initWithPeer:_myPeerID];
    newSession.delegate = self;
    
    return newSession;
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
    
    for(MCPeerID* peer in _currentSession.connectedPeers)
    {
        if([peerID isEqual:peer])
        {
            NSLog(@"[%@] is already connected.", peerID.displayName);
            return;
        }
    }
    
    NSTimeInterval linkDeadTime = 15;
    
    MCSession* inviteSession = _currentSession;
    [browser invitePeer:peerID toSession:inviteSession withContext:nil timeout:linkDeadTime];
    
    NSLog(@"Inviting PeerID:[%@] to session...", peerID.displayName);
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Lost connection to PeerID:[%@]", peerID.displayName);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"lostPeer" object:self];
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
    
    for(MCPeerID* peer in _currentSession.connectedPeers)
    {
        if([peer isEqual:peerID])
        {
            NSLog(@"Peer already in session; sending NO.");
            invitationHandler(NO, _currentSession);
            return;
        }
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
        
        [session sendData:[pulseBack dataUsingEncoding:NSUTF8StringEncoding] toPeers:@[peerID]
                    withMode:MCSessionSendDataReliable
                       error:&error];
    }
    else
    {
        
        id task = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if([task isKindOfClass:[CSTask class]])
        {
            AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            [d.globalTaskManager insertTaskIntoList:task];
        }
//        CSTask* newTaskFromData = [[CSTask alloc]
//                                   initWithCoder:[NSKeyedUnarchiver
//                                                  unarchiveObjectWithData:data]]
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
