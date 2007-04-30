#define GDM_GREETER_PROTOCOL_VERSION "3"

#define GDM_MSG		'D'
#define GDM_NOECHO	'U'
#define GDM_PROMPT	'N'
#define GDM_SESS	'G'
#define GDM_LANG	'&'
#define GDM_SSESS	'C'
#define GDM_SLANG	'R'
#define GDM_RESET	'A'
#define GDM_QUIT	'P'

#define GDM_STARTTIMER	's'
#define GDM_STOPTIMER	'S'
#define GDM_SETLOGIN	'l'

#define GDM_DISABLE	'-'
#define GDM_ENABLE	'+'
#define GDM_RESETOK	'r'
#define GDM_NEEDPIC	'#'
#define GDM_READPIC	'%'
#define GDM_ERRBOX	'e'
#define GDM_ERRDLG	'E'
#define GDM_NOFOCUS	'f'
#define GDM_FOCUS	'F'
#define GDM_SAVEDIE	'!'
#define GDM_QUERY_CAPSLOCK 'Q'

#define GDM_INTERRUPT_TIMED_LOGIN	'T'
#define GDM_INTERRUPT_CONFIGURE		'C'
#define GDM_INTERRUPT_SUSPEND		'S'
#define GDM_INTERRUPT_SELECT_USER	'U'
#define GDM_INTERRUPT_LOGIN_SOUND	'L'
#define GDM_INTERRUPT_THEME		'H'

#define DISPLAY_REMANAGE 2 // restart display
#define DISPLAY_ABORT 4 // houston, we've got a problem
#define DISPLAY_REBOOT 8 // reboot..
#define DISPLAY_HALT 16 // halt..
#define DISPLAY_SUSPEND 17 // suspend..
#define DISPLAY_CHOSEN 20 // successful chooser session, restart display
#define DISPLAY_RUN_CHOOSER 30 // run chooser
#define DISPLAY_XFAILED 64 // X failed
#define DISPLAY_GREETERFAILED 65 // greeter failed (crashed)
#define DISPLAY_RESTARTGREETER 127 // restart greeter...
#define DISPLAY_RESTARTGDM 128 // restart gdm...
