//
//  CSSessionDataAnalyzer.h
//  CommSync
//
//  Created by CommSync on 2/18/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSessionManager.h"
#import "CSUserRealmModel.h"
#import "CSChatMessageRealmModel.h"

#define kCSNewTaskResourceInformationContainer @"resourceInformationContainer"

@class RLMRealm;
@interface CSSessionDataAnalyzer : NSObject <MCSessionDataHandlingDelegate>

// Task queue for new tasks that are waiting for database writes
@property (strong, nonatomic) NSMutableDictionary* requestPool;
@property (strong, nonatomic, readonly) NSOperationQueue* dataAnalysisQueue;
@property (strong, nonatomic) CSSessionManager* globalManager;

+ (CSSessionDataAnalyzer*) sharedInstance:(CSSessionManager*)manager;

- (void) analyzeReceivedData:(NSData*)receivedData fromPeer:(MCPeerID*)peer;
- (void) sendMessageToAllPeersForNewTask:(CSTaskRealmModel*)task;

- (CSTaskRealmModel*) getModelFromQueueOrDatabaseWithID:(NSString*)taskID;
- (NSDictionary *) buildTaskRequestFromTaskID:(NSString*)taskID;
- (NSDictionary *) buildNewTaskNotificationFromTaskID:(NSString*)taskID;

@end

@interface CSDataAnalysisOperation : NSOperation

@property (strong, nonatomic) NSData* dataToAnalyze;
@property (strong, nonatomic) MCPeerID* peer;
@property (strong, nonatomic) NSMutableDictionary* requestPool;
@property (strong, nonatomic) NSMutableDictionary* messagePool;

@property (weak, nonatomic) CSSessionDataAnalyzer* parentAnalyzer;

-(void) removeMessageRequest:(NSString*) message;

@end

@interface CSNewTaskResourceInformationContainer : NSObject

@property (strong, nonatomic) NSString* resourceName;
@property (strong, nonatomic) NSString* peerDisplayName;
@property (strong, nonatomic) NSString* taskObservationString;

@end
