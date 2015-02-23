//
//  CSMessageRealmModel.m
//  CommSync
//
//  Created by Darin Doria on 2/16/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSChatMessageRealmModel.h"

@interface CSChatMessageRealmModel ()
@property (nonatomic, strong, readwrite) NSString *messageText;
@property (nonatomic, strong, readwrite) NSDate *createdAt;
@property (nonatomic, strong, readwrite) NSString *createdBy;
@end

@implementation CSChatMessageRealmModel

- (instancetype)initWithMessage:(NSString *)message byUser:(NSString *)username
{
    self = [super init];
    
    if (self)
    {
        self.createdBy = username;
        self.messageText = message;
        self.createdAt = [NSDate date];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.createdBy = [aDecoder decodeObjectForKey:@"createdBy"];
        self.messageText = [aDecoder decodeObjectForKey:@"text"];
        self.createdAt = [aDecoder decodeObjectForKey:@"createdAt"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.createdBy forKey:@"createdBy"];
    [aCoder encodeObject:self.messageText forKey:@"text"];
    [aCoder encodeObject:self.createdAt forKey:@"createdAt"];
}

- (NSString *)senderId
{
    return self.createdBy;
}

- (NSString *)senderDisplayName
{
    return self.createdBy;
}

- (NSDate *)date
{
    return self.createdAt;
}

- (BOOL)isMediaMessage
{
    return NO;
}

- (NSUInteger)hash
{
    return (int)[[NSProcessInfo processInfo] globallyUniqueString];
}

- (NSString *)text
{
    return self.messageText;
}




@end
