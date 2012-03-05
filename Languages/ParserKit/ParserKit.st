"
============================================================================
  ParserKit.st -- OMeta like parser implementation

  Copyright (C) 2011 Mathieu Suen <mathieu@nebu.li>

  The parser have the same syntax that the OMeta one. Although the semantic 
  could differ. For the time being to write expression use the 
  PKParseExpression class. See example at the bottom of the file.

    2012/03/05 Fix way input consuming. 

    2012/02/22 Many bug fix and start to implement a OMeta parser. 
      - Todo fix the way we walk throw the input. When to consume or not
    the input etc.
      - Some PK*Expression should be singleton

    2011/09/21 Beginning of the expression tree
      - Get the expression tree implementation inspire from OMGrammar
 
    2011/10/20 Beginning of the OMeta implementation
      - Adding the PKParserBase PKRules class

    2011/11/09 Todo merge PKRules with PKParserBase

============================================================================
"

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
]

Symbole extend [

]

NSObject extend [
	matchSize [ ^1 ]
]


NSObject subclass: PKParseMatch [
	| input range |

	+emptyMatch: input [
        ^self new initWithInput: input length: 0; 
			yourself
	]

	initWithInput: list length: length [
		super init.
		input := list.
		range := (NSValue rangeWithLocation: input position length: length).
		input pushPosition: range length + range location.
		^self
	]

	sequenceWith: match [
		input mergePosition.
		input lastPosition == range location ifFalse: [
			"Can be remove or rephrase later."
			NSException raise: 'ParseKit' format: 'Last position is not same as the location range, something is wrong here'].
		(range location + range length) == match range location
			ifFalse: [ NSException raise: 'ParserKit' format: 'Can not add the range, it is not contigus'].
		range := NSValue rangeWithLocation: range location length: (range length + match  range length).
	]

	match  [ ^input fromRange: range ]
	isEmpty [ ^range length = 0]
	isSuccess [ ^true ]
	isFailure [ ^false ]
	range [^range]
	description [
		^'PKMatchSuccess  ( Recognized: ''', (input fromRange: range), ''')\n' 
	]
]

NSObject subclass: PKParseFail [
	| input failedPosition describ |

	initWithInput: list description: string [
		super init.
		describ := string.
		input := list.
		failedPosition := input position.
		^self
	]
	
	isFailure [ ^true ]
	isSuccess [ ^false ]

	description [ 
		^'PKMatchFailure  ( At: ''',   failedPosition description, ''', ', input stream, ') ', describ, '\n' 
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

	or: exp1 or:exp2 or: exp3 or: exp4 [
		^(((self or: exp1) or:exp2) or: exp3) or: exp4
	]

	not [
		^PKNegateExpression alloc initWithExp: self
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

	parseInput: sequence [
		^self subclassResponsibility
	]
		
	parseInput: list ifFailed: aBlock [
		| match |
		match := (self parseInput: list).
		^match isFailure ifTrue: [aBlock value]
						 ifFalse: [ match ]
	]
	
]

PKParseExpression subclass: PKDotExpression [
	parseInput: list [
		^list atEnd 
            ifTrue: [PKParseFail alloc initWithInput: list description: 'Unexpected end of stream']
			ifFalse: [PKParseMatch alloc initWithInput: list length: list head length]
	]

	description [
		^'.'
	]
]

PKParseExpression subclass: PKAlphabeticExpression [
	
	parseInput: list [
		^list head isEmpty 
			ifTrue: [PKParseFail alloc initWithInput: list description: 'Expected alphabetic character']
			ifFalse: [
				(list head characterAtIndex: 0) isAlphabetic
			        ifTrue: [PKParseMatch alloc initWithInput: list length: list head length]
			        ifFalse: [PKParseFail alloc initWithInput: list description: 'Expected alphabetic character']]
	]

	description [
		^'[a-zA-Z]'
	]
]

PKParseExpression subclass: PKRangeExpression [
	| from to |

	initFrom: fromChar to: toChar [
		self init.
		from := fromChar.
		to := toChar.
		^self
	]

	parseInput: list [
		^list head isEmpty 
            ifTrue: [PKParseFail alloc initWithInput: list description: 'Expected character [', from, '-', to, ']']
			ifFalse: [
		         (((list head characterAtIndex: 0) >= ( from  characterAtIndex: 0)) and: ((list head characterAtIndex: 0) <= (to characterAtIndex: 0)))
	                   ifTrue: [PKParseMatch alloc initWithInput: list length: list head length]
		               ifFalse: [PKParseFail alloc initWithInput: list description: 'Expected character [', from, '-', to, ']']]
		
	]

	description [
		^'[', from, '-', to, ']'
	]
	
]

PKParseExpression subclass: PKNumericExpression [

	parseInput: list [
		^list head isEmpty ifTrue: [PKParseFail alloc initWithInput: list description: 'Expected digit character']
			ifFalse: [
				(list head characterAtIndex: 0) isDigit
			        ifTrue: [PKParseMatch alloc initWithInput: list length: list head length]
			        ifFalse: [PKParseFail alloc initWithInput: list description: 'Expected digit character']]

	]

	description [
		^'[0-9]'
	]
]

"Abstract class for composing expression"
PKParseExpression subclass: PKComposeExpression [
	| exp |

	initWithExp: expression [ 
		super init.
		exp := expression. 
		^self 
	]

	description [
		^exp description	
	]

	parseInput: list [
	    ^exp parseInput: list	
	]
]

PKComposeExpression subclass: PKNamedExpression [
	| name |
	initWithName: string exp: expression [
		super init.
		exp := expression.
		name := string.
		^self
	]

	parseInput: list  [
		| match |
		match := list matchRule: name.
		(match == nil) ifTrue: [
			match := exp parseInput: list.
			list  addMatch: match at: list position named: name.
		].
		^match
	]
]

PKComposeExpression subclass: PKAlphanumericExpression [

	init [
		self initWithExp: (  PKAlphabeticExpression new or: PKNumericExpression new )
	]
]

PKParseExpression subclass: PKTokenExpression [
	| match |

	initWithPattern: matchPattern [
		super init.
		match := matchPattern.
		^self
	]
	
	parseInput: list [
		| return |
		((list head: match matchSize) isEqual: match) ifTrue: [ 
			return := PKParseMatch alloc initWithInput: list
								length: match matchSize.
		] ifFalse: [
			return := PKParseFail alloc initWithInput: list description: 'Unexpected token'
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

	parseInput: list [
		^list atEnd
            ifTrue: [PKParseMatch alloc initWithInput: list length: 0]
			ifFalse: [PKParseFail alloc initWithInput: list description:  'Expected an empty string'] 
	]

	description [
		^ '$ '
	]
]

PKParseExpression subclass: PKSequenceExpression [
 	| e1 e2 |

	initWithFirst: exp1 second: exp2 [
		e1 := exp1.
		e2 := exp2.
		^self
	] 

	parseInput: list [
		| match1 |
		match1 := e1 parseInput: list.
		^match1 isSuccess ifTrue: [
			| match2 |
			match2 := (e2 parseInput: list).
			match2 isSuccess 
                ifTrue: [ match1 sequenceWith: match2 ]
				ifFalse: [ list popPosition. match2 ]
		] ifFalse: [ match1 ]
	]

	description [
		^e1 description, e2 description
	]
]

PKComposeExpression subclass: PKLookAheadExpression [

	
	parseInput: list [
		| match |
		match := exp parseInput: list.
		^match isFailure 
           ifTrue: [ match]
	       ifFalse: [list popPosition. match]
	]
]

PKComposeExpression subclass: PKNegateExpression [

	initWithExp: expression [
		super initWithExp: (PKLookAheadExpression alloc initWithExp: expression).
		^self
	]

	description [
		^'!(',exp description,')'
	]

	parseInput: list [
		| match |
		match := exp parseInput: list.
		^match isSuccess ifTrue: [PKParseFail alloc initWithInput: list description: 'Should not match ', exp description] 
						 ifFalse: [PKParseMatch alloc initWithInput: list length: 0]
	]
]

PKParseExpression subclass: PKAlternateExpression [
     | first second |

	initWithExp: exp1 or: exp2 [
		first := exp1.
		second := exp2
	]

	parseInput: list [
		 ^first parseInput: list ifFailed: [
			 | match |
			 match := second parseInput: list.
			 match isFailure 
                 ifTrue:[ PKParseFail alloc initWithInput: list description: 'Expected ', self description]
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
		canBeEmpty := aBool.
		^self
	]
	
	parseInput: list [
		| match currentMatch |
		match := PKParseMatch emptyMatch: list.
		[
			currentMatch := e parseInput: list.
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

"--- Recursive Extend ---"
NSString extend [
	asExp [
		^PKTokenExpression new initWithPattern: self
	]
]

NSObject subclass: PKInputStream [
    | memo stream position positionStack positionStack |

    initWithStream: input [
        stream := input.
        memo := NSMutableDictionary new.
		positionStack := NSMutableArray new.
		position := 0.
		^self
	]

	description [
		^stream substringWithRange: (NSValue rangeWithLocation: position length: stream length - position)
	]

    addMatch: parserMatch at: position named: aString [
		| matchList |
		((memo objectForKey: position) == nil)
			 ifTrue: [memo setValue: NSMutableDictionary new forKey: position].
		matchList := memo objectForKey: position.
		matchList setValue: parserMatch forKey: aString
	]

	matchRule: string [
		^self matchAt: position rule: string
	]

	matchAt: position rule: aString [
		| matchList |
		matchList := memo objectForKey: position.
		^(matchList == nil)
            ifTrue: [nil]
			ifFalse: [matchList objectForKey: aString]
	]

	pushPosition: anInt [
		positionStack addObject: position.
		position := anInt
	]

	lastPosition [
		^positionStack lastObject
	]

	popPosition [
		position := positionStack lastObject.
		positionStack removeLastObject.
	]

	fromRange: range [
		^(range length == 0) ifTrue: ['']
			ifFalse: [
				stream substringWithRange: range]
	]

	head [
		^self head: 1
	]
	
	head: size [
		"Todo non local return seems broken"
		^(position + size) > stream length ifTrue: ['']
			ifFalse: [self fromRange: (NSValue rangeWithLocation: position length: size)]
	]

	mergePosition [
		positionStack count >= 2 ifFalse: [NSException raise: 'PKParser' format: 'Not enought position to merge'].
		positionStack removeLastObject
	]

	position [
		^position
	]

	length [
		^stream length
	]

	atEnd [
		^self position = stream length
	]

	stream [
		^stream
	]
]

NSObject subclass: PKRules [
	| parent rules name |

	initWithName: string [
		super init.
		name := string.
		parent := nil.
		rules := NSMutableDictionary new.
		^self
	]
	
	at: rule [
		^self lookup: rule ifFailed: [
			NSException raise: 'PKParser' format: 'Rule not found: ', rule
		]
	]

	addRule: name expression: exp [
		| rule |
		rule := PKNamedExpression alloc initWithName: name exp: exp.
		rules setValue: rule forKey: name
	]

	lookup: rule ifFailed: aBlock [
		| return |
		return := rules objectForKey: rule.
		return == nil ifTrue:[
			return := parent.
			return == nil
                ifTrue: aBlock
				ifFalse: [	
					return := parent lookup: rule ifFailed: aBlock
				]
		].
		^return	
	]
		
	initWithParent: pkRules name: string [
		self initWithName: string.
		parent := pkRules
	]

	description [
		| desc |
		desc := name, ' {'.
		rules allKeys do: [:key | 
			desc := desc, key, ' <- ', (rules objectForKey: key) description, '\n'
		].
		^desc, '}'	
	]
		
	subgrammar: string [
		^self class alloc initWithParent: self
	]
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
]

NSObject subclass: PKParserBase [
	| input +rulesRepo rules |

	+derivate: parent subgrammar: name [
		| rule newRule |
		rule := self getGrammar: parent.
		newRule := rule subgrammar: name.
		rulesRepo setValue: newRule forKey: name.
		^newRule
	]

	+getGrammar: name [
		| rule |
		rule := rulesRepo objectForKey: name
		rule == nil ifTrue: [
			^NSException raise: 'ParserKit' format: 'Can not found grammar ''', name, ''''
		].
		^rule	
	]

	+getNewGrammar: name [
		| rule |
		rule := PKRules alloc initWithName: name.
		rulesRepo setValue: rule forKey: name.
		^rule	
	]

    initWithGrammar: grammarName [
		rules := self class getGrammar: grammarName.
		^self
	]

	initWithNewGrammar: grammarName [
		rules := self class getNewGrammar: grammarName.
		^self
	]

	subgrammar: name [
		rules := self class derivate: rules subgrammar: name.
	]

	at: rule [
		^rules at: rule
	]

	addRule: name expression: exp [
		rules addRule: name expression: exp
	]

	description [
		^rules description
	]
	
	apply: rule [
		| exp |
		exp := rules lookup: rule ifFailed: [
			NSException raise: 'ParserKit' format: 'Invalid rule'
		].
		^exp parseInput: input.
	]
	
	match: inputStream rule: rule [
		input := PKInputStream alloc initWithStream: inputStream.
		^self apply: rule
	]
   
]

NSObject subclass: SmalltalkTool [
	
	run [
		| dict parser abStar abStar b c tExp alphaNumeric oMeta |
		abStar := PKRepetitionExpression alloc
					 initWithExpression: 'ab' asExp
					 canBeEmpty: false; yourself.

		parser := abStar or: 'a' asExp.

		parser := ('c' asExp repeat) seq: parser seq: PKEmptyExpression uniqueInstance.

		alphaNumeric  := PKAlphanumericExpression new repeat.
		oMeta := PKParserBase alloc initWithNewGrammar: 'Test'.
		oMeta addRule: 'alphaNum'  expression: alphaNumeric.
		ETTranscript show: 'This is a test\n'.
		ETTranscript show: true; cr.
		ETTranscript show: NSObject alloc; cr.
		ETTranscript show: (parser parseInput: 'cab' asInputStream); cr.
		ETTranscript show: alphaNumeric; cr.
		ETTranscript show: (alphaNumeric parseInput: 'Good34'  asInputStream); cr.
		ETTranscript show: (alphaNumeric parseInput: 'testing4'  asInputStream); cr.
		ETTranscript show: (oMeta match: 'testing4' rule: 'alphaNum'); cr.
		oMeta := self pegGrammar.

		ETTranscript show: oMeta; cr.
		ETTranscript show: (oMeta at: 'Char'); cr.
		ETTranscript show: (oMeta match:( '\', 'n') rule: 'Char').
		ETTranscript show: (oMeta match:('n') rule: 'Char').
		ETTranscript show: (oMeta match:( '\', '266') rule: 'Char').
		ETTranscript show: (oMeta match:( '\', '268') rule: 'Char').
		ETTranscript show: (oMeta match:( '\', '66') rule: 'Char').
		ETTranscript show: (oMeta match:( '\', '66') rule: 'Char').
		ETTranscript show: (oMeta match:( '\', '66-', '\', '234') rule: 'Range').
		ETTranscript show: (oMeta match:( 'a-d') rule: 'Range').
		ETTranscript show: (oMeta match:( '[a-d] ') rule: 'Class').
		ETTranscript show: (oMeta match:( '[a-d\34] ') rule: 'Class').
		ETTranscript show: (oMeta match:( '[a-dA-Z]\n') rule: 'Class').
		"ETTranscript show: parser;cr.
		ETTranscript show: (parser parseInput: 'c'); cr."

		"ETTranscript show: (C sqrt: 4)."
	    "ETTranscript show: (C NSMakeRange: {0 . 1})"
	]

	pegGrammar [
		| oMeta  |
		oMeta := PKParserBase alloc initWithNewGrammar: 'PEG'.
		oMeta addRule: 'EndOfLine' expression: ('\r\n' asExp or: '\n' asExp).
		oMeta addRule: 'Space' expression: (' ' asExp or: '\t' asExp or: (oMeta at: 'EndOfLine')).
		oMeta addRule: 'Comment' expression: ('#' asExp seq: ((oMeta at: 'EndOfLine') not seq: (PKDotExpression new) ) repeat seq: (oMeta at: 'EndOfLine')).
		oMeta addRule: 'Spacing' expression: ((oMeta at: 'Space') or: (oMeta at: 'Comment')).
		oMeta addRule: 'DOT' expression: ('.' asExp seq: (oMeta at: 'Spacing')).
		oMeta addRule: 'CLOSE' expression: ( ')' asExp seq: (oMeta at: 'Spacing')). 
		oMeta addRule: 'OPEN' expression: ( '(' asExp seq: (oMeta at: 'Spacing')).
		oMeta addRule: 'PLUS' expression: ( '+' asExp seq: (oMeta at: 'Spacing')).
		oMeta addRule: 'STAR' expression: ( '*' asExp seq: (oMeta at: 'Spacing')).
		oMeta addRule: 'QUESTION' expression: ( '?' asExp seq: (oMeta at: 'Spacing')).
		oMeta addRule: 'NOT' expression: ( '!' asExp seq: (oMeta at: 'Spacing')).
		oMeta addRule: 'SLASH' expression: ( '&' asExp seq: (oMeta at: 'Spacing')).
		oMeta addRule: 'AND' expression: ( '/' asExp seq: (oMeta at: 'Spacing')).
		oMeta addRule: 'LEFTARROW' expression: ( '<-' asExp seq: (oMeta at: 'Spacing')).
		oMeta addRule: 'Char' expression: 
			(('\' asExp seq: {'n' . 'r' . 't' . ''''. '"' . '[' . ']'} joinAll)
				or: ('\' asExp seq: (PKRangeExpression alloc initFrom: '0' to: '2') 
							   seq: (PKRangeExpression alloc initFrom: '0' to: '7') 
							   seq: (PKRangeExpression alloc initFrom: '0' to: '7') )
				or: ('\' asExp seq: (PKRangeExpression alloc initFrom: '0' to: '7') 
							   seq: (PKRangeExpression alloc initFrom: '0' to: '7') )
			    or: ('\' asExp not seq: (PKDotExpression new)  )).
		oMeta addRule: 'Range' expression: (((oMeta at: 'Char') seq: '-' asExp seq: (oMeta at: 'Char')) or: (oMeta at: 'Char')).
		oMeta addRule: 'Class' expression: ('[' asExp seq: (']' asExp not seq: (oMeta at: 'Range')) repeat seq: ']' asExp seq: (oMeta at: 'Space')).
		^oMeta
	]
]

"Basic PEG parser:

# Hierarchical syntax
Grammar <- Spacing Definition+ EndOfFile
Definition <- Identifier LEFTARROW Expression
Expression <- Sequence (SLASH Sequence)*
Sequence <- Prefix*
Prefix <- (AND / NOT)? Suffix
Suffix <- Primary (QUESTION / STAR / PLUS)?
Primary <- Identifier !LEFTARROW
/ OPEN Expression CLOSE
/ Literal / Class / DOT
# Lexical syntax
Identifier <- IdentStart IdentCont* Spacing
IdentStart <- [a-zA-Z_]
IdentCont <- IdentStart / [0-9]
Literal <- [’] (![’] Char)* [’] Spacing
/ [""] (![""] Char)* [""] Spacing
Class <- ’[’ (!’]’ Range)* ’]’ Spacing
Range <- Char ’-’ Char / Char
Char <- ’\\’ [nrt’""\[\]\\]
/ ’\\’ [0-2][0-7][0-7]
/ ’\\’ [0-7][0-7]?
/ !’\\’ .
LEFTARROW <- ’<-’ Spacing
SLASH <- ’/’ Spacing
AND <- ’&’ Spacing
NOT <- ’!’ Spacing
QUESTION <- ’?’ Spacing
STAR <- ’*’ Spacing
PLUS <- ’+’ Spacing
OPEN <- ’(’ Spacing
CLOSE <- ’)’ Spacing
DOT <- ’.’ Spacing
Spacing <- (Space / Comment)*
Comment <- ’#’ (!EndOfLine .)* EndOfLine
Space <- ’ ’ / ’\t’ / EndOfLine
EndOfLine <- ’\r\n’

"
