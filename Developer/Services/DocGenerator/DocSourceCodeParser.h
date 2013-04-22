/*
	Copyright (C) 2013 Muhammad Hussein Nasrollahpour

	Author:  Muhammad Hussein Nasrollahpour <iapplechocolate@me.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <SourceCodeKit/SourceCodeKit.h>
#import "DocPageWeaver.h"

@interface DocSourceCodeParser : NSObject <DocSourceParsing>
{
    @private
	SCKSourceCollection *sourceCollection;
    SCKClangSourceFile *sourceFile;
    id <DocWeaving> pageWeaver;
}

@end
