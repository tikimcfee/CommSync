//
//  CSTaskTransientObjectStore.m
//  CommSync
//
//  Created by CommSync on 2/11/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskTransientObjectStore.h"

#define kUUID @"kUUID"
#define kDeviceID @"kDeviceID"
#define kConcatenatedID @"kConcatenatedID"
#define kTaskTitle @"kTaskTitle"
#define kTaskPriority @"kTaskPriority"
#define kTaskDescription @"kTaskDescription"
#define kTaskImages @"kTaskImages"
#define kTaskAudio @"taskAudio"

@implementation CSTaskTransientObjectStore

#pragma mark - Lifecycle
- (id)initWithRealmModel:(CSTaskRealmModel*)model {
    
    if(self = [super init]) {
        self.UUID = model.UUID;
        self.deviceID = model.deviceID;
        self.concatenatedID = model.concatenatedID;
        
        self.taskTitle = model.taskTitle;
        self.taskDescription = model.taskDescription;
        self.taskPriority = model.taskPriority;
        
        self.taskAudio = model.taskAudio;
        self.taskImages_NSDataArray_JPEG = model.taskImages_NSDataArray_JPEG;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.UUID = [aDecoder decodeObjectForKey:kUUID];
        self.deviceID = [aDecoder decodeObjectForKey:kDeviceID];
        self.concatenatedID = [aDecoder decodeObjectForKey:kConcatenatedID];
        
        self.taskTitle = [aDecoder decodeObjectForKey:kTaskTitle];
        self.taskDescription = [aDecoder decodeObjectForKey:kTaskDescription];
        self.taskPriority = [aDecoder decodeIntForKey:kTaskPriority];
        
        // see if the decoder gives us an image array
        id imageMutableArray_DATA = [aDecoder decodeObjectForKey:kTaskImages];
        if (imageMutableArray_DATA) {
            self.taskImages_NSDataArray_JPEG = imageMutableArray_DATA;
        } else {
            NSMutableArray* tempArrayOfImages = [NSMutableArray new];
            NSData* archivedImages = [NSKeyedArchiver archivedDataWithRootObject:tempArrayOfImages];
            self.taskImages_NSDataArray_JPEG = archivedImages;
        }
        id taskAudio_DATA = [aDecoder decodeObjectForKey:kTaskAudio];
        if(taskAudio_DATA) {
            self.taskAudio = taskAudio_DATA;
        } else {
            NSData* empty = [NSData data];
            self.taskAudio = empty;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.UUID forKey:kUUID];
    [aCoder encodeObject:self.deviceID forKey:kDeviceID];
    [aCoder encodeObject:self.concatenatedID forKey:kConcatenatedID];
    
    [aCoder encodeObject:self.taskTitle forKey:kTaskTitle];
    [aCoder encodeObject:self.taskDescription forKey:kTaskDescription];
    [aCoder encodeInteger:self.taskPriority forKey:kTaskPriority];

    [aCoder encodeObject:self.taskImages_NSDataArray_JPEG forKey:kTaskImages];
    [aCoder encodeObject:self.taskAudio forKey:kTaskAudio];
}


#pragma mark - Persistence indirection layer
- (void)setAndPersistPropertiesOfNewTaskObject:(CSTaskRealmModel*)model
                                       inRealm:(RLMRealm*)realm
                               withTransaction:(BOOL)transcation
{
    if(transcation)
        [realm beginWriteTransaction];
    
    model.UUID = self.UUID;
    model.deviceID = self.deviceID;
    model.concatenatedID = self.concatenatedID;
    
    model.taskTitle = self.taskTitle ? self.taskTitle : @"NO TITLE";
    model.taskDescription = self.taskDescription ? self.taskDescription : @"NO DESCRIPTION";
    model.taskPriority = self.taskPriority;
    
    // Compute task images on the fly
    NSMutableArray* tempArrayOfImages = [NSMutableArray arrayWithCapacity:self.TRANSIENT_taskImages.count];
    for(UIImage* image in self.TRANSIENT_taskImages) { // for every TRANSIENT UIImage we have on this task
        
        NSLog(@"New size after normalization only is %ld", (unsigned long)[[NSKeyedArchiver archivedDataWithRootObject:image] length]);
        NSData* thisImage = UIImageJPEGRepresentation(image, 0.0); // make a new JPEG data object with some compressed size
        NSLog(@"New size after JPEG compression is %ld", (unsigned long)[[NSKeyedArchiver archivedDataWithRootObject:thisImage] length]);
        
        [tempArrayOfImages addObject:thisImage]; // add it to our container
    }
    
    NSData* archivedImages = [NSKeyedArchiver archivedDataWithRootObject:tempArrayOfImages];
    model.taskImages_NSDataArray_JPEG = archivedImages;
    
    // Grab task audio on the fly
    if(self.taskAudio) {
        model.taskAudio = self.taskAudio;
    }
    
    [realm addObject:model];
    
    if(transcation)
        [realm commitWriteTransaction];
    
    self.BACKING_DATABASE_MODEL = model;
}

- (CSTaskRealmModel*)BACKING_DATABASE_MODEL {
    if(_BACKING_DATABASE_MODEL)
        return _BACKING_DATABASE_MODEL;
    
    _BACKING_DATABASE_MODEL = [CSTaskRealmModel objectInRealm:[RLMRealm defaultRealm] forPrimaryKey:_concatenatedID];
    
    return _BACKING_DATABASE_MODEL;
}

- (void)setAndPersistPropertiesOfNewTaskObject:(CSTaskRealmModel*)model
                                       inRealm:(RLMRealm*)realm
{
    [self setAndPersistPropertiesOfNewTaskObject:model inRealm:realm withTransaction:YES];
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
    _temporaryWriteError = error;
    [thisTasksData writeToURL:fileURL options:NSDataWritingAtomic error:&error];
    
    if(!error)
        self.temporaryFileURL = fileURL;
    
    return self.temporaryFileURL;
}

- (BOOL) removeTemporaryTaskDataFromDisk {
    NSError *error = nil;
    
    [[NSFileManager defaultManager] removeItemAtURL:self.temporaryFileURL error:&error];
    
    if(error) {
        NSLog(@"Task Removal Error for task %@ : \n%@", self.taskTitle, error);
    }
    
    return error ? YES : NO;
}

#pragma mark - ASYNC callbacks
- (void) getAllImagesForTaskWithCompletionBlock:(void (^)(BOOL))completion {
    
    if(self.TRANSIENT_taskImages) {
        completion(YES);
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        id imageMutableArray = [NSKeyedUnarchiver unarchiveObjectWithData:self.taskImages_NSDataArray_JPEG];
        
        if([imageMutableArray isKindOfClass:[NSMutableArray class]]) { // if it does ...
            self.TRANSIENT_taskImages = [NSMutableArray new]; // ... make sure the task now has a container array
            NSMutableArray* imgs = (NSMutableArray*)imageMutableArray; /// convenience pointer
            for(NSData* newImageData in imgs) { // for every NSData representation of the image ...
                [self.TRANSIENT_taskImages addObject:[UIImage imageWithData:newImageData]]; // ... add a new UIImage to the container
            }
        }
        
        completion(YES);
    });
}

@end
