"
Interpret the wildcard operator.
"
PKParseExpression subclass: PKDotExpression [
	parseInput: list withCurrentParser: parser delegate: delegate [
		^list atEnd 
            ifTrue: [PKParseFail alloc initWithInput: list description: 'Unexpected end of stream']
			ifFalse: [PKParseMatch alloc initWithInput: list length: list head length]
	]

	description [
		^'.'
	]

]

