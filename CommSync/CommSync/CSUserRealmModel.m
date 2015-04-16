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
        self.unsentMessages = 0;
        self.avatar = -1;
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
        self.avatar = [aDecoder decodeIntegerForKey:@"Avatar"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.displayName forKey:@"displayName"];
    [aCoder encodeObject:self.peerID forKey:@"peerID"];
    [aCoder encodeInteger:self.unreadMessages forKey:@"unreadMessages"];
    [aCoder encodeInteger:self.avatar forKey:@"Avatar"];
}

-(void)addMessage
{
    self.unreadMessages = self.unreadMessages + 1;
}

-(void)removeMessages
{
    self.unreadMessages = 0;
}


-(void)addUnsent
{
    self.unsentMessages = self.unsentMessages + 1;
}

-(void)removeUnsent
{
    self.unsentMessages = 0;
}

-(NSString*)getMessageNumber
{
    return [NSString stringWithFormat:@"( %d unread)", self.unreadMessages];
}

+ (NSString*)primaryKey {
    return @"displayName";
}

-(NSString *) getPicture
{
    if(!self.avatar) return @"Avatar-1";
    return [NSString stringWithFormat:@"Avatar%d", self.avatar];
}

@end
