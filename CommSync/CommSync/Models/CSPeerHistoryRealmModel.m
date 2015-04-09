//
//  CSPeerHistoryRealmModel.m
//  CommSync
//
//  Created by Anna Stavropoulos on 3/4/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSPeerHistoryRealmModel.h"

@implementation CSPeerHistoryRealmModel

- (instancetype)initWithMessage:(NSData *)peerID
{
    self = [super init];
    
    if (self)  
    {
        self.peerID = peerID;
       // self.dispalyID = displayName;
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.peerID= [aDecoder decodeObjectForKey:@"peerID"];
       // self.dispalyID = [aDecoder decodeObjectForKey:@"displayName"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.peerID forKey:@"peerID"];
    //[aCoder encodeObject:self.dispalyID forKey:@"displayName"];
}


@end
