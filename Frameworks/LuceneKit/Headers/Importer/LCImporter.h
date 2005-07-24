#ifndef __LuceneKit_Importer__
#define __LuceneKit_Importer__

@protocol LCImporter <NSObject>
/** Return the attributes of file.
 * This method mimic Apple's Spotlight API:
 *   Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, 
 *                              CFStringRef contentTypeUTI, CFStringRef pathToFile)
 * path: the file path.
 * type: the file type.
 * attributes: place to store attributes.
 */
- (BOOL) metadataForFile: (NSString *) path type: (NSString *) type 
			  attributes: (NSMutableDictionary *) attributes;

/** Return the file type this importer will works.
 * More than one importer can register the same type.
 * Files with this type will be indexed twice.
 */
- (NSArray *) types;

/** Each kind of data has a key attribute for identification.
 * The value for this key attribute must to be unique.
 * For example, the keyAttribute of a file is path.
 * For contact, it must be something unique.
 * This attribute must exists in the attributes return by -metadataForFile:type:attributes:
 */
- (NSString *) keyAttribute;

/** Use these attributes to determine whether an file should be reindex.
 * This attributes will be stored as it is.
 * The more updateAttributes, the bigger the index data.
 * If updateAttributes is nil, file will always be indexed.
 */
- (NSArray *) attributesForUpdate;

@end

#endif /*  __LuceneKit_Importer__ */
