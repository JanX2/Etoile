#import "NSFileHandle+line.h"

@implementation NSFileHandle (line)

- (NSData*) readDataWithSize: (unsigned int) size
{
	unsigned int read = 0;
	unsigned int rest = size;
	NSMutableData* data = [NSMutableData new];

	while (read < size)
	{
		NSData* readData = [self readDataOfLength: rest];
		if (readData != nil)
		{
			unsigned int len = [readData length];
			if (len > 0)
			{
				read += len;
				rest -= len;
				[data appendData: readData];
			}
		}
		else
		{
			return [data autorelease];
		}
	}
	return [data autorelease];
}

- (void) writeLine: (NSString*) string
{
	NSString* line = [NSString stringWithFormat: @"%@\n", string];
	NSData* data = [line dataUsingEncoding: NSISOLatin1StringEncoding];
	[self writeData: data];
}

#define STX 0x2

- (void) sendSTX
{
	NSString* msg = [NSString stringWithFormat: @"%c", STX];
	[self writeLine: msg];
}
- (void) sendMSG: (NSString*) message
{
	NSString* msg = [NSString stringWithFormat: @"%c%@", STX,message];
	[self writeLine: msg];
}

- (void) waitUntilData: (id) log
{
	NS_DURING
	while (YES)
	{
		[log appendFormat: @"     will read data...\n"];
		[log writeToFile: @"/tmp/log" atomically: YES];
		NSData* data = [self readDataWithSize: 1];
		NSString* str = [[NSString alloc] initWithData: data encoding: NSISOLatin1StringEncoding];
		[log appendFormat: @"     read data: <%@> (%@)\n", data, str];
		[str release];
		[log writeToFile: @"/tmp/log" atomically: YES];
		if ([data length] == 1)
		{
			char c = ((char *)[data bytes])[0];
			if (c == STX)
			{
				return;	
			}
		}
	}
	NS_HANDLER
		[log appendFormat: @"EXCEPTION\n"];
		[log writeToFile: @"/tmp/log" atomically: YES];
		[log appendFormat: @"EXCEPTION in waitUntilData : %@\n", [localException name], [localException reason]];
		[log writeToFile: @"/tmp/log" atomically: YES];
	NS_ENDHANDLER
}

- (NSString*) readLine
{
	NSMutableData* mdata = [NSMutableData new];
	while (YES)
	{
		NSData* data = [self readDataWithSize: 1];
		char c = *(char*)[data bytes];
		if (c == '\n')
		{
			NSString* line = [[NSString alloc] initWithData: mdata
				encoding: NSISOLatin1StringEncoding];
			[mdata release];
			return [line autorelease];
		}
		else
		{
			[mdata appendData: data];
		}
	}
}

@end
