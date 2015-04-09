//
//  CSUserRealmModel.m
//  CommSync
//
//  Created by Anna Stavropoulos on 3/4/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSUserRealmModel.h"
@interface CSUserRealmModel()


@end
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
    self.unreadMessages = self.unreadMessages + 1;
}

-(void)removeMessages
{
   // self.stringNum = @"0";
    self.unreadMessages = 0;
}

-(NSString*)getMessageNumber
{
   // if(!_stringNum) _stringNum = @"0";
    return [NSString stringWithFormat:@"( %d unread)", self.unreadMessages];
}

@end
