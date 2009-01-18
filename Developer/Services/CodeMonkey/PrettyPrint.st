
LKAST extend [
    prettyprint [
	| writer |
	writer := IndentedWriter new.
	self prettyprintToWriter: writer.
	^ writer value
    ]
    
    prettyprintToWriter: writer [
	"The default implementation: A lispy coloured output that
	also prints the AST node's class name."
	"writer append: '('."
	"writer blue: [ writer append: self className; append: ' '. ]."
	"writer red: [ writer append: self description. ]."
	writer append: self description.
	"writer append: ')'."
    ]
]

LKToken extend [
    prettyprintToWriter: writer [
	writer append: self.
    ]
]

LKIfStatement extend [
    prettyprintToWriter: writer [
	condition prettyprintToWriter: writer.
    ]
]

LKComment extend [
    prettyprintToWriter: writer [
	writer blue: self description.
    ]
]

LKCompilationUnit extend [
    prettyprintToWriter: writer [
	classes do: [ :class |
	    class prettyprintToWriter: writer.
	].
	categories do: [ :category |
	    category prettyprintToWriter: writer.
	].
    ]
]

LKCategoryDef extend [
    prettyprintToWriter: writer [
        writer append: classname; append: ' extend ['; cr.
        writer indent: [
	        methods do: [ :method |
                method prettyprintToWriter: writer.
	        ].
        ].
        writer append: ']'; cr.
    ]
]

LKSubclass extend [
    prettyprintToWriter: writer [
        writer append: superclass; append: ' subclass: ';
               append: classname; append: ' ['; cr.
	    
	    writer indent: [
	        (ivars count > 0) ifTrue: [
                writer append: '| '.
                ivars do: [ :ivar |
                    writer append: ivar; append: ' '.
                ].
                writer append: '|'; cr; cr.
	        ].
	        
            methods do: [ :method |
                method prettyprintToWriter: writer.
            ].
        ].
    
    writer append: ']'; cr.
    ]
]

LKMethod extend [
    prettyprintToWriter: writer [
        "signature prettyprintToWriter: writer."
        "writer append: ' ['; cr."
	"writer indent: ["
	    "Print local variables"
	    (symbols locals count > 0) ifTrue: [
	        writer append: '| '.
	        symbols locals do: [ :symbol |
		    writer italic: symbol; append: ' '.
		].
		writer append: '|'; cr.
	    ].
	    "Print statements"
	    statements do: [ :stmt |
	        stmt prettyprintToWriter: writer.
		writer append: '.'; cr.
	    ].
	"]."
	"writer append: ']'; cr."
    ]
]

LKMessageSend extend [
    xxxprettyprintToWriter: writer [
	| sel |
	target prettyprintToWriter: writer.
	writer append: ' '.
	sel := selector componentsSeparatedByString: ':'.
	ETTranscript show: 'selector: '; show: selector.
	ETTranscript show: ' nb: '; show: sel count; cr.
	0 to: sel count do: [:x|
		ETTranscript show: x; cr.
		(x < sel count) ifTrue: [
			ETTranscript show: x; show: ' '; show: (sel objectAtIndex: x); cr.
		]
	].
	ETTranscript show: 'done iterating.'.
	sel count = 1 ifTrue: [
		writer append: selector.
	] ifFalse: [
		ETTranscript show: 'sel: '; show: 0; cr.
		writer append: (sel objectAtIndex: 0).
	].
	1 to: arguments count do: [ :i |
		ETTranscript show: 'args: '; show: i; cr.
		ETTranscript show: 'sel count: '; show: sel count; cr.
		ETTranscript show: 'args count: '; show: arguments count; cr.
		(i < sel count) ifTrue: [
			writer append: ' '.
			writer append: (sel objectAtIndex: i).
		].
		writer append: ':'.
		writer append: (arguments objectAtIndex: i).
	]
    ]
    xxprettyprintToWriter: writer [
        | sel |
	"Debugging"
	writer append: '(msgsend '.
	
	sel = selector componentsSeparatedByString: ':'.
	"XXX: This comparison doesn't work."
	sel count = 1 ifTrue: [
	    writer green: [ writer append: selector. ].
	] ifFalse: [
	    "XXX: Keyword messages not done yet, looping with
	    integers is hard at the moment."
	    writer red: [ writer append: self description. ].
	].
	
	"Debugging"
	writer append: ')'.
    ]
]

