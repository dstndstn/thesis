all: review.pdf verify.pdf tech-report.pdf thesis.pdf

## lacheck,  chktex
## 2-up:
## pdfnup --nup 2x1 --pages 1,5-98,100-152 --frame true --outfile 2up.pdf --paper letterpaper thesis.pdf


REVIEW_FIGS := quad-fig.pdf rangesearch-bb-fig.pdf rangesearch-split-fig.pdf

VFIGS := fgbg-1d fgbg-2d symm-bg symm-fg gc-ref gc-test-false \
	gc-test-true gc-odds-false1 gc-odds-false2 gc-odds-bg \
	gc-bayes1 gc-bayes2 nstars-fg1 nstars-fg2 nstars-bayes \
	exgain-1 exgain-2 exgain-total-1 exgain-total-2 \
	donut-ref donut-test donut-bayes donut-thetas ror-rotation \
	ror-bayes

VERIFY_FIGS := $(addsuffix .pdf,$(addprefix figs-verify/,$(VFIGS)))

figs.tex: $(addsuffix .tex,$(addprefix figs-verify/, simple symm gc nstars exgain donut ror))
	cat $^ > $@

TFIGS := quad-fig sdss-er-cputime sdss-er-nmatch sdss-er-nimage \
	sdss-er-ntoverify \
	sdss-er-bayes sdss-er-codeerr sdss-bands-objs sdss-bands-time \
	sdss-qual-time sdss-qual-objs galex-cputime galex-indexid aegis-acs-quad \
	sdss-quad galex-quad density-fig

TECH_FIGS := $(addsuffix .pdf,$(addprefix figs-techreport/,$(TFIGS)))

figs-techreport/density-fig: density-fig.tex figs-techreport/usnob-density.png \
		figs-techreport/cut-402-density.png figs-techreport/index-1302-density.png
	pdflatex density-fig
	mv density-fig.pdf $@

trfigs.tex: $(addsuffix .tex,$(addprefix figs-techreport/, \
		sdss-er sdss-ntoverify sdss-bands sdss-qual sdss-imsize sdss-sizehints sdss-density \
		sdss-triquint galex quads))
	cat $^ > $@

kdfigs.tex: $(addsuffix .tex,$(addprefix figs-kdtree/, \
		kdtree-eg kdtree-mindist kdtree-nn kdfigs-tikz kd-bar))
	cat $^ > $@

KDTREE_TIKZ_FIGS := pointerless-fig.pdf permute-fig.pdf apply-perm-fig.pdf \
	r-only-fig.pdf transpose-fig.pdf bitpack-fig.pdf

$(KDTREE_TIKZ_FIGS):: %.pdf: %.tex tikzfig.tex kdfigs.tex
	pdflatex $<

KDFIGS := kdtree-bbox kdtree-split mindist-bbox mindist-split

KD_FIGS := $(addsuffix .pdf,$(addprefix figs-kdtree/,$(KDFIGS)))

KDTREE_FIGS := $(KD_FIGS) $(addprefix figs-kdtree/,$(KDTREE_TIKZ_FIGS))

PDFLATEX = pdflatex
BIBTEX = bibtex

tech-report.pdf: tech-report-wrapper.tex tech-report.tex preamble.tex trfigs.tex tech-report-wrapper.bib
	-rm tech-report.pdf
	-$(PDFLATEX) $<
	-$(BIBTEX) `basename $< .tex`
	-bash -c " ( grep Rerun tech-report-wrapper.log && $(PDFLATEX) $< ) || echo noRerun "
	-bash -c " ( grep Rerun tech-report-wrapper.log && $(PDFLATEX) $< ) || echo noRerun "
	mv tech-report-wrapper.pdf tech-report.pdf

tech-report-wrapper.bib: tech-report.bib common.bib
	cat $^ > $@

review.pdf: review-wrapper.tex review.tex
	-rm review.pdf
	-$(PDFLATEX) $<
	-bash -c " ( grep Rerun $*.log && $(PDFLATEX) $< ) || echo noRerun "
	-bash -c " ( grep Rerun $*.log && $(PDFLATEX) $< ) || echo noRerun "
	mv review-wrapper.pdf review.pdf

verify.pdf: verify-wrapper.tex verify-wrapper.bib verify.tex preamble.tex $(VERIFY_FIGS) figs.tex
	-rm verify.pdf
	-$(PDFLATEX) $<
	(grep Rerun `basename $< .tex`.log && $(PDFLATEX) $< ) || echo ok
	(grep Rerun `basename $< .tex`.log && $(PDFLATEX) $< ) || echo ok
	mv verify-wrapper.pdf verify.pdf

verify-wrapper.bib: verify.bib common.bib
	cat $^ > $@

kdtree.pdf: kdtree-wrapper.tex kdtree.tex preamble.tex $(KDTREE_FIGS) kdfigs.tex kdtree-wrapper.bib
	-rm $@
	-$(PDFLATEX) $<
	-$(BIBTEX) $<
	(grep Rerun `basename $< .tex`.log && $(PDFLATEX) $< ) || echo ok
	(grep Rerun `basename $< .tex`.log && $(PDFLATEX) $< ) || echo ok
	mv kdtree-wrapper.pdf $@

verify.tex: $(VERIFY_FIGS) figs.tex

review.tex: $(REVIEW_FIGS)

kdtree.tex: $(KDTREE_FIGS) kdfigs.tex

thesis.tex: $(REVIEW_FIGS) $(KDTREE_FIGS) thesis.bib

thesis.bib: review.bib verify.bib tech-report.bib kdtree.bib common.bib
	cat $^ > $@

kdtree-wrapper.bib: kdtree.bib common.bib
	cat $^ > $@

GREP := grep -q

%.pdf: %.tex
	-($(PDFLATEX) $*; echo return value $$?)
	-($(GREP) "Citation .* undefined" $*.log && bibtex $*) || echo ok
	-(grep Rerun $*.log && $(PDFLATEX) $*) || echo ok
	-(grep Rerun $*.log && $(PDFLATEX) $*) || echo ok
