/**
 * Étoilé ProjectManager - XCBPropertyHelpers.m
 *
 * Copyright (C) 2010 Christopher Armstrong
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
#include <XCBKit/XCBPropertyHelpers.h>
#include <XCBKit/XCBAtomCache.h>

@implementation XCBWindow (XCBPropertyHelpers)
- (void)replaceProperty: (NSString*)propertyName atomList: (NSArray*)atomList
{
	XCBAtomCache *atomCache = [XCBAtomCache sharedInstance];
	xcb_atom_t *atom_list = calloc([atomList count], sizeof(xcb_atom_t));
	for (int i = 0; i < [atomList count]; i++)
	{
		atom_list[i] = [atomCache atomNamed: [atomList objectAtIndex: i]];
	}
	[self changeProperty: propertyName
	                type: @"ATOM"
	              format: 32
	                mode: XCB_PROP_MODE_REPLACE
	                data: atom_list
	               count: [atomList count]];
	free(atom_list);
}
@end

