//
//  UITabBar+CommSyncStyle.m
//  CommSync
//
//  Created by Darin Doria on 4/13/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "UITabBar+CommSyncStyle.h"
#import "UIColor+FlatColors.h"

@implementation UITabBar (CommSyncStyle)

- (void)setupCommSyncStyle {
    
    self.barTintColor = [UIColor flatWetAsphaltColor];
    self.translucent = NO;
    self.tintColor = [UIColor flatCloudsColor];
}

@end
