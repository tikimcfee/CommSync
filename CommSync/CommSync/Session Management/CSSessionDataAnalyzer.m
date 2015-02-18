//
//  CSSessionDataAnalyzer.m
//  CommSync
//
//  Created by CommSync on 2/18/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSSessionDataAnalyzer.h"
#import "CSChatMessageRealmModel.h"


// Critical constants for building data transmission strings
#define kCSDefaultStringEncodingMethod NSUTF16StringEncoding
#define kCS_HEADER_NEW_TASK     @"NEW_TASK"
#define kCS_HEADER_TASK_REQUEST @"TASK_REQUEST"
#define kCS_STRING_SEPERATOR    @":"


@implementation CSSessionDataAnalyzer

+ (CSSessionDataAnalyzer*) sharedInstance:(CSSessionManager*)manager {
    static dispatch_once_t once;
    static CSSessionDataAnalyzer* sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.globalManager = manager;
    });
    
    return sharedInstance;
}

- (void) analyzeReceivedData:(NSData*)receivedData fromPeer:(MCPeerID*)peer{
    
    // Determine if data is a string / command
    NSString* stringFromData = [[NSString alloc] initWithData:receivedData encoding:kCSDefaultStringEncodingMethod];
    
    if(stringFromData)
    {
        NSArray* stringComponents = [stringFromData componentsSeparatedByString:kCS_STRING_SEPERATOR];
        
        // -- TASK CREATION --
        // Is the string a prompt of new task creation?
            // Check the task realm for the task; if it does not exist, send the peer a request for the task
                // +++!!!+++ IF IT NEEDS TO BE UPDATED, REQUEST!
        
        // Is the string a request for a task?
            // Make sure you have the requested task, and initiate a resource send of task to the requesting peer
        
    }
    else
    {
        id receivedObject = [NSKeyedUnarchiver unarchiveObjectWithData:receivedData];
        
        if([receivedObject isKindOfClass:[CSChatMessageRealmModel class]])
        {
            // OP
        }
    }
    
}

- (NSString*) buildTaskRequestStringFromNewTaskString:(NSString*)sourceString
{
    if(!sourceString) {
        NSLog(@"<?> String build failed - no source string.");
        return nil;
    }
    
    NSArray* stringComponents = [sourceString componentsSeparatedByString:kCS_STRING_SEPERATOR];
    
    if(stringComponents.count < 2) {
        NSLog(@"<?> String build failed - malformed new task string");
        return nil;
    }
    
    NSString* taskID = [stringComponents objectAtIndex:1];
    
    NSString* requestString = [NSString stringWithFormat:@"%@%@%@",
                               kCS_HEADER_TASK_REQUEST,
                               kCS_STRING_SEPERATOR,
                               taskID];
    
    return requestString;
}




@end
