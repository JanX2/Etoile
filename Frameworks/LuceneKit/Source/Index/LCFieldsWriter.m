#include "LuceneKit/Index/LCFieldsWriter.h"
#include "LuceneKit/Index/LCFieldInfos.h"
#include "LuceneKit/Document/LCDocument.h"
#include "LuceneKit/Document/LCField.h"
#include "LuceneKit/Store/LCDirectory.h"
#include "LuceneKit/Store/LCIndexOutput.h"
#include "GNUstep.h"

@implementation LCFieldsWriter

- (id) initWithDirectory: (id <LCDirectory>) d
                  segment: (NSString *) segment
		  fieldInfos: (LCFieldInfos *) fn
{
  self = [self init];
  ASSIGN(fieldInfos, fn);
  ASSIGN(fieldsStream, [d createOutput: [segment stringByAppendingPathExtension: @"fdt"]]);
  ASSIGN(indexStream, [d createOutput: [segment stringByAppendingPathExtension: @"fdx"]]);
  return self;
}

- (void) close
{
  [fieldsStream close];
  [indexStream close];
}

- (void) addDocument: (LCDocument *) doc
{
  [indexStream writeLong: [fieldsStream filePointer]];

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
         if ([field isBinary])
           bits |= LCFieldsWriter_FIELD_IS_BINARY;
         if ([field isCompressed])
           bits |= LCFieldsWriter_FIELD_IS_COMPRESSED;
                
         [fieldsStream writeByte: bits];
                
         if ([field isCompressed]) {
#if 0 // FIXME: not supprt yet
                  // compression is enabled for the current field
                  byte[] data = null;
                  // check if it is a binary field
                  if (field.isBinary()) {
                    data = compress(field.binaryValue());
                  }
                  else {
                    data = compress(field.stringValue().getBytes("UTF-8"));
                  }
                  final int len = data.length;
                  fieldsStream.writeVInt(len);
                  fieldsStream.writeBytes(data, len);
#endif
          } else {
                  // compression is disabled for the current field
                  if ([field isBinary]) {
		    NSData *data = [field binaryValue];
                    int len = [data length];
		    [fieldsStream writeVInt: len];
		    [fieldsStream writeBytes: data length: len];
                  }
                  else {
		    [fieldsStream writeString: [field stringValue]];
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
