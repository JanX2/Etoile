
@interface ETTeXSimpleHandler : ETTeXHandler
{
	BOOL isStarted;
}
+ (void)setTextType: (NSString*)aType forTeXCommand: (NSString*)aCommand;
@end
@interface ETTeXNonNestedHandler : ETTeXSimpleHandler
{
	int depth;
}
@end


@interface ETTeXNestableHandler : ETTeXSimpleHandler @end

@interface ETTeXEnvironmentHandler : ETTeXHandler
{
	NSString *environmentName;
	BOOL inBegin;
	BOOL inEnd;
}
+ (void)setTextType: (NSString*)aType forTeXEnvironment: (NSString*)aCommand;
@end


/**
 * Parser for the subset of LaTeX that I use.
 */
@interface ETTeXSectionHandler : ETTeXHandler
@end

@interface ETTeXLinkHandler : ETTeXHandler
{
	NSMutableDictionary *attributes;
}
@end


@interface ETTeXIndexHandler : ETTeXLinkHandler
{
	int depth;
	NSMutableString *buffer;
}
@end


@interface ETTeXRefHandler : ETTeXLinkHandler @end
@interface ETTeXLabelHandler : ETTeXLinkHandler @end

@interface ETTeXItemHandler : ETTeXHandler
{
	BOOL inOptArg;
	BOOL hasOptArg;
	BOOL startedBody;
}
@end

