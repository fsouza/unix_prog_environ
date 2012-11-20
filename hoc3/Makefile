OBJS = hoc.o init.o math.o symbol.o

YFLAGS = -d

hoc3: $(OBJS)
	$(CC) $(OBJS) -o hoc3

y.tab.h: hoc.o

hoc.o: hoc.h

init.o symbol.o: hoc.h y.tab.h

clean:
	rm -f $(OBJS) y.tab.h hoc.c
