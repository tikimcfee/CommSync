//
//  CSCommentRealmModel.m
//  CommSync
//
//  Created by Anna Stavropoulos on 2/2/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSCommentRealmModel.h"

@implementation CSCommentRealmModel

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.UID = [aDecoder decodeObjectForKey:@"UID"];
        self.text = [aDecoder decodeObjectForKey:@"text"];
        self.time = [aDecoder decodeObjectForKey:@"time"];
        
       
        
        // TODO
        // Task media
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.UID forKey:@"UID"];
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeObject:self.time forKey:@"time"];
    
}
@end
