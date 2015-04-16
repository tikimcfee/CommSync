//
//  CSTaskResourceSendOperation.h
//  CommSync
//
//  Created by CommSync on 4/13/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSTaskRealmModel.h"

@interface CSTaskResourceSendOperation : NSOperation

@property (strong, nonatomic) CSTaskRealmModel* realmModelToSend;
@property (strong, nonatomic) MCPeerID* peerRecipient;
@property (strong, nonatomic) MCSession* peerSession;

@property (assign, nonatomic) BOOL taskSendComplete;

- (void) configureWithModel:(CSTaskRealmModel*)model
                  recipient:(MCPeerID*)peer
                  inSession:(MCSession*)session;

@end
