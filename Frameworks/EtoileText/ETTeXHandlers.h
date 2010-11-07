
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
@interface ETTeXIgnoreHandler : ETTeXHandler @end


@interface ETTeXNestableHandler : ETTeXSimpleHandler @end

@interface ETTeXEnvironmentHandler : ETTeXHandler
{
	NSString *environmentName;
	BOOL isVerbatim;
	BOOL inBegin;
	BOOL inEnd;
}
+ (void)setTextType: (NSString*)aType forTeXEnvironment: (NSString*)aCommand;
+ (void)addVerbatimEnvironment: (NSString*)anEnvironment;
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

