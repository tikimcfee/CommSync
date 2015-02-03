//
//  CSTaskRealmModel.m
//  CommSync
//
//  Created by Ivan Lugo on 1/27/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskRealmModel.h"

@implementation CSTaskRealmModel

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
