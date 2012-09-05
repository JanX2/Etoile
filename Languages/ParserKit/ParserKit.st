"
============================================================================
  ParserKit.st -- OMeta like parser implementation

  Copyright (C) 2011,2012 Mathieu Suen <mathieu@nebu.li>
  Copyright (C) 2012 Niels Grewe <niels.grewe@halbordnung.de>

  The parser has a slightly different syntax than the OMeta one. Semantics
  could also differ. For the time being to write expression use the 
  PKParseExpression class. See example at the bottom of the file.

    2012/03/08 Rule lookup can be optimize at runtime

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

"
============================================================================
  
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


"
============================================================================

  Classes to implement semantic actions

============================================================================
"

"
 The delayed action array records a number of delayed invocations so that they
 can be executed after parsing was successful.
"
NSObject subclass: NSDelayActionArray [
	| anArray |

	init [
		super init.
		anArray := NSMutableArray new.
	]

	addObject: anObject [
		anArray addObject: anObject
	]

	addAction: anObject [
		(anObject isArray and: (anObject == nil) not)
			ifTrue: [anObject do: [:each | self addObject: each]]
			ifFalse: [self addObject: anObject].
		^self
	]

	isArray [^true]

	do: aBlock [
		anArray do: aBlock
	]

	isExplicitAction [ ^true ]

	canReduce [^true]
	reduceOn: target [
		| result implicit |
		" Find out whether the array only contains implicit actions. In
		  this case, we want to rejoin them. "
		implicit := anArray leftFoldWithInitialValue: true
		                                   intoBlock: [ :acc :each | acc and: (each isExplicitAction not) ].
		result := anArray map: [:each | 
			each canReduce 
                   ifTrue: [each reduceOn: target]
				   ifFalse: [each]].
		(1 = (result count)) ifTrue: [ result := result objectAtIndex: 0 ]
		                    ifFalse: [
			implicit ifTrue: [
				" FIXME: Define generic protocol so that this
				  works for something other than strings. "
				result := result componentsJoinedByString: ''
			]
		].
		^result.
	]
	description [
		^anArray leftFoldWithInitialValue: 'Delay:'
		                        intoBlock: [ :acc :action |
			'Delay:' = acc ifTrue: [acc, ' ', action description]
		                   ifFalse: [acc, ', ', action description]
		]           	
	]
]


