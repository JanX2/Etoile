#ifndef __LUCENE_DOCUMENT_DATE_TOOLS__
#define __LUCENE_DOCUMENT_DATE_TOOLS__

#include <Foundation/Foundation.h>

typedef enum _LCResolution {
	LCResolution_YEAR = 1,
	LCResolution_MONTH,
	LCResolution_DAY,
	LCResolution_HOUR,
	LCResolution_MINUTE,
	LCResolution_SECOND,
	LCResolution_MILLISECOND
} LCResolution;

@interface NSString (LuceneKit_Document_Date)
+ (id) stringWithCalendarDate: (NSCalendarDate *) date
                   resolution: (LCResolution) res;
+ (id) stringWithTimeIntervalSince1970: (NSTimeInterval) time
                            resolution: (LCResolution) resolution;
- (NSTimeInterval) timeIntervalSince1970;
- (NSCalendarDate *) calendarDate;
@end

@interface NSCalendarDate (LuceneKit_Document_Date)
- (NSCalendarDate *) dateWithResolution: (LCResolution) resolution;
- (NSTimeInterval) timeIntervalSince1970WithResolution: (LCResolution) resolution;
@end

#endif /* __LUCENE_DOCUMENT_DATE_TOOLS__ */

