/*#io
docCopyright("Steve Dekorte", 2002)
docLicense("BSD revised")
*/

// loop

IoObject *IoObject_loop(IoObject *self, IoObject *locals, IoMessage *m);
IoObject *IoObject_while(IoObject *self, IoObject *locals, IoMessage *m);
IoObject *IoObject_foreachSlot(IoObject *self, IoObject *locals, IoMessage *m);
IoObject *IoObject_for(IoObject *self, IoObject *locals, IoMessage *m);

// break

IoObject *IoObject_returnIfNonNil(IoObject *self, IoObject *locals, IoMessage *m);
IoObject *IoObject_return(IoObject *self, IoObject *locals, IoMessage *m);
IoObject *IoObject_break(IoObject *self, IoObject *locals, IoMessage *m);
IoObject *IoObject_continue(IoObject *self, IoObject *locals, IoMessage *m);
IoObject *IoObject_eol(IoObject *self, IoObject *locals, IoMessage *m);

// branch 

IoObject *IoObject_if(IoObject *self, IoObject *locals, IoMessage *m);

// tail call

IoObject *IoObject_tailCall(IoObject *self, IoObject *locals, IoMessage *m);
