
NSMutableAttributedString extend [
    addAttribute: name value: attribute [
	| range |
	range := (NSValue rangeWithLocation: 0 length: self length).
	self addAttribute: name value: attribute range: range.
    ]
    setAttributes: attributes [
	| range |
	range := (NSValue rangeWithLocation: 0 length: self length).
	self setAttributes: attributes range: range.
    ]
]

NSObject subclass: PrettyPrintWriter [
    | textSize buffer indent termred termgreen termblue atstart |
    
    init [
	"XXX How can I make -init return nil without nonlocal returns
	and without assigning to self?"
        super init == nil ifFalse: [
	    textSize := 16.
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
    
    makeString: str [
	| s attributes |
	attributes := NSMutableDictionary new.
	attributes setObject: (NSFont systemFontOfSize: textSize) forKey: 'NSFontAttributeName'.
	s := NSMutableAttributedString alloc initWithString: str attributes: attributes.
	^ s.
    ]

    append: str [
	self appendString: (self makeString: str).
    ]

    appendString: str [
        atstart ifTrue: [
            indent timesRepeat: [
		buffer appendAttributedString: (self makeString: ' ').
	    ].
	].
	buffer appendAttributedString: str.
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

    commentToken: str [
	| s font color |
	s := self makeString: str.
	font := (NSFont systemFontOfSize: textSize) italic.
	color := (NSColor colorWithCalibratedRed: '0.0' green: '0.0' blue: '0.4' alpha: '1.0').
	s addAttribute: 'NSForegroundColorAttributeName' value: color.
	s addAttribute: 'NSFontAttributeName' value: font.
	self appendString: s.
    ]


    selectorToken: str [
	| s font color |
	s := self makeString: str.
	font := (NSFont boldSystemFontOfSize: textSize).
	color := (NSColor colorWithCalibratedRed: '0.3' green: '0.1' blue: '0.1' alpha: '1.0').
	s addAttribute: 'NSForegroundColorAttributeName' value: color.
	s addAttribute: 'NSFontAttributeName' value: font.
	self appendString: s.
    ]

    stringToken: str [
	| s font color |
	s := self makeString: str.
	font := (NSFont systemFontOfSize: textSize) italic.
	color := (NSColor brownColor).
	s addAttribute: 'NSForegroundColorAttributeName' value: color.
	s addAttribute: 'NSFontAttributeName' value: font.
	self appendString: s.
    ]

    localVariableToken: str [
	| s font color |
	s := self makeString: str.
	font := (NSFont systemFontOfSize: textSize) italic.
	color := (NSColor darkGrayColor).
	s addAttribute: 'NSForegroundColorAttributeName' value: color.
	s addAttribute: 'NSFontAttributeName' value: font.
	self appendString: s.
    ]

    bold: str [
	| s font |
	font := NSFont boldSystemFontOfSize: textSize.
	s := self makeString: str.
	s addAttribute: 'NSFontAttributeName' value: font.
	self appendString: s.
    ]

    italic: str [
	| s font |
	font := (NSFont systemFontOfSize: textSize) italic.
	s := self makeString: str.
	s addAttribute: 'NSFontAttributeName' value: font.
	self appendString: s.
    ]

    write: str withColor: color [
	| s |
	s := self makeString: str.
	s addAttribute: 'NSForegroundColorAttributeName' value: color.
	self appendString: s.
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

