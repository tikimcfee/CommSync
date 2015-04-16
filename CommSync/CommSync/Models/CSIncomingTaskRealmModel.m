//
//  CSIncomingTaskRealmModel.m
//  CommSync
//
//  Created by Ivan Lugo on 4/12/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSIncomingTaskRealmModel.h"

@implementation CSIncomingTaskRealmModel

+ (NSDictionary *)defaultPropertyValues {
    
    NSDictionary* defaults = nil;
    
    defaults = @{@"taskObservationString" : @"",
                 @"peerDisplayName" : @"",
                 @"trueTaskName" : @""
                 };
    
    return defaults;
}

+( NSString*) primaryKey {
    return @"taskObservationString";
}

@end
