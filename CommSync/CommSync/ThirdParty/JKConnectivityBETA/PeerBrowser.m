//
//  ServerBrowser.m
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

#import "PeerBrowser.h"

// A category on NSNetService that's used to sort NSNetService objects by their name.
@interface NSNetService (BrowserViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService*)aService;
@end

@implementation NSNetService (BrowserViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService*)aService {
	return [[self name] localizedCaseInsensitiveCompare:[aService name]];
}
@end


// Private properties and methods
@interface PeerBrowser ()

// Sort services alphabetically
- (void)sortServers;

@end


@implementation PeerBrowser

@synthesize servers;
@synthesize delegate;

// Initialize
- (id)init {
  servers = [[NSMutableArray alloc] init];
  return self;
}


// Cleanup
- (void)dealloc {
  if ( servers != nil ) {
    servers = nil;
  }
  self.delegate = nil;
}


// Start browsing for servers
- (BOOL)start {
  // Restarting?
  if ( netServiceBrowser != nil ) {
    [self stop];
  }

	netServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if( !netServiceBrowser ) {
		return NO;
	}

	netServiceBrowser.delegate = self;
    //[netServiceBrowser setIncludesPeerToPeer:YES];
	[netServiceBrowser searchForServicesOfType:@"_commsync_peertopeer._tcp." inDomain:@"local"];
  
  return YES;
}


// Terminate current service browser and clean up
- (void)stop {
  if ( netServiceBrowser == nil ) {
    return;
  }
  
  [netServiceBrowser stop];
  netServiceBrowser = nil;
  
  [servers removeAllObjects];
}


// Sort servers array by service names
- (void)sortServers {
  [servers sortUsingSelector:@selector(localizedCaseInsensitiveCompareByName:)];
}


#pragma mark -
#pragma mark NSNetServiceBrowser Delegate Method Implementations

// New service was found
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
  // Make sure that we don't have such service already (why would this happen? not sure)
    
	NSLog(@"New NetService Was Found with Name %@",[netService name]);
	
  if ( ! [servers containsObject:netService] ) {
    // Add it to our list
    [servers addObject:netService];
      
    NSLog(@"We Are Now Going To Attempt To Resolve The Net Service with name %@",[netService name]);
    [netService setDelegate:self];
    [netService resolveWithTimeout:5.0];
  } else {
      NSLog(@"We were told about a new peer... but we allready know about this peer... why were they discovered twice..%@",[netService name]);
  }

  // If more entries are coming, no need to update UI just yet
  if ( moreServicesComing ) {
    return;
  }
  
  // Sort alphabetically and let our delegate know
  [self sortServers];
  [delegate updatePeerList];
}


// Service was removed
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
  // Remove from list
	if ( [servers containsObject:netService] )
	{
		[servers removeObject:netService];
		[delegate peerIsGone:netService];
        
		// If more entries are coming, no need to update UI just yet
		if ( moreServicesComing ) 
		{
			return;
		}
		
		// Sort alphabetically and let our delegate know
		[self sortServers];
		[delegate updatePeerList];
	}
  
}

- (void)netServiceWillResolve:(NSNetService *)sender {
    NSLog(@"I Will Resolve %@",[sender name]);
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSLog(@"I Finished Resolving %@",[sender name]);
    [delegate newPeerDiscovered:sender];
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data {
    NSLog(@"The Peer %@  Has updated their TXT Record Data",[sender name]);
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    NSLog(@"I failed to resolve the user %@ shall we still add them?",[sender name]);
    [delegate newPeerDiscovered:sender];
}

@end
