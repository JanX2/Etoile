#import <EtoileFoundation/Macros.h>

@class NSString;
/** Constants for globally-defined types. */

/**
 * The name of the style.
 */
EMIT_STRING(kETTextStyleName);

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
EMIT_STRING(kETTextHeadingLevel);
/**
 * A paragraph of text.  
 */
EMIT_STRING(ETTextParagraphType);
/**
 * A reference to some other document, or part of this document.  Should
 * contain a value associated with the kETTextLinkName key providing the name
 * of the target.  
 */
EMIT_STRING(ETTextLinkType);
/**
 * A section that may be referenced elsewhere.  
 */
EMIT_STRING(ETTextLinkTargetType);
/**
 * Text to be associated with this link in the index.
 */
EMIT_STRING(kETTextLinkIndexText);
/**
 * Key indicating the name of this link.  For link targets, this must be a
 * string or UUID.  For links, this may also be an NSURL indicating a foreign
 * resource.
 */
EMIT_STRING(kETTextLinkName);
/**
 * This node is imported from an external source.  The text contents, if they
 * exist, should not be regarded as the authoritative version.
 */
EMIT_STRING(ETTextForeignImportType);
/**
 * The location of the original for a foreign import.  This may be a CoreObject
 * reference, a URL, or a path.
 */
EMIT_STRING(kETTextSourceLocation);
/**
 * The first line to use when importing text from an external source.
 */
EMIT_STRING(kETTextFirstLine);
/**
 * The last line to use when importing text from an external source.
 */
EMIT_STRING(kETTextLastLine);
/**
 * A footnote.  When typesetting, the text in this section should be replaced
 * with a reference number and added to the end of the current page.
 */
EMIT_STRING(ETTextFootnoteType);
