/**
 * Étoilé ProjectManager - XCBDamage.m
 *
 * Copyright (C) 2010 Christopher Armstrong <carmstrong@fastmail.com.au>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 **/
#import "XCBDrawable.h"
#import "XCBDamage.h"
#import "XCBConnection.h"
#import "XCBExtension.h"
#import "XCBFixes.h"

#import <EtoileFoundation/EtoileFoundation.h>

@implementation XCBDamage
+ (void)initializeExtensionWithConnection: (XCBConnection*)connection;
{
	static const char *extensionName = "DAMAGE";
	NSObject *delegate = [connection delegate];
	xcb_query_extension_reply_t* reply;
	
	reply = XCBInitializeExtension(
			connection,
			extensionName);

	xcb_damage_query_version_cookie_t version_cookie = 
		xcb_damage_query_version([connection connection], 
			XCB_DAMAGE_MAJOR_VERSION,
			XCB_DAMAGE_MINOR_VERSION);
	xcb_damage_query_version_reply_t* version_reply = 
		xcb_damage_query_version_reply(
				[connection connection], version_cookie, NULL);
	if (!XCBCheckExtensionVersion(
				XCB_DAMAGE_MAJOR_VERSION,
				XCB_DAMAGE_MINOR_VERSION,
				version_reply->major_version,
				version_reply->minor_version))
	{
		free(reply);
		free(version_reply);
		[[NSException 
			exceptionWithName: XCBExtensionNotPresentException
			           reason: @"Unable to find the damage extension with the version required."
			         userInfo: [NSDictionary dictionary]]
			raise];
	}

	if ([delegate respondsToSelector: @selector(XCBConnection:damageNotify:)])
	{
		[XCBConn setSelector: @selector(XCBConnection:damageNotify:)
		           forXEvent: reply->first_event + XCB_DAMAGE_NOTIFY];
		NSLog(@"Registering damageNotify: handler for delegate.");
	}
	NSLog(@"Initialized damage extension for connection %@", connection);
	free(version_reply);
	free(reply);	
}

- (id)initWithDrawable: (NSObject<XCBDrawable>*)drawable
           reportLevel: (xcb_damage_report_level_t)reportLevel;
{
	SUPERINIT;
	damage = xcb_generate_id([XCBConn connection]);
	xcb_damage_create([XCBConn connection], damage, [drawable xcbDrawableId], reportLevel);
	return self;
}
- (id)copyWithZone: (NSZone*)zone
{
	return [self retain];
}
- (void)dealloc
{
	xcb_damage_destroy([XCBConn connection], damage);
	[super dealloc];
}
+ (XCBDamage*)damageWithDrawable: (NSObject<XCBDrawable>*)drawable
                     reportLevel: (xcb_damage_report_level_t)reportLevel;
{
	return [[[self alloc]
		initWithDrawable: drawable
		     reportLevel: reportLevel]
		autorelease];
}

- (xcb_damage_damage_t)xcbDamageId
{
	return damage;
}
- (void)subtractWithRepair: (XCBFixesRegion*)repair 
                     parts: (XCBFixesRegion*)parts;
{
	xcb_xfixes_region_t repair_id = 0, parts_id = 0;
	if (repair)
		repair_id = [repair xcbXFixesRegionId];
	if (parts)
		parts_id = [parts xcbXFixesRegionId];
	xcb_damage_subtract([XCBConn connection],
			damage,
			repair_id,
			parts_id);
}
@end
