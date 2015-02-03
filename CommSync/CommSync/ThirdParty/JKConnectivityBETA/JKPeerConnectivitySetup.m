//
//  JKPeerConnectivitySetup.m
//  HeartChat
//
//  Created by Judit Klein on 2/09/14.
//  Copyright (c) 2014 juditk. All rights reserved.
//

#import "JKPeerConnectivitySetup.h"
#import <UIKit/UIKit.h>

@implementation JKPeerConnectivitySetup

@synthesize deviceNameIdentifier, groupIdentifier, myUniqueID;

+ (JKPeerConnectivitySetup *) sharedSetup
{
    static JKPeerConnectivitySetup *sharedSetup = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSetup = [[self alloc] init];
    });
    return sharedSetup;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        defaults = [NSUserDefaults standardUserDefaults];
        
        if (![self getValueForKey:@"firstrun"]){
            
            [self addNewValueToDefaults:@"hasrun" keyForValue:@"firstrun"];
            [self runFirstTimeExperience];
            
            NSLog(@"First time running");
            
        } else {
            
            NSLog(@"Not the first time running");
            deviceNameIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:@"Name"];
            myUniqueID = [[NSUserDefaults standardUserDefaults] stringForKey:@"UUID"];
        }
        
        groupIdentifier = @"1";
    }
    return self;
}

- (BOOL) runFirstTimeExperience {
    
    //this method will only be run if the app has never been run before
    //this will set up the device with a new UUID
    
    //Create UUID String and save it to default
    NSString *UUIDToSave = [[NSUUID UUID] UUIDString];
    UUIDToSave = [UUIDToSave substringToIndex:15];
    [self addNewValueToDefaults:UUIDToSave keyForValue:@"UUID"];
    myUniqueID = UUIDToSave;
    NSLog(@"New UUID string: %@", UUIDToSave);
    
    
    NSString *deviceName = [[UIDevice currentDevice] name];
    [self addNewValueToDefaults:deviceName keyForValue:@"Name"];
    deviceNameIdentifier = deviceName;
    NSLog(@"Device Name: %@", deviceName);
    
    return true;
}

- (BOOL) addNewValueToDefaults: (id)valueToAdd keyForValue:(NSString *)keyForValue {
    
    [defaults setObject:valueToAdd forKey:keyForValue];
    [defaults synchronize];
    return true;
    
}

- (BOOL) removeValueForKey: (NSString *)keyForValue {
    
    [defaults removeObjectForKey:keyForValue];
    [defaults synchronize];
    return true;
    
}

- (id) getValueForKey: (NSString *)keyForValue {
    
    return [defaults objectForKey:keyForValue];
    
}

@end
