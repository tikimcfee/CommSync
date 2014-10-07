//
//  ViewController.m
//  CommSync
//
//  Created by Ivan Lugo on 9/30/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ViewController () <MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>

#define COMMSYNC_SERVICE_ID @"commsync2014"

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

// MCMultiPeer objects
@property (strong, nonatomic) MCSession* mySession;
@property (strong, nonatomic) MCPeerID* myPeerID;

@property (strong, nonatomic) MCNearbyServiceAdvertiser* serviceAdvertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser* serviceBrowser;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Create the user's sessions
    NSString* randomID = [NSString stringWithFormat:@"%d", arc4random() % 100000];
    NSLog(@"NAME -- %@", randomID);
    _myPeerID = [[MCPeerID alloc]initWithDisplayName:randomID];
    _mySession = [[MCSession alloc] initWithPeer:_myPeerID];
    _mySession.delegate = self;
}

# pragma Heartbeat Handler

# pragma Button Handlers
- (IBAction)startBrowsing:(id)sender {
    MCNearbyServiceBrowser* browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_myPeerID
                                                                       serviceType:COMMSYNC_SERVICE_ID];
    browser.delegate = self;
    _serviceBrowser = browser;
    
    [_serviceBrowser startBrowsingForPeers];
    NSLog(@"Started to browse...");
    
    _browsingStatus.text = @"Browsing...";
}

- (IBAction)stopBrowsing:(id)sender {
    [_serviceBrowser stopBrowsingForPeers];
    _serviceBrowser = nil;
    
    NSLog(@"Stopped browsing for peers!");
    
    _browsingStatus.text = @"Manually stopped browsing";
}

- (IBAction)startAdvertising:(id)sender {
    NSDictionary* discoveryInfo = @{};
    
    MCNearbyServiceAdvertiser* advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_myPeerID
                                                                              discoveryInfo:discoveryInfo
                                                                                serviceType:COMMSYNC_SERVICE_ID];
    advertiser.delegate = self;
    _serviceAdvertiser = advertiser;
    
    [advertiser startAdvertisingPeer];
    NSLog(@"Started to advertise...");
    
    _advertisingStatus.text = @"Advertising...";
}

- (IBAction)stopAdvertising:(id)sender {
    
    [_serviceAdvertiser stopAdvertisingPeer];
    _serviceAdvertiser = nil;
    
    NSLog(@"Stopped advertising");
    
    _advertisingStatus.text = @"Manually stopped advertising";
}

- (IBAction)sendPulse:(id)sender {
    NSString* pulseText = @"~PULSE~";
    NSData* newPulse = [pulseText dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    
    for(MCPeerID* peer in _mySession.connectedPeers)
    {
        NSLog(@"Sending a pulse to :: [%@]", peer.displayName);
        [_mySession sendData:newPulse toPeers:@[peer]
                    withMode:MCSessionSendDataUnreliable
                       error:&error];
    }

}


# pragma MCBrowser Delegate
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
//    for(MCPeerID* peer in _mySession.connectedPeers)
//    {
//        if(peerID.displayName == peer.displayName)
//            return;
//    }
    
    NSTimeInterval linkDeadTime = 15.0;
    [browser invitePeer:peerID toSession:_mySession withContext:nil timeout:linkDeadTime];
    NSLog(@"Inviting PeerID:[%@] to session...", peerID.displayName);
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Lost connection to PeerID:[%@] !!", peerID.displayName);
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"Start browsing failed :: %@", error);
    _browsingStatus.text = @"Unable to start browsing.";
}

# pragma MCAdvertiser Delegate
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void (^)(BOOL accept,
                             MCSession *session))invitationHandler
{
    NSLog(@"PeerID:[%@] sent an invitation.", peerID.displayName);
    
//    for(MCPeerID* peer in _mySession.connectedPeers)
//    {
//        if(peer.displayName == peerID.displayName)
//            invitationHandler(NO, nil);
//    }
    
    NSLog(@"...Auto accepting...");
    invitationHandler(YES, _mySession);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"Start advertising failed :: %@", error);
    _advertisingStatus.text = @"Unable to start advertising.";
}


# pragma MCSession Delegate
- (void) session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    certificateHandler(YES);
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Received Data: %@", data);
    
    NSError* error;
    [_mySession sendData:data toPeers:@[peerID]
                withMode:MCSessionSendDataUnreliable
                   error:&error];
}


- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSString* stateString;
    switch (state) {
        case 0:
            stateString = @"Not connected";
            break;
        case 1:
            stateString = @"Connecting";
            break;
        case 2:
            stateString = @"Connected";
            break;
        default:
            break;
    }
    
    NSLog(@"=====================");
    NSLog(@"Session peers: %@", session.connectedPeers);
    NSLog(@"=====================");
    NSLog(@"Peer: [%@] --> New State: [%@]", peerID.displayName, stateString);
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"Started receiving resource: %@", resourceName);
}


- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSLog(@"Finished receiving resource: %@", resourceName);
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Peer: [%@] is streaming", peerID.displayName);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
