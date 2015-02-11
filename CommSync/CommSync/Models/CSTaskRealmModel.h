//
//  CSTaskRealmModel.h
//  CommSync
//
//  Created by Ivan Lugo on 1/27/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>
#import "CSCommentRealmModel.h"

typedef NS_ENUM(NSInteger, CSTaskPriority)
{
    CSTaskPriorityLow = 0,
    CSTaskPriorityMedium,
    CSTaskPriorityHigh
};

@interface CSTaskRealmModel : RLMObject <NSCoding, UIImagePickerControllerDelegate>

@property RLMArray<CSCommentRealmModel> *comments;



// Task persistence properties
@property NSString* UUID;
@property NSString* deviceID;
@property NSString* concatenatedID;

// Task information
@property NSString* taskTitle;
@property NSString* taskDescription;
@property CSTaskPriority taskPriority;

// Task media
@property NSData* taskImages_NSDataArray_JPEG;
@property NSData* taskAudio;
@property (strong, nonatomic) NSMutableArray* TRANSIENT_taskImages;

//@property id taskAudio;
//@property id taskVideo;
//@property id taskAttachmentData;

- (void) getAllImagesForTaskWithCompletionBlock:(void (^)(BOOL))completion;

- (void) addComment: (CSCommentRealmModel *) newComment;

@end
