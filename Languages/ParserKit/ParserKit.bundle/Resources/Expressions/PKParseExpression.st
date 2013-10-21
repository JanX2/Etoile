"
Root class for all expression for the interpreted parser.
This class and all it's subclass should only be used for bootstrapping the parser.
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

