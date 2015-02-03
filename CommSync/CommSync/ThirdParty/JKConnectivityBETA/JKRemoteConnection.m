//
//  JKRemoteConnection.m
//  JKPeerConnectivity
//
//  Copyright (c) 2009 Peter Bakhyryev <peter@byteclub.com>, ByteClub LLC
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "JKRemoteConnection.h"
//#import "HRTMessageServer.h"


// Private properties
@interface JKRemoteConnection ()
@end


@implementation JKRemoteConnection

@synthesize connection;

// Setup connection but don't connect yet
- (id)initWithHost:(NSString*)host andPort:(int)port {
  connection = [[Connection alloc] initWithHostAddress:host andPort:port];
  return self;
}


// Initialize and connect to a net service
- (id)initWithNetService:(NSNetService*)netService {
  connection = [[Connection alloc] initWithNetService:netService];
  return self;
}


// Cleanup
- (void)dealloc {
  self.connection = nil;
}


// Start everything up, connect to server
- (BOOL)start {
  if ( connection == nil ) {
    return NO;
  }
  
  // We are the delegate
  connection.delegate = self;
  
  return [connection connect];
}


// Stop everything, disconnect from server
- (void)stop {
  if ( connection == nil ) {
    return;
  }
  
  [connection close];
  self.connection = nil;
}

//This will broadcast a given NSDictionary to all clinets connected to this device
- (void)broadcastPacket:(NSDictionary*)packet fromId:(NSString*)fromID {
    
    // Send it out
    [connection sendNetworkPacket:packet];
}


#pragma mark -
#pragma mark ConnectionDelegate Method Implementations

- (void)connectionAttemptFailed:(Connection*)connection {
    NSLog(@"Failed To COnnecto To REmote Peer");
#warning Failed To Connect To Peer Logic goes here
}


- (void)connectionTerminated:(Connection*)connection {
    NSLog(@"Connection To Remote Peer has been terminated");

    [delegate remoteConnectionHasClosed:self];
    #warning Peer has left us goes here

}


- (void)receivedNetworkPacket:(NSDictionary*)packet viaConnection:(Connection*)connection {
	
    //NSLog(@"Incomming Data From Peer %@",packet);
    
    //Decode it
    
//    [[HRTMessageServer sharedManager]decodeMessage:[packet objectForKey:@"MessagePacket"]];

#warning THIS IS WHERE THE MESSAGE COMES IN TO THE CLIENT FROM OTHER CLIENTS, IT NEEDS TO BE SENT TO THE MESSAGE DECODE SERVER FROM HERE
#warning IVAN - replace hrtmessageserver functionality
    
    
}


@end
