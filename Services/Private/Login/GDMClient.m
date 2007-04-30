#import "GDMClient.h"

@implementation GDMClient

- (id) init
{
	return [self initWithInput: 
	       		[NSFileHandle fileHandleWithStandardInput]
			andOutput: 
	       		[NSFileHandle fileHandleWithStandardOutput]];
}

- (id) initWithInput: (NSFileHandle*) anInput andOutput: (NSFileHandle*) anOutput
{
	self = [super init];

	input = [anInput retain];
	output = [anOutput retain];
	log = [NSMutableString new];
	
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(newData:)
		name: NSFileHandleDataAvailableNotification
		object: input];

	waitForInput = NO;
	loggingIn = NO;
	
	return self;
}

- (void) start
{
	waitForInput = YES;
//	[input waitForDataInBackgroundAndNotify];
}

- (void) setDelegate: (id) aDelegate
{
	[aDelegate retain];
	[delegate release];
	delegate = aDelegate;
}

- (void) error
{
	waitForInput = NO;
	loggingIn = NO;
	[delegate gdmError: self];
}

- (void) dealloc
{
	[desktop release];
	[log release];
	[input release];
	[output release];
	[super dealloc];
}

- (void) newData: (id) notification
{
//	[self parse];
}

- (void) defaultRead
{
	[input waitUntilData: log]; 
	[input readLine];
	[output sendSTX];
}
- (void) beginning
{
	[self defaultRead];
	#define READ(NAME) if ([self read: NAME] == NO) { [output sendSTX]; return; } else { [output sendSTX]; }
	READ (GDM_SETLOGIN);
	READ (GDM_MSG);
        #undef READ
}

- (BOOL) loginWithUsername: (NSString*) userName password: (NSString*) pw 
                   session: (NSString *) session
{
	BOOL res = NO;
	user = userName;
	password = pw;
        desktop = session;

	NS_DURING
	#define READ(NAME) if ([self read: NAME] == NO) { [output sendSTX]; return NO; } else { [output sendSTX]; }

	[log appendFormat: @"\nLOGIN: <%@> PASS: <%@>\n", userName, password];
	[log writeToFile: @"/tmp/log" atomically: YES];
	
	//READ (GDM_SETLOGIN);
	//READ (GDM_MSG);

	if ([self read: GDM_PROMPT])
	{
		// we send the username...
		if (userName) [output sendMSG: userName];					
		else [output sendSTX];
	}

	READ (GDM_MSG);
	if ([self read: GDM_SETLOGIN]) // ack... here lastLine should be equal to userName..
	{
		[output sendSTX];

		if ([self read: GDM_NOECHO])
		{
			if (password) [output sendMSG: password];
			else [output sendSTX];
		}

		// now, we can have setlogin upto quit, or query capslock and errbox and reset...
		
		if ([self read: GDM_SETLOGIN])
		{
			[output sendSTX];
			// and lastLine should be equal to userName

			if ([self read: GDM_SESS])
			{
				[output sendMSG: [NSString stringWithFormat: @"%@.desktop", desktop]];
				READ (GDM_LANG);
				READ (GDM_SSESS);
				READ (GDM_SLANG);

				if ([self read: GDM_QUIT])
				{
					res = YES;
				}	
			}
		}
		else
		{
			[output sendSTX];
			// then next message should be errbox, then reset
			READ (GDM_ERRBOX);
			[input readLine];
			READ (GDM_RESET);
			READ (GDM_SETLOGIN);
			READ (GDM_MSG);
		}
	}
	else
	{
		[output sendSTX];
		// then next message should be errbox, then reset
		READ (GDM_ERRBOX);
		[input readLine];
		READ (GDM_RESET);
		READ (GDM_SETLOGIN);
		READ (GDM_MSG);
	}

	NS_HANDLER
		[log appendFormat: @"EXCEPTION in login %@ : %@\n", [localException name], [localException reason]];
		[log writeToFile: @"/tmp/log" atomically: YES];
	NS_ENDHANDLER
	return res;
}

