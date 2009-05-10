#include <stdint.h>

typedef struct _XCBPoint
{
	int16_t x;
	int16_t y;
} XCBPoint;

typedef struct _XCBSize
{
	int16_t width;
	int16_t height;
} XCBSize;

typedef struct _XCBRect 
{
	XCBPoint origin;
	XCBSize size;
} XCBRect;

static const XCBRect XCBInvalidRect = {{0xffff, 0xffff}, {0xffff, 0xffff}};

static inline XCBRect XCBMakeRect(int16_t x,
                                  int16_t y,
                                  int16_t width,
                                  int16_t height)
{
	XCBRect rect = { {x, y}, {width, height} };
	return rect;
}

static inline NSString *XCBStringFromRect(XCBRect rect)
{
	return [NSString stringWithFormat:@"(%hd, %hd), (%hd, %hd)",
		   rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
}
