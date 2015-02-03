//
//  JKPeerConnectivityDelegate.h
//  GeoStormEmbedded
//
//  Created by Judit Klein on 4/20/14.
//  Copyright (c) 2014 Judit Klein. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JKPeer.h"
@protocol JKPeerConnectivityDelegate

- (void)peerHasJoined:(JKPeer*)newPeer;
- (void)peerHasLeft:(JKPeer*)leavingPeer;

@end
