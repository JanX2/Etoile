#ifndef __LuceneKit_LCMetadata_Attribute__
#define __LuceneKit_LCMetadata_Attribute__

#include <Foundation/NSString.h>

/* These attributes will be stored in index data. */
  /* Importer usually doesn't set LCMetadataChangeDateAttribute. LCIndexManager will do. */
static NSString *LCMetadataChangeDateAttribute = @"LCMetadataChangeDateAttribute";
static NSString *LCContentCreationDateAttribute = @"LCContentCreationDateAttribute";
static NSString *LCContentModificationDateAttribute = @"LCContentModificationDateAttribute";
static NSString *LCContentTypeAttribute = @"LCContentTypeAttribute";
static NSString *LCCreatorAttribute = @"LCCreatorAttribute";
static NSString *LCEmailAddressAttribute = @"LCEmailAddressAttribute";
static NSString *LCIdentifierAttribute = @"LCIdentifierAttribute";
static NSString *LCPathAttribute = @"LCPathAttribute";

/* These attributes will NOT be stored in index data */
static NSString *LCTextContentAttribute = @"LCTextContentAttribute";

#endif /*  __LuceneKit_LCMetadata_Attribute__ */