LKAssignExpr extend [
    prettyprintToWriter: writer [
	target prettyprintToWriter: writer.
	writer append: ' := '.
	expr prettyprintToWriter: writer.
    ]
]

LKStringLiteral extend [
    prettyprintToWriter: writer [
        writer green: self description.
    ]
]

LKDeclRef extend [
    prettyprintToWriter: writer [
	 ((symbols scopeOfSymbol: symbol) > 4) ifTrue: [
		"ivar and cvar"
		writer bold: self description.
	] ifFalse: [
	 	((symbols scopeOfSymbol: symbol) = 4) ifTrue: [
			writer italic: self description.
		] ifFalse: [
			writer append: self description.
		]
	].
    ]
]

LKBlockExpr extend [
    prettyprintToWriter: writer [
	writer append: '['; cr.
	writer indent: [
		statements do: [ :stmt |
			stmt prettyprintToWriter: writer.
			writer append: '.'; cr.
		].
	].
	writer append: ']'.
    ]
]

NSObject subclass: IndentedWriter [
    | buffer indent termred termgreen termblue atstart attrs s |
    
    init [
	"XXX How can I make -init return nil without nonlocal returns
	and without assigning to self?"
        super init == nil ifFalse: [
	    buffer := NSMutableAttributedString new.
	    indent := 0.
	    termred := NSColor redColor.
	    termgreen := NSColor greenColor.
	    termblue := NSColor blueColor.
	    "We begin at the start of a line."
	    atstart := true.
	].
	^ self.
    ]
    
    append: str [
        atstart ifTrue: [
            indent timesRepeat: [
	        buffer appendAttributedString: 
			(NSMutableAttributedString alloc initWithString: ' ').
	    ].
	].
	buffer appendAttributedString: 
		(NSMutableAttributedString alloc initWithString: str).
	atstart := false.
    ]

    cr [
	buffer appendAttributedString: 
		(NSMutableAttributedString alloc initWithString: '\n').
	atstart := true.
    ]
    
    red: str [
	self write: str withColor: termred.
    ]
    
    green: str [
	self write: str withColor: termgreen.
    ]
    
    blue: str [
	self write: str withColor: termblue.
    ]

    bold: str [
	attrs := NSMutableDictionary new.
	attrs setObject: (NSFont boldSystemFontOfSize: 12) forKey: 'NSFontAttributeName'.
	s := NSMutableAttributedString alloc initWithString: str attributes: attrs.
	buffer appendAttributedString: s.
	s release.
    ]

    italic: str [
	| font |
	font := (NSFont systemFontOfSize: 12) italic.
	attrs := NSMutableDictionary new.
	attrs setObject: font forKey: 'NSFontAttributeName'.
	s := NSMutableAttributedString alloc initWithString: str attributes: attrs.
	buffer appendAttributedString: s.
	s release.
    ]

    write: str withColor: color [
        atstart ifTrue: [
            indent timesRepeat: [
	        buffer appendAttributedString: 
			(NSMutableAttributedString alloc initWithString: ' ').
	    ].
	].
	attrs := NSMutableDictionary new.
	attrs setObject: color forKey: 'NSForegroundColorAttributeName'.
	s := NSMutableAttributedString alloc initWithString: str attributes: attrs.
	buffer appendAttributedString: s.
	s release.
	atstart := false.
    ]
    
    inColor: color write: block [
        "self append: color."
	block value.
    ]
    
    indent: block [
	indent := indent + 4.
	block value.
	indent := indent - 4.
    ]
    
    value [
	^ buffer
    ]
]

NSObject subclass: SmalltalkTool [
    filename [
	^ 'test.st'
    ]
    
    run [
	| ast program parser |
	1 to: 3 do: [:x| ETTranscript show: 'plop: '; show: x; cr. ].
	program := NSString stringWithContentsOfFile: self filename.
	parser := SmalltalkParser new.
	ast := parser parseString: program.
	ETTranscript show: ast prettyprint; cr.
    ]
]
