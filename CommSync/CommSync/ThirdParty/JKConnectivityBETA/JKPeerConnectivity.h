//
//  JKPeerConnectivity.h
//  GeoStormEmbedded
//
//  Created by Judit Klein on 4/19/14.
//  Copyright (c) 2014 Judit Klein. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JKLocalConnection.h"
#import "JKRemoteConnection.h"

#import "PeerBrowser.h"
#import "PeerDiscoveryDelegate.h"

#import "JKPeerConnectivityDelegate.h"
#import "JKPeer.h"

@interface JKPeerConnectivity : NSObject <PeerDiscoveryDelegate,JKConnectionDelegate>
{
    //I Myself will only have one "local" connection which I will use to braodcast to all clients
    JKLocalConnection *myConnection;
    
    //I will have multiple "Peer Connections" which I will recive incomming packets from
    NSMutableSet *peerConnections;
    
    //Peer ID to Connection Map, I have a connection to each peer, if I only want to send on that connection I can
    NSMutableDictionary *peerIDToConnectionMap;

    //JKPeer to NetService Map
    NSMutableDictionary *peerToNetServiceMap;
    
    //This will search for other Peers
    PeerBrowser *peerBrowser;
    
    id<JKPeerConnectivityDelegate> delegate;
    
    //This is the current group stable identifier that we will only connect to
    //clients which have this, aka the Major of the beacon
    NSString *groupID;
}

@property(nonatomic,retain) id<JKPeerConnectivityDelegate> delegate;
@property(nonatomic,retain) NSMutableSet* peerConnections;
@property(nonatomic,retain) NSMutableDictionary *peerIDToConnectionMap;
@property(nonatomic,retain) NSMutableDictionary *peerToNetServiceMap;


+ (JKPeerConnectivity *) sharedManager;

- (void) startConnectingToPeersWithGroupID:(NSString*)partyName;
- (void) stopConnectionsAndResetState;
- (void) stopEverything;


- (void) sendDataToOnePeer:(JKPeer *)peerToSendTo data:(NSData *)dataToSend;
- (void) sendDataToAllPeers:(NSData *)dataToSend;

- (void)removePeerWithID:(NSString*)peerID;

@end
