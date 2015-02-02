//
//  CSFrameworkSupportedConnectivityManager.h
//  CommSync
//
//  Created by CommSync on 2/2/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>

// General connectivitiy
#import "JKPeerConnectivity.h"
#import "CSConnectivityConstants.h"
#import "CSFrameworkSupportedDataServer.h"

// Data Framework and Implemented Models
#import <Realm/Realm.h>
#import "CSTaskRealmModel.h"

@interface CSFrameworkSupportedConnectivityManager : NSObject <JKPeerConnectivityDelegate>

#pragma mark - Instantiation and other setup
+ (CSFrameworkSupportedConnectivityManager*) sharedConnectivityManager;

#pragma mark - Helper methods
- (NSArray*) currentConnectedPeers;

#pragma mark - Data passing
- (void) sendSingleTask:(CSTaskRealmModel*)task toPeer:(JKPeer*)peer;
- (void) sendSingleTaskToAllPeers:(CSTaskRealmModel*)task;

- (void) sendMultipleTasks:(NSArray*)tasks toPeer:(JKPeer*)peer;
- (void) sendMultipleTasksToAllPeers:(NSArray *)tasks;

- (void) sendTextualMessage:(NSString*)message toSinglePeer:(JKPeer*)peer;
- (void) sendTextualMessageToAllPeers:(NSString*)message;


@end
