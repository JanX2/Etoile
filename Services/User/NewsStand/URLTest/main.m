#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface Controller: NSObject
{
	NSMutableData *receivedData;
}
@end

@implementation Controller
- (void) applicationDidFinishLaunching:(NSNotification *) not
{
//	NSURL *url = [NSURL URLWithString: @"http://www.gnustep.org/"];
//	NSURL *url = [NSURL URLWithString: @"http://news.google.com/?output=rss"];
	NSURL *url = [NSURL URLWithString: @"http://osnews.com/files/recent.xml"];
	NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	NSLog(@"%@", url);
	// create the request
	NSURLRequest *theRequest=[NSURLRequest requestWithURL: url
//                        cachePolicy:NSURLRequestReloadIgnoringCacheData
                        cachePolicy:NSURLRequestUseProtocolCachePolicy
                    timeoutInterval:60.0];

	// create the connection with the request
	// and start loading the data

	NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];

	if (theConnection) {
		// Create the NSMutableData that will hold
		// the received data
		// receivedData is declared as a method instance elsewhere
NSLog(@"Here");
	    receivedData=[[NSMutableData data] retain];
	} else {
	    // inform the user that the download could not be made
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
    // it can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    // receivedData is declared as a method instance elsewhere
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    // release the connection, and the data object
    [connection release];
    // receivedData is declared as a method instance elsewhere
    [receivedData release];

    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    // do something with the data
    // receivedData is declared as a method instance elsewhere
    NSLog(@"Succeeded! Received %d bytes of data",[receivedData length]);
	[receivedData writeToFile: @"OSNews_DATA" atomically: YES];
	NSString *string = [[NSString alloc] initWithData: receivedData encoding: NSUTF8StringEncoding];
	[string writeToFile: @"OSNews_String" atomically: YES];
	[string release];

    // release the connection, and the data object
    [connection release];
    [receivedData release];
}

-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse

{
	NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    NSURLRequest *newRequest=request;
    if (redirectResponse) {
        newRequest=nil;
    }
    return newRequest;
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge

{
	NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
#if 0
    if ([challenge previousFailureCount] == 0) {
        NSURLCredential *newCredential;
        newCredential=[NSURLCredential credentialWithUser:[self preferencesName]
                                       password:[self preferencesPassword]
                                   persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        // inform the user that the user name and password
        // in the preferences are incorrect
        [self showPreferencesCredentialsAreIncorrectPanel:self];
    }
#endif
}

-(NSCachedURLResponse *)connection:(NSURLConnection *)connection
                 willCacheResponse:(NSCachedURLResponse *)cachedResponse

{
	NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    NSCachedURLResponse *newCachedResponse=cachedResponse;

    if ([[[[cachedResponse response] URL] scheme] isEqual:@"https"]) {
        newCachedResponse=nil;
    } else {
        NSDictionary *newUserInfo;
        newUserInfo=[NSDictionary dictionaryWithObject:[NSCalendarDate date]
                                                 forKey:@"Cached Date"];

        newCachedResponse=[[[NSCachedURLResponse alloc]
                            initWithResponse:[cachedResponse response]
                    data:[cachedResponse data]
                        userInfo:newUserInfo
                               storagePolicy:[cachedResponse storagePolicy]]
                           autorelease];

    }

    return newCachedResponse;
}

@end

int main(int argc, const char *argv[])
{
	CREATE_AUTORELEASE_POOL(x);
#if 1
	[NSApplication sharedApplication];
	[NSApp setDelegate: AUTORELEASE([[Controller alloc] init])];
	[NSApp run];
#else
	Controller *controller = [[Controller alloc] init];
        /* Register for the notification */
        NSNotificationCenter * center = [NSDistributedNotificationCenter 
                defaultCenter];
        [center addObserver:controller
                           selector:@selector(statusChanged:) 
                                   name:@"LocalPresenceChangedNotification" 
                                 object:nil];

	[controller applicationDidFinishLaunching: nil];
	[[NSRunLoop currentRunLoop] run];
#endif
	DESTROY(x);
NSLog(@"Exit");
	return 0;
}

