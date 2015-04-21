//
//  CSTabBarController.m
//  CommSync
//
//  Created by Darin Doria on 4/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTabBarController.h"
#import "IonIcons.h"
#import "UIColor+FlatColors.h"

@implementation CSTabBarController

- (void)viewDidLoad {
    
    UITabBarItem *tabBarItem1 = [self.tabBar.items objectAtIndex:0];
    tabBarItem1.image = [IonIcons imageWithIcon:ion_ios_home_outline size:30.0f color:[UIColor flatCloudsColor]];
    tabBarItem1.selectedImage = [IonIcons imageWithIcon:ion_ios_home size:30.0f color:[UIColor flatCloudsColor]];
    tabBarItem1.title = @"Tasks";
    
    UITabBarItem *tabBarItem2 = [self.tabBar.items objectAtIndex:1];
    tabBarItem2.image = [IonIcons imageWithIcon:ion_ios_people_outline size:30.0f color:[UIColor flatCloudsColor]];
    tabBarItem2.selectedImage = [IonIcons imageWithIcon:ion_ios_people size:30.0f color:[UIColor flatCloudsColor]];
    tabBarItem2.title = @"Users";
    
    UITabBarItem *tabBarItem3 = [self.tabBar.items objectAtIndex:2];
    tabBarItem3.image = [IonIcons imageWithIcon:ion_ios_chatbubble_outline size:30.0f color:[UIColor flatCloudsColor]];
    tabBarItem3.selectedImage = [IonIcons imageWithIcon:ion_ios_chatbubble size:30.0f color:[UIColor flatCloudsColor]];
    tabBarItem3.title = @"Chat";
    
    UITabBarItem *tabBarItem4 = [self.tabBar.items objectAtIndex:3];
    tabBarItem4.image = [IonIcons imageWithIcon:ion_ios_gear_outline size:30.0f color:[UIColor flatCloudsColor]];
    tabBarItem4.selectedImage = [IonIcons imageWithIcon:ion_ios_gear size:30.0f color:[UIColor flatCloudsColor]];
    tabBarItem4.title = @"Settings";
}

@end
