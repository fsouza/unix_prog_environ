OBJS = hoc.o code.o init.o math.o symbol.o

YFLAGS = -d

hoc5: $(OBJS)
	$(CC) $(OBJS) -o hoc5

y.tab.h: hoc.o

hoc.o code.o init.o symbol.o: hoc.h

code.o init.o symbol.o: hoc.h y.tab.h

clean:
	rm -f $(OBJS) y.tab.h hoc.c
