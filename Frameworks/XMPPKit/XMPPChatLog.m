//
//  XMPPChatLog.m
//  Jabber
//
//  Created by David Chisnall on 25/11/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XMPPChatLog.h"
#import "XMPPError.h"

NSString * logBasePath;
NSMutableDictionary * chatLogs;

static NSDictionary * ERROR_STYLE;
@implementation XMPPChatLog
+ (void)initialize
{
        //TODO: Set this using portable filesystem functions
        NSString * processName = [[[NSProcessInfo processInfo] arguments] objectAtIndex:0];
        NSRange lastSlash = [processName rangeOfString:@"/" options:NSBackwardsSearch];
        if(lastSlash.location != NSNotFound)
        {
                processName = [processName substringFromIndex:lastSlash.location + 1];
        }
        //Set the base path to be ~/Library/Logs/AppName - This allows multiple apps to use the same library but store their logs in different places
        logBasePath = [NSString stringWithFormat:@"%@/logs/%@", 
                                        [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0],
                                        processName];
        if(![[NSFileManager defaultManager] fileExistsAtPath:logBasePath])
        {
                [[NSFileManager defaultManager] createDirectoryAtPath:logBasePath
                                                                                                   attributes:nil];
        }
        logBasePath = [logBasePath stringByAppendingString:@"/"];
        chatLogs = [[NSMutableDictionary alloc] init];
        ERROR_STYLE = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSColor colorWithCalibratedRed:1.0f 
                                                                  green:0.0f
                                                                   blue:0.0f
                                                                  alpha:1.0f],
                NSForegroundColorAttributeName,
                nil];
}

+ (void) setLogBasePath:(NSString*)aPath
{
        if([aPath characterAtIndex:[aPath length]-1] == '/')
        {
                logBasePath = aPath;
        }
        else
        {
                logBasePath = [aPath stringByAppendingString:@"/"];
        }
}

+ (id) chatLogWithPerson:(XMPPPerson*)aPerson
{
        return [[XMPPChatLog alloc] initWithPerson:aPerson];
}
- (void) initLog
{
        NSString * logFolder = [[NSString alloc] initWithFormat:@"%@%@/%@", 
                logBasePath, 
                [remoteEntity group], 
                [remoteEntity name]];
        //If the log folder doesn't exist, create it
        if(![[NSFileManager defaultManager] fileExistsAtPath:logFolder])
        {
                NSString * groupLogPath = [NSString stringWithFormat:@"%@%@",
                        logBasePath,
                        [remoteEntity group]];
                //We can't create the log folder if the folder it's supposed to be in doesn't exist.
                if(![[NSFileManager defaultManager] fileExistsAtPath:groupLogPath])
                {
                        [[NSFileManager defaultManager] createDirectoryAtPath:groupLogPath
                                                                                                           attributes:nil];
                }
                [[NSFileManager defaultManager] createDirectoryAtPath:logFolder
                                                                                                   attributes:nil];
        }
        if(isXML)
        {
                logFileName = [[NSString alloc] initWithFormat:@"%@/%@.xml",
                        logFolder, 
                        [today descriptionWithCalendarFormat:@"%y-%m-%d (%a)"]];        
                //TODO: Initialise log
        }
        else
        {
                logFileName = [[NSString alloc] initWithFormat:@"%@/%@.rtf", 
                        logFolder, 
                        [today descriptionWithCalendarFormat:@"%y-%m-%d (%a)"]];        
        }
        //Check if file exists and load log if it does.
        NSFileHandle * logFile = [NSFileHandle fileHandleForReadingAtPath:logFileName];
        
        if(logFile != nil)
        {
                if(isXML)
                {
                        //TODO: Read XML file
                }
                else
                {
                        log = [[NSMutableAttributedString alloc] initWithRTF:[logFile readDataToEndOfFile]  documentAttributes:NULL];
                }
        }
        else
        {
                if(isXML)
                {
                        //TODO: Read XML file
                }
                else
                {
                        log = [[NSMutableAttributedString alloc] init];
                }                        
        }
}
- (id) initWithPerson:(XMPPPerson*)person useXMLFormatLog:(BOOL)_xml
{
        self = [self init];
        if(self == nil)
        {
                return nil;
        }
        isXML = _xml;
        remoteEntity = person;
        [self initLog];
        return self;
}


+ (id) chatLogWithPerson:(XMPPPerson*)person useXMLFormatLog:(BOOL)_xml
{
        return  [[XMPPChatLog alloc] initWithPerson:person useXMLFormatLog:_xml];
}

- (id) initWithPerson:(XMPPPerson*)aPerson
{
        return [self initWithPerson:(XMPPPerson*)aPerson useXMLFormatLog:NO];
}

- (id) init
{
        self = [super init];
        if(self == nil)
        {
                return nil;
        }
        isXML = NO;
        today = [[NSCalendarDate alloc] init];
        logFileName = nil;
        remoteEntity = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                                                         selector:@selector(autoSave:)
                                                                                                 name:@"NSApplicationWillTerminateNotification"
                                                                                           object:NSApp];
        return self;
}

