//
//  CSUserRealmModel.m
//  CommSync
//
//  Created by Anna Stavropoulos on 3/4/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSUserRealmModel.h"

@implementation CSUserRealmModel

- (instancetype)initWithMessage:(NSData *)peerID withDisplayName:(NSString*) display
{
    self = [super init];
    
    if (self)  
    {
        self.peerID = peerID;
        self.displayName = display;
        self.unreadMessages = 0;
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.peerID= [aDecoder decodeObjectForKey:@"peerID"];
        self.displayName= [aDecoder decodeObjectForKey:@"displayName"];
        self.unreadMessages = [aDecoder decodeIntForKey:@"unreadMessages"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.displayName forKey:@"displayName"];
    [aCoder encodeObject:self.peerID forKey:@"peerID"];
    [aCoder encodeInt:self.unreadMessages forKey:@"unreadMessages"];
}

-(void)addMessage
{
    self.unreadMessages++;
}

-(void)removeMessages
{
    self.unreadMessages = 0;
}

-(NSString*)getMessageNumber
{
    return [NSString stringWithFormat:@"%d",_unreadMessages];
}

@end
