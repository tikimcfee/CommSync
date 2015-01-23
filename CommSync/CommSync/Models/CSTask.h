//
//  CSTask.h
//  CommSync
//
//  Created by Ivan Lugo on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CSTask : NSObject <NSCoding>

// Storage data structure
@property (strong, nonatomic) CSTask* leftChild;
@property (strong, nonatomic) CSTask* rightChild;

// Task properties
@property (strong, nonatomic) NSString* UUID;
@property (strong, nonatomic) NSString* deviceID;
@property (strong, nonatomic) NSString* concatenatedID;

@property (strong, nonatomic) NSString* taskTitle;
@property (strong, nonatomic) NSString* taskDescription;

@property (strong, nonatomic) id taskAudio;
@property (strong, nonatomic) UIImage* taskImage;
@property (strong, nonatomic) id taskVideo;
@property (strong, nonatomic) id taskAttachmentData;

typedef NS_ENUM(NSInteger, CSTaskPriority)
{
    CSTaskPriorityLow = 0,
    CSTaskPriorityMedium,
    CSTaskPriorityHigh
};

@property (assign, nonatomic) CSTaskPriority taskPriority;


- (CSTask*) initWithUUID:(NSString*)UUID andDeviceID:(NSString*)deviceID;


@end
