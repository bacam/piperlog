TARGETS=filter.bc filter convert.bc convert

all: $(TARGETS)

.PHONY: all clean

clean:
	rm -f $(TARGETS) *.cmo *.cmi *.cmx *.o depends

%.cmi: %.mli
	ocamlc -g -c -I +pcre $<
%.cmo: %.ml
	ocamlc -g -c -I +pcre $<

%.cmx %.o: %.ml
	ocamlopt -c -I +pcre $<

filter.bc: file.cmo filter.cmo
	ocamlc -g -I +pcre -o $@ pcre.cma $^
filter: file.cmx filter.cmx
	ocamlopt -I +pcre -o $@ pcre.cmxa $^

convert.bc: file.cmo convert.cmo
	ocamlc -g -I +pcre -o $@ pcre.cma $^
convert: file.cmx convert.cmx
	ocamlopt -I +pcre -o $@ pcre.cmxa $^

depends: file.ml filter.ml convert.ml
	ocamldep $^ > $@

include depends
