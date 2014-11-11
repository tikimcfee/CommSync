//
//  CSSettingsViewController.m
//  CommSync
//
//  Created by CommSync on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSSettingsViewController.h"

@interface CSSettingsViewController ()

@end

@implementation CSSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)sendGlobalPulse:(UIButton *)sender {
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CSSessionManager* sessionManager = d.globalSessionManager;
    
    [sessionManager sendPulseToPeers];
}

- (IBAction)tearDown:(id)sender {
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CSSessionManager* sessionManager = d.globalSessionManager;
    
    [sessionManager tearDownConnectivityFramework];
}

- (IBAction)rebuild:(id)sender {
    
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CSSessionManager* sessionManager = d.globalSessionManager;
    
    [sessionManager resetAdvertiserService];
    [sessionManager resetBrowserService];
    [sessionManager resetPeerID];
    
    MCSession* s =[[MCSession alloc] initWithPeer:sessionManager.myPeerID];
    s.delegate = sessionManager;
    sessionManager.currentSession = s;
    
    [sessionManager.userSessionsDisplayNamesToSessions setObject:s forKey:sessionManager.myPeerID.displayName];
}



@end