- (BOOL) read: (int) code
{

	BOOL res = NO;

	NS_DURING

	[log appendFormat: @"  <- will read %c\n", code];
	[log writeToFile: @"/tmp/log" atomically: YES];
	[input waitUntilData: log];
	[log appendFormat: @"     ready to read..\n"];
	[log writeToFile: @"/tmp/log" atomically: YES];
	[lastLine release];
	lastLine = [input readLine];
	[log appendFormat: @"     read: <%@>..\n", lastLine];
	[log writeToFile: @"/tmp/log" atomically: YES];
	[log appendFormat: @"read <%@> waiting for <%c>\n", lastLine, code];
	[log writeToFile: @"/tmp/log" atomically: YES];
	if ([lastLine length] > 0)
	{
		char c = [lastLine cString][0];
		if (code == c) res = YES;
	}
	if ([lastLine length] > 1)
	{
		lastLine = [lastLine substringFromIndex: 1];
	}
	[log appendFormat: @"  -> read %c complete, %d\n", code, res];
	[log writeToFile: @"/tmp/log" atomically: YES];

	NS_HANDLER
		[log appendFormat: @"EXCEPTION in read(%c) %@ : %@\n", code, [localException name], [localException reason]];
		[log writeToFile: @"/tmp/log" atomically: YES];
	NS_ENDHANDLER
	[lastLine retain];
	return res;
}

- (void) parse
{
	BOOL valid = NO;	
	while (valid)
	{
		[log appendString: @"PARSE\n"];
		[log writeToFile: @"/tmp/log" atomically: YES];
		[input waitUntilData: nil];
		NSString* msg = [input readLine];

		[log appendFormat: @"Lu <%@> ", msg];
		[log writeToFile: @"/tmp/log" atomically: YES];
		
		if ([msg length] > 0)
		{
			char c = [msg cString][0];
			
			switch (c)
			{
				case GDM_SETLOGIN:
					[log appendString: @"SETLOGIN"];
					[output sendSTX];
					break;
				case GDM_NEEDPIC:
					[log appendString: @"NEEDPIC"];
					[output sendSTX];
					break;
				case GDM_READPIC:
					[log appendString: @"READPIC"];
					[output sendSTX];
					break;
				case GDM_MSG:
					msg = [msg substringFromIndex: 1];
					[log appendFormat: @"MESSAGE (%@)", msg];
					[output sendSTX];
					break;
				case GDM_PROMPT:
					msg = [msg substringFromIndex: 1];
					[log appendFormat: @"PROMPT (%@)", msg];
					// we send the username
					if (user) [output sendMSG: user];					
					else [output sendSTX];
					break;	
				case GDM_QUERY_CAPSLOCK:
					[log appendString: @"QUERY CAPSLOCK"];
					[output sendSTX]; // we could send STX followed by 'Y\n'
					break;	
				case GDM_ERRBOX:
					[log appendString: @"ERRBOX"];
					[output sendSTX]; 
					[self error];
					break;	
				case GDM_RESET:
					[log appendString: @"RESET"];
					[output sendSTX]; 
					//return NO;
					[self error];
					break;	
				case GDM_NOECHO:
					msg = [msg substringFromIndex: 1];
					[log appendFormat: @"NOECHO (%@)", msg];
					// we send the password
					if (password) [output sendMSG: password];
					else [output sendSTX];
					break;	
				case GDM_SESS:
					msg = [msg substringFromIndex: 1];
					[log appendFormat: @"SESS (%@)", msg];
					[output sendMSG: [NSString stringWithFormat: @"%@.desktop", desktop]];
					break;	
				case GDM_LANG:
					[log appendString: @"LANG"];
					[output sendMSG: @""];					
					break;	
				case GDM_SSESS: // save session
					[log appendString: @"SAVE SESSION"];
					[output sendMSG: @"Y"];					
					break;	
				case GDM_SLANG: // save lang
					[log appendString: @"SAVE LANG"];
					[output sendMSG: @""];					
					break;	
				case GDM_QUIT: 
					[log appendString: @"QUIT"];
					[output sendMSG: @""];					
					valid = NO;
					//return YES;
					[delegate gdmLogged: self];
					break;	
			}
			[log appendString: @"\n"];
			[log writeToFile: @"/tmp/log" atomically: YES];
		}
	}
	if (waitForInput) [input waitForDataInBackgroundAndNotify];
}

- (void) sendLoginPassword
{  
	[output sendMSG: password];
}
@end

