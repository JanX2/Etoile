
CFLAGS += -g

all: EtoileThread.o EtoileThreadProxyReturn.o EtoileThreadTest.o EtoileThreadedObject.o NSObject+Threaded.o NSObject+Futures.o
	$(CC) -framework Foundation $^ -o EtoileThreadTest

clean:
	@rm -f *.o


EtoileThread.o: EtoileThread.m EtoileThread.h
EtoileThreadProxyReturn.o: EtoileThreadProxyReturn.m \
  EtoileThreadProxyReturn.h
EtoileThreadTest.o: EtoileThreadTest.m NSObject+Threaded.h \
  EtoileThreadProxyReturn.h
EtoileThreadedObject.o: EtoileThreadedObject.m EtoileThreadedObject.h \
  EtoileThread.h EtoileThreadProxyReturn.h
NSObject+Futures.o: NSObject+Futures.m NSObject+Futures.h
NSObject+Threaded.o: NSObject+Threaded.m NSObject+Threaded.h \
  EtoileThread.h EtoileThreadedObject.h EtoileThreadProxyReturn.h
