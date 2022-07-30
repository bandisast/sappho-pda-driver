INCDIR = Inc
SRCDIR = Src
OBJDIR = Build
CC=gcc
CFLAGS=-I$(INCDIR)

_DEPS = pda_drivers.h gpio.h sample_file.h debug.h
DEPS = $(patsubst %,$(INCDIR)/%,$(_DEPS))

_OBJ = pda_drivers.o gpio.o sample_file.o debug.o
OBJ = $(patsubst %,$(OBJDIR)/%,$(_OBJ))

LIBS = -lpthread -lprussdrv -lm

$(OBJDIR)/%.o: $(SRCDIR)/%.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)
	
sappho_exec: $(OBJ)
	$(CC) -o $@ $^ $(CFLAGS) $(LIBS)
	
.PHONY: clean

clean:
	rm -f $(OBJDIR)/*.o *~ core
	@echo Done cleaning....