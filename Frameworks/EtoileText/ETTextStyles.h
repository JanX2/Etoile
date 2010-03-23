#import <EtoileFoundation/Macros.h>

@class NSString;
/** Constants for globally-defined types. */

/**
 * The name of the style.
 */
EMIT_STRING(ETTextStyleName);

/**
 * Heading type.  The type may also have a ETTextHeadingLevel key representing
 * the depth of the heading, with 0 indicating a top level heading. 
 */
EMIT_STRING(ETTextHeadingType);
/**
 * The depth of a specific heading.  The interpretation of the depth is
 * specific to the document type.  For example, in a book it might be a part,
 * chapter, section and so on, while in a short document it may be section,
 * subsection, and so on.
 */
EMIT_STRING(ETTextHeadingLevel);
/**
 * A paragraph of text.  
 */
EMIT_STRING(ETTextParagraphType);
/**
 * A reference to some other document, or part of this document.
 */
EMIT_STRING(ETTextLinkType);
