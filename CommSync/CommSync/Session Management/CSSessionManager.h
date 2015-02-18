//
//  CSSessionManager.h
//  CommSync
//
//  Created by Ivan Lugo on 10/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

// Session management strings
#define COMMSYNC_SERVICE_ID @"comm-sync-2014"
#define PULSE_STRING @"|~PULSE~|"
#define PULSE_BACK_STRING @"|~PULSE-BACK~|"
#define MANUAL_DISCONNECT_STRING @"|~DISCONNECT~|"

// Notification names
#define kCSDidStartReceivingResourceWithName @"kCSDidStartReceivingResourceWithName"
#define kCSDidFinishReceivingResourceWithName @"kCSDidFinishReceivingResourceWithName"
#define kCSReceivingProgressNotification @"kCSReceivingProgressNotification"

@class CSTaskTransientObjectStore;

@interface CSSessionManager : NSObject <MCNearbyServiceBrowserDelegate,
                                        MCNearbyServiceAdvertiserDelegate,
                                        MCSessionDelegate>

// MCMultiPeer objects
@property (strong, nonatomic) MCPeerID* myPeerID;

@property (strong, nonatomic) MCNearbyServiceAdvertiser* serviceAdvertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser* serviceBrowser;

// 1-1 session objects
@property (strong, nonatomic) NSMutableDictionary* sessionLookupDisplayNamesToSessions;


// Lifecycle and connection testing
- (CSSessionManager*) initWithID:(NSString*)userID;
- (void) sendPulseToPeers;

// Task transmission
- (void) sendNewTaskToPeers:(CSTaskTransientObjectStore*)newTask;
- (void) sendSingleTask:(CSTaskTransientObjectStore*)task toSinglePeer:(MCPeerID*)peer;

- (void) sendDataPacketToPeers:(NSData*)dataPacket;
- (void) sendSingleDataPacket:(NSData*)dataPacket toSinglePeer:(MCPeerID*)peer;

// Repair methods
- (void) nukeSession;
- (void) nukeRealm;


@end