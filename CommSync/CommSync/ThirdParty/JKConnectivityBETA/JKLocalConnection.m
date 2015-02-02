//
//  JKLocalConnection.m
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

#import "JKLocalConnection.h"
#import "Connection.h"
//#import "HRTMessageServer.h"

// Private properties
@interface JKLocalConnection ()
@property(nonatomic,retain) Server* server;
@property(nonatomic,retain) NSMutableSet* clients;
@end


@implementation JKLocalConnection

@synthesize server, clients;

// Initialization
- (id)init {
  clients = [[NSMutableSet alloc] init];
  
  return self;
}


// Cleanup
- (void)dealloc {
  self.clients = nil;
  self.server = nil;
}


// Start the server and announce self
- (BOOL)start {
  // Create new instance of the server and start it up
  server = [[Server alloc] init];
  
  // We will be processing server events
  server.delegate = self;
  
  // Try to start it up
  if ( ! [server start] ) {
    self.server = nil;
    return NO;
  }
  
  return YES;
}


// Stop everything
- (void)stop {
  // Destroy server
  [server stop];
  self.server = nil;
  
  // Close all connections
  [clients makeObjectsPerformSelector:@selector(close)];
}

//This will broadcast a given NSDictionary to all clinets connected to this device
- (void)broadcastPacket:(NSDictionary*)packet fromId:(NSString*)fromID {
    
    // Send it out
    [clients makeObjectsPerformSelector:@selector(sendNetworkPacket:) withObject:packet];
}

//This will broadcast a given NSDictionary to all clinets connected to this device
- (void)broadcastPacketInJSON:(NSData*)packet fromId:(NSString*)fromID {
    
    // Send it out
    [clients makeObjectsPerformSelector:@selector(sendNetworkPacketToAndroidDevice:) withObject:packet];
}


#pragma mark -
#pragma mark ServerDelegate Method Implementations

// Server has failed. Stop the world.
- (void) serverFailed:(Server*)server reason:(NSString*)reason {
  // Stop everything and let our delegate know
  [self stop];
  [delegate roomTerminated:self reason:reason];
}


// New client connected to our server. Add it.
- (void) handleNewConnection:(Connection*)connection {
  // Delegate everything to us
  connection.delegate = self;
  
  // Add to our list of clients
  [clients addObject:connection];
}


#pragma mark -
#pragma mark ConnectionDelegate Method Implementations

// We won't be initiating connections, so this is not important
- (void) connectionAttemptFailed:(Connection*)connection {
}


// One of the clients disconnected, remove it from our list
- (void) connectionTerminated:(Connection*)connection {
  [clients removeObject:connection];
}


// One of connected clients sent a chat message. Propagate it further.
- (void) receivedNetworkPacket:(NSDictionary*)packet viaConnection:(Connection*)connection {

#warning THIS IS WHERE THE MESSAGE COMES IN TO THE CLIENT FROM OTHER CLIENTS, IT NEEDS TO BE SENT TO THE MESSAGE DECODE SERVER FROM HERE
#warning IVAN - replace hrtmessageserver functionality
//    [[HRTMessageServer sharedManager]decodeMessage:[packet objectForKey:@"MessagePacket"]];

}


@end
