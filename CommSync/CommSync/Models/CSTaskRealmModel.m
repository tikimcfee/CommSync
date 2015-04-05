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
    
    NSData* emptyAudio = [NSKeyedArchiver archivedDataWithRootObject:[NSNull null]];
    
    defaults = @{@"taskImages_NSDataArray_JPEG": archivedImages,
                 @"taskAudio":emptyAudio,
                 
                 @"taskDescription":@"",
                 @"taskTitle":@"",
                 @"taskPriority":[NSNumber numberWithInt:0],
                 
                 @"UUID":@"",
                 @"deviceID":@"",
                 @"concatenatedID":@"",
                 @"assignedID":@"",
                 @"tag":@"",
                 @"completed":@false
                 
                 };
    
    return defaults;
}

+ (NSArray*)ignoredProperties {
    return @[@"transientModel"];
}

+ (NSString*)primaryKey {
    return @"concatenatedID";
}

#pragma mark - Accessors and Helpers
- (CSTaskTransientObjectStore*)transientModel {
    if(_transientModel)
        return _transientModel;
    
    _transientModel = [[CSTaskTransientObjectStore alloc] initWithRealmModel:self];
    
    return _transientModel;
}

+ (NSMutableArray*)getTransientTaskList: (NSString*)user withTag: (NSString*)tag completionStatus:(BOOL)completed{
    RLMResults* allTasks;
    NSPredicate *pred;
    
    
    //if(!user)allTasks = [CSTaskRealmModel allObjects];
    
    if(user && tag) pred = [NSPredicate predicateWithFormat:@"assignedID = %@  AND tag = %@ AND completed = %d" , user, tag, completed];
    else if(user && !tag) pred = [NSPredicate predicateWithFormat:@"assignedID = %@", user];
    else if(!user && tag) pred = [NSPredicate predicateWithFormat:@"tag = %@ AND completed = %d", tag, completed];
    else pred = [NSPredicate predicateWithFormat:@"completed = %d", completed];
    
    
    allTasks = [CSTaskRealmModel objectsInRealm:[RLMRealm defaultRealm] withPredicate:pred];
   
    NSMutableArray* taskDataStore = [NSMutableArray arrayWithCapacity:allTasks.count];
    for(CSTaskRealmModel* t in allTasks) {
        [taskDataStore addObject: [[CSTaskTransientObjectStore alloc] initWithRealmModel:t]];
    }
    
    return taskDataStore;
}

- (void) addComment: (CSCommentRealmModel *) newComment{
   
    RLMRealm* realm = [RLMRealm defaultRealm];

    
    [realm beginWriteTransaction];
    [self.comments addObject :newComment];
    [realm commitWriteTransaction]; 
}

@end
