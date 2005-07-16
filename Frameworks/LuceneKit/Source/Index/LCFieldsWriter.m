#include <LuceneKit/Index/LCFieldsWriter.h>
#include <LuceneKit/Store/LCIndexOutput.h>
#include <LuceneKit/Util/NSData+Additions.h>
#include <LuceneKit/GNUstep/GNUstep.h>

@implementation LCFieldsWriter

- (id) initWithDirectory: (id <LCDirectory>) d
				 segment: (NSString *) segment
			  fieldInfos: (LCFieldInfos *) fn
{
	self = [self init];
	ASSIGN(fieldInfos, fn);
	NSString *f = [segment stringByAppendingPathExtension: @"fdt"];
	ASSIGN(fieldsStream, [d createOutput: f]);
	f = [segment stringByAppendingPathExtension: @"fdx"];
	ASSIGN(indexStream, [d createOutput: f]);
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

- (void) addDocument: (LCDocument *) doc
{
	[indexStream writeLong: [fieldsStream offsetInFile]];
	
	int storedCount = 0;
	NSEnumerator *fields = [doc fieldEnumerator];
	LCField *field;
	while ((field = [fields nextObject])) 
    {
		if ([field isStored])
			storedCount++;
    }
	[fieldsStream writeVInt: storedCount];
	
	fields = [doc fieldEnumerator];
	while ((field = [fields nextObject])) 
    {
		if([field isStored]){
			[fieldsStream writeVInt: [fieldInfos fieldNumber: [field name]]];
			
			char bits = 0;
			if ([field isTokenized])
				bits |= LCFieldsWriter_FIELD_IS_TOKENIZED;
			if ([field isData])
				bits |= LCFieldsWriter_FIELD_IS_BINARY;
			if ([field isCompressed])
				bits |= LCFieldsWriter_FIELD_IS_COMPRESSED;
			
			[fieldsStream writeByte: bits];
			if ([field isCompressed]) {
				// compression is enabled for the current field
				NSData *data = nil;
				// check if it is a binary field
				if ([field isData]) {
                    ASSIGN(data, [field data]);
				}
				else {
					ASSIGN(data, [[field string] dataUsingEncoding: NSUTF8StringEncoding]);
				}
				ASSIGN(data, [data compressedData]);
				int len = [data length];
				[fieldsStream writeVInt: len];
				[fieldsStream writeBytes: data length: len];
			} else {
				// compression is disabled for the current field
				if ([field isData]) {
					NSData *data = [field data];
                    int len = [data length];
					[fieldsStream writeVInt: len];
					[fieldsStream writeBytes: data length: len];
				}
				else {
					[fieldsStream writeString: [field string]];
				}
			}
		}
	}
}

#if 0
private final byte[] compress (byte[] input) {
	
	// Create the compressor with highest level of compression
	Deflater compressor = new Deflater();
	compressor.setLevel(Deflater.BEST_COMPRESSION);
	
	// Give the compressor the data to compress
	compressor.setInput(input);
	compressor.finish();
	
	/*
	 * Create an expandable byte array to hold the compressed data.
	 * You cannot use an array that's the same size as the orginal because
	 * there is no guarantee that the compressed data will be smaller than
	 * the uncompressed data.
	 */
	ByteArrayOutputStream bos = new ByteArrayOutputStream(input.length);
	
	// Compress the data
	byte[] buf = new byte[1024];
	while (!compressor.finished()) {
        int count = compressor.deflate(buf);
        bos.write(buf, 0, count);
	}
	
	compressor.end();
	
	// Get the compressed data
	return bos.toByteArray();
}
#endif

@end
