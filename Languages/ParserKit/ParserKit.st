"
============================================================================
  ParserKit.st -- OMeta like parser implementation

  Copyright (C) 2011 Mathieu Suen <mathieu@nebu.li>

  The parser have the same syntax that the OMeta one. Although the semantic 
  could differ. For the time being to write expression use the 
  PKParseExpression class. See example at the bottom of the file.

  ChangeLogs
    2011/09/21 Beginning of the expression tree
      - Get the expression tree implementation inspire from OMGrammar
 
    2011/10/20 Beginning of the OMeta implementation
      - Adding the PKParserBase PKRules class

  TODO: Continue with the parseList:for: implementation.
    The idea is that expression, when match success, store the result
    in the memoize list.

============================================================================
"

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

	initWithTail [
		super init.
		tail := ''.
		describ := 'Fail match to avoid recursive call'
	]
	
	tail [ ^tail]
	isFailure [ ^true ]
	isSuccess [ ^false ]

	description [ 
		^'PKMatchFailure  ( Tail: ''',  tail description, ''') ', describ, '\n' 
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

	seq: exp1 seq: exp2 [
		^(self seq: exp1) seq: exp2
	]

	seq: exp1 seq: exp2 seq: exp3 [
		^(self seq: exp1 seq: exp2) seq: exp3
	]

	 parseList: sequence [
		 ^self subclassResponsibility
	 ]

	 parseList: list ifFailed: aBlock [
		| match |
		 match := (self parseList: list).
		 ^match isFailure ifTrue: [aBlock value]
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
			return := PKParseFail alloc initWithTail: list description: 'Unexpected token'
		].
		^return
	]

	description [
		^ match description
	]
]

PKParseExpression subclass: PKEmptyExpression [
	| +instance |

	+initialize [
        instance := self new.
	]

	+uniqueInstance [
        ^instance
	]

	parseList: list [
		^list isEmpty 
            ifTrue: [PKParseMatch alloc initWithMatch: '' tail: list]
			ifFalse: [PKParseFail alloc initWithTail: list description:  'Expected an empty string'] 
	]

	description [
		^ '$ '
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
			match2 := (e2 parseList: match1 tail).
			match2 isSuccess 
                ifTrue: [ match1 sequenceWith: match2 ]
				ifFalse: [ match2 ]
		] ifFalse: [ match1 ]
	]

	description [
		^e1 description, e2 description
	]
]

PKParseExpression subclass: PKAlternateExpression [
     | first second |

	initWithExp: exp1 or: exp2 [
		first := exp1.
		second := exp2
	]

	 parseList: list [
		 ^first parseList: list ifFailed: [
			 | match |
			 match := second parseList: list.
			 match isFailure 
                 ifTrue:[ PKParseFail alloc initWithTail: list description: 'Expected ', self description]
				 ifFalse: [match]
		 ]		
	 ]

	description [
		^'(', first description, ' or ', second description, ')'
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

	description [
		^e description , (canBeEmpty ifTrue: ['*'] ifFalse: ['+'])
	]
]

"--- Ecursive Extend ---"
NSString extend [
	asExp [
		^PKTerminalExpression new initWithPattern: self
	]
]

NSObject subclass: PKInputStream [
    | memo originalStream currentStream|

    initWithStream: input [
        orignialStream := input.
        memo := NSMutableDictionary alloc init.

	]

    setValue: object forKey: key [
        memo setValue: object forKey: key
	]

    objectForKey: key [
         ^memo objectForKey: key
	]

    stream [
        ^originalStream
	]
]

NSOBject subclass: PKRules [
	| parent rules name |

	initWithName: string [
		super init.
		name := string.
		parent := nil.
		rules := NSMutableDictionary new.
	 	
	]

	addRule: name expression: exp [
		rules setValue: exp forKey: name
	]

	lookup: rule ifFaild: aBlock [
		| return |
		(return := rules objectForKey: rule == nil) ifTrue:[
			return := (parent == nil) 
                ifTrue: aBlock
				ifFalse: [	
					return := parent lookup: rule ifFaild: aBlock
				]
		].
		^return	
	]
		
	initWithParent: pkRules name: string [
		self initWithName: string.
		parent := pkRules
	]
		
	subclass: string [
		^slef class alloc initWithParent: self
	]
]


NSObject subclass: PKParserBase [
	| input +rulesRepo rules  |

	+derivate: parent subclass: name [
		| rule |
		(rule := rulesRepo objectForKey: parent) == nil ifTrue: [
			^ETTranscript show: 'Can not found parent grammar ''', parent, ''''; cr
		].
		rules setValue: (rule subclass: name) forKey: name
	]

	+getGrammar: name [
		^rulesRepo objectForKey: name
	]
	

    initWithGrammar: name [
		rules := self class getGrammar: name.
	]
	
	apply: rule [
		| exp return |
		(return := input objectForKey: rule) == nil ifTrue: [
			input setValue: PKParseFail alloc initWithTail forKey: rule.
			exp := rules lookup: rule ifNotFound: [
				ETTranscript show: 'Invalid rule'
			].
		    return := exp parseList: input stream for: self
		].
		^return
	]
	
	match: inputStream rule: rule [
		input := PKInputStream alloc initWithStream: inputStream.
		self apply: rule
	]
   
]

NSObject subclass: SmalltalkTool [
	
	run [
		| dict parser abStar abStar b c tExp |
		dict := NSMutableDictionary new.
		dict setValue: 4 forKey: 'foo' .
		ETTranscript show: (dict objectForKey: 'foo' ); cr.
		ETTranscript show: (dict objectForKey: 5 ); cr.
		abStar := PKRepetitionExpression alloc
					 initWithExpression: 'ab' asExp
					 canBeEmpty: false; yourself.

		parser := abStar or: 'a' asExp.

		parser := ('c' asExp repeat) seq: parser seq: PKEmptyExpression uniqueInstance.

	"	ETTranscript show: 'This is a test\n'.
		ETTranscript show: true; cr.
		ETTranscript show: NSObject alloc; cr."
		ETTranscript show: (parser parseList: 'ccccccccabaab'); cr.

		ETTranscript show: parser;cr.
		ETTranscript show: (parser parseList: 'c'); cr.

		"ETTranscript show: (C sqrt: 4)."
	    "ETTranscript show: (C NSMakeRange: {0 . 1})"
	]
]