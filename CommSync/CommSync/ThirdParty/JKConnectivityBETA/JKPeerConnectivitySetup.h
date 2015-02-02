//
//  JKPeerConnectivitySetup.h
//  HeartChat
//
//  Created by Judit Klein on 2/09/14.
//  Copyright (c) 2014 juditk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JKPeerConnectivitySetup : NSObject
{
    NSString *deviceNameIdentifier;
    NSString *groupIdentifier;
    NSString *myUniqueID;
    NSUserDefaults *defaults;
}

@property (nonatomic, strong) NSString *deviceNameIdentifier;
@property (nonatomic, strong) NSString *groupIdentifier;
@property (nonatomic, strong) NSString *myUniqueID;

+ (JKPeerConnectivitySetup *) sharedSetup;

@end
