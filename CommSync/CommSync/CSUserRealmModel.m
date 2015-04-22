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

- (instancetype)initWithMessage:(NSData *)peerID withDisplayName:(NSString*) display withID:uniqueID lastChanged:(NSDate*)changeTime
{
    self = [super init];
    
    if (self)
    {
        self.peerID = peerID;
        self.displayName = display;
        self.unreadMessages = 0;
        self.unsentMessages = 0;
        self.avatar = -1;
        self.uniqueID = uniqueID;
        self.lastUpdated = changeTime;
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
        self.uniqueID = [aDecoder decodeObjectForKey:@"uniqueID"];
        self.lastUpdated = [aDecoder decodeObjectForKey:@"lastUpdated"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.displayName forKey:@"displayName"];
    [aCoder encodeObject:self.peerID forKey:@"peerID"];
    [aCoder encodeInteger:self.unreadMessages forKey:@"unreadMessages"];
    [aCoder encodeInteger:self.avatar forKey:@"Avatar"];
    [aCoder encodeObject:self.uniqueID forKey:@"uniqueID"];
    [aCoder encodeObject:self.lastUpdated forKey:@"lastUpdated"];
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

-(int)getMessageNumber
{
    return (int)self.unreadMessages;
}

+ (NSString*)primaryKey {
    return @"uniqueID";
}

-(NSString *) getPicture
{
    if(!self.avatar) return @"Avatar -1";

    return [NSString stringWithFormat:@"Avatar %ld", (long)self.avatar];
}

- (void) updateChangeTime
{
    self.lastUpdated = [NSDate date];
}
@end
