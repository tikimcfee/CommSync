//
//  WKPeerinterfaceController.m
//  CommSync
//
//  Created by Anna Stavropoulos on 3/14/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "WKPeerinterface.h"
#import "CSPeerRow.h"

@interface WKPeerInterface()
@property bool refresh;
@end


@implementation WKPeerInterface

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
   
    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    _refresh = YES;
    [self sendRequest];
    

}



- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    _refresh = NO;
}


- (void)configureTableWithData: (NSDictionary *) peers{
    
   
    [_peerTable setNumberOfRows:[peers count] withRowType:@"default"];
    int count = 0;
    for(NSString* s in [peers allKeys])
    {
        CSPeerRow *row = [_peerTable rowControllerAtIndex:count++];
        [row.userLabel setText:s];
        
        NSString* status = [peers valueForKey:s];
        
        if( [status isEqualToString:@"Connected"]) [row.statusLabel setText:@"✓"];
        else [row.statusLabel setText:@"X"];
    }
       
}

- (void)sendRequest {
    if(!_refresh) return;
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
  
    [requestData setValue:@"task" forKey:@"task2"];
    [WKPeerInterface openParentApplication:requestData reply:^(NSDictionary *replyInfo, NSError *error) {
        
        NSLog(@"%@ %@",replyInfo, error);
        [self configureTableWithData:replyInfo];
    }];
    
        [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(sendRequest) userInfo:nil repeats:NO];
 
    
}
@end



