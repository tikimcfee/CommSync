//
//  JKPeer.m
//  GeoStormEmbedded
//
//  Created by Judit Klein on 4/21/14.
//  Copyright (c) 2014 Judit Klein. All rights reserved.
//

#import "JKPeer.h"

@implementation JKPeer
@synthesize peerName,peerMajor,peerNetService,peerOSType;

- (instancetype)initWithNetService:(NSNetService*)netService Name:(NSString*)Name Major:(NSString*)Major osType:(NSString*)osType
{
    self = [super init];
    if (self) {
        
        self.peerNetService = netService;
        self.peerName = Name;
        self.peerMajor = Major;
        self.peerOSType = osType;
    }
    return self;
}


@end
