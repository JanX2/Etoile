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

#import "FontsComponent.h"

@implementation FontsComponent

-(void) awakeFromNib
{
    NSLog(@"Font component awoke from Nib.");
    NSFontManager* fontManager = [NSFontManager sharedFontManager];
    
    NSArray* fonts = [[fontManager availableFontNamesWithTraits: 0]
        sortedArrayUsingSelector: @selector(compare:)];
    
    NSArray* sizeArray = [NSArray arrayWithObjects:
        [NSNumber numberWithFloat: 7],
        [NSNumber numberWithFloat: 8],
        [NSNumber numberWithFloat: 9],
        [NSNumber numberWithFloat: 10],
        [NSNumber numberWithFloat: 11],
        [NSNumber numberWithFloat: 12],
        [NSNumber numberWithFloat: 13],
        [NSNumber numberWithFloat: 14],
        [NSNumber numberWithFloat: 16],
        [NSNumber numberWithFloat: 18],
        [NSNumber numberWithFloat: 20],
        [NSNumber numberWithFloat: 22],
        [NSNumber numberWithFloat: 24],
        [NSNumber numberWithFloat: 36],
        [NSNumber numberWithFloat: 48],
        nil
    ];
    
    [feedTableFontBox setNameOptions: fonts];
    [feedTableFontBox setSizeOptions: sizeArray];
    [feedTableFontBox attachToNameDefault: @"RSSReaderFeedListFontDefaults"];
    [feedTableFontBox attachToSizeDefault: @"RSSReaderFeedListSizeDefaults"];
    
    [articleTableFontBox setNameOptions: fonts];
    [articleTableFontBox setSizeOptions: sizeArray];
    [articleTableFontBox attachToNameDefault: @"RSSReaderArticleListFontDefaults"];
    [articleTableFontBox attachToSizeDefault: @"RSSReaderArticleListSizeDefaults"];
    
    [articleFontBox setNameOptions: fonts];
    [articleFontBox setSizeOptions: sizeArray];
    [articleFontBox attachToNameDefault: @"RSSReaderArticleContentFontDefaults"];
    [articleFontBox attachToSizeDefault: @"RSSReaderArticleContentSizeDefaults"];
    
    [articleFixedFontBox setNameOptions: fonts];
    [articleFixedFontBox setSizeOptions: sizeArray];
    [articleFixedFontBox attachToNameDefault: @"RSSReaderFixedArticleContentFontDefaults"];
    [articleFixedFontBox attachToSizeDefault: @"RSSReaderFixedArticleContentSizeDefaults"];
    
    // Load font image and give name
    NSString* imgPath = [[NSBundle bundleForClass: [self class]]
        pathForResource: @"Fonts" ofType: @"tiff" ];
    NSAssert1([imgPath length] > 0, @"Bad image path %@", imgPath);
    NSImage* fontsImage = [[NSImage alloc] initWithContentsOfFile: imgPath];
    NSAssert(fontsImage != nil, @"\"Fonts\" image couldn't be loaded from the resources.");
    [fontsImage setName: @"Fonts"];
}


// ----------------------------------------------------
//    PreferencePanel methods
// ----------------------------------------------------
-(NSString*) prefPaneName
{
    return @"Fonts";
}

-(NSImage*) prefPaneIcon
{
	return [NSImage imageNamed: @"Fonts"];
}

@end
