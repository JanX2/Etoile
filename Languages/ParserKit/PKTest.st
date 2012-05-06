"
============================================================================
  ParserKit.st -- OMeta like parser implementation
/NS
  Copyright (C) 2011 Mathieu Suen <mathieu@nebu.li>

  The parser have the same syntax that the OMeta one. Although the semantic 
  could differ. For the time being to write expression use the 
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

NSObject subclass: SmalltalkTool [
	
	run [
		| dict parser abStar b c tExp alphaNumeric parameterized multiSequence multiAlternate oMeta oMetaMatch content contentString match |

		ETTranscript setDebugMode: false.
		abStar := PKRepetitionExpression alloc
					 initWithExpression: 'ab' asExp
					 canBeEmpty: false; yourself.

		parser := abStar or: 'a' asExp.
		parser := ('c' asExp repeat) seq: parser seq: PKEmptyExpression uniqueInstance.
		alphaNumeric  := PKAlphanumericExpression new repeat.
		parameterized := (PKNumericExpression new bind: 'num') parameterTarget: 'num' selector: #isLessThan: arguments: {'7'}.
		multiSequence := PKNArySequenceExpression new.
		multiSequence addExpression: ('c' asExp repeat); addExpression: parser; addExpression: PKEmptyExpression uniqueInstance.
		multiAlternate := PKNAryAlternateExpression new.
		multiAlternate addExpression: ('c' asExp); addExpression: ('d' asExp); addExpression: ('e' asExp).
		multiAlternate := multiAlternate repeat.
		oMeta := PKParser alloc initWithNewGrammar: 'Test'.
		oMeta addRule: 'alphaNum'  expression: alphaNumeric.
		ETTranscript show: (parser parseInput: 'cab' asInputStream); cr.
		ETTranscript show: (multiSequence parseInput: 'cab' asInputStream); cr.
		ETTranscript show: (multiAlternate parseInput: 'cde' asInputStream); cr.
		ETTranscript show: alphaNumeric; cr.
		ETTranscript show: (alphaNumeric parseInput: 'Good34'  asInputStream); cr.
		ETTranscript show: (alphaNumeric parseInput: 'testing4'  asInputStream); cr.
		ETTranscript show: (parameterized parseInput: '6' asInputStream); cr.
		ETTranscript show: (parameterized parseInput: '8' asInputStream); cr.
		ETTranscript show: (oMeta match: 'testing4' rule: 'alphaNum'); cr.
		oMeta := PKParser alloc initWithGrammar: '_ActionizedEtoileOMeta'.
		ETTranscript show: oMeta rules; cr.
		ETTranscript show: oMeta; cr.
		ETTranscript show: (oMeta at: 'Char'); cr.
		ETTranscript show: (oMeta match:( '\\n') rule: 'Char').
		ETTranscript show: (oMeta match:('n') rule: 'Char').
		ETTranscript show: (oMeta match:( '\66') rule: 'Char').
		ETTranscript show: (oMeta match:( '\F8') rule: 'Char').
		ETTranscript show: (oMeta match:( '\6E') rule: 'Char').
		ETTranscript show: (oMeta match:( '\6A') rule: 'Char').
		ETTranscript show: (oMeta match:( '\66-\F4') rule: 'Range').
		ETTranscript show: (oMeta match:( 'a-d') rule: 'Range').
		ETTranscript show: (oMeta match:( '[a-d] ') rule: 'Class').
		ETTranscript show: (oMeta match:( '[a-d\34] ') rule: 'Class').
		ETTranscript show: (oMeta match:( '[a-dA-Z]\n') rule: 'Class').
		ETTranscript show: (oMeta match:( '''foo'' bar') rule: 'Literal').
		ETTranscript show: (oMeta match:( '"bar" foo') rule: 'Literal').
		ETTranscript show: (oMeta match:( '. ? ') rule: 'Suffix').
		ETTranscript show: (oMeta match:( '([zf]"oo")?') rule: 'Suffix').
		ETTranscript show: (oMeta match: '' rule: 'Spacing').
		ETTranscript show: (oMeta match: 'One <- .' rule: 'Grammar').
		ETTranscript show: (oMeta match: 'EndOfLine <- "\r\n"' rule: 'Grammar').
		ETTranscript show: (oMeta match: 'Ometa { EndOfLine <- "\r\n" }' rule: 'Ometa').
		ETTranscript show: (oMeta match: 'Foo' rule: 'Identifier').
		oMeta setDelegate: (PKParserASTGenerator new).
		oMetaMatch := oMeta match:  '"\r\n"' rule: 'Literal'.
		ETTranscript show: oMetaMatch description;cr.
		oMetaMatch reduce.
		content := NSFileManager defaultManager contentsAtPath: './ometa.pk'.
		contentString := NSString alloc initWithData: content encoding: 4.
		self testSubgrammar.
		
		ETTranscript show: (PKParser loadGrammarsFromString: contentString); cr.
		ETTranscript show: (PKParser getGrammar: 'ActionizedEtoileOMeta') description; cr.

		match := oMeta match: '''test''' rule: 'Literal'.
		ETTranscript show: match reduce; cr.
		match := oMeta match: '[:alnum:]' rule: 'BuiltinRange'.
		ETTranscript show: match reduce; cr.
		match := oMeta match: '.' rule: 'Primary'.
		ETTranscript show: match reduce; cr.
		match := oMeta match: '$' rule: 'Primary'.
		ETTranscript show: match reduce; cr.
		match := oMeta match: 'a-d' rule: 'Range'.
		ETTranscript show: match reduce; cr.
		
		match := oMeta match:( '[a-d] ') rule: 'Class'.
		ETTranscript show: match.
		ETTranscript show: match reduce; cr.

		match := oMeta match:( '[a-d\34] ') rule: 'Class'.
		ETTranscript show: match.
		ETTranscript show: match reduce; cr.

		match := oMeta match:( '\\t') rule: 'Char'.
		ETTranscript show: match.
		ETTranscript show: match reduce; cr.

		match := oMeta match:( '\\n') rule: 'Char'.
		ETTranscript show: match.
		ETTranscript show: match reduce; cr.

		match := oMeta match:( '\\\\') rule: 'Char'.
		ETTranscript show: match.
		ETTranscript show: match reduce; cr.

		match := oMeta match:( '\5F') rule: 'Char'.
		ETTranscript show: match.
		ETTranscript show: match reduce; cr.

		
	]

	testSubgrammar [
		|grammar sub|
		grammar := PKParser alloc initWithNewGrammar: 'PEG'.
		grammar addRule: 'Ab' expression: ('a' asExp or: 'b' asExp).
		ETTranscript show: (grammar match: 'b'  rule: 'Ab').

		sub := grammar subgrammar: 'PEG2'.
		sub addRule: 'Ab' expression: ('c' asExp or: 'd' asExp).
		ETTranscript show: (sub match: 'b'  rule: 'Ab').
		ETTranscript show: (sub match: 'c'  rule: 'Ab').
	]

]

