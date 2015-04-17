//
//  UINavigationBar+CommSyncStyle.m
//  CommSync
//
//  Created by Darin Doria on 4/13/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "UINavigationBar+CommSyncStyle.h"
#import "UIColor+FlatColors.h"

@implementation UINavigationBar (CommSyncStyle)

- (void)setupCommSyncStyle {
    self.barTintColor = [UIColor flatWetAsphaltColor];
    self.barStyle = UIBarStyleBlack;
    self.tintColor = [UIColor flatCloudsColor];
    self.translucent = NO;
}

@end