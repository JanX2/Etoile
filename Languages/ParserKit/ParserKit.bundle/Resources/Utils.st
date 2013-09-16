"
============================================================================
  
  Copyright (C) 2011,2012 Mathieu Suen <mathieu@nebu.li>

  Helper and convenience classes and categories

============================================================================
"

NSObject subclass: PKTranscriptController [
	| +inDebugMode |

	+setDebugMode: value [ inDebugMode := value ]
	+isInDebugMode [ ^inDebugMode ]

]

ETTranscript extend [

	+setDebugMode: value [
		PKTranscriptController setDebugMode: value
	]
    +debug: output [
		 PKTranscriptController isInDebugMode ifTrue: [ self show: output]
	 ]

	+debugCr [
		PKTranscriptController isInDebugMode ifTrue: [ self cr]
	]
]

NSMutableDictionary extend [
	at: key ifAbsentDo: aBlock [
		| return |
		return := self objectForKey: key.
		return == nil ifTrue: [
			return := aBlock value
		].
		^return	
	]

	at: key ifAbsentPut: aBlock [
		^self at: key ifAbsentDo: [
			self setValue: aBlock value forKey: key.
			self objectForKey: key
		]
	]
]

NSString extend [

	concat: other [
		^self stringByAppendingString: other
	]

	asInputStream [
		^PKInputStream alloc initWithStream: self
	]

	matchSize [ ^self length ]
	count [ ^self length]
	isEmpty [^self length = 0]
	isNotEmpty [^self length > 0 ]

	isLessThan: other [
		^(self integerValue) < (other integerValue)
	]

	asExp [
		^PKTokenExpression new initWithPattern: self
	]
]


NSObject extend [
	canReduce [^false]
	isExplicitAction [ ^ false ]
	matchSize [ ^1 ]
	isArray [^false]
	joinAll [ ^self ]
	sequenceAll [ ^self ]
	asArray [ ^{ self } ]
]

NSArray extend [
	joinAll [
		| exp |
		exp := nil.
		self do: [ :value |
			(exp == nil)
                ifTrue: [
					exp := value asExp]
				ifFalse: [exp := exp or: value asExp].
		].
		^exp
	]
	sequenceAll [
		| exp |
		exp := nil.
		self do: [ :value |
			(exp == nil)
                ifTrue: [
					exp := value asExp]
				ifFalse: [exp := exp seq: value asExp].
		].
		^exp
	]

	asArray [ ^self ]
]


