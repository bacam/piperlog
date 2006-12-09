PROGRAMS=piperlog.bc piperlog piperlog-convert.bc piperlog-convert
TARGETS=$(PROGRAMS) piperlog.html

progs: $(PROGRAMS)
all: $(TARGETS)

.PHONY: progs all clean

clean:
	rm -f $(TARGETS) *.cmo *.cmi *.cmx *.o depends

%.cmi: %.mli
	ocamlc -g -c -I +pcre $<
%.cmo: %.ml
	ocamlc -g -c -I +pcre $<

%.cmx %.o: %.ml
	ocamlopt -c -I +pcre $<

%.html: %.man
	groff -man -Thtml $< > $@

piperlog.bc: file.cmo filter.cmo
	ocamlc -g -I +pcre -o $@ pcre.cma $^
piperlog: file.cmx filter.cmx
	ocamlopt -I +pcre -o $@ pcre.cmxa $^

piperlog-convert.bc: file.cmo piperlog-convert.cmo
	ocamlc -g -I +pcre -o $@ pcre.cma $^
piperlog-convert: file.cmx piperlog-convert.cmx
	ocamlopt -I +pcre -o $@ pcre.cmxa $^

depends: file.ml filter.ml piperlog-convert.ml
	ocamldep $^ > $@

include depends
