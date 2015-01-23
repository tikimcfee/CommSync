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

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.UUID = [aDecoder decodeObjectForKey:@"UUID"];
        self.deviceID = [aDecoder decodeObjectForKey:@"deviceID"];
        self.concatenatedID = [aDecoder decodeObjectForKey:@"concatenatedID"];

        self.taskTitle = [aDecoder decodeObjectForKey:@"taskTitle"];
        self.taskDescription = [aDecoder decodeObjectForKey:@"taskDescripion"];
        self.taskPriority = [aDecoder decodeIntForKey:@"taskPriority"];
        
        // TODO
        // Task media
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.UUID forKey:@"UUID"];
    [aCoder encodeObject:self.deviceID forKey:@"deviceID"];
    [aCoder encodeObject:self.concatenatedID forKey:@"concatenatedID"];
    
    [aCoder encodeObject:self.taskTitle forKey:@"taskTitle"];
    [aCoder encodeObject:self.taskDescription forKey:@"taskDescripion"];
    [aCoder encodeInteger:self.taskPriority forKey:@"taskPriority"];
}

@end
