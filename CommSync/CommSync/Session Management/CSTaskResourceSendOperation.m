//
//  CSTaskResourceSendOperation.m
//  CommSync
//
//  Created by CommSync on 4/13/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskResourceSendOperation.h"

@implementation CSTaskResourceSendOperation

- (void) main {
    
    NSData* newTaskDataBlob = [NSKeyedArchiver archivedDataWithRootObject:_realmModelToSend];
    
    NSLog(@"Total size going out: %.2fkB (%tu Bytes)", newTaskDataBlob.length / 1024.0, newTaskDataBlob.length);
    
    NSURL* URLOfNewTask = [_realmModelToSend temporarilyPersistTaskDataToDisk:newTaskDataBlob];
    
    [_peerSession sendResourceAtURL:URLOfNewTask
                              withName:_realmModelToSend.concatenatedID
                                toPeer:_peerRecipient
                 withCompletionHandler:
     ^(NSError *error) {
         if(error) {
             NSLog(@"Task sending FAILED with error: %@ to peer: %@", error, _peerRecipient.displayName);
             _taskSendComplete = YES;
         }
         else {
             NSLog(@"Task sending COMPLETE with name to peer: %@", _peerRecipient.displayName);
             _taskSendComplete = YES;
         }
     }];

    while(!_taskSendComplete) {
        [NSThread sleepForTimeInterval:0.5];
    }
}

- (void) configureWithModel:(CSTaskRealmModel*)model recipient:(MCPeerID*)peer inSession:(MCSession*)session {
    _realmModelToSend = model;
    _peerRecipient = peer;
    _peerSession = session;
}

@end
