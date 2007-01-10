
CFLAGS += -g

all: ETThread.o ETThreadProxyReturn.o ETThreadTest.o ETThreadedObject.o NSObject+Threaded.o
	$(CC) -framework Foundation $^

clean:
	@rm -f *.o

ETThread.o: ETThread.m ETThread.h
ETThreadProxyReturn.o: ETThreadProxyReturn.m ETThreadProxyReturn.h
ETThreadTest.o: ETThreadTest.m NSObject+Threaded.h
ETThreadedObject.o: ETThreadedObject.m ETThreadedObject.h ETThread.h
NSObject+Threaded.o: NSObject+Threaded.m NSObject+Threaded.h ETThread.h \
  ETThreadedObject.h ETThreadProxyReturn.h
