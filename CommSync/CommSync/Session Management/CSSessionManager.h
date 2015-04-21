//
//  CSSessionManager.h
//  CommSync
//
//  Created by Ivan Lugo on 10/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "CSTaskResourceSendOperation.h"

// Session management strings
#define COMMSYNC_SERVICE_ID @"comm-sync-2014"
#define PULSE_STRING @"|~PULSE~|"
#define PULSE_BACK_STRING @"|~PULSE-BACK~|"
#define MANUAL_DISCONNECT_STRING @"|~DISCONNECT~|"

// Notification names
#define kCSTaskObservationID @"kCSTaskObservationID"
#define kCSDidStartReceivingResourceWithName @"kCSDidStartReceivingResourceWithName"
#define kCSDidFinishReceivingResourceWithName @"kCSDidFinishReceivingResourceWithName"
#define kCSReceivingProgressNotification @"kCSReceivingProgressNotification"

@class CSTaskRealmModel, RLMRealm, CSUserRealmModel;

@protocol MCSessionDataHandlingDelegate <NSObject>

@required
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress;

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error;

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID;

@end

@interface CSSessionManager : NSObject <MCNearbyServiceBrowserDelegate,
                                        MCNearbyServiceAdvertiserDelegate,
                                        MCSessionDelegate>

// MCMultiPeer objects
@property (strong, nonatomic) MCPeerID*         myPeerID;
@property (strong, nonatomic) NSString*         myUniqueID;
@property (strong, nonatomic) NSString*         myDisplayName;
@property (strong, nonatomic) CSUserRealmModel* myUserModel;

@property (strong, nonatomic) MCNearbyServiceAdvertiser* serviceAdvertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser* serviceBrowser;
@property (strong, nonatomic) NSMutableDictionary* currentConnectedPeers;
@property (strong, nonatomic) NSMutableDictionary* unreadMessages;

// Data queue
@property (strong, nonatomic) NSOperationQueue* mainTaskSendQueue;


// 1-1 session objects
@property (strong, nonatomic) NSMutableDictionary* sessionLookupDisplayNamesToSessions;

// Delegate objects for handling callbacks
@property (strong, nonatomic) id <MCSessionDataHandlingDelegate> dataHandlingDelegate;

// Lifecycle and connection testing
- (CSSessionManager*) initWithID:(NSString*)userID withDisplay:(NSString*) userName;

// Task transmission
- (void) sendNewTaskToPeers:(CSTaskRealmModel*)newTask;
- (void) sendSingleTask:(CSTaskRealmModel*)task toSinglePeer:(MCPeerID*)peer;

- (void) sendDataPacketToPeers: (NSData*)dataPacket;
- (void) sendSingleDataPacket:  (NSData*)dataPacket toSinglePeer:(MCPeerID*)peer;

// Repair methods
- (void) nukeSession;
- (void) resetBrowserAndAdvertiser;
- (void) nukeRealm;
- (void) nukeHistory;
- (void) nukeChatHistory;

- (void)createUserModel;
- (void)updateAvatar:       (NSInteger)            number;

+ (NSString *)incomingTaskRealmDirectory;
+ (NSString *)peerHistoryRealmDirectory;
+ (NSString *)privateMessageRealmDirectory;
+ (NSString *)chatMessageRealmDirectory;
@property (strong, nonatomic) RLMRealm *peerHistoryRealm;
@property (strong, nonatomic) RLMRealm *chatMessageRealm;
@property (strong, nonatomic) RLMRealm *privateMessageRealm;

@property (strong, nonatomic) dispatch_queue_t taskRealmQueue;
@property (strong, nonatomic) dispatch_queue_t privateMessageQueue;
@property (strong, nonatomic) dispatch_queue_t chatMessageQueue;
@property (strong, nonatomic) dispatch_queue_t peerHistoryQueue;

@property (strong, nonatomic) NSMutableDictionary* allTags;

-(void) addTag:(NSString*) tag;
-(void) addMessage:(NSString*) peer;
-(void) removeMessage:(NSString*) peer;
@end