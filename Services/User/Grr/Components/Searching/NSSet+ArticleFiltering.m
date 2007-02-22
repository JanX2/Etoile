/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>
   
   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License version 2 as published by the Free Software Foundation.
   
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "NSSet+ArticleFiltering.h"
#import "Article.h"

@implementation NSSet (ArticleFiltering)

/**
 * Searches the articles contained in the receiver for the given string.
 * Returns the result set of articles that matched the search string.
 * If the search string is nil or empty, the receiver itself is returned.
 */
- (NSSet*) subsetFilteredForString: (NSString*) searchString
{
	if (searchString == nil || [searchString length] == 0) {
		return self;
	}
	
	NSArray* articles = [self allObjects];

	unsigned subsetSize = 0;
	id<Article>* subsetObjects = malloc( sizeof(id) * [articles count] );
	
	int i;
	for (i=0; i<[articles count]; i++) {
	    id<Article> article = [articles objectAtIndex: i];
	    
	    NSString* headline = [article headline];
	    if (headline != nil) {
	        if ([headline rangeOfString: searchString].location != NSNotFound) {
	            subsetObjects[subsetSize] = article;
	            subsetSize ++;
	        }
	    }
	}
	NSLog(@"filtered down to %d of %d articles.", subsetSize, [articles count]);
	NSSet* resultSet = [NSSet setWithObjects: subsetObjects count: subsetSize];

	free( subsetObjects );

	return resultSet;
}

@end

