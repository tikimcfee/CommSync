//
//  CSFrameworkSupportedDataServer.m
//  CommSync
//
//  Created by CommSync on 2/2/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSFrameworkSupportedDataServer.h"

@implementation CSFrameworkSupportedDataServer

+ (CSFrameworkSupportedDataServer*) sharedServer {
    
    static CSFrameworkSupportedDataServer* sharedDataServer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDataServer = [[self alloc]init];
    });
    
    return sharedDataServer;
}

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}



@end
