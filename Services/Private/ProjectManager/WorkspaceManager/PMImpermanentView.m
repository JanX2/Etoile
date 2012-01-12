/**
 * Étoilé ProjectManager - WorkspaceManager - PMImpermanentView.m
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
#import "PMImpermanentView.h"
#import "PMWindowTracker.h"
#import <EtoileFoundation/EtoileFoundation.h>

#define NOTIFY_DELEGATE(sel) \
	if ([delegate respondsToSelector: @selector(sel)]) \
		[delegate sel self]

@implementation PMImpermanentView
- (id)initWithWindowTracker: (PMWindowTracker*)aTracker
{
	SUPERINIT;
	tracker = [aTracker retain];
	[tracker setDelegate: self];
	[self setIcon: [tracker windowPixmap]];
	[self setImage: [tracker windowPixmap]];
	[self setName: [tracker windowName]];
	return self;
}

- (void)setDelegate: (id<PMImpermanentViewDelegate>)aDelegate
{
	self->delegate = aDelegate;
}

- (void)dealloc
{
	[tracker setDelegate: nil];
	[tracker release];
	[image release];
	[icon release];
	[name release];
	[super dealloc];
}
- (void)trackedWindowActivated: (PMWindowTracker*)aTracker
{
	[self setName: [aTracker windowName]];
	NOTIFY_DELEGATE(viewActivated:);
}
- (void)trackedWindowDidShow: (PMWindowTracker*)aTracker
{
	NOTIFY_DELEGATE(viewDidShow:);
}
- (void)trackedWindowDidHide: (PMWindowTracker*)aTracker
{
	NOTIFY_DELEGATE(viewDidHide:);
}
- (void)trackedWindowDeactivated: (PMWindowTracker*)aTracker
{
	NOTIFY_DELEGATE(viewDeactivated:);
}
- (void)trackedWindowPixmapUpdated: (PMWindowTracker*)aTracker
{
	[self setImage: [tracker windowPixmap]];
	[self setIcon: [tracker windowPixmap]];
}
- (NSImage*)image
{
	return image;
}

- (NSImage*)icon
{
	return icon;
}
- (void)setImage: (NSImage*)aImage
{
	ASSIGN(image, aImage);
}
- (void)setIcon: (NSImage*)aIcon
{
	ASSIGN(icon, aIcon);
}
- (NSString*)name
{
	return name;
}

- (void)setName: (NSString*)newName
{
	ASSIGN(name, newName);
}

- (NSString*)displayName
{
	return [self name];
}

+ (ETEntityDescription*)newEntityDescription
{
	ETEntityDescription *desc = [self newBasicEntityDescription];
	if ([[desc name] isEqual: [PMImpermanentView className]] == NO)
		return desc;
	
	ETPropertyDescription *image = [ETPropertyDescription
		descriptionWithName: @"image"
		               type: (id)@"NSImage"];
	ETPropertyDescription *icon = [ETPropertyDescription
		descriptionWithName: @"icon"
		               type: (id)@"NSImage"];
	ETPropertyDescription *name = [ETPropertyDescription
		descriptionWithName: @"name"
		               type: (id)@"NSString"];
	[desc setPropertyDescriptions: A(image, icon, name)];
	return desc;
}

- (PMWindowTracker*)tracker
{
	return tracker;
}

- (NSArray*)propertyNames
{
	return [[super propertyNames] arrayByAddingObjectsFromArray: A(@"image", @"icon", @"name")];
}

- (NSSet*)observableKeyPaths
{
	return S(@"image", @"icon", @"name");
}
@end