NSObject subclass: PKMatchRangeNotice [
	| match rule range |

	initWithMatch: aMatch rule: aRule at: aRange [
		super init.
		match := aMatch.
		rule := aRule.
		range := aRange.
	]

	canReduce [ ^true ]

	isExplicitAction [
		^(match respondsToSelector: #isExplicitAction ) ifTrue: [
			(self == match) ifTrue: [ false ]
			               ifFalse: [ match isExplicitAction ].
		] ifFalse: [
			| action |
			action := match matchAction.
			(nil == action) ifTrue: [ false ]
			ifFalse: [
				(action isKindOfClass: PKMatchRangeNotice class) ifTrue: [ false ]
				ifFalse: [ action isExplicitAction ]
			]
		]
	]

	originalMatch [ ^match ]

	range [ ^range ]

	setOriginalMatch: aMatch [
		match := aMatch
	]

	reduceOn: target [
		| selector |
		selector := ('matched', rule, 'At:') selValue.
		ETTranscript debug: 'Reduce called: '; debug: selector; debugCr.
		(target respondsToSelector: selector) ifTrue: [
			target performSelector: selector withObject: range.
		] ifFalse: [
			target ifResponds matched: rule at: range.
		].
		^match canReduce ifTrue: [ 
			match reduceOn: target
		] ifFalse: [
			match match
		]
	]

	description [ ^'Notice about match for ''', rule, ''' at ', range description ] 
]

"
  Delayed invocations are used to record the semantic actions defined by parse
  expressions and to execute them after the parse tree has successfully
  constructed.
"
NSObject subclass: NSDelayInvocation [
	| selector args original |
	
	+invocationWithSelector: aSelector arguments: someArgs originalMatch: match [
		^self alloc initWithSelector: aSelector arguments: someArgs originalMatch: match
	]
	initWithSelector: aSelector arguments: someArgs originalMatch: match [
		super init.
		selector := aSelector.
		args := someArgs.
		original := match.
		^self
	]

	isExplicitAction [^true]
	canReduce [^true]
	reduceOn: target [
		| oldSelString rangedSelector reduceArgs anInvoc |
		oldSelString := selector description.
		(oldSelString hasPrefix: '#') ifTrue: [ oldSelString := oldSelString substringFromIndex: 1 ].
		rangedSelector := (oldSelString hasSuffix: ':') ifTrue: [ (oldSelString stringByAppendingString: 'range:') selValue ]
		                                               ifFalse: [ (oldSelString stringByAppendingString: 'Range:') selValue ].
		" If the delegate is also interested in the range, invoke that method (and add the
		  implicitly bound range argument, of course)"
		(target respondsToSelector: rangedSelector) ifTrue: [
			selector := rangedSelector.
			args := args arrayByAddingObject: original range.
		].

		^(target respondsToSelector: selector) ifTrue: [
			reduceArgs := args map: [:each | each canReduce ifTrue: [
				| res | res := each reduceOn: target.
				(res == nil) ifTrue: [
					NSNull new
				] ifFalse: [
					res].
			] ifFalse: [each]].
			anInvoc := NSInvocation invocationWithTarget: target selector: selector arguments: reduceArgs.
			anInvoc invoke.
			anInvoc returnValueAsObject
		] ifFalse: [
			" if the selector cannot be invoked, we just return the original match. "
			ETTranscript debug: 'Delegate does not respond to action ''', selector description, '''';debugCr. 
			original matchText
		]
	]

	description [
		| argList |
		argList := args leftFoldWithInitialValue: ''
		intoBlock: [ :acc :arg |
			'' = acc ifTrue: [arg description]
			        ifFalse: [ acc, ', ', arg description]
		].
		^ selector description, ' with args: (', argList, ')'
	]
]


" 
  Generates a delayed invocation with the arguments bound to the corresponding
  expressions from the current parsing environment. We might want to define a
  subclass that doesn't use invocations but instead uses the JIT to compile
  blocks that can be executed in the environment.  
"
NSObject subclass: PKParseAction [
	| selector argumentNames |
	
	initWithSelector: sel argumentNames: args [
		selector := sel.
		argumentNames := args.
	]

	invocationInEnvironment: env originalMatch: match [
		| argsBuild |
		argsBuild := NSMutableArray new.
		argumentNames do: [:each |
			| value |
			ETTranscript debug: 'Parsing with de following env.'; debug: env; debugCr.
			value := env objectForKey: each.
			value == nil ifTrue: [NSException raise: 'ParserKit' format: 'Unknown binding: ', each].
			argsBuild addObject: value.
		].
		^NSDelayInvocation invocationWithSelector: selector arguments: argsBuild originalMatch: match
	]
	
	messageString [
		| messageString |
		(selector description hasSuffix: ':') ifTrue: [
			| selectorParts |
			selectorParts := selector description componentsSeparatedByString: ':'.
			selectorParts := selectorParts zippedCollectionWithCollection: argumentNames andBlock: [ 
				:first :second |
				first, ': ', second
			].
			messageString := selectorParts componentsJoinedByString: ' '.
		] ifFalse: [
			messageString := selector description.
		].
		^(messageString hasPrefix: '#') ifTrue: [
			messageString substringWithRange: (NSValue rangeWithLocation: 1 length: (messageString length - 1))
		] ifFalse: [ messageString ].
	]

	description [ ^ '[', self messageString, ']' ]
]



"
  Parse predicates can be evaluated right away to decide whether a given
  expression should match.
"
PKParseAction subclass: PKParsePredicate [
	| targetName |
	initWithTargetName: trgt selector: sel argumentNames: args [
		super initWithSelector: sel argumentNames: args.
		targetName := trgt.
		^self
	]

	succeedsInEnvironment: env withDelegate: delegate [
		| target arguments invocation |
		arguments := argumentNames mappedCollectionWithBlock: [ :argName |
			|value |
			value := env objectForKey: argName.
			"FIXME: This is a quick hack. If the value cannot be bound, we assume
			 that it should be interpreted as a literal value."
			value == nil ifTrue: [value := argName].

			" We might need to reduce the value first, which might trigger
			  unwanted side-effects if we need to backtrack latter.
			  TODO: In the ParserKit manual, clearly inform the user about
			  the fact that it is unsafe use bound matches with side-effecting
			  actions in predicates. The only thing we can avoid is triggering
			  match range notices to the delegate."
			value canReduce ifTrue: [
				(value isKindOfClass: PKMatchRangeNotice class) ifTrue: [
					| innerValue |
					innerValue := value originalMatch.
					innerValue canReduce ifTrue: [
						innerValue := innerValue reduceOn: delegate.
					] ifFalse: [
						innerValue := innerValue match.
					].
					value setOriginalMatch: innerValue.
					value := innerValue.
				] ifFalse: [
				  value := value reduceOn: delegate.
				  " We also need to update the environment with the reduced value. "
				  env replaceObject: value forKey: argName.
				].
			].	
			value.
		].
		target := env objectForKey: targetName.
		target == nil ifTrue: [target := targetName].
		invocation := NSInvocation invocationWithTarget: target selector: selector arguments: arguments.
		invocation invoke.
		^invocation returnValueAsBool
	]
	
	description [
		^'?(', targetName, ' ', self messageString, ')'.
	]
]


"
  Parse restrictions are a reduced case of actions that can be used to replace a
  match with a bound sub-expression.
"	
NSObject subclass: PKParseRestriction [
	| binding |
	initWithBinding: name [
		super init.
		binding := name.
		^self
	]

	restrictInEnvironment: env [
		| value |
		value := env objectForKey: binding.
		value == nil ifTrue: [NSException raise: 'ParserKit' format: 'Unknown binding: ', binding].
		^PKRestrictedMatch alloc initWithResult: value
	]

	description [ ^binding ]
]

"
  Restricted matches can be used just as delayed invocations, but they only
  contain their literal value.
"
NSObject subclass: PKRestrictedMatch [
	| restricted |
	initWithResult: result [
		super init.
		restricted := result.
		^self
	]

	reduceOn: delegate [
		^(restricted canReduce) ifTrue: [restricted reduceOn: delegate]
		                       ifFalse: [restricted].	
	]
	
	canReduce [ ^true ]

	isExplicitAction [ ^true ]

	description [ ^restricted description ]
]

"
============================================================================
  
  Expression classes for the ParserKit oMeta parser

============================================================================
"

NSObject subclass: PKParseExpression [
	
	asExp [^self]

	bind: name [
		^PKBindExpression alloc initWithExp: self name: name
	]

	or: exp [
		| alternative |
		((exp isKindOfClass: PKNAryAlternateExpression class) or: (exp isKindOfClass: PKAlternateExpression class)) ifTrue: [
			alternative := PKNAryAlternateExpression new.
			alternative addExpression: self.
			alternative addExpressions: exp expressions.
		] ifFalse: [ alternative := PKAlternateExpression alloc initWithExp: self or: exp].
		^alternative
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
		| sequence |
		((exp isKindOfClass: PKNArySequenceExpression class) or: (exp isKindOfClass: PKSequenceExpression class)) ifTrue: [
			sequence := PKNArySequenceExpression new.
			sequence addExpression: self.
			sequence addExpressions: exp expressions.
		] ifFalse: [ sequence := PKSequenceExpression alloc initWithFirst: self second: exp].
		^sequence
	]

	actionSelector: aSel arguments: args  [
		^self semanticAction: (PKParseAction alloc initWithSelector: aSel argumentNames: args).
	]

	semanticAction: action [
		^PKActionExpression alloc initWithExp: self action: action
	]

	parameterTarget: trgt selector: aSel arguments: args [
		^self parameter: (PKParsePredicate alloc initWithTargetName: trgt selector: aSel argumentNames: args).
	]

	parameter: predicate [	
		^PKParameterizedExpression alloc initWithExp: self predicate: predicate
	]	

	restrict: binding [
		^PKRestrictionExpression alloc initWithExp: self restriction: (PKParseRestriction alloc initWithBinding: binding)
	]
	seq: exp1 seq: exp2 [
		^(self seq: exp1) seq: exp2
	]

	seq: exp1 seq: exp2 seq: exp3 [
		^(self seq: exp1 seq: exp2) seq: exp3
	]

	seq: exp1 seq: exp2 seq: exp3 seq: exp4 [
		^(self seq: exp1 seq: exp2 seq: exp3) seq: exp4
	]

	maybe [
		^PKMaybeExpression alloc initWithExp: self
	]

	lookahead [
		^PKLookAheadExpression alloc initWithExp: self
	]

	parseInput: sequence  withCurrentParser: parser delegate: delegate [
		^self subclassResponsibility
	]

	parseInput: sequence withCurrentParser: parser [
		^self parseInput: sequence withCurrentParser: parser delegate: nil
	]

	parseInput: sequence [
		^self parseInput: sequence withCurrentParser: nil delegate: nil.
	]
		
	parseInput: list withCurrentParser: parser delegate: delegate ifFailed: aBlock [
		| match |
		match := (self parseInput: list withCurrentParser: parser delegate: delegate).
		^match isFailure ifTrue: [aBlock value]
						 ifFalse: [ match ]
	]

	parseInput: list withCurrentParser: parser ifFailed: aBlock [
		^self parseInput: list withCurrentParser: parser delegate: nil ifFailed: aBlock
	]

	isMemoizable [ ^true ]

	" We need a special memoizability check for lookups to non-terminals because
	  they might recursively refer to themselves."
	isMemoizableForNonTerminal: name inGrammar: grammar [ ^true ]
]

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

PKParseExpression subclass: PKWhitespaceExpression [

	parseInput: list withCurrentParser: parser delegate: delegate [
		^list head isEmpty ifTrue: [
			PKParseFail alloc initWithInput: list description: 'Expected whitespace character'
		] ifFalse: [
			(list head characterAtIndex: 0) isWhitespace ifTrue: [
				PKParseMatch alloc initWithInput: list length: list head length
			] ifFalse: [
				PKParseFail alloc initWithInput: list description: 'Expected whitespace character'
			]
		]
	]

	description [ ^'[[:space:]]']
]


PKParseExpression subclass: PKRangeExpression [
	| from to |

	initFrom: fromChar to: toChar [
		super init.
		from := fromChar.
		to := toChar.
		^self
	]

	parseInput: list withCurrentParser: parser delegate: delegate [
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

	parseInput: list withCurrentParser: parser delegate: delegate [
		^list head isEmpty ifTrue: [PKParseFail alloc initWithInput: list description: 'Expected digit character']
			ifFalse: [
				(list head characterAtIndex: 0) isDigit
			        ifTrue: [PKParseMatch alloc initWithInput: list length: list head length]
			        ifFalse: [PKParseFail alloc initWithInput: list description: 'Expected digit character']]

	]

	description [
		^'[[:digit:]]'
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

	parseInput: list withCurrentParser: parser delegate: delegate [
	    ^exp parseInput: list  withCurrentParser: parser delegate: delegate
	]

	expression [^exp]

	" Non-Memoizability is inherited. "
	isMemoizable [ ^exp isMemoizable ]
	isMemoizableForNonTerminal: name inGrammar: grammar [ ^exp isMemoizableForNonTerminal: name inGrammar: grammar ] 

	setDelegate: aDelegate [
		super setDelegate: aDelegate.
		exp setDelegate: aDelegate.
	]
]


"Abstract compose expression with n subexpressions" 
PKParseExpression subclass: PKNAryComposeExpression [
	| expressions |

	init [
		super init.
		expressions := NSMutableArray new.
		^self
	]

	addExpression: exp
	[
		expressions addObject: exp.
	]

	addExpressions: exprs
	[
		expressions addObjectsFromArray: exprs.
	]

	expressions [ ^expressions]

	isMemoizableForNonTerminal: name inGrammar: grammar [
		| result |
		result := true.
		expressions do: [ :exp|
			result ifTrue: [
				result := exp isMemoizableForNonTerminal: name inGrammar: grammar.
			]
		].
		^result. 
	]

	isMemoizable [ ^self isMemoizableForNonTerminal: nil inGrammar: nil ]

	setDelegate: aDelegate [
		super setDelegate: aDelegate.
		expressions do: [ :each | each setDelegate: aDelegate ].
	]
]

PKComposeExpression subclass: PKActionExpression [
	| action |
	
	initWithExp: aExp action: anAction [
		super initWithExp: aExp.
		action := anAction
	]

	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		
		match := exp parseInput: list withCurrentParser: parser delegate: delegate.
		match isSuccess  ifTrue: [
			match attachAction: (action invocationInEnvironment: list environment originalMatch: match)
		].
		
		^match
	]
	description [ ^exp description, ' -> ', action description ]
]

" Restricted expressions are a quick hack to work around the fact that our 
  delegate based action syntax does not allow us to replace the parse match with
  a bound subexpression without jumping to a large number of hoops. (i.e. write
  a delegate method that does nothing"
PKComposeExpression subclass: PKRestrictionExpression [
	| restriction |
	initWithExp: aExp restriction: aRestriction [
		super initWithExp: aExp.
		restriction := aRestriction
	]

	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		
		match := exp parseInput: list withCurrentParser: parser.
		match isSuccess  ifTrue: [
			match attachAction: (restriction restrictInEnvironment: list environment)
		].	
		^match
	]
	description [ ^exp description, ' -> ', restriction description ]
]

PKComposeExpression subclass: PKParameterizedExpression [
	| predicate |
	initWithExp: aExp predicate: pred [
		super initWithExp: aExp.
		predicate := pred.
	]
	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		match := exp parseInput: list  withCurrentParser: parser delegate: delegate.
		^match isSuccess ifTrue: [
			(predicate succeedsInEnvironment: (list environment) withDelegate: delegate) ifTrue: [ match ]
			ifFalse: [
				list popPosition.
				PKParseFail alloc initWithInput: list
				                    description: ('Expected ', exp description, ' to satisfy parameter ', predicate description)].
		] ifFalse: [ match ].
	]
	
	description [
		^exp description, ' ', predicate description
	]
	
	isMemoizable [ ^false ]
	isMemoizableForNonTerminal: name inGrammar: grammar [ ^false ] 
]

PKComposeExpression subclass: PKNonTerminalExpression [
	| name  |
	initWithName: string exp: expression [
		super init.
		exp := expression.
		name := string.
		^self
	]

	parseInput: list  withCurrentParser: parser delegate: delegate  [
		| match |
		list inEnvironmentDo: [
			exp == nil ifTrue: [NSException raise: 'ParserKit' format: 'Uncomplete grammar definition for ', name].
			ETTranscript debug: 'Trying non terminal: ', name, ' input pos: '; debug: list positionStack; debugCr.
			match := list matchRule: name.
			(match == nil) ifTrue: [
				| position |
				position := list position.
				match := exp parseInput: list  withCurrentParser: parser delegate: delegate.
				
				match isSuccess ifTrue: [
					" Add an implicit range notice "
					(match matchAction == nil) ifTrue: [
						match attachAction: (PKMatchRangeNotice alloc
						  initWithMatch: match
						           rule: name
						             at: match range)	
					] ifFalse: [
						" If there is already an action, we need to use that for
						  the match "
						(match matchAction isKindOfClass: PKMatchRangeNotice class) ifFalse: [
							match attachAction: (PKMatchRangeNotice alloc
							     initWithMatch: match matchAction
							              rule: name
							                at: match range)
						]
					].
				].
				" Only memoize the matches from expressions for which it is safely possible. "
				exp isMemoizable ifTrue: [list addMatch: match at: position named: name].
			] ifFalse: [ match isSuccess ifTrue: [
				ETTranscript debug: 'Pushing back position: '; debug: match stopPosition; debugCr.
				list pushPosition: match stopPosition.
				]
			].
			ETTranscript debug: 'End of non terminal: ', name, ' input pos: '; debug: list positionStack; debug: 'last position: '; debug: list position; debug: ', match: '; debug: match matchText; debugCr.
		].
		^match
	]

	setExpression: anExp [ exp := anExp ]
	description [^name]
]

PKComposeExpression subclass: PKAlphanumericExpression [

	init [
		self initWithExp: (  PKAlphabeticExpression new or: PKNumericExpression new )
	]
	
	description [^'[[:alnum:]]']
]


PKParseExpression subclass: PKTokenExpression [
	| match |

	initWithPattern: matchPattern [
		super init.
		match := matchPattern.
		^self
	]
	
	parseInput: list withCurrentParser: parser delegate: delegate [
		| return |
		((list head: match matchSize) isEqual: match) ifTrue: [ 
			return := PKParseMatch alloc initWithInput: list
								length: match matchSize.
		] ifFalse: [
			return := PKParseFail alloc initWithInput: list description: 'Unexpected token, expected: ', match
		].
		^return
	]

	description [
		^'''', match description, ''''
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

	parseInput: list withCurrentParser: parser delegate: delegate [
		^list atEnd
            ifTrue: [PKParseMatch alloc initWithInput: list length: 0]
			ifFalse: [PKParseFail alloc initWithInput: list description:  'Expected an empty string'] 
	]

	description [
		^ '$'
	]
]

PKParseExpression subclass: PKAnythingExpression [
	| +instance |

	+initialize [
		instance := self new.
	]

	+uniqueInstance [
		^instance
	]

	parseInput: list  withCurrentParser: parser delegate: delegate [ ^PKParseMatch alloc initWithInput: list length: 0]

	description [ ^'']
]

PKParseExpression subclass: PKSequenceExpression [
 	| e1 e2 |

	initWithFirst: exp1 second: exp2 [
		e1 := exp1.
		e2 := exp2.
		^self
	] 

	parseInput: list withCurrentParser: parser delegate: delegate [
		| match1 |
		match1 := e1 parseInput: list withCurrentParser: parser delegate: delegate.
		^match1 isSuccess ifTrue: [
			| match2 |
			match2 := (e2 parseInput: list withCurrentParser: parser delegate: delegate).
			match2 isSuccess 
                ifTrue: [ 
					"ETTranscript debug: 'Merge sequence: ''', match1 matchText, ''' with: ''', match2 matchText, ''''; debugCr."
					match1 sequenceWith: match2 ]
				ifFalse: [ list popPosition. match2 ]
		] ifFalse: [ match1 ]
	]

	expressions [ ^{e1. e2} ]

	seq: exp [
		| multiSeq |
		multiSeq := PKNArySequenceExpression new.
		multiSeq addExpressions: self expressions.
		^multiSeq seq: exp
	]

	description [
		^e1 description, ' ', e2 description
	]

	isMemoizable [ ^e1 isMemoizable ifTrue: [e2 isMemoizable]
			               ifFalse: [false] ]

	isMemoziableForNonTerminal: name inGrammar: grammar [ ^ (e1 isMemoizableForNonTerminal: name inGrammar: grammar) and:
		(e2 isMemoizableForNonTerminal: name inGrammar: grammar) ]
]

PKNAryComposeExpression subclass: PKNArySequenceExpression [

	parseInput: list withCurrentParser: parser delegate: delegate[
		| match |
		match := PKParseMatch emptyMatch: list.
		expressions do: [ :exp|
			match isSuccess ifTrue: [
				| currentMatch |
				currentMatch := exp parseInput: list withCurrentParser: parser delegate: delegate.
				currentMatch isSuccess ifTrue: [ 
					"ETTranscript debug: 'Merge sequence ''', match matchText, ''' with: ''', currentMatch matchText, ''''; debugCr."
					match := match sequenceWith: currentMatch.
				] ifFalse: [
					list popPosition.
					match := PKParseFail new initWithInput: list description: 'Unexpected token, expected: ', exp description
					                                 cause: currentMatch.
				].
			]
		].
		^ match
	]
	
	seq: exp
	[
		((exp isKindOfClass: PKNArySequenceExpression class) or: (exp isKindOfClass: PKSequenceExpression class)) ifTrue: [
			self addExpressions: exp expressions.
		] ifFalse: [ self addExpression: exp ].
		^self
	]

	description [
		^expressions leftFoldWithInitialValue: ''
		                            intoBlock: [ :acc :exp|
			('' = acc) ifTrue: [exp description]
			          ifFalse: [acc, ' ', exp description]
		]
	]
]

PKComposeExpression subclass: PKBindExpression [
	| name |

	initWithExp: exp name: aName [
		super initWithExp: exp.
		name := aName
	]

	parseInput: list withCurrentParser: parser delegate: delegate[
		| match |
		match := exp parseInput: list withCurrentParser: parser delegate: delegate. 
		match bind: name.
		^match
	]

	description [ ^'(', exp description, '):', name ]
	
]

PKComposeExpression subclass: PKLookAheadExpression [

	
	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		match := exp parseInput: list withCurrentParser: parser delegate: delegate.
		match isFailure ifFalse: [list popPosition].
		^match
	]
	
	description [ ^'&(', exp description, ')' ]
]

PKComposeExpression subclass: PKNegateExpression [

	initWithExp: expression [
		super initWithExp: (PKLookAheadExpression alloc initWithExp: expression).
		^self
	]

	description [
		^'!(',exp expression description,')'
	]

	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		match := exp parseInput: list withCurrentParser: parser delegate: delegate.
		^match isSuccess ifTrue: [PKParseFail alloc initWithInput: list description: 'Should not match ', exp description] 
						 ifFalse: [PKParseMatch alloc initWithInput: list length: 0]
	]
]

PKComposeExpression subclass: PKMaybeExpression [
	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		match := exp parseInput: list withCurrentParser: parser delegate: delegate.
		^match isSuccess ifTrue: [match]
						 ifFalse: [ PKParseMatch alloc initWithInput: list length: 0 ]
	]
	
	description [^'(', exp description, ')?']
]

PKParseExpression subclass: PKAlternateExpression [
     | first second |

	initWithExp: exp1 or: exp2 [
		first := exp1.
		second := exp2
	]

	parseInput: list withCurrentParser: parser delegate: delegate[
		 ^first parseInput: list  withCurrentParser: parser delegate: delegate ifFailed: [
			 | match |
			 match := second parseInput: list withCurrentParser: parser delegate: delegate.
			 match isFailure 
                 ifTrue:[ PKParseFail alloc initWithInput: list description: 'Expected ', self description]
				 ifFalse: [match]
		 ]		
	 ]

	expressions [ ^{first. second} ]

	or: exp [
		| multiOr |
		multiOr := PKNAryAlternateExpression new.
		multiOr addExpression: first; addExpression: second.
		
		^multiOr or: exp.
	]

	description [
		^first description, ' / ', second description
	]
	
	isMemoizable [ ^first isMemoizable ifTrue: [second isMemoizable]
			                  ifFalse: [false] ]

	isMemoziableForNonTerminal: name inGrammar: grammar [ ^ (first isMemoizableForNonTerminal: name inGrammar: grammar) and:
		(second isMemoizableForNonTerminal: name inGrammar: grammar) ]

]

PKNAryComposeExpression subclass: PKNAryAlternateExpression [
	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		match := PKParseFail alloc initWithInput: list description: 'Expected ', self description.
		expressions do: [ :exp |
			match isSuccess ifFalse: [
				| currentMatch |
				currentMatch := exp parseInput: list withCurrentParser: parser delegate: delegate.
				currentMatch isSuccess ifTrue: [ match := currentMatch ]
			]
		].
		^match
	]
	
	description [
		^expressions leftFoldWithInitialValue: ''
		                            intoBlock: [ :acc :exp|
			('' = acc) ifTrue: [exp description]
			          ifFalse: [acc, ' / ', exp description]
		]
	]

	or: exp [
		((exp isKindOfClass: PKNAryAlternateExpression class) or: (exp isKindOfClass: PKAlternateExpression class)) ifTrue: [
			self addExpressions: exp expressions.
		] ifFalse: [ self addExpression: exp ]
	]
]



PKComposeExpression subclass: PKRepetitionExpression [
	| canBeEmpty |

	initWithExpression: anExp canBeEmpty: aBool [
		super init.
		exp := anExp.
		canBeEmpty := aBool.
		^self
	]
	
	parseInput: list withCurrentParser: parser delegate: delegate[
		| match currentMatch |
		match := PKParseMatch emptyMatch: list.
		[
			currentMatch := exp parseInput: list withCurrentParser: parser delegate: delegate.
			currentMatch isSuccess
		] whileTrue: [ 
			"ETTranscript debug: 'Merge repetition ', match matchText, ' with: ', currentMatch matchText; debugCr."
			match := match sequenceWith: currentMatch.
		].
		^(match isEmpty and: canBeEmpty not) 
            ifTrue: [list popPosition. PKParseFail new initWithInput: list description: 'Unexpected token, expected: ', exp description
	                                                           cause: currentMatch ]
			ifFalse: [match]
	]

	description [
		^exp description , (canBeEmpty ifTrue: ['*'] ifFalse: ['+'])
	]
]

PKParseExpression subclass: PKNonTerminalLookup [
	| grammar name |
	initWithGrammar: aGrammar name: aName [
		grammar := aGrammar.
		name := aName
	]

	parseInput: list withCurrentParser: parser delegate: delegate [
		"ETTranscript debug: 'Apply ', name, ' at: '; debug: list position; debugCr."
		"This allow expression to apply super rules or self rules"
		^(grammar == nil ) ifTrue: [parser matchStream: list rule: name delegate: delegate] 
						   ifFalse: [grammar matchStream: list rule: name delegate: delegate]
	]

	isMemoizable [ 
		(grammar == nil) ifTrue: [^true].
		^(grammar rules lookup: name ifFailed: [^false]) isMemoizableForNonTerminal: name inGrammar: grammar ]

	isMemoizableForNonTerminal: aName inGrammar: aGrammar [ 
		(grammar == nil) ifTrue: [^true].
		^((grammar == aGrammar) and: (name = aName)) ifTrue: [true] 
													 ifFalse: [self isMemoizable]
	]
	description [ ^name ]
]

"
============================================================================
  
  Basic (string) input stream and related utilities

============================================================================
"

"The environment stack maintains a scoped list of all bound variables in an 
 OMeta parse tree."
NSObject subclass: PKEnvironmentStack [
	| environmentStack top |
	init [
		environmentStack := NSMutableArray new.
		top := NSMutableDictionary new.
		top setValue: NSMutableDictionary new
		      forKey: '$_matches'.
		^self
	]

	setValue: val forKey: key [
		top setValue: val forKey: key.
	]

	setObject: obj forKey: key [
		self setValue: obj forKey: key.
	]

	setAction: action forKey: key fromMatch: match [
		self setValue: action forKey: key.
		self registerMatch: match forKey: key.
	]

	registerMatch: match forKey: name [
		(top objectForKey: '$_matches') setValue: match forKey: name.
	]
	objectForKey: key [
		| object |
		object := top objectForKey: key.
		^(object == nil) ifTrue: [ self searchStackFor: key ]
		                ifFalse: [ object ]	
	]

	searchStackFor: key [
		| object |
		object := nil.
		" The stack top is at index 0, so we can just iterate over the array to
		  return the most locally scoped binding first. "
		environmentStack do: [ :each |
			(nil == object) ifTrue: [
				object := each objectForKey: key.
			]
		].
		^object
	]


	" This method replaces the value of a binding in place. This is needed for
	  predicates that reduce their arguments during parsing. "
	replaceObject: newObject forKey: key [
		| oldObject |
		oldObject := top objectForKey: key.
		((oldObject == nil) not) ifTrue: [top setObject: newObject forKey: key]
		                     ifFalse: [
			environmentStack do: [ :each |
				(nil == oldObject) ifTrue: [
					oldObject := each objectForKey: key.
					(nil == oldObject) ifFalse: [each setObject: newObject
					                                     forKey: key].
				]
			]
		]
	]

	pushEnvironment [
		environmentStack insertObject: top atIndex: 0.
		top := NSMutableDictionary new.
		top setValue: NSMutableDictionary new
		      forKey: '$_matches'.
	]

	popEnvironment [
		self restoreActions.
		top := environmentStack objectAtIndex: 0.
		environmentStack removeObjectAtIndex: 0.
	]

	" It is necessary to restore actions for memoized matches "
	restoreActions [
		| matches |
		matches := top objectForKey: '$_matches'.
		matches allKeys do: [ :each |
			|match action |
			match := matches objectForKey: each.
			action := top objectForKey: each.
			"Only perform the restore if there is no new action that has overriden this one"
			(match matchAction == nil) ifTrue: [
				match attachAction: action
			] ifFalse: [
				"But we also reattach the action if the new one is only implicit "
				match matchAction isExplicitAction ifFalse: [ match attachAction: action ].
			].	
		].
	]

	description [ ^'Env stack: ', environmentStack description, ' top: ', top description]
]

"
  PKInputStream maintains the position into the stream being parsed, the
  corresponding environment and memoized matches.
  
  Subclassing note: Input stream subclasses that want to parse something other
  than strings need to override -substreamWithRange:, -emptyStream and
  potentially -length.
"
NSObject subclass: PKInputStream [
    | memo stream position positionStack environmentStack |

    initWithStream: input [
	super init.
	stream := input.
	memo := NSMutableDictionary new.
	positionStack := NSMutableArray new.
	position := 0.
	environmentStack := PKEnvironmentStack new.
	self
]

	description [
		^(self substreamWithRange: (NSValue rangeWithLocation: position length: (self length) - position)), ' pos: ', positionStack description
	]

	inEnvironmentDo: aBlock [
		environmentStack pushEnvironment.
		aBlock value.
		environmentStack popEnvironment.
	]

	bind: name object: anObject [
		environmentStack setValue: anObject forKey: name

	]

	bind: name action: anAction match: match [
		environmentStack setAction: anAction forKey: name fromMatch: match.
	]

	environment [^environmentStack ]

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
		^(range length == 0) ifTrue: [self emptyStream]
			ifFalse: [
				self substreamWithRange: range]
	]

	head [
		^self head: 1
	]
	
	head: size [
		"Todo non local return seems broken"
		^(position + size) > self length ifTrue: [self emptyStream]
			ifFalse: [self fromRange: (NSValue rangeWithLocation: position length: size)]
	]

	mergePosition [
		positionStack count >= 2 ifFalse: [NSException raise: 'PKParser' format: 'Not enought position to merge'].
		positionStack removeLastObject
	]

	position [^position]
	positionStack [^positionStack]
	length [ ^stream length]
	atEnd [^self position = self length]
	
	stream [ ^stream ]

	substreamWithRange: range [
		^stream substringWithRange: range
	]

	emptyStream [ ^'']
]

"
============================================================================
  
  Match classes

============================================================================
"

NSObject subclass: PKParseMatch [
	| input range action delegate |

	+emptyMatch: input [
        ^self new initWithInput: input length: 0; 
			yourself
	]

	initWithInput: list length: length [
		super init.
		action := nil.
		input := list.
		range := (NSValue rangeWithLocation: input position length: length).
		input pushPosition: range length + range location.
		^self
	]
	
	copyInitWith: list range: aRange [
		input := list.
		range := aRange.
		action := nil
	]

	sequenceWith: match [
		| newMatch |
		input mergePosition.
		input lastPosition = range location ifFalse: [
			"Can be remove or rephrase later."
			NSException raise: 'ParseKit' format: 'Last position is not same as the location range, something is wrong here range loc: ', range location description, ' last input: ', input lastPosition description, ' match: ', match description, ' merge with: ', self description ].
		(range location + range length) = match range location
			ifFalse: [ NSException raise: 'ParserKit' format: 'Can not add the range, it is not contiguous'].
		newMatch := self class alloc copyInitWith: input range: (NSValue rangeWithLocation: range location length: (range length + match  range length)).
		(action == nil and: match matchAction == nil) ifFalse: [
			newMatch attachAction: NSDelayActionArray new.
			" It is important to attach the verbatim matches from matches that do not require actions,
			  but only if it's no the empty match (esp. since every sequence matching starts with the
			  empty match."
			(action == nil) ifTrue: [self isEmpty ifFalse: [ newMatch sequenceAction: self matchText ]]
			               ifFalse: [newMatch sequenceAction: action].
			(match matchAction == nil) ifTrue: [newMatch isEmpty ifFalse: [newMatch sequenceAction: match matchText]]
			                          ifFalse: [newMatch sequenceAction: match matchAction].
		].
		^newMatch
	]

	bind: name [
		action == nil
            ifTrue: [input bind: name object: (input fromRange: range)]
			ifFalse: [input bind: name action: action match: self. action := nil]
	]
	
	setDelegate: anObject  [ delegate := anObject ]

	sequenceAction: anAction [ 
		action == nil 
			ifTrue:  [action := anAction]
			ifFalse: [ action := action addAction: anAction ]
	]

	attachAction: anAction [
		" There might still be an attached action if the result was not bound.
		  In this case, it is safe to assume that the result of the evaluation 
		  is irrelevant to reducing the expression at hand. 
		  FIXME: People might potentially be interested in the side-effects..."
		action := anAction.	
	]

	matchAction [^action]
	match  [ ^(input fromRange: range)]
	isEmpty [ ^range length = 0]
	isSuccess [ ^true ]
	isFailure [ ^false ]
	range [^range]
	reduce [^action == nil ifTrue: [nil] ifFalse: [action reduceOn: delegate]]
    stopPosition [^range length + range location]
	matchText [^ input fromRange: range]
	description [
		^'PKMatchSuccess  ( Recognized: ''', self matchText , ''' location: ', range description,' action: ', action description, ')\n' 
	]
]


NSObject subclass: PKParseFail [
	| input failedPosition describ delegate cause |

	initWithInput: list description: string cause: theCause [
		super init.
		describ := string.
		input := list.
		cause := theCause.
		failedPosition := input position.
		^self
	]
	initWithInput: list description: string [
		^self initWithInput: list description: string cause: nil
	]

	cause [
		^(cause == nil) ifTrue: [ self ]
		                ifFalse: [ cause cause ]
	]  

	setDelegate: anObject  [ delegate := anObject]
	stopPosition [^failedPosition]
	isFailure [ ^true ]
	isSuccess [ ^false ]
	matchAction [^nil]
	matchText [^'PKParseFail']
	bind: name ["No sensible thing can be done here"]
	description [
		| desc |
		 desc := 'PKMatchFailure  ( At: ''',   failedPosition description, ''', ', input stream, ') ', describ, '\n'.
		(nil == cause) ifFalse: [desc := desc, 'Cause: ', self cause description, '\n'].
		^desc. 
	]
]

"
============================================================================
  
  Main parser class and builtin declarations of the Étoilé oMeta dialect.
  
============================================================================
"


"
  PKRules encapsulates the rules set up by a single grammar.
"
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
			| ruleExp |
			ruleExp := PKNonTerminalExpression alloc initWithName: rule exp: nil.
			rules setValue: ruleExp forKey: rule.
			ruleExp
		]
	]

	addRule: name expression: exp [
		| rule |
		rule := rules objectForKey: name.
		rule == nil ifTrue: [
			rule := PKNonTerminalExpression alloc initWithName: name exp: exp.
		    rules setValue: rule forKey: name
		] ifFalse: [
			rule setExpression: exp
		].
		^rule
	]

	lookup: rule ifFailed: aBlock [
		| return |
		return := rules objectForKey: rule.
		return == nil ifTrue:[
			parent == nil
                ifTrue: [ return := aBlock value ]
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

	name [ ^name ]

	description [
		| desc |
		desc := name.
		parent == nil ifFalse: [ desc := desc, ' : ', parent name ].
		desc := desc, ' {\n'.
		rules allKeys do: [:key | 
			desc := desc, key, ' <- ', (rules objectForKey: key) expression description, '\n'
		].
		^desc, '}'	
	]
		
	subgrammar: string [
		^self class alloc initWithParent: self name: string
	]
]


NSObject subclass: PKParser [
	| +rulesRepo input rules delegate |

	+initialize [
		rulesRepo := NSMutableDictionary new.
		self actionizedParserGrammar.
		self loadGrammarsFromBundle: NSBundle mainBundle.
 	]

	+actionizedParserGrammar [
		| ocParser |
		ocParser := (self parserGrammar) subgrammar: '_ActionizedEtoileOMeta'.
		ocParser addRule: 'Nullary' expression: (((ocParser at: 'Identifier') bind: 'nullary')
			actionSelector: #makeNullarySelector: arguments: {'nullary'}).
		ocParser addRule: 'Keyword' expression: ((ocParser at: 'IdentStart') seq: (ocParser at: 'IdentCont') repeat seq: (ocParser at: 'COLON')).
		ocParser addRule: 'KeywordMessagePart' expression: ((((ocParser at: 'Keyword') bind: 'selectorPart')
			seq: ((ocParser at: 'Identifier') bind: 'argument'))
				actionSelector: #makeKeywordMessagePart:argument: arguments: {'selectorPart'. 'argument'}).
		ocParser addRule: 'KeywordMessage' expression: (((ocParser at: 'KeywordMessagePart') repeatOneLeast bind: 'selectorArgumentPairs')
			actionSelector: #makeSelectorAndArguments: arguments: {'selectorArgumentPairs'}).
		ocParser addRule: 'Statements' expression: ((ocParser at: 'KeywordMessage') or: (ocParser at: 'Nullary')).
		^ocParser
	]

	+parserGrammar [
		| oMeta  |
		oMeta := PKParser alloc initWithNewGrammar: '_EtoileOMeta'.
		oMeta addRule: 'EndOfLine' expression: ('\r\n' asExp or: '\n' asExp).
		oMeta addRule: 'Space' expression: (PKWhitespaceExpression new or: (oMeta at: 'EndOfLine')).
		oMeta addRule: 'Comment' expression: ('#' asExp seq: ((oMeta at: 'EndOfLine') not 
            seq: (PKDotExpression new) ) repeat seq: (oMeta at: 'EndOfLine')).
		oMeta addRule: 'Spacing' expression: ((((oMeta at: 'Space') or: (oMeta at: 'Comment')) repeat) actionSelector: #makeEmpty arguments: {}).
		oMeta addRule: 'HexDigit' expression: ((PKRangeExpression alloc initFrom: '0' to: '9') or: (PKRangeExpression alloc initFrom: 'A' to: 'F')).
		oMeta addRule: 'DOT' expression: ((('.' asExp bind: 'expr') seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'DOLLAR' expression: ((('$' asExp bind: 'expr') seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'COLON' expression: (((':' asExp bind: 'expr') seq: (oMeta at: 'Spacing'))restrict:  'expr'  ).
		oMeta addRule: 'CLOSE' expression: ((( ')' asExp  bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ). 
		oMeta addRule: 'OPEN' expression: ((( '(' asExp  bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'CCLOSE' expression: ((( '}' asExp  bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ). 
		oMeta addRule: 'COPEN' expression: ((( '{' asExp  bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'ACLOSE' expression: ((( ']' asExp  bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ). 
		oMeta addRule: 'AOPEN' expression: ((( '[' asExp  bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'PLUS' expression: ((('+' asExp bind: 'expr') seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'STAR' expression: ((('*' asExp bind: 'expr') seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'QUESTION' expression: ((('?' asExp bind: 'expr')  seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'NOT' expression: ((('!' asExp bind: 'expr') seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'SLASH' expression: (( '/' asExp seq: (oMeta at: 'Spacing')) actionSelector: #orJunction arguments: {}).
		oMeta addRule: 'AND' expression: ((('&' asExp bind: 'expr') seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'LEFTARROW' expression: ((( '<-' asExp   bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'RIGHTARROW' expression: ((( '->' asExp   bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'CARET' expression: ((('^' asExp   bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'Char' expression: 
			((('\' asExp seq: ({'n' . 'r' . 't' . ''''. '"' . '[' . ']'. '\'} joinAll bind: 'specialChar'))  
                          actionSelector: #parseSpecialChar: arguments: {'specialChar'})
				or: (('\' asExp seq: (((oMeta at: 'HexDigit') 
							    seq: (oMeta at: 'HexDigit')) bind: 'hexChar'))
				  actionSelector: #parseHexChar: arguments: {'hexChar'})
			    or: ('\' asExp not seq: (PKDotExpression new)  )).
		oMeta addRule: 'BuiltinRange' expression: ((('[:' asExp) seq: 
			(((('alpha' asExp) or: ('alnum' asExp) or: ('digit' asExp))
				or: ('lower' asExp) or: ('upper' asExp) or: ('space' asExp))
			 bind: 'builtinRange')
			seq: (':]' asExp)) actionSelector: #makeBuiltinRange: arguments: {'builtinRange'}).
		oMeta addRule: 'Range' expression: (((((oMeta at: 'Char') bind: 'first') 
        	seq: '-' asExp seq: ((oMeta at: 'Char') bind: 'second')) 
				 actionSelector: #makeRangeFrom:to: arguments: {'first'. 'second'})
		or: (oMeta at: 'BuiltinRange')
        	or: (((oMeta at: 'Char') bind: 'tok') actionSelector: #makeToken: arguments: {'tok'})).
		oMeta addRule: 'Class' expression: (('[' asExp 
			seq: ((']' asExp not seq: (oMeta at: 'Range')) repeat bind: 'rangeList')
                	seq: ']' asExp 
                	seq: (oMeta at: 'Spacing')) actionSelector: #join: arguments: {'rangeList'}).
		oMeta addRule: 'Literal' expression: ((('''' asExp 
                seq: (('''' asExp not seq: (oMeta at: 'Char')) repeat bind: 'literal') 
				seq: '''' asExp seq: (oMeta at: 'Spacing') ) 
			or: ('"' asExp 
                seq: (('"' asExp not seq: (oMeta at: 'Char')) repeat bind: 'literal') 
				seq: '"' asExp seq: (oMeta at: 'Spacing') ))
		  actionSelector: #makeLiteral: arguments: {'literal'}).
		oMeta addRule: 'IdentStart'  expression: ((PKRangeExpression alloc initFrom: 'a' to: 'z') 
			or: (PKRangeExpression alloc initFrom: 'A' to: 'Z')
			or: '_' asExp).
		oMeta addRule: 'IdentCont' expression: ((oMeta at: 'IdentStart') or: (PKRangeExpression alloc initFrom: '0' to: '9')).
		oMeta addRule: 'Identifier' expression: (((((oMeta at: 'IdentStart') seq: ((oMeta at: 'IdentCont') repeat)) bind: 'ident') seq: (oMeta at: 'Spacing'))
			restrict: 'ident').
		oMeta addRule: 'SuperRuleApplication' expression: (((oMeta at: 'CARET') seq: ((oMeta at: 'Identifier') bind: 'rule'))
			actionSelector: #makeRuleLookup:fromSuperGrammar: arguments: {'rule'. 'superGrammar'}).
		oMeta addRule: 'ForeignRuleApplication' expression: ((((oMeta at: 'Identifier') bind: 'grammar')
			seq: ('::' asExp)
			seq: ((oMeta at: 'Identifier') bind: 'rule'))
				actionSelector: #makeRuleLookup:fromGrammar: arguments: {'rule'. 'grammar'}).
		oMeta addRule: 'RuleApplication' expression: ((oMeta at: 'SuperRuleApplication')
			or: (oMeta at: 'ForeignRuleApplication')
			or: ((((oMeta at: 'Identifier') bind: 'rule') seq: ((oMeta at: 'LEFTARROW') not))
				actionSelector: #makeRuleLookup: arguments: {'rule'})).
		oMeta addRule: 'ParenthesizedExpression' expression: (((oMeta at: 'OPEN')
			seq: ((oMeta at: 'Expression') bind: 'expr')
			seq: (oMeta at: 'CLOSE'))
				restrict: 'expr').
		oMeta addRule: 'Primary' expression: (((((oMeta at: 'RuleApplication') bind: 'expr') seq: (oMeta at: 'LEFTARROW') not)
				restrict: 'expr')
			or: (oMeta at: 'ParenthesizedExpression')
			or: (oMeta at: 'Literal')
			or: (oMeta at: 'Class')
			or: (((oMeta at: 'DOT') actionSelector: #makeWildcard arguments: {})
				or: ((oMeta at: 'DOLLAR') actionSelector: #makeEOF arguments: {}))).
		oMeta addRule: 'Suffix' expression: ((((oMeta at: 'Primary') bind: 'expression')
            seq: (((oMeta at: 'QUESTION') or: (oMeta at: 'STAR') or: (oMeta at: 'PLUS')) maybe bind: 'modifier')
			seq: ((oMeta at: 'Binding') maybe bind: 'bindingName')
			seq: ((oMeta at: 'Predicate') maybe bind: 'predicate'))
			   actionSelector: #makeExpression:modifier:bind:predicate: arguments: {'expression'. 'modifier'. 'bindingName'. 'predicate'}).
		oMeta addRule: 'Prefix' expression: ((((((oMeta at: 'AND') or: (oMeta at: 'NOT')) maybe bind: 'junction') 
            seq: ((oMeta at: 'Suffix') bind: 'expression'))
			   actionSelector: #makePrefix:exp: arguments: {'junction'. 'expression'})
			or: (((oMeta at: 'Binding') bind: 'bindingName')
				actionSelector: #makeAnythingBind: arguments: {'bindingName'})).
		oMeta addRule: 'Action' expression: (((oMeta at: 'RIGHTARROW')
			seq: (oMeta at: 'AOPEN')
			seq: ((oMeta at: 'Statements') bind: 'actionStatements')
			seq: (oMeta at: 'ACLOSE'))
				actionSelector: #makeAction: arguments: {'actionStatements'}).
		oMeta addRule: 'Restriction' expression: (((oMeta at: 'RIGHTARROW')
			seq: ((oMeta at: 'Identifier') bind: 'bindingName'))
				actionSelector: #makeRestriction: arguments: { 'bindingName' }).
		oMeta addRule: 'Binding' expression: ((':' asExp seq: ((oMeta at: 'Identifier') bind: 'bindingName')) restrict: 'bindingName').
		oMeta addRule: 'Predicate' expression: (((oMeta at: 'QUESTION') seq: (oMeta at: 'OPEN') seq: ((oMeta at: 'Identifier') bind: 'target')
		    seq: ((oMeta at: 'Statements') bind: 'predicateMessage') seq: (oMeta at: 'CLOSE'))
		       actionSelector: #makePredicate:target: arguments: {'predicateMessage'. 'target'}). 
		oMeta addRule: 'Sequence' expression: ((((oMeta at: 'Prefix')  repeat bind: 'expressions')
        	seq: (((oMeta at: 'Action') or: (oMeta at: 'Restriction')) maybe bind: 'action'))
				actionSelector: #makeSequenceExpression:actionOrRestriction: arguments: {'expressions'. 'action'}).
		oMeta addRule: 'Expression' expression: ((((oMeta at: 'Sequence') bind: 'expression1')
			seq: ((((oMeta at: 'SLASH')
			seq: (oMeta at: 'Sequence')) repeat) bind: 'alternative'))
				actionSelector: #makeAlternativeExpression:alternative: arguments: { 'expression1'. 'alternative' }).
		oMeta addRule: 'Definition' expression: ((((oMeta at: 'Identifier') bind: 'ruleName')
			seq: (oMeta at: 'LEFTARROW')
			seq: ((oMeta at: 'Expression') bind: 'ruleExpression'))
				actionSelector: #makeRule:expression: arguments: {'ruleName'. 'ruleExpression'}).
		oMeta addRule: 'Grammar' expression: (((oMeta at: 'Spacing') seq: (((oMeta at: 'Definition') repeatOneLeast) bind: 'expr'))
			restrict:  'expr').
		oMeta addRule: 'SuperGrammarIdentifier' expression: (((oMeta at: 'COLON') seq: ((oMeta at: 'Identifier') bind: 'super'))
			actionSelector: #makeSuperGrammar: arguments: {'super'}).
		oMeta addRule: 'Ometa' expression: ((((oMeta at: 'Identifier') bind: 'grammar')
			seq: (((oMeta at: 'SuperGrammarIdentifier') maybe bind: 'superGrammar'))
            seq: (oMeta at: 'COPEN')
			seq: ((oMeta at: 'Grammar') bind: 'grammarList')
			seq: (oMeta at: 'CCLOSE'))
				actionSelector: #makeGrammar:parent:rules: arguments: {'grammar'. 'superGrammar'. 'grammarList'}).
		oMeta addRule: 'OmetaList' expression: (((oMeta at: 'Spacing') 
            seq: (((oMeta at: 'Ometa') repeatOneLeast) bind: 'grammars')
			seq: PKEmptyExpression uniqueInstance)
				restrict: 'grammars').
		^oMeta
	]

	+derivate: parent subgrammar: name [
		| rule newRule |
		newRule := parent subgrammar: name.
		rulesRepo setValue: newRule forKey: name.
		^newRule
	]

	+getGrammar: name [
		| rule |
		rule := rulesRepo objectForKey: name.
		rule == nil ifTrue: [
			^NSException raise: 'ParserKit' format: 'Cannot load grammar ''', name, ''''
		].
		^rule	
	]

	+getNewGrammar: name [
		| rule |
		rule := PKRules alloc initWithName: name.
		rulesRepo setValue: rule forKey: name.
		^rule	
	]

	setDelegate: anObject [
		delegate := anObject
	]

	+supportsGrammar: name [
		^((rulesRepo objectForKey: name) == nil) not.
	]

	+loadGrammarsFromBundle: bundle [
		|files|
		files := bundle pathsForResourcesOfType: 'pk'
		                            inDirectory: nil.
		files leftFoldWithInitialValue: {}
		                     intoBlock: [ :acc :each|
			acc arrayByAddingObjectsFromArray:
			  (self loadGrammarsFromString: (NSString stringWithContentsOfFile: each)).
		] 
	]
	
	+loadGrammarsFromString: string [
		| parserParser internalDelegate match grammars notificationCenter |
		internalDelegate := PKParserRuleGenerator new.
		parserParser := PKParser alloc initWithGrammar: '_ActionizedEtoileOMeta'.
		parserParser setDelegate: internalDelegate.
		match := parserParser match: string rule: 'OmetaList'.
		"TODO: Smarter error reporting."
		match isSuccess ifFalse: [NSException raise: 'PKParserException' format: 'Could not load grammar.'].
		notificationCenter := NSNotificationCenter defaultCenter.
		grammars := match reduce asArray.
		grammars do: [ :each|
			notificationCenter postNotificationName: 'PKParserGrammarBecameAvailable'
			                                 object: self
                                           userInfo: (NSDictionary dictionaryWithObject: (each name)
			                                 forKey: 'name').
		].
		^grammars map: [ :each | each name ].
	]
    

	initWithGrammar: grammarName [
		super init.
		rules := self class getGrammar: grammarName.
		^self
	]

	initWithNewGrammar: grammarName [
		super init.
		rules := self class getNewGrammar: grammarName.
		^self
	]

	subgrammar: name [
		rules := self class derivate: rules subgrammar: name.
	]

	at: rule [
		^PKNonTerminalLookup alloc initWithGrammar: self name: rule
	]

	addRule: name expression: exp  [
		rules addRule: name expression: exp
	]

	description [
		^rules description
	]
	

	apply: rule [
		^self apply: rule withInit: nil delegate: delegate 
	]

	apply: rule withInit: init delegate: aDelegate[
		| exp |
		exp := rules lookup: rule ifFailed: [
			NSException raise: 'ParserKit' format: ('Invalid rule ', rule)
		].
		(init == nil) ifFalse: [ exp := init seq: exp ].
		^exp parseInput: input withCurrentParser: self delegate: aDelegate.
	]
	
	match: inputStream rule: rule [
		^self matchStream: (PKInputStream alloc initWithStream: inputStream)
		             rule: rule
		         withInit: (rules lookup: '__init__' ifFailed: [nil])
			 delegate: delegate.
	]

	matchStream: stream rule: rule delegate: aDelegate [
		^self matchStream: stream rule: rule withInit: nil delegate: aDelegate.
	]
	
	matchStream: stream rule: rule withInit: init delegate: aDelegate [
		|match|
		(aDelegate == nil) ifTrue: [aDelegate := delegate].
		input := stream.	
		match := self apply: rule withInit: init delegate: aDelegate.
		match setDelegate: aDelegate.
		^match
	]

	rules  [ ^rules ]
   

	getMatchWithInput: list length: len  [
		^PKParseMatch alloc initWithInput: list length: len.
	]

	getMatchCopyWithInput: list range: range  [
		^PKParseMatch alloc copyInitWith: list range: range.
	]

	getEmptyMatch: list [
		^PKParseMatch emptyMatch: list
	]


	getFailureWithInput: list description: desc cause: cause [
		^PKParseFail alloc initWithInput: list description: desc cause: cause.
	]
]


"
============================================================================
Delegate and utilities to parse oMeta grammars
============================================================================
"

"
  Expression generator, presently only used for alternative expressions.
"
NSObject subclass: PKAstExpressionGen [
	| expression operation |

	initWithExp: exp operation: op [
		expression := exp.
		operation := op
	]

	reduce: exp [
		exp == nil 
            ifFalse: [ expression ]
			ifTrue: [ operation value: exp value: expression ]
	]
]


"
  The purpose of the delayed expression builder is to defer generating
  expressions that depend on global state until after the entire grammar
  has been parsed.
"
NSObject subclass: PKDelayedExpressionBuilder [
	| block exp |

	initWithBlock: aBlock [
		block := aBlock.
		exp := nil.
		^self.
	]

	initWithExp: anExp [
		exp := anExp.
		block := nil.
		^self
	]

	asExp [ ^self ]
	
	bind: name [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value bind: name ].
		
	]

	repeat [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value repeat ].
	]
	
	repeatOneLeast [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value repeatOneLeast ].
	]

	maybe [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value maybe ].
	]

	parameter: predicate [
		^PKDelayedExpressionBuilder alloc initWithBlock: [ self value parameter: predicate ].
	]

	semanticAction: action [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value semanticAction: action ].
	]

	restrict: binding [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value restrict: binding ].
	]

	not [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value not ].
	]

	lookahead [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value lookahead ].
	]

	seq: exp [
		^(exp isKindOfClass: PKDelayedExpressionBuilder class) ifTrue: [
			PKDelayedExpressionBuilder alloc initWithBlock: [self value seq: exp value ]
		] ifFalse: [
			PKDelayedExpressionBuilder alloc initWithBlock: [self value seq: exp ]
		]
	]

	or: exp [
		^(exp isKindOfClass: PKDelayedExpressionBuilder class) ifTrue: [
			PKDelayedExpressionBuilder alloc initWithBlock: [self value or: exp value ]
		] ifFalse: [
			PKDelayedExpressionBuilder alloc initWithBlock: [self value or: exp ]
		]
	]
	
	value [ ^(nil == exp) ifTrue: [ block value ]
		                 ifFalse: [ exp ]	
	]
]


NSObject subclass: PKParserAbstractGenerator [
	| delegate specialCharToChar |

	init [
		super init.
		specialCharToChar := NSMutableDictionary new.
		specialCharToChar setValue: '\n' forKey: 'n'.
		specialCharToChar setValue: '\t' forKey: 't'.
		specialCharToChar setValue: '\r' forKey: 'r'.
		specialCharToChar setValue: '\\' forKey: '\\'.
		specialCharToChar setValue: '''' forKey: ''''.
		specialCharToChar setValue: '"' forKey: '"'.
		specialCharToChar setValue: '[' forKey: '['.
		specialCharToChar setValue: ']' forKey: ']'.
		^self
	]

	setDelegate: aDelegate [
		delegate := aDelegate
	]	

	makeEmpty [^'']

	parseSpecialChar: char [
		^specialCharToChar objectForKey: char
	]

	parseHexChar: value [
		| scanner return |
		scanner := NSScanner scannerWithString: value.
		return := NSMutableString new.
		return appendCharacter: scanner hexIntegerValue.
		^return
	]

]
"
  Delegate class that generates a grammar. The main entry point is
  #makeGrammar:parent:rules. That method also installs the parsed grammars into
  the rule repository.

  Dependencies on foreign grammars are not yet automatically resolved. You need
  to make sure that all referenced grammars have already been registered.
"
PKParserAbstractGenerator subclass: PKParserRuleGenerator [

	makeLiteral: literal [
		| result |
		(literal isKindOfClass: NSArray class) ifTrue: [
			result := literal componentsJoinedByString: ''.
		] ifFalse: [ result := literal ].
		^result asExp
	]

	makeRangeFrom: first to: second [
		^PKRangeExpression alloc initFrom: first to: second.
	]

	makeBuiltinRange: builtin [
		| exp |
		'alpha' = builtin ifTrue: [exp := PKAlphabeticExpression new].	
		'alnum' = builtin ifTrue: [exp := PKAlphanumericExpression new].	
		'digit' = builtin ifTrue: [exp := PKNumericExpression new].	
		'lower' = builtin ifTrue: [exp := PKLowercaseExpression new].	
		'upper' = builtin ifTrue: [exp := PKUppercaseExpression new].	
		'space' = builtin ifTrue: [exp := PKWhitespaceExpression new].	

		^exp
	]

	makeToken: tok [
		^PKTokenExpression alloc initWithPattern: tok

	]

	makeSuperGrammar: sup [
		^PKParser getGrammar: sup.
	]

	makeGrammar: grammarName parent: superGrammar rules: rules [
		| grammar |
		"Note: The grammars returned by PKParser are actually PKRules instances."
		'' = superGrammar ifTrue: [
			grammar := PKParser getNewGrammar: grammarName
		] ifFalse: [
			grammar := PKParser derivate: superGrammar subgrammar: grammarName.
		].
		ETTranscript debug: 'Building grammar ''', grammarName, ''''; debugCr.
		
		rules do: [ :each |
			| name expression |
			name := each objectForKey: 'rule'.
			expression := each objectForKey: 'expression'.
			" We need to materialize expressions whose building has been delayed
			  because the need to know about the grammars. "
			(expression isKindOfClass: PKDelayedExpressionBuilder class) ifTrue: [
				expression := expression value.
			].
			ETTranscript debug: 'Adding rule ''', name, ''' expression: ', (expression description); debugCr.
			grammar addRule: name expression: expression.
		].
		delegate ifResponds loadedGrammar: grammarName.
		^grammar 
	]

	makeNullarySelector: sel [
		^sel selValue
	]



	makeEOF [^PKEmptyExpression uniqueInstance]

	makeKeywordMessagePart: keyword argument: arg [
		^NSDictionary dictionaryWithObjects: { keyword componentsJoinedByString: ''. arg }
		                            forKeys: { 'selectorPart'. 'argumentName' }
	]

	makeSelectorAndArguments: components [
		| selector args |
		selector := ''.
		args := NSMutableArray new.
		(components isKindOfClass: NSArray class) ifFalse: [ components := { components } ].
		components do: [ :each |
			selector := selector, (each objectForKey: 'selectorPart').
			args addObject: (each objectForKey: 'argumentName').
		].
		^ NSDictionary dictionaryWithObjects: { selector. args }
		                             forKeys: { 'selector'. 'arguments' }
	]

	makeAction: actionInfo [
		^(actionInfo isKindOfClass: NSDictionary class) ifTrue: [
			PKParseAction alloc initWithSelector: (actionInfo objectForKey: 'selector')
		     	                   argumentNames: (actionInfo objectForKey: 'arguments') 	
		] ifFalse: [
			PKParseAction alloc initWithSelector: actionInfo argumentNames: nil
		]
	]

	makeRestriction: binding [
		^PKParseRestriction alloc initWithBinding: binding
	]

	makePredicate: predicateInfo target: target [
		^(predicateInfo isKindOfClass: NSDictionary class) ifTrue: [
			PKParsePredicate alloc initWithTargetName: target
			                                 selector: (predicateInfo objectForKey: 'selector')
			                            argumentNames: (predicateInfo objectForKey: 'arguments')
		] ifFalse: [
			PKParsePredicate alloc initWithTargetName: target
			                                 selector: predicateInfo
			                            argumentNames: nil
		]
	]

	makeRule: ruleName expression: expression [
		^NSDictionary dictionaryWithObjects: { ruleName. expression }
                                    forKeys: { 'rule'. 'expression' }	
	] 

	makeExpression: expression modifier: mode bind: name predicate: predicate [
		mode = '+' ifTrue: [ expression := expression repeatOneLeast ].
		mode = '*' ifTrue: [ expression := expression repeat ].
		mode = '?' ifTrue: [ expression := expression maybe ].
		name = '' ifFalse: [ expression := expression bind: name ].
		predicate = '' ifFalse: [ expression parameter: predicate ].
		^expression
	]

	makePrefix: junction exp: expression [
		junction = '!' ifTrue: [ expression := expression not ].
		junction = '&' ifTrue: [ expression := expression lookahead ].	
		^expression
	]

	makeSequenceExpression: expressions actionOrRestriction: action [
		| expression |
		(expressions isKindOfClass: NSArray class) ifTrue: [
			expression := expressions leftFoldWithInitialValue: nil
			                                         intoBlock: [ :acc :exp|
				(nil == acc) ifTrue: [ exp ]
				            ifFalse: [ 
					"If the argument and not the receiver is a delayed builder, we need to wrap
					 the receiver in one."
					(acc isKindOfClass: PKDelayedExpressionBuilder class) ifFalse: [
						(exp isKindOfClass: PKDelayedExpressionBuilder class) ifTrue: [
							acc := PKDelayedExpressionBuilder alloc initWithExp: acc
						]
					].
					acc seq: exp ]
			].
		] ifFalse: [
			expression := expressions.
		].
		action = '' ifFalse: [
			(action isKindOfClass: (PKParseAction class)) ifTrue: [
				expression := expression semanticAction: action
			] ifFalse: [
				"It's a restriction statement, but we need to unpack the binding again"
				expression := expression restrict: action description.
			].
		].
		^expression.
	]
	
	makeAlternativeExpression: exp1 alternative: alts [
		| expression |
		'' = alts ifTrue: [ expression := exp1 ]
		       ifFalse: [
			| op expectObj |
			expectObj := false.
			op := nil.
			expression := alts leftFoldWithInitialValue: exp1
			                                  intoBlock: [ :acc :expOrBlock|
				expectObj ifTrue: [
					" The current value is an object, we make sure that the next is being
					  interpreted as a block and update the accumulator by executing the block. "
					expectObj := false.
					"If the argument and not the receiver is a delayed builder, we need to wrap
					 the receiver in one."
					(acc isKindOfClass: PKDelayedExpressionBuilder class) ifFalse: [
						(expOrBlock isKindOfClass: PKDelayedExpressionBuilder class) ifTrue: [
							acc := PKDelayedExpressionBuilder alloc initWithExp: acc
						]
					].
					op value: acc value: expOrBlock
				] ifFalse: [
					" The next element will be an object, we store the operation and return the
					  present state of the accumulator. " 
					op := expOrBlock.
					expectObj := true.
					acc
				]
			].
		].
		^expression
	]
	
	" Returns a closure that is wrapped in an expressionBuilder which can be
	  evaluated by the action creating the grammar in order to install the rule
	  lookup. "
	makeRuleLookup: ruleName fromGrammar: grammarName [
		^PKDelayedExpressionBuilder alloc initWithBlock: [
			PKNonTerminalLookup alloc initWithGrammar: (PKParser alloc initWithGrammar: grammarName)
			                                     name: ruleName
		]
	]

	makeRuleLookup: ruleName [
		^PKDelayedExpressionBuilder alloc initWithBlock: [
			PKNonTerminalLookup alloc initWithGrammar: nil
			                                     name: ruleName
		]
	]

	" Super lookups are less problematic because the super grammar is
	  required to be resolved prior to the grammar we are parsing right
	  now. "
	makeRuleLookup: ruleName fromSuperGrammar: superGrammar [
		^PKNonTerminalLookup alloc initWithGrammar: superGrammar
			                              name: ruleName
	]


	orJunction [^[:exp1 :exp2 | exp1 or: exp2 ]]
	seqJunction [^[:exp1 :exp2 | exp1 seq: exp2 ]]

	makeWildcard [^PKDotExpression new]

	makeAnythingBind: name [ ^(PKAnythingExpression uniqueInstance) bind: name ]

	join: list [
		^list joinAll
	]

	sequence: list [
		^list sequenceAll
	]
]


PKParserAbstractGenerator subclass: PKParserASTGenerator [
	| +rangeBuiltinSelectors |

	+initialize [
		rangeBuiltinSelectors := NSDictionary alloc initWithObjects:
		  { 'isAlphabetic' . 'isUppercase' . 'isLowercase' . 'isDigit' . 'isAlphanumeric' . 'isWhitespace' }
		                                                    forKeys:
		  { 'alpha' . 'upper' . 'lower' . 'digit' . 'alnum' . 'space' }
	]

	+selectorForBuiltinRange: name [ ^rangeBuiltinSelectors objectForKey: name ]

	init [
		super init.
		^self
	]


	" Reference to the superclass ivar for the input stream "
	inputRef [ ^LKDeclRef referenceWithSymbol: 'input' ]

	" Reference to the superclass ivar for the delegate "
	delegateRef [ ^LKDeclRef referenceWithSymbol: 'delegate' ]

	" Gets a failure at the present position the description string will be 
	  turned into a literal, cause is supposed to be nil or a reference to 
	  the failure causing this one. "
	getFailureWithDescription: desc cause: cause [
		| descLiteral causeRef msg |
		cause == nil ifTrue: [ causeRef := LKNilRef builtin ]
		            ifFalse: [ causeRef := cause ].
		descLiteral := LKLiteral literalFromString: desc.
		msg := LKMessageSend messageWithSelectorName: 'getFailWithInput:description:cause:'
		arguments: { self inputRef . descLiteral . causeRef }.
		msg setTarget: (LKSelfRef referenceWithSymbol: 'self').
		^msg
	]

	" Gets a match of the specified length. "
	getMatchOfLength: len [
		| msg |
		msg := LKMessageSend messageWithSelectorName: 'getMatchWithInput:length:'
		arguments: { self inputRef . len }.
		msg setTarget: (LKSelfRef referenceWithSymbol: 'self').
		^msg
	]

	getEmptyMatch [
		| msg |
		msg := LKMessageSend messageWithSelectorName: 'getEmptyMatch:'
		arguments: { self inputRef }.
		msg setTarget: (LKSelfRef referenceWithSymbol: 'self').
		^msg
	]

	ifAtEndThenFailElse: elseStatements [
		| isAtEnd |
		isAtEnd := LKMessageSend messageWithSelectorName: 'atEnd'.
		isAtEnd setTarget: self inputRef.
		^LKIfStatement ifStatementWithCondition: isAtEnd
		                                   then: { self getFailureWithDescription: 'Unexpected end of stream' cause: nil }
		                                   else: elseStatements
		
	]

	makeLiteral: literal [
		| theLit litLen listHead comparison |
		(literal isKindOfClass: NSArray class) ifTrue: [
			theLit := literal componentsJoinedByString: ''.
		] ifFalse: [ theLit := literal ].
		" Build LKLiterals for the literal we are matching and its length. "
		litLen := LKNumberLiteral literalFromString: ((theLit matchSize) stringValue).
		theLit := LKLiteral literalFromString: theLit.

		" Message send to obtain the appropriate number of characters from the input
		  stream "
		listHead := LKMessageSend messageWithSelectorName: 'head:'
		                                        arguments: { litLen }.
		listHead setTarget: self inputRef.

		" Message send to check whether the literal matches the head of the stream "
		comparison := LKMessageSend messageWithSelectorName: 'isEqual:'
		                                          arguments: { listHead }.
		comparison setTarget: theLit.
		^LKIfStatement ifStatementWithCondition: comparison
		                                   then: { self getMatchOfLength: litLen }
		                                   else: {
		  self getFailureWithDescription: ('Expected literal "', theLit description, '"') cause: nil }
	]

	makeToken: tok [ self makeLiteral: tok ]

	makeWildcard [
		| isAtEnd getHead getHeadLength|
		isAtEnd := LKMessageSend messageWithSelectorName: 'atEnd'.
		isAtEnd setTarget: self inputRef.
		getHead := LKMessageSend messageWithSelectorName: 'head'.
		getHead setTarget: self inputRef.
		getHeadLength := LKMessageSend messageWithSelectorName: 'length'.
		getHeadLength setTarget: getHead.
		^LKIfStatement ifStatementWithCondition: isAtEnd
		                                   then: { self getFailureWithDescription: 'Unexpected end of stream' cause: nil }
		                                   else: { self getMatchOfLength: getHeadLength }
		
	]

	makeEOF [ 
		| isAtEnd |
		isAtEnd := LKMessageSend messageWithSelectorName: 'atEnd'.
		isAtEnd setTarget: self inputRef.
		^LKIfStatement ifStatementWithCondition: isAtEnd
		                                   then: { self getEmptyMatch }
		                                   else: { self getFailureWithDescription: 'Expected end of stream' cause: nil }

	]

	makeGrammar: grammarName parent: parent rules: method [
		ETTranscript show:  'makeGrammar ', grammarName, ' parent ', parent, ' rules, ', method description; cr.
		ETTranscript show: 'First rule '; show:  method first.
	]

	makeRuleLookup: ruleName fromSelf: selfName [
		| msg |
		msg := LKMessageSend messageWithSelectorName: ('_rule_', ruleName).
		msg setTarget: (LKSelfRef referenceWithSymbol: 'self').
		^msg.
	]

	makeRuleLookup: ruleName fromSuperGrammar: superGrammar [
		| msg |
		msg := LKMessageSend messageWithSelectorName: ('_rule_', ruleName).
		msg setTarget: (LKSuperRef referenceWithSymbol: 'super').
		^msg.
	]

	makeRuleLookup: ruleName fromGrammar: grammarName [
		| lookupMsg parseMsg  |
		" Foreign rule invocations require us to obtain a parser for the grammar and
		  invoke the method corresponding to the rule from there. "
		lookupMsg := LKMessageSend messageWithSelectorName: 'parserForGrammar:'
                                                         arguments: { (LKLiteral literalFromString: grammarName) }.
		lookupMsg setTarget: LKSelfRef referenceWithSymbol: 'self'.
		parseMsg := LKMessageSend messageWithSelectorName: ('_rule_', ruleName).
		parseMsg setTarget: lookupMsg.
		^parseMsg.
	]

	makeBuiltinRange: name [	
		| listHead charAtIndex comparison |

		listHead := LKMessageSend messageWithSelectorName: 'head'.
		listHead setTarget: self inputRef.
		charAtIndex := LKMessageSend messageWithSelectorName: 'characterAtIndex:'
		                                           arguments: { LKNumberLiteral literalFromString: '0' }.
		charAtIndex setTarget: listHead.

		" look up the character class test selector and check whether the character matches"
		comparison := LKMessageSend messageWithSelectorName: (PKParserASTGenerator selectorForBuiltinRange: name).
		comparison setTarget: charAtIndex.
		^self ifAtEndThenFailElse: { 
		  LKIfStatement ifStatementWithCondition: comparison
		                                    then: { self getMatchOfLength: (LKNumberLiteral literalFromString: '1') }
		                                    else: {
		    self getFailureWithDescription: ('Expected character from class [:', name, ':]') cause: nil }
		  }
	]

	makeRangeFrom: first to: last [
		| block lteLast gteFirst predicate listHead charAtIndex charAssign matchIf blockInvoke |
		listHead := LKMessageSend messageWithSelectorName: 'head'.
		listHead setTarget: self inputRef.
		charAtIndex := LKMessageSend messageWithSelectorName: 'characterAtIndex:'
		                                           arguments: { LKNumberLiteral literalFromString: '0' }.
		charAtIndex setTarget: listHead.
		charAssign := LKAssignExpr assignWithTarget: (LKDeclRef referenceWithSymbol: 'charValue')
		                                       expr: charAtIndex.
		lteLast := LKMessageSend messageWithSelectorName: 'isLessThanOrEqualTo:'
			                                   arguments:
		  { LKNumberLiteral literalFromString: ((last characterAtIndex: 0) stringValue) }.
		lteLast setTarget: (LKDeclRef referenceWithSymbol: 'charValue').
		gteFirst := LKMessageSend messageWithSelectorName: 'isGreaterThanOrEqualTo:'
			                                   arguments:
		  { LKNumberLiteral literalFromString: ((first characterAtIndex: 0) stringValue) }.
		gteFirst setTarget: (LKDeclRef referenceWithSymbol: 'charValue').
		predicate := LKMessageSend messageWithSelectorName: 'and:'
                                                 arguments: { lteLast }.
		predicate setTarget: gteFirst.
		matchIf := LKIfStatement ifStatementWithCondition: predicate
		  then: { self getMatchOfLength: (LKNumberLiteral literalFromString: '1') }
		  else: { self getFailureWithDescription: ('Expected character [', first, '-', last, ']') cause: nil }.
		block := LKBlockExpr blockWithArguments: {} locals: { 'charValue' } statements: {charAssign . matchIf }.
		blockInvoke := LKMessageSend messageWithSelectorName: 'value'.
		blockInvoke setTarget: block.
		^self ifAtEndThenFailElse: { blockInvoke }
	]


]

