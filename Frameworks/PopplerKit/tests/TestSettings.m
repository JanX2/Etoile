
#import "TestSettings.h"

#ifdef GNUSTEP
NSString* kTestDocument = @"testdocument.pdf";
NSString* kTestRenderDirectory = @"rendered";
#else
NSString* kTestDocument = @"../../tests/testdocument.pdf";
NSString* kTestRenderDirectory = @"../../tests/rendered";
#endif

NSString* kNonExistentDocument = @"/nowhere/foo.pdf";
unsigned  kTestDocumentPageCount = 6;

