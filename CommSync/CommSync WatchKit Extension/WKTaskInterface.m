//
//  WKTaskInterface.m
//  CommSync
//
//  Created by Anna Stavropoulos on 3/14/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "WKTaskInterface.h"
#import "CSTaskRow.h"

@interface WKTaskInterface()
@property bool refresh;
@end


@implementation WKTaskInterface

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    _refresh = YES;
    [self sendRequest];
    [super willActivate];
}

- (void)didDeactivate {
    _refresh = NO;
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}



- (void)configureTableWithData: (NSDictionary *) peers{
     
    [_taskTable setNumberOfRows:[peers count] withRowType:@"TaskRow"];
    int count = 0;
    for(NSString* s in [peers allKeys])
    {
        CSTaskRow *row = [_taskTable rowControllerAtIndex:count++];
        [row.taskName setText: s];
        
       
    }
    
}

- (void)sendRequest {
    
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setValue:@"task" forKey:@"task"];
    
    [WKTaskInterface openParentApplication:requestData reply:^(NSDictionary *replyInfo, NSError *error) {
        NSLog(@"%@ %@",replyInfo, error);
        [self configureTableWithData:replyInfo];
    }];
   if(_refresh) [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(sendRequest) userInfo:nil repeats:NO];
}
@end



