#import "Tell.h"
#import "ScriptCenter.h"

@protocol block
- (id) value:(id) object;
@end

@implementation Tell
+ (void) application:(NSString*)anApp to:(id)aBlock
{
	[aBlock value:[ScriptCenter scriptDictionaryForApplication:anApp]];
}
@end
