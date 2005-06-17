/* Author: Quentin Mathe <qmathe@club-internet.fr> */

#import <LuceneKit/Store/LCFSDirectory.h>


@interface LCMMapDirectory : LCFSDirectory
{
    
}

/* Overriden methods */
- (LCIndexInput *) openInput: (NSString *)name;

@end
