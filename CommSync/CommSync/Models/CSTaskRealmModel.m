//
//  CSTaskRealmModel.m
//  CommSync
//
//  Created by Ivan Lugo on 1/27/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskRealmModel.h"

@implementation CSTaskRealmModel

#pragma mark - Lifecycle
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.UUID = [aDecoder decodeObjectForKey:@"UUID"];
        self.deviceID = [aDecoder decodeObjectForKey:@"deviceID"];
        self.concatenatedID = [aDecoder decodeObjectForKey:@"concatenatedID"];
        
        self.taskTitle = [aDecoder decodeObjectForKey:@"taskTitle"];
        self.taskDescription = [aDecoder decodeObjectForKey:@"taskDescripion"];
        self.taskPriority = [aDecoder decodeIntForKey:@"taskPriority"];
        
        // see if the decoder gives us an image array
        id imageMutableArray_DATA = [aDecoder decodeObjectForKey:@"taskImages"];
        if (imageMutableArray_DATA) {
            self.taskImages_NSDataArray_JPEG = imageMutableArray_DATA;
        } else {
            NSMutableArray* tempArrayOfImages = [NSMutableArray new];
            NSData* archivedImages = [NSKeyedArchiver archivedDataWithRootObject:tempArrayOfImages];
           self.taskImages_NSDataArray_JPEG = archivedImages;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.UUID forKey:@"UUID"];
    [aCoder encodeObject:self.deviceID forKey:@"deviceID"];
    [aCoder encodeObject:self.concatenatedID forKey:@"concatenatedID"];
    
    [aCoder encodeObject:self.taskTitle forKey:@"taskTitle"];
    [aCoder encodeObject:self.taskDescription forKey:@"taskDescripion"];
    [aCoder encodeInteger:self.taskPriority forKey:@"taskPriority"];
    
    // NOTE!
    // This is ALL KINDS OF EXTREMELY INEFFICIENT!
    // We should not rearchive and reconvert images we have already worked with
    NSMutableArray* tempArrayOfImages = [NSMutableArray arrayWithCapacity:self.TRANSIENT_taskImages.count];
    for(UIImage* image in self.TRANSIENT_taskImages) { // for every TRANSIENT UIImage we have on this task
        NSData* thisImage = UIImageJPEGRepresentation(image, 0.3); // make a new JPEG data object with some compressed size
        [tempArrayOfImages addObject:thisImage]; // add it to our container
    }
    
    NSData* archivedImages = [NSKeyedArchiver archivedDataWithRootObject:tempArrayOfImages]; // archive the data ...
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    self.taskImages_NSDataArray_JPEG = archivedImages; // and set the images of this task to the new archive
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [aCoder encodeObject:self.taskImages_NSDataArray_JPEG forKey:@"taskImages"]; // encode the object and pray
}

+ (NSArray*)ignoredProperties {
    
    return @[@"TRANSIENT_taskImages"];
}

//+ (NSDictionary*)defaultPropertyValues {
//    NSMutableArray* tempArrayOfImages = [NSMutableArray new];
//    NSData* archivedImages = [NSKeyedArchiver archivedDataWithRootObject:tempArrayOfImages];
//    
//    return @{@"taskImages_NSDataArray_JPEG":archivedImages};
//}

#pragma mark - Accessors and Helpers

- (void) getAllImagesForTaskWithCompletionBlock:(void (^)(BOOL))completion {
    
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
