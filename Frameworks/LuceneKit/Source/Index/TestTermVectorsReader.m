#include "TestTermVectorsReader.h"
#include "Store/LCRAMDirectory.h"

@implementation TestTermVectorsReader

- (id) init
{
    self = [super init];
    writer = nil;
    //Must be lexicographically sorted, will do in setup, versus trying to maintain here
    testFields = [NSArray arrayWithObjects: @"f1", @"f2", @"f3", nil];
    testFieldsStorePos = [NSArray arrayWithObjects: [NSNumber numberWithBool: YES], [NSNumber numberWithBool: NO], [NSNumber numberWithBool: YES], [NSNumber numberWithBool: NO], nil];
    testFieldsStoreOff = [NSArray arrayWithObjects: [NSNumber numberWithBool: YES], [NSNumber numberWithBool: NO], [NSNumber numberWithBool: NO], [NSNumber numberWithBool: YES], nil];
    testTerms = [NSArray arrayWithObjects: @"this", @"is", @"a", @"test", nil];
    dir = [[LCRAMDirectory alloc] init];
    seg = @"testSegment";
    fieldInfos = [[LCFieldInfos alloc] init];
    return self;
}

#if 0
  protected void setUp() {
    for (int i = 0; i < testFields.length; i++) {
      fieldInfos.add(testFields[i], true, true, testFieldsStorePos[i], testFieldsStoreOff[i]);
    }
    
    for (int i = 0; i < testTerms.length; i++)
    {
      positions[i] = new int[3];
      for (int j = 0; j < positions[i].length; j++) {
        // poditions are always sorted in increasing order
        positions[i][j] = (int)(j * 10 + Math.random() * 10);
      }
      offsets[i] = new TermVectorOffsetInfo[3];
      for (int j = 0; j < offsets[i].length; j++){
        // ofsets are alway sorted in increasing order
        offsets[i][j] = new TermVectorOffsetInfo(j * 10, j * 10 + testTerms[i].length());
      }        
    }
    try {
      Arrays.sort(testTerms);
      for (int j = 0; j < 5; j++) {
        writer = new TermVectorsWriter(dir, seg, fieldInfos);
        writer.openDocument();

        for (int k = 0; k < testFields.length; k++) {
          writer.openField(testFields[k]);
          for (int i = 0; i < testTerms.length; i++) {
            writer.addTerm(testTerms[i], 3, positions[i], offsets[i]);      
          }
          writer.closeField();
        }
        writer.closeDocument();
        writer.close();
      }

    } catch (IOException e) {
      e.printStackTrace();
      assertTrue(false);
    }    
  }

  protected void tearDown() {

  }

  public void test() {
      //Check to see the files were created properly in setup
      assertTrue(writer.isDocumentOpen() == false);          
      assertTrue(dir.fileExists(seg + TermVectorsWriter.TVD_EXTENSION));
      assertTrue(dir.fileExists(seg + TermVectorsWriter.TVX_EXTENSION));
  }
  
  public void testReader() {
    try {
      TermVectorsReader reader = new TermVectorsReader(dir, seg, fieldInfos);
      assertTrue(reader != null);
      TermFreqVector vector = reader.get(0, testFields[0]);
      assertTrue(vector != null);
      String [] terms = vector.getTerms();
      assertTrue(terms != null);
      assertTrue(terms.length == testTerms.length);
      for (int i = 0; i < terms.length; i++) {
        String term = terms[i];
        //System.out.println("Term: " + term);
        assertTrue(term.equals(testTerms[i]));
      }
      
    } catch (IOException e) {
      e.printStackTrace();
      assertTrue(false);
    }
  }  
  
  public void testPositionReader() {
    try {
      TermVectorsReader reader = new TermVectorsReader(dir, seg, fieldInfos);
      assertTrue(reader != null);
      TermPositionVector vector;
      String [] terms;
      vector = (TermPositionVector)reader.get(0, testFields[0]);
      assertTrue(vector != null);      
      terms = vector.getTerms();
      assertTrue(terms != null);
      assertTrue(terms.length == testTerms.length);
      for (int i = 0; i < terms.length; i++) {
        String term = terms[i];
        //System.out.println("Term: " + term);
        assertTrue(term.equals(testTerms[i]));
        int [] positions = vector.getTermPositions(i);
        assertTrue(positions != null);
        assertTrue(positions.length == this.positions[i].length);
        for (int j = 0; j < positions.length; j++) {
          int position = positions[j];
          assertTrue(position == this.positions[i][j]);
        }
        TermVectorOffsetInfo [] offset = vector.getOffsets(i);
        assertTrue(offset != null);
        assertTrue(offset.length == this.offsets[i].length);
        for (int j = 0; j < offset.length; j++) {
          TermVectorOffsetInfo termVectorOffsetInfo = offset[j];
          assertTrue(termVectorOffsetInfo.equals(offsets[i][j]));
        }
      }
      
      TermFreqVector freqVector = reader.get(0, testFields[1]); //no pos, no offset
      assertTrue(freqVector != null);      
      assertTrue(freqVector instanceof TermPositionVector == false);
      terms = freqVector.getTerms();
      assertTrue(terms != null);
      assertTrue(terms.length == testTerms.length);
      for (int i = 0; i < terms.length; i++) {
        String term = terms[i];
        //System.out.println("Term: " + term);
        assertTrue(term.equals(testTerms[i]));        
      }
      
      
    } catch (IOException e) {
      e.printStackTrace();
      assertTrue(false);
    }
    catch (ClassCastException cce)
    {
      cce.printStackTrace();
      assertTrue(false);
    }
  }
  
  public void testOffsetReader() {
    try {
      TermVectorsReader reader = new TermVectorsReader(dir, seg, fieldInfos);
      assertTrue(reader != null);
      TermPositionVector vector = (TermPositionVector)reader.get(0, testFields[0]);
      assertTrue(vector != null);
      String [] terms = vector.getTerms();
      assertTrue(terms != null);
      assertTrue(terms.length == testTerms.length);
      for (int i = 0; i < terms.length; i++) {
        String term = terms[i];
        //System.out.println("Term: " + term);
        assertTrue(term.equals(testTerms[i]));
        int [] positions = vector.getTermPositions(i);
        assertTrue(positions != null);
        assertTrue(positions.length == this.positions[i].length);
        for (int j = 0; j < positions.length; j++) {
          int position = positions[j];
          assertTrue(position == this.positions[i][j]);
        }
        TermVectorOffsetInfo [] offset = vector.getOffsets(i);
        assertTrue(offset != null);
        assertTrue(offset.length == this.offsets[i].length);
        for (int j = 0; j < offset.length; j++) {
          TermVectorOffsetInfo termVectorOffsetInfo = offset[j];
          assertTrue(termVectorOffsetInfo.equals(offsets[i][j]));
        }
      }
      
      
    } catch (IOException e) {
      e.printStackTrace();
      assertTrue(false);
    }
    catch (ClassCastException cce)
    {
      cce.printStackTrace();
      assertTrue(false);
    }
  }
  

  /**
   * Make sure exceptions and bad params are handled appropriately
   */ 
  public void testBadParams() {
    try {
      TermVectorsReader reader = new TermVectorsReader(dir, seg, fieldInfos);
      assertTrue(reader != null);
      //Bad document number, good field number
      reader.get(50, testFields[0]);
      assertTrue(false);      
    } catch (IOException e) {
      assertTrue(true);
    }
    try {
      TermVectorsReader reader = new TermVectorsReader(dir, seg, fieldInfos);
      assertTrue(reader != null);
      //Bad document number, no field
      reader.get(50);
      assertTrue(false);      
    } catch (IOException e) {
      assertTrue(true);
    }
    try {
      TermVectorsReader reader = new TermVectorsReader(dir, seg, fieldInfos);
      assertTrue(reader != null);
      //good document number, bad field number
      TermFreqVector vector = reader.get(0, "f50");
      assertTrue(vector == null);      
    } catch (IOException e) {
      assertTrue(false);
    }
  }    
#endif

@end
