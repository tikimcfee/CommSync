//
//  InterfaceController.m
//  CommSync WatchKit Extension
//
//  Created by Anna Stavropoulos on 3/14/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "InterfaceController.h"


@interface InterfaceController()
@property (copy, nonatomic) NSArray *settingsList;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    self.settingsList = @[@"Send Pulse", @"Tear Down", @"Rebuild", @"Remove User History", @"Populate Tasks", @"NUKE SESSION", @"NUKE DATABASE"];
    
    
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



