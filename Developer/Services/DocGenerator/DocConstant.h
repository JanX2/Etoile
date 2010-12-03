//
/** <title>DocConstant</title>

	<abstract>Represents documented constant in the doc element tree.</abstract>

	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2010
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "DocElement.h"
#import "GSDocParser.h"

@interface DocConstant : DocElement <GSDocParserDelegate>
{

}

@end
