"
Interpret expression for alphabetic value
"
PKParseExpression subclass: PKAlphabeticExpression [
	
	parseInput: list withCurrentParser: parser delegate: delegate [
		^list head isEmpty 
			ifTrue: [PKParseFail alloc initWithInput: list description: 'Expected alphabetic character']
			ifFalse: [
				(list head characterAtIndex: 0) isAlphabetic
			        ifTrue: [PKParseMatch alloc initWithInput: list length: list head length]
			        ifFalse: [PKParseFail alloc initWithInput: list description: 'Expected alphabetic character']]
	]

	description [
		^'[[:alpha:]]'
	]
]

