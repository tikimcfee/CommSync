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

@protocol MCSessionDataHandlingDelegate <NSObject>

@required
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress;

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error;

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID;

@end

@class CSTaskTransientObjectStore;

@interface CSSessionManager : NSObject <MCNearbyServiceBrowserDelegate,
                                        MCNearbyServiceAdvertiserDelegate,
                                        MCSessionDelegate>

// MCMultiPeer objects
@property (strong, nonatomic) MCPeerID* myPeerID;
@property (strong, nonatomic) MCNearbyServiceAdvertiser* serviceAdvertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser* serviceBrowser;
@property (strong, nonatomic) NSMutableDictionary* currentConnectedPeers;
@property (strong, nonatomic) NSMutableDictionary* peerHistory;

// 1-1 session objects
@property (strong, nonatomic) NSMutableDictionary* sessionLookupDisplayNamesToSessions;

// Delegate objects for handling callbacks
@property (strong, nonatomic) id <MCSessionDataHandlingDelegate> dataHandlingDelegate;

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
- (void) resetBrowserAndAdvertiser;
- (void) nukeRealm;
- (void) nukeHistory;

- (void)updatePeerHistory:(MCPeerID *)peerID;

+ (NSString *)peerHistoryRealmDirectory;

@end