//
//  CSTask.h
//  CommSync
//
//  Created by Ivan Lugo on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSTask : NSObject

@property (strong, nonatomic) CSTask* leftChild;
@property (strong, nonatomic) CSTask* rightChild;

@property (strong, nonatomic) NSString* UUID;
@property (strong, nonatomic) NSString* deviceID;
@property (strong, nonatomic) NSString* concatenatedID;


- (CSTask*) initWithUUID:(NSString*)UUID andDeviceID:(NSString*)deviceID;


@end
