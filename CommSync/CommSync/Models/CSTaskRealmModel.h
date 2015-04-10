//
//  CSTaskRealmModel.h
//  CommSync
//
//  Created by Ivan Lugo on 1/27/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <Realm/Realm.h>
#import "CSCommentRealmModel.h"
#import "CSTaskRevisionRealmModel.h"
#import "CSTaskMediaRealmModel.h"


#define kUUID @"UUID"
#define kDeviceId @"deviceID"
#define kConcatenatedID @"concatenatedID"
#define kAssignedID @"assignedID"
#define kTag @"tag"
#define kCompleted @"completed"
#define kTaskTitle @"taskTitle"
#define kTaskDescription @"taskDescription"
#define kTaskPriority @"taskPriority"

#define kRevisionDataArray @"revisionDataArray"
#define kMediaDataArray @"mediaDataArray"
#define kCommentsDataArray @"commentsDataArray"


typedef NS_ENUM(NSInteger, CSTaskPriority)
{
    CSTaskPriorityLow = 0,
    CSTaskPriorityMedium,
    CSTaskPriorityHigh
};

@interface CSTaskRealmModel : RLMObject <NSCoding>

@property RLMArray<CSCommentRealmModel> *comments;
@property RLMArray<CSTaskRevisionRealmModel> *revisions;
@property RLMArray<CSTaskMediaRealmModel> *taskMedia;

// Task persistence properties
@property NSString* UUID;
@property NSString* deviceID;
@property NSString* concatenatedID;
@property NSString* assignedID;
@property NSString* tag;
@property BOOL completed;

// Transient properties
@property (strong, nonatomic) NSURL* TRANSIENT_audioDataURL;


// Task information
@property NSString* taskTitle;
@property NSString* taskDescription;
@property CSTaskPriority taskPriority;

+ (NSMutableArray*)getTransientTaskList: (NSString*)user withTag: (NSString*)tag completionStatus:(BOOL)completed;
- (void) getAllImagesForTaskWithCompletionBlock:(void (^)(NSMutableArray*))completion;
- (NSData*) getTaskAudio;

- (NSURL*) temporarilyPersistTaskDataToDisk:(NSData*)thisTasksData;

- (void) addTaskMediaOfType:(CSTaskMediaType)type withData:(NSData*)data toRealm:(RLMRealm*)realm inTransation:(BOOL)transaction;
- (void) addComment: (CSCommentRealmModel *) newComment;
- (void) addRevision:(CSTaskRevisionRealmModel*)revision;

+ (NSString*)stringForProperty:(CSTaskProperty)property;
- (id)valueForProperty:(CSTaskProperty)property;

@end
