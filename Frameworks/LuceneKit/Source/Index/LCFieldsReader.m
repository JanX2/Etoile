#include <LuceneKit/Index/LCFieldsReader.h>
#include <LuceneKit/Index/LCFieldsWriter.h>
#include <LuceneKit/Store/LCDirectory.h>
#include <LuceneKit/Store/LCIndexInput.h>
#include <LuceneKit/Util/NSData+Additions.h>
#include <LuceneKit/GNUstep/GNUstep.h>

/**
* Class responsible for access to stored document fields.
 *
 * It uses &lt;segment&gt;.fdt and &lt;segment&gt;.fdx; files.
 *
 * @version $Id$
 */
@implementation LCFieldsReader

- (id) initWithDirectory: (id <LCDirectory>) d
				 segment: (NSString *) segment
			  fieldInfos: (LCFieldInfos *) fn
{
	self = [super init];
	ASSIGN(fieldInfos, fn);
	ASSIGN(fieldsStream, [d openInput: [segment stringByAppendingPathExtension: @"fdt"]]);
	ASSIGN(indexStream, [d openInput: [segment stringByAppendingPathExtension: @"fdx"]]);
	size = (int)([indexStream length]/8);
	return self;
}

- (void) dealloc
{
	DESTROY(fieldInfos);
	DESTROY(fieldsStream);
	DESTROY(indexStream);
	[super dealloc];
}

- (void) close
{
	[fieldsStream close];
	[indexStream close];
}

- (int) size
{
	return size;
}

- (LCDocument *) document: (int) n
{
	[indexStream seek: (n * 8L)];
	long position = [indexStream readLong];
	[fieldsStream seek: position];
	
	LCDocument *doc = [[LCDocument alloc] init];
	int numFields = [fieldsStream readVInt];
	int i, fieldNumber;
	for (i = 0; i < numFields; i++) 
    {
		fieldNumber = [fieldsStream readVInt];
		LCFieldInfo *fi = [fieldInfos fieldInfoWithNumber: fieldNumber];
		
		char bits = [fieldsStream readByte];
		
		BOOL compressed = (bits & LCFieldsWriter_FIELD_IS_COMPRESSED) != 0;
		BOOL tokenize = (bits & LCFieldsWriter_FIELD_IS_TOKENIZED) != 0;
		
		if ((bits & LCFieldsWriter_FIELD_IS_BINARY) != 0) {
			long len = [fieldsStream readVInt];
			NSMutableData *b = [[NSMutableData alloc] init];
			[fieldsStream readBytes: b offset: 0 length: len];
			if (compressed)
			{
				NSData *d = [b decompressedData];
				if (d)
				{
					LCField *field = [[LCField alloc] initWithName: [fi name]
															 value: d
															 store: LCStore_Compress];
					[doc addField: field];
					DESTROY(field);
				//doc.add(new Field(fi.name, uncompress(b), Field.Store.COMPRESS));
				}
			}
			else
			{
				LCField *field = [[LCField alloc] initWithName: [fi name]
														 value: AUTORELEASE([b copy])
														 store: LCStore_YES];
				[doc addField: field];
				DESTROY(field);
			}
			DESTROY(b);
		}
		else {
			LCIndex_Type index;
			LCStore_Type store = LCStore_YES;
			
			if ([fi isIndexed] && tokenize)
				index = LCIndex_Tokenized;
			else if ([fi isIndexed] && !tokenize)
				index = LCIndex_Untokenized;
			else
				index = LCIndex_NO;
			
			if (compressed) {
				store = LCStore_Compress;
				int len = [fieldsStream readVInt];
				NSMutableData *b = [[NSMutableData alloc] init];
				[fieldsStream readBytes: b offset: 0 length: len];
				NSString *s = [[NSString alloc] initWithData: [b decompressedData] encoding: NSUTF8StringEncoding];
				LCField *field = [[LCField alloc] initWithName: [fi name]
														string: s
														 store: store
														 index: index
													termVector: ([fi isTermVectorStored] ? LCTermVector_YES : LCTermVector_NO)];
				[doc addField: field];
				DESTROY(field);
				DESTROY(b);
#if 0
				doc.add(new Field(fi.name,      // field name
								  new String(uncompress(b), "UTF-8"), // uncompress the value and add as string
								  store,
								  index,
								  fi.storeTermVector ? Field.TermVector.YES : Field.TermVector.NO));
#endif
			}
			else // Not compressed
			{
				LCField *field = [[LCField alloc] initWithName: [fi name]
														string: [fieldsStream readString]
														 store: store
														 index: index
													termVector: ([fi isTermVectorStored] ? LCTermVector_YES : LCTermVector_NO)];
				[doc addField: field];
				DESTROY(field);
			}
		}
    }
	
    return AUTORELEASE(doc);
}

#if 0
private final byte[] uncompress(final byte[] input)
throws IOException
{
	
    Inflater decompressor = new Inflater();
    decompressor.setInput(input);
	
    // Create an expandable byte array to hold the decompressed data
    ByteArrayOutputStream bos = new ByteArrayOutputStream(input.length);
	
    // Decompress the data
    byte[] buf = new byte[1024];
    while (!decompressor.finished()) {
		try {
			int count = decompressor.inflate(buf);
			bos.write(buf, 0, count);
		}
		catch (DataFormatException e) {
			// this will happen if the field is not compressed
			throw new IOException ("field data are in wrong format: " + e.toString());
		}
    }
	
    decompressor.end();
    
    // Get the decompressed data
    return bos.toByteArray();
}
#endif

@end
