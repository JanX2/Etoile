#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <unistd.h>
#import "ETObjectStore.h"

@implementation ETSerialObjectSocket
- (id) initWithRemoteHost:(NSString*)aHost forService:(NSString*)aService
{
	if(nil == (self = [self init])) {return nil;}
	char * server = (char*)[aHost UTF8String];
	if (aService == nil)
	{
		aService = @"CoreObject";
	}
	char * service = (char*)[aService UTF8String];
	struct addrinfo hints, *res, *res0;
	int error;

	memset(&hints, 0, sizeof(hints));
	hints.ai_family = PF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	//Ask for a stream address.
	error = getaddrinfo(server, service, &hints, &res0);
	if (error)
	{
		NSLog(@"Error looking up address info: %s", gai_strerror(error));
		[self release];
		return nil;
	}
	s = -1;
	for (res = res0; res != NULL && s < 0 ; res = res->ai_next)
	{
		s = socket(res->ai_family, res->ai_socktype,
		res->ai_protocol);
		//If the socket failed, try the next address
		if (s < 0)
		{
			continue;
		}
		//If the connection failed, try the next address
		if (connect(s, res->ai_addr, res->ai_addrlen) < 0)
		{
			close(s);
			s = -1;
			continue;
		}
	}
	freeaddrinfo(res0);
	if (s < 0)
	{
		NSLog(@"Error connecting: %s", gai_strerror(error));
		[self release];
		return nil;
	}
	return self;
}

- (void) finalize 
{
	send(s, [buffer bytes], [buffer length], 0);
}
@end
