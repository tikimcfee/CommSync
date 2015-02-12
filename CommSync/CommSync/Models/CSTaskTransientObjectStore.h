//
//  CSTaskTransientObjectStore.h
//  CommSync
//
//  Created by CommSync on 2/11/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSTaskRealmModel.h"

@interface CSTaskTransientObjectStore : NSObject

// Realm persistence information
@property (strong, nonatomic) NSString* UUID;
@property (strong, nonatomic) NSString* deviceID;
@property (strong, nonatomic) NSString* concatenatedID;

// Task information
@property (strong, nonatomic) NSString* taskTitle;
@property (strong, nonatomic) NSString* taskDescription;
@property (assign, nonatomic) CSTaskPriority taskPriority;

@property (strong, nonatomic) NSMutableArray* TRANSIENT_taskImages;
@property (strong, nonatomic) NSURL* TRANSIENT_audioDataURL;

@property (strong, nonatomic) NSData* taskAudio;
@property (strong, nonatomic) NSData* taskImages_NSDataArray_JPEG;



- (id)initWithRealmModel:(CSTaskRealmModel*)model;

- (void)setAndPersistPropertiesOfNewTaskObject:(CSTaskRealmModel*)model
                                       inRealm:(RLMRealm*)realm;

- (void)setAndPersistPropertiesOfNewTaskObject:(CSTaskRealmModel*)model
                                       inRealm:(RLMRealm*)realm
                               withTransaction:(BOOL)transcation;



@end