- (BOOL) update
{
        //Check if today is stil today
        if([today dayOfCommonEra] != [[NSCalendarDate date] dayOfCommonEra])
        {
                NSLog(@"Rolling over chat logs");
                [self save];
                today = [[NSCalendarDate alloc] init];
                [self initLog];
                return YES;
        }
        return NO;
}

- (void) autoSave:(NSTimer*)_sender
{
        autoSaveTimer = nil;
        if(![self update])
        {
                [self save];
        }
}
- (id) logErrorMessage:(XMPPMessage*)aMessage
{
        XMPPError * error = [aMessage error];
        NSCalendarDate * timestamp = [[aMessage timestamp] time];
        if(timestamp == nil)
        {
                timestamp = [NSCalendarDate calendarDate];
        }        
        NSString * errorString = [NSString stringWithFormat:@"(%@) Error %d:\n%@\n",
                [timestamp descriptionWithCalendarFormat:@"%H:%M:%S"],
                [error errorCode],
                [[error errorMessage] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        NSAttributedString * errorMessage = [[NSAttributedString alloc] initWithString:errorString
                                                                                                                                                attributes:ERROR_STYLE];
        [log appendAttributedString:errorMessage];
        return errorMessage;
}
- (id) logMessage:(XMPPMessage*)aMessage
{
        if(isXML)
        {
                //TODO:  Implement this
                return nil;
        }
        else
        {
                if(autoSaveTimer == nil)
                {
                        autoSaveTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)15.0
                                                                                                                          target:self
                                                                                                                        selector:@selector(autoSave:)
                                                                                                                        userInfo:nil
                                                                                                                         repeats:NO];
                }                
                if([aMessage type] == MESSAGE_TYPE_ERROR)
                {
                        return [self logErrorMessage:aMessage];
                }
                //TODO:  Make `you / he says' message colours configurable.
                //TODO:  Localise messages
                BOOL emote = ([[aMessage body] length] >= 3 && [[[aMessage body] substringToIndex:3] isEqualToString:@"/me"]);
                NSMutableAttributedString * messageText;
                NSColor * headerColour;
                NSCalendarDate * timestamp = [[aMessage timestamp] time];

                
                if(timestamp == nil)
                {
                        timestamp = [NSCalendarDate calendarDate];
                }

                NSMutableString * headerString = [NSMutableString stringWithFormat:@"(%@) ",[timestamp descriptionWithCalendarFormat:@"%H:%M:%S"]];
                
                if([aMessage in])
                {
                        headerColour = [NSColor colorWithCalibratedRed:0.0f 
                                                                                                         green:0.0f
                                                                                                          blue:1.0f
                                                                                                         alpha:1.0f];
                        if(emote)
                        {
                                [headerString appendString:[NSString stringWithFormat:@"%@ ", [remoteEntity name]]];
                        }
                        else
                        {
                                [headerString appendString:[NSString stringWithFormat:@"%@ says:\n", [remoteEntity name]]];
                        }
                }
                else
                {
                        headerColour = [NSColor colorWithCalibratedRed:1.0f 
                                                                                                         green:0.0f
                                                                                                          blue:0.0f
                                                                                                         alpha:1.0f];
                        if(emote)
                        {
                                [headerString appendString:@"Your Avatar "];
                        }
                        else
                        {
                                [headerString appendString:@"You say:\n"];
                        }
                }
                messageText = [[NSMutableAttributedString alloc] initWithString:headerString];
                NSAttributedString * attributedMessageBody = [aMessage HTMLBody];
                if(emote)
                {
                        attributedMessageBody = [attributedMessageBody attributedSubstringFromRange:NSMakeRange(3,[[aMessage body] length]-3)];
                        //messageBody = [messageBody stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; 
                }
                [messageText addAttribute:NSForegroundColorAttributeName value:headerColour range:NSMakeRange(0,[messageText length])];
                
                [messageText appendAttributedString:attributedMessageBody];
                [messageText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];

                [log appendAttributedString:messageText];
                return messageText;
        }
}

- (BOOL) isXML
{
        return isXML;
}

- (BOOL) save
{
        NS_DURING
        {
                if(isXML)
                {
                        //TODO:  Implement this
                }
                else
                {
                        NSLog(@"Saving log: \"%@\"", logFileName);
                        NSFileHandle * logFile = [[NSFileHandle alloc] initWithFileDescriptor:fileno(fopen([logFileName UTF8String], "w")) closeOnDealloc:YES];
                        [logFile writeData:[log RTFFromRange:NSMakeRange(0,[(NSAttributedString*)log length]) documentAttributes:nil]];
                }
        }
        NS_HANDLER
        {
                return NO;        
        }
        NS_ENDHANDLER
        return YES;
}
+ (NSString*) logPath
{
        return logBasePath;
}
- (id) getLogForToday
{
        return log;
}
@end
