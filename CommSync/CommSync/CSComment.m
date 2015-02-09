//
//  CSComment.m
//  CommSync
//
//  Created by Student on 2/3/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSComment.h"

@implementation CSComment
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.UID = [aDecoder decodeObjectForKey:@"UID"];
        self.text = [aDecoder decodeObjectForKey:@"text"];
        self.time = [aDecoder decodeIntForKey:@"time"];
        
        
        
        // TODO
        // Task media
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.UID forKey:@"UID"];
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeInteger:self.time forKey:@"time"];
    
}
@end
