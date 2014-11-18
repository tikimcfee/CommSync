//
//  ViewController.m
//  CommSync
//
//  Created by Ivan Lugo on 9/30/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSSessionManager.h"
#import "AppDelegate.h"
#import "MessageViewController.h"

@interface MessageViewController()

// browsing
@property (strong, nonatomic) IBOutlet UIButton *startBrowsingButton;
@property (strong, nonatomic) IBOutlet UIButton *stopBrowsingButton;
@property (strong, nonatomic) IBOutlet UILabel *browsingStatus;

// advertising
@property (strong, nonatomic) IBOutlet UIButton *startAdvertisingButton;
@property (strong, nonatomic) IBOutlet UIButton *stopAdvertisingButton;
@property (strong, nonatomic) IBOutlet UILabel *advertisingStatus;

// status labels
@property (strong, nonatomic) IBOutlet UILabel *heartbeatStatus;
@property (strong, nonatomic) IBOutlet UILabel *connectedPeerName;

// session manager
@property (strong, nonatomic) CSSessionManager* sessionManager;

//messaging
@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) NSArray *searchResult;

@end

@implementation MessageViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    
    
    // Create the user's sessions
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    _sessionManager = d.globalSessionManager;
    
}

-(id)init
{
    //tab style view
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    return self;
}

# pragma Heartbeat Handler

# pragma Button Handlers
- (IBAction)startBrowsing:(id)sender {
    
    NSLog(@"Started to browse...");
    
    _browsingStatus.text = @"Browsing...";
}

- (IBAction)stopBrowsing:(id)sender {
    
    NSLog(@"Manually stopped browsing for peers!");
    
    _browsingStatus.text = @"Manually stopped browsing";
}

- (IBAction)startAdvertising:(id)sender {

    NSLog(@"Started to advertise...");
    
    _advertisingStatus.text = @"Advertising...";
}

- (IBAction)stopAdvertising:(id)sender {
    
    NSLog(@"Manually stopped advertising!");
    
    _advertisingStatus.text = @"Manually stopped advertising";
}

- (IBAction)sendPulse:(id)sender {
    NSLog(@"Sending a pulse...");
    [_sessionManager sendPulseToPeers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
