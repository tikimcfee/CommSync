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
    
    NSLog(@"Setting up a session");
    
    // Create the session that peers will be invited/join into.
    [[JKPeerConnectivity sharedManager]setDelegate:self];
    [[JKPeerConnectivity sharedManager]startConnectingToPeersWithGroupID:@"1"];
    
}


@end
