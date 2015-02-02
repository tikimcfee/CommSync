//
//  JKPeerConnectivity.m
//  GeoStormEmbedded
//
//  Created by Judit Klein on 4/19/14.
//  Copyright (c) 2014 Judit Klein. All rights reserved.
//

#import "JKPeerConnectivity.h"
static JKPeerConnectivity *sharedSession = nil;

@implementation JKPeerConnectivity

@synthesize delegate;
@synthesize peerConnections;
@synthesize peerIDToConnectionMap;
@synthesize peerToNetServiceMap;
+ (JKPeerConnectivity *) sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSession = [[self alloc] init];
    });
    return sharedSession;
}

- (id)init {
    if (self = [super init]) {
        [self startUp];
    }
    
    return self;
}


- (void)startUp {
    //Set up our own server & start it up
    [JKPeerConnectivitySetup sharedSetup];
    
    NSLog(@"Bringing Up My Local Connection");
    myConnection = [[JKLocalConnection alloc] init];
    
    //Set up the set for our connections that we will have
    NSLog(@"Setting Up A Collection For All My Peers I Find");
    peerConnections = [[NSMutableSet alloc]init];
    peerIDToConnectionMap = [[NSMutableDictionary alloc]init];
    peerToNetServiceMap = [[NSMutableDictionary alloc] init];
    //Start Browsing for peers
    NSLog(@"Starting Browsing For Peers");
    peerBrowser = [[PeerBrowser alloc]init];
    [peerBrowser setDelegate:self];
}

- (void) stopConnectionsAndResetState {
    //Reset our Group ID
    groupID = nil;
    
    //Stop looking for peers
    [peerBrowser stop];
    
    //Empty out our peerConnections
    
    for (JKRemoteConnection *connection in peerConnections) {
        [[connection connection] close];
    }
    
    //Close our own connection (so sad)
    NSLog(@"Bringing Down My Local Connection");
    [myConnection stop];
    myConnection = nil;
    myConnection = [[JKLocalConnection alloc] init];

    
    
    NSLog(@"Peer State Is Now Reset");
    peerConnections = nil;
    peerIDToConnectionMap = nil;
    peerToNetServiceMap = nil;
    
    peerConnections = [[NSMutableSet alloc]init];
    peerIDToConnectionMap = [[NSMutableDictionary alloc]init];
    peerToNetServiceMap = [[NSMutableDictionary alloc] init];
    
    NSLog(@"Maps are now reset, we are ready to go again");
}

- (void) startConnectingToPeersWithGroupID:(NSString*)partyName {
    groupID = partyName;
    
    //Set up our own server & start it up
    [myConnection start];
    
    //Start Browsing for peers
    [peerBrowser start];
}

- (void) stopEverything {

    [myConnection stop];
    [peerBrowser stop];
    
}


- (void)updatePeerList {
    NSLog(@"Told That The List Of Disocvered Peers Has changed, Currently reads %@",[peerBrowser servers]);

}

