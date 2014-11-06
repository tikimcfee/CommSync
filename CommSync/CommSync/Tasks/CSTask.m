//
//  CSTask.m
//  CommSync
//
//  Created by Ivan Lugo on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSTask.h"

@implementation CSTask

- (CSTask*) initWithUUID:(NSString*)UUID andDeviceID:(NSString*)deviceID
{
    self = [super init];
    if(self)
    {
        _UUID = UUID;
        _deviceID = deviceID;
        _concatenatedID = [NSString stringWithFormat:@"%@%@", UUID, deviceID];
    }
    
    return self;
}

@end
