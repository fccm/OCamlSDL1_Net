OCAMLC := ocamlc
OCAMLOPT := ocamlopt
OCAMLMKLIB := ocamlmklib

all: cma cmxa
byte cma: sdlnet.cma
opt cmxa: sdlnet.cmxa
.PHONY: all cma cmxa byte opt

INC_DIR := /usr/include/SDL
#INC_DIR := /usr/local/include/SDL
LIB_DIR := /usr/lib
#LIB_DIR := /usr/local/lib
LDLIBS := -lSDL -lSDL_net

sdlnet.mli: sdlnet.ml
	$(OCAMLC) -i $< > $@

sdlnet.cmi: sdlnet.mli
	$(OCAMLC) -c $<

sdlnet.cmo: sdlnet.ml sdlnet.cmi
	$(OCAMLC) -c $<

sdlnet.cmx: sdlnet.ml sdlnet.cmi
	$(OCAMLOPT) -c $<

sdlnet_stub.o: sdlnet_stub.c
	$(OCAMLC) -c -ccopt -I$(INC_DIR) $<

sdlnet.cma: sdlnet.cmo libsdlnet.a
	$(OCAMLMKLIB) -o sdlnet -L$(LIB_DIR) $(LDLIBS) $<

sdlnet.cmxa: sdlnet.cmx libsdlnet.a
	$(OCAMLMKLIB) -o sdlnet -L$(LIB_DIR) $(LDLIBS) $<

libsdlnet.a: sdlnet_stub.o
	$(OCAMLMKLIB) -o sdlnet -L$(LIB_DIR) $(LDLIBS) $<

.PHONY: clean
clean:
	$(RM) *.[oa] *.so *.dll *.cm[ixoa] *.cmxa

