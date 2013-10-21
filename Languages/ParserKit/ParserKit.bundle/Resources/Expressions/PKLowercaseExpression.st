"
Interpret a lowercase epxression
"
PKParseExpression subclass: PKLowercaseExpression [

	parseInput: list withCurrentParser: parser delegate: delegate [
		^list head isEmpty ifTrue: [
			PKParseFail alloc initWithInput: list description: 'Expected lowercase character'
		] ifFalse: [
			(list head characterAtIndex: 0) isLowercase ifTrue: [
				PKParseMatch alloc initWithInput: list length: list head length
			] ifFalse: [
				PKParseFail alloc initWithInput: list description: 'Expected lowercase character'
			]
		]
	]

	description [ ^'[[:lower:]]']
]

