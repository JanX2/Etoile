/** <title>ETRSSArticle.h</title>
 
	<abstract></abstract>
	
	Copyright (C) 2009 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  09-09-13
	License: Modified BSD (see COPYING)
 */

#import <RSSKit/RSSKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "ETMessage.h"

@interface ETNewsArticle : ETMessage
{
	RSSArticle *_article;
}

+ (ETNewsArticle *)articleWithRSSArticle: (RSSArticle *)article;

- (id)initWithRSSArticle: (RSSArticle *)article;


@end
