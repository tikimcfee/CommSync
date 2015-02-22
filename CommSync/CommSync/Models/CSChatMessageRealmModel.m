//
//  CSMessageRealmModel.m
//  CommSync
//
//  Created by Darin Doria on 2/16/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSChatMessageRealmModel.h"

@implementation CSChatMessageRealmModel

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.createdBy = [aDecoder decodeObjectForKey:@"createdBy"];
        self.text = [aDecoder decodeObjectForKey:@"text"];
        self.createdAt = [aDecoder decodeObjectForKey:@"createdAt"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.createdBy forKey:@"createdBy"];
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeObject:self.createdAt forKey:@"createdAt"];
}

@end