- (void)newPeerDiscovered:(NSNetService*)newPeer {
    NSDictionary *txtInfo = [NSNetService dictionaryFromTXTRecordData:[newPeer TXTRecordData]];
    
    NSLog(@"Told A New Peer Is Now Here!!! WELCOME!!!! %@ Your Discovery Info contained %@",newPeer,txtInfo);
    
    NSLog(@"This Peers Beacon is %@",[[NSString alloc] initWithData:[txtInfo objectForKey:@"DeviceBeacon"]
                                                           encoding:NSUTF8StringEncoding]);
    
    NSLog(@"This Peers DeviceID is %@",[[NSString alloc] initWithData:[txtInfo objectForKey:@"DeviceID"]
                                                             encoding:NSUTF8StringEncoding]);
    
    NSLog(@"It Is Running Operating System %@",[[NSString alloc] initWithData:[txtInfo objectForKey:@"DeviceType"]
                                                                     encoding:NSUTF8StringEncoding]);
    
#warning We also need to check if we even have room for this peer anymore
    
    //if statement on groupID for groupID - startConnectingToPeersWithGroupID
    //save remote user's device beacon
    
    if ( ![txtInfo objectForKey:@"DeviceType"] ) {
        NSLog(@"This device has no TXT data, they may be an Android for peer %@",newPeer);
        
        JKRemoteConnection *newRemoteConnection = [[JKRemoteConnection alloc]initWithNetService:newPeer];
        [newRemoteConnection setDelegate:self];
        [newRemoteConnection setDisplayName:@"We come in peace"];
        [peerConnections addObject:newRemoteConnection];
        
        JKPeer *newJKPeer = [[JKPeer alloc] initWithNetService:newPeer
                                                          Name:@"We come in peace"
                                                         Major:@"Default"
                                                        osType:@"Android"];
        
        
        [peerIDToConnectionMap setObject:newRemoteConnection forKey:newJKPeer.peerName];
        [peerToNetServiceMap setObject:newJKPeer forKey:newPeer.name];
        
        if ( [newRemoteConnection start] ) {
            [delegate peerHasJoined:newJKPeer];
        }
        
        return;

    }
    
    NSString *remotePeerDeviceBeacon = [[NSString alloc] initWithData:[txtInfo objectForKey:@"DeviceBeacon"]
                                                             encoding:NSUTF8StringEncoding];
    
    if ( [remotePeerDeviceBeacon isEqualToString:groupID] ) {
        NSLog(@"this peer is the same as us, invite them!");
        
        
        JKRemoteConnection *newRemoteConnection = [[JKRemoteConnection alloc]initWithNetService:newPeer];
        [newRemoteConnection setDelegate:self];
        [newRemoteConnection setDisplayName:[[NSString alloc] initWithData:[txtInfo objectForKey:@"DeviceID"] encoding:NSUTF8StringEncoding]];
        [peerConnections addObject:newRemoteConnection];
        
        JKPeer *newJKPeer = [[JKPeer alloc] initWithNetService:newPeer
                                                          Name:[[NSString alloc] initWithData:[txtInfo objectForKey:@"DeviceID"] encoding:NSUTF8StringEncoding]
                                                         Major:[[NSString alloc] initWithData:[txtInfo objectForKey:@"DeviceBeacon"] encoding:NSUTF8StringEncoding]
                                                        osType:[[NSString alloc] initWithData:[txtInfo objectForKey:@"DeviceType"] encoding:NSUTF8StringEncoding]];
        
        
        [peerIDToConnectionMap setObject:newRemoteConnection forKey:newJKPeer.peerName];
        [peerToNetServiceMap setObject:newJKPeer forKey:newPeer.name];
        
        if ( [newRemoteConnection start] ) {
            [delegate peerHasJoined:newJKPeer];
        }
        
    } else {
        NSLog(@"This peer is not the same as us, shun hem!");
    }
    
}
- (void) remoteConnectionHasClosed:(JKConnection*)oldConnection {
    
    NSArray *temp = [peerIDToConnectionMap allKeysForObject:oldConnection];
    NSString *key = [temp objectAtIndex:0];
    
    [peerIDToConnectionMap removeObjectForKey:key];
    [peerConnections removeObject:oldConnection];
    
}

- (void)peerIsGone:(NSNetService *)leavingPeer {
    
    //Did we have a connection to this one? if so, time to say goodbye
    JKRemoteConnection *connection = [peerIDToConnectionMap objectForKey:leavingPeer.name];
    
    if ( connection ) {
        //we had a connection to this, we can shut it down
        [connection stop];
        [peerConnections removeObject:connection];
        [peerIDToConnectionMap removeObjectForKey:leavingPeer.name];
    }
    
    JKPeer *lPeer = [peerToNetServiceMap objectForKey:leavingPeer.name];
    
    if (lPeer) {
        [delegate peerHasLeft:lPeer];
        [peerToNetServiceMap removeObjectForKey:leavingPeer.name];
    }
    
}

- (void)removePeerWithID:(NSString*)peerID
{
    JKRemoteConnection *connection = [peerIDToConnectionMap objectForKey:peerID];
    [peerConnections removeObject:connection];
    
    [peerIDToConnectionMap removeObjectForKey:peerID];
}


- (void) sendDataToAllPeers:(NSData *)dataToSend {
    
    NSLog(@"Peermap reads %@",peerConnections);
    NSLog(@"Peermap reads %@",peerIDToConnectionMap);

    
#if TESTING_ANDROID_CROSS_PLATFORM
    NSLog(@"Sending Data On My Local Connection Now...IN JSON!!!!");
    [myConnection broadcastPacketInJSON:dataToSend fromId:@"Device"];
    .
#else
    
    NSLog(@"Sending Data On My Local Connection Now");
    NSDictionary *messageDict = [NSDictionary dictionaryWithObject:dataToSend forKey:@"MessagePacket"];
    [myConnection broadcastPacket:messageDict fromId:@"Device"];
    
#endif
    
}

- (void) sendDataToOnePeer:(JKPeer *)peerToSendTo data:(NSData *)dataToSend {
    
    NSLog(@"Sending Data To One Peer Only");
    
    NSLog(@"Peermap reads %@",peerConnections);
    NSLog(@"Peermap reads %@",peerIDToConnectionMap);

    //Find our connection to that peer soley
    JKRemoteConnection *rConnection = [peerIDToConnectionMap objectForKey:peerToSendTo.peerName];
    
    if ( rConnection ) {
        NSLog(@"We Have A Connection To This One");
        NSDictionary *messageDict = [NSDictionary dictionaryWithObject:dataToSend forKey:@"MessagePacket"];
        [rConnection broadcastPacket:messageDict fromId:@"Device"];
    }
    
}


@end
