//
//  CSTaskRealmModel.m
//  CommSync
//
//  Created by Ivan Lugo on 1/27/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskRealmModel.h"

@implementation CSTaskRealmModel

#pragma mark - Realm modeling protocol

+ (NSDictionary *)defaultPropertyValues {
    
    NSDictionary* defaults = nil;
    
    NSMutableArray* tempArrayOfImages = [NSMutableArray arrayWithCapacity:0];
    
    defaults = @{@"taskDescription":@"",
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
    return @[@"TRANSIENT_audioDataURL"];
}

+ (NSString*)primaryKey {
    return @"concatenatedID";
}

#pragma mark - Add media to tasks 
- (void) addTaskMediaOfType:(CSTaskMediaType)type withData:(NSData*)data toRealm:(RLMRealm*)realm inTransation:(BOOL)transaction {

    if(transaction) {
        [realm beginWriteTransaction];
    }
    
    CSTaskMediaRealmModel* newMedia = [CSTaskMediaRealmModel new];
    newMedia.mediaType = type;
    newMedia.mediaData = data;
    
    [self.taskMedia addObject:newMedia];
    
    if(transaction) {
        [realm commitWriteTransaction];
    }
}


#pragma mark - Temporary resource on disk for task streaming
- (NSURL*) temporarilyPersistTaskDataToDisk:(NSData*)thisTasksData {
    
    // We don't need complex unique identifiers; we will clean up immediately when finished sending
    // This is time inefficient, but safe and manageable
    NSString* temporaryUniqueID = [[NSUUID UUID] UUIDString];
    
    // Generate the file name from the above AND this task's concat_id. Unique much?
    NSString *fileName = [NSString stringWithFormat:@"%@_%@",
                          temporaryUniqueID, self.concatenatedID];
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    
    NSError* error;
    [thisTasksData writeToURL:fileURL options:NSDataWritingAtomic error:&error];
    
    return fileURL;
}

#pragma mark - ASYNC callbacks
- (void) getAllImagesForTaskWithCompletionBlock:(void (^)(NSMutableArray*))completion {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray* taskImages = [NSMutableArray new];
        
        for(CSTaskMediaRealmModel* rev in self.taskMedia) {
            if (rev.mediaType == CSTaskMediaType_Photo) {
                [taskImages addObject: [UIImage imageWithData:rev.mediaData]];
            }
        }
        
        completion(taskImages);
    });
}

#pragma mark - Accessors and Helpers
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
        [taskDataStore addObject: t];
    }
    
    return taskDataStore;
}

- (NSData*) getTaskAudio {
    for (CSTaskMediaRealmModel* media in self.taskMedia) {
        if(media.mediaType == CSTaskMediaType_Audio) {
            return media.mediaData;
        }
    }
    
    return nil;
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
//        case CSTaskProperty_taskAudio:
//            return self.taskAudio;
//            break;
        case CSTaskProperty_taskDescription:
            return self.taskDescription;
            break;
//        case CSTaskProperty_taskImages_NSDataArray_JPEG:
//            return self.taskImages_NSDataArray_JPEG;
//            break;
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
