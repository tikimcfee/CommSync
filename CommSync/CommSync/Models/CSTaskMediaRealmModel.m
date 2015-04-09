//
//  CSTaskMediaRealmModel.m
//  HubSync
//
//  Created by CommSync on 4/9/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskMediaRealmModel.h"

@implementation CSTaskMediaRealmModel

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues
{
    NSNumber* type = [NSNumber numberWithInt:-1];
    NSData* emptyData = [NSData data];
    
    return @{@"mediaData":emptyData, @"mediaType":type};
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

@end
