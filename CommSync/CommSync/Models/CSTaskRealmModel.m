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
    
    
    
    if(user && tag) pred = [NSPredicate predicateWithFormat:@"assignedID = %@  AND tag = %@ AND completed = %d" , user, tag, completed];
    else if(user && !tag)pred = [NSPredicate predicateWithFormat:@"assignedID = %@ AND completed = %d", user, completed ];
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

- (void) addRevision:(CSTaskRevisionRealmModel*)revision {
    RLMRealm* realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [self.revisions addObject :revision];
    [realm commitWriteTransaction];
}

+ (NSString*)stringForProperty:(CSTaskProperty)property {
    NSString* propertyString;
    switch(property) {
        case CSTaskProperty_assignedID:
            propertyString = @"assignedID";
            break;
        case CSTaskProperty_completed:
            propertyString = @"completed";
            break;
        case CSTaskProperty_concatenatedID:
            propertyString = @"concatenatedID";
            break;
        case CSTaskProperty_deviceID:
            propertyString = @"deviceID";
            break;
        case CSTaskProperty_tag:
            propertyString = @"tag";
            break;
        case CSTaskProperty_taskAudio:
            propertyString = @"taskAudio";
            break;
        case CSTaskProperty_taskDescription:
            propertyString = @"taskDescription";
            break;
        case CSTaskProperty_taskImages_NSDataArray_JPEG:
            propertyString = @"taskImages_NSDataArray_JPEG";
            break;
        case CSTaskProperty_taskPriority:
            propertyString = @"taskPriority";
            break;
        case CSTaskProperty_taskTitle:
            propertyString = @"taskTitle";
            break;
        case CSTaskProperty_UUID:
            propertyString = @"UUID";
            break;
        default:
            break;
    }
    
    return propertyString;
}

- (id)valueForProperty:(CSTaskProperty)property {
    switch(property) {
        case CSTaskProperty_assignedID:
            return self.assignedID;
            break;
        case CSTaskProperty_completed:
            return [NSNumber numberWithBool:self.completed];
            break;
        case CSTaskProperty_concatenatedID:
            return self.concatenatedID;
            break;
        case CSTaskProperty_deviceID:
            return self.deviceID;
            break;
        case CSTaskProperty_tag:
            return self.tag;
            break;
        case CSTaskProperty_taskAudio:
            return self.taskAudio;
            break;
        case CSTaskProperty_taskDescription:
            return self.taskDescription;
            break;
        case CSTaskProperty_taskImages_NSDataArray_JPEG:
            return self.taskImages_NSDataArray_JPEG;
            break;
        case CSTaskProperty_taskPriority:
            return [NSNumber numberWithInteger:self.taskPriority];
            break;
        case CSTaskProperty_taskTitle:
            return self.taskTitle;
            break;
        case CSTaskProperty_UUID:
            return self.UUID;
            break;
        default:
            return nil;
    }
}

@end
