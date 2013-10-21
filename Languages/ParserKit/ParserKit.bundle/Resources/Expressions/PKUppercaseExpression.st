"
Interpret an uppercase expression.
"
PKParseExpression subclass: PKUppercaseExpression [

	parseInput: list withCurrentParser: parser delegate: delegate [
		^list head isEmpty ifTrue: [
			PKParseFail alloc initWithInput: list description: 'Expected uppercase character'
		] ifFalse: [
			(list head characterAtIndex: 0) isUppercase ifTrue: [
				PKParseMatch alloc initWithInput: list length: list head length
			] ifFalse: [
				PKParseFail alloc initWithInput: list description: 'Expected uppercase character'
			]
		]
	]

	description [ ^'[[:upper:]]']
]

