
NSString extend [
	
	head: size [
		"TODO fix it with NSMakeRange"
		^size > self count 
			  ifTrue: [ self ]
			  ifFalse: [ self substringWithRange: (NSValue rangeWithLocation: 0 length: size)]
	]

	tailFrom: position [
		^self substringWithRange: (NSValue rangeWithLocation: position length: (self count - position))
	]
	
	concat: other [
		^self stringByAppendingString: other
	]

	matchSize [ ^self length ]
	count [ ^self length]
	isEmpty [^self length = 0]
]

NSObject extend [
	matchSize [ ^1 ]
]

NSArray extend [
	head: size [
		"TODO fix it with NSMakeRange"
		^size > self count 
			  ifTrue: [ self ]
			  ifFalse: [ self substringWithRange: (NSValue rangeWithLocation: 0 length: size)]
	]

	tailFrom: position [
		^self subarrayWithRange: (NSValue rangeWithLocation: position length: (self count - position))
	]

]

NSObject subclass: PKParseMatch [
	| matchList tail |

	+emptyMatch: tail [
        ^self new initWithMatch: tail class new tail: tail; 
			yourself
	]

	initWithMatch: list tail: tailList [
		super init.
		matchList := list.
		tail := tailList
	]

	sequenceWith: match [
		matchList := matchList concat: match matchList.
		tail := match tail.
	]

	tail [ ^tail ]
	matchList [ ^matchList ]
	isEmpty [ ^matchList isEmpty]
	isSuccess [ ^true ]
	isFailure [ ^false ]
	description [ 
		^'PKMatchSuccess  ( Recognized: ''', matchList description, ''' Tail: ''',  tail description, ''')\n' 
	]
]

NSObject subclass: PKParseFail [
	| tail describ |

	initWithTail: list description: string [
		super init.
		describ := string.
		tail := list
	]
	tail [ ^tail]
	isFailure [ ^true ]
	isSuccess [ ^false ]

	description [ 
		^'PKMatchFailure  ( Tail: ''',  tail description, ''')\n' 
	]
]


NSObject subclass: PKParseExpression [

	or: exp [
		^PKAlternateExpression alloc initWithExp: self or: exp.
	]

	or: exp1 or: exp2 [
		^(self or: exp1) or: exp2
	]

	or: exp1 or: exp2 or: exp3 [
		^((self or: exp1) or: exp2) or: exp3
	]

	repeat [
		^PKRepetitionExpression alloc initWithExpression: self canBeEmpty: true
	]

	repeatOneLeast [
		^PKRepetitionExpression alloc initWithExpression: self canBeEmpty: false
	]
	
	seq: exp [
		^PKSequenceExpression alloc initWithFirst: self second: exp
	]

	 parseList: sequence [
		 ^self subclassResponsibility
	 ]

	 parseList: list ifFailed: aBlock [
		 | match |
		 match := (self parseList: list).
		 ^match isFailure ifTrue: [ aBlock value ]
			 ifFalse: [ match ]
	 ]

]

PKParseExpression subclass: PKTerminalExpression [
	| match |

	initWithPattern: matchPattern [
		super init.
		match := matchPattern
	]
	
	parseList: list [
		| return |
		((list head: match matchSize) isEqual: match) ifTrue: [ 
			return := PKParseMatch alloc initWithMatch: (list head: match matchSize) 
								tail: (list tailFrom: match matchSize).
		] ifFalse: [
			return := PKParseFail alloc initWithTail: list description: 'Unexpected token, expected ', match  
		].
		^return
	]
]

PKParseExpression subclass: PKSequenceExpression [
 	| e1 e2 |

	initWithFirst: exp1 second: exp2 [
		e1 := exp1.
		e2 := exp2
	] 

	parseList: list [
		| match1 |
		match1 := e1 parseList: list.
		^match1 isSuccess ifTrue: [
			| match2 |
			match2 := (e2 parseList: match tail).
			match2 ifSuccess 
                ifTrue: [ match1 sequenceWith: match2 ]
				ifFalse: [ ]
		] ifFalse: [ match ]
	]
]

PKParseExpression subclass: PKAlternateExpression [
     | first second |

	initWithExp: exp1 or: exp2 [
		first := exp1.
		second := exp2
	]

	 parseList: list [
		 ^first parseList: list ifFailed: [ second parseList: list ]		
	 ]
]

PKParseExpression subclass: PKRepetitionExpression [
	| e canBeEmpty |

	initWithExpression: exp canBeEmpty: aBool [
		super init.
		e := exp.
		canBeEmpty := aBool
	]
	
	parseList: list [
		| match currentMatch |
		match := PKParseMatch emptyMatch: list.
		[
			currentMatch := (e parseList: (match tail)).
			currentMatch isSuccess
		] whileTrue: [match sequenceWith: currentMatch].
		^(match isEmpty and: canBeEmpty not) 
            ifTrue: [PKParseFail new initWithTail: list description: 'Unexpected token, expected ...']
			ifFalse: [match]
	]
]

"--- Ecursive Extend ---"
NSString extend [
	asExp [
		^PKTerminalExpression new initWithPattern: self
	]
]

NSObject subclass: SmalltalkTool [
	
	run [
		| parser abStar abStar b c tExp |

		abStar := PKRepetitionExpression alloc
					 initWithExpression: 'ab' asExp
					 canBeEmpty: false; yourself.

		parser := 'a' asExp or: abStar.

		parser := ('c' asExp repeat) seq: parser.

	"	ETTranscript show: 'This is a test\n'.
		ETTranscript show: true; cr.
		ETTranscript show: NSObject alloc; cr."
		ETTranscript show: (parser parseList: 'ccccccccabab'); cr.
		ETTranscript show: (parser parseList: 'c'); cr.

		"ETTranscript show: (C sqrt: 4)."
	    "ETTranscript show: (C NSMakeRange: {0 . 1})"
	]
]
