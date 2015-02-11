//
//  CSTaskRealmModel.m
//  CommSync
//
//  Created by Ivan Lugo on 1/27/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskRealmModel.h"
#import "CSTaskTransientObjectStore.h"


@implementation CSTaskRealmModel

#pragma mark - Realm modeling protocol

+ (NSDictionary *)defaultPropertyValues {
    
    NSDictionary* defaults = nil;
    
    NSMutableArray* tempArrayOfImages = [NSMutableArray arrayWithCapacity:0];
    NSData* archivedImages = [NSKeyedArchiver archivedDataWithRootObject:tempArrayOfImages];
    
    NSData* emptyAudio = [@"NO_AUDIO" dataUsingEncoding:NSUTF8StringEncoding];
    
    defaults = @{@"taskImages_NSDataArray_JPEG": archivedImages,
                 @"taskAudio":emptyAudio,
                 
                 @"taskDescription":@"",
                 @"taskTitle":@"",
                 @"taskPriority":[NSNumber numberWithInt:0],
                 
                 @"UUID":@"",
                 @"deviceID":@"",
                 @"concatenatedID":@""};
    
    return defaults;
}

#pragma mark - Accessors and Helpers

- (void) addComment: (CSCommentRealmModel *) newComment{
   
    RLMRealm* realm = [RLMRealm defaultRealm];

    
    [realm beginWriteTransaction];
    [self.comments addObject :newComment];
    [realm commitWriteTransaction]; 
}

+ (NSString*)primaryKey {
    return @"concatenatedID";
}

@end
