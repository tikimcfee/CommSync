//
//  CSFrameworkSupportedConnectivityManager.m
//  CommSync
//
//  Created by CommSync on 2/2/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSFrameworkSupportedConnectivityManager.h"

@implementation CSFrameworkSupportedConnectivityManager


+ (CSFrameworkSupportedConnectivityManager*) sharedConnectivityManager {

    static CSFrameworkSupportedConnectivityManager* sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}


- (void)setupSession
{
    
    NSLog(@"[%@ -- Setting up a session]", kAPPLICATIONNETWORKNAME);
    
    // Create the session that peers will be invited/join into.
    [[JKPeerConnectivity sharedManager]setDelegate:self];
    
#warning This may be part of the key to multi-session and N connectivity
    
    [[JKPeerConnectivity sharedManager]startConnectingToPeersWithGroupID:@"1"];
    
}

#pragma mark JKPeerConnectivty Delegate Methods (New Networking 2.0 Framework)

- (void)peerHasJoined:(JKPeer*)newPeer {
    
    NSLog(@"[%@ -- We Are Now Connected To Peer %@", kAPPLICATIONNETWORKNAME, newPeer);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPeerChangedStateNotification object:self];
}

-(void)peerHasLeft:(JKPeer *)leavingPeer {
    NSLog(@"[%@ -- We Are No Longer Connected To Peer %@", kAPPLICATIONNETWORKNAME, leavingPeer);
    //[self removePeerFromPeerMap:leavingPeer.peerName];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPeerChangedStateNotification object:self];
    
}

#pragma mark JKPeerConnectivity Helper Methods

- (NSArray*) currentConnectedPeers {
    
    return [[[JKPeerConnectivity sharedManager]peerConnections] allObjects];
}

#pragma mark - Data passing

- (void) sendSingleTask:(CSTaskRealmModel*)task toPeer:(JKPeer*)peer {
    
    
}
//- (void) sendSingleTaskToAllPeers:(CSTaskRealmModel*)task;
//
//- (void) sendMultipleTasks:(NSArray*)tasks toPeer:(JKPeer*)peer;
//- (void) sendMultipleTasksToAllPeers:(NSArray *)tasks;
//
//- (void) sendTextualMessage:(NSString*)message toSinglePeer:(JKPeer*)peer;
//- (void) sendTextualMessageToAllPeers:(NSString*)message;


@end
