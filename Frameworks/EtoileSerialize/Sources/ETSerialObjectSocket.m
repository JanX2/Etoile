#import "ETObjectStore.h"
#import <EtoileFoundation/ETSocket.h>
#import <EtoileFoundation/Macros.h>

@implementation ETSerialObjectSocket
- (id) initWithRemoteHost:(NSString*)aHost forService:(NSString*)aService
{
	SUPERINIT
	if (aService == nil)                                                                   
	{                                                                                      
		aService = @"CoreObject";                                                      
	} 
	ETSocket *theSocket = [ETSocket socketConnectedToRemoteHost: aHost
	                                                 forService: aService];
	ASSIGN(socket,theSocket);
	return self;
}

- (void) finalize 
{
	[socket sendData: buffer];
}

DEALLOC([socket release];)
@end
