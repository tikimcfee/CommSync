//
//  CSSessionManager.h
//  CommSync
//
//  Created by Ivan Lugo on 10/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

#define COMMSYNC_SERVICE_ID @"comm-sync-2014"
#define PULSE_STRING @"|~PULSE~|"
#define PULSE_BACK_STRING @"|~PULSE-BACK~|"
#define MANUAL_DISCONNECT_STRING @"|~DISCONNECT~|"

@interface CSSessionManager : NSObject <MCNearbyServiceBrowserDelegate,
                                        MCNearbyServiceAdvertiserDelegate,
                                        MCSessionDelegate>

// MCMultiPeer objects
@property (strong, nonatomic) MCSession* currentSession;
@property (strong, nonatomic) NSMutableDictionary* userSessionsDisplayNamesToSessions;
@property (strong, nonatomic) MCPeerID* myPeerID;
@property (strong, nonatomic) NSString* userID;


@property (strong, nonatomic) MCNearbyServiceAdvertiser* serviceAdvertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser* serviceBrowser;

- (CSSessionManager*) initWithID:(NSString*)userID;
- (void)tearDownConnectivityFramework;
- (void)sendPulseToPeers;


@end