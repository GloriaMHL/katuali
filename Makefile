.PHONY: install update reads clean_test test_basecall test_align test_subsample test_canu test_flye test_flye_racon test_flye_medaka test_canu_racon test_canu_medaka test_miniasm_racon check docs test_pipeline_all_fast_assm_polish test_pipeline_all_standard_assm_polish test_pipeline_all_medaka_eval test_pipeline_all_medaka_feat test_pipeline_all_medaka_train 

UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
	JOBS=$(shell sysctl -n hw.physicalcpu)
endif
ifeq ($(UNAME), Linux)
	JOBS=$(shell nproc)
endif

IN_VENV=. ./venv/bin/activate
TEST=${IN_VENV} && cd test && katuali -s Snakefile --configfile config.yaml --printshellcmds -j ${JOBS} --config THREADS_PER_JOB=${JOBS}

venv/bin/activate:
	test -d venv || virtualenv venv --prompt '(katuali) ' --python=python3
	${IN_VENV} && pip install pip --upgrade
	${IN_VENV} && pip install -r requirements.txt

install: venv/bin/activate
	${IN_VENV} && python setup.py develop

update: venv/bin/activate
	git stash
	git checkout master
	git pull origin master
	${IN_VENV} && pip install -r requirements.txt


test: install test_basecall test_align test_subsample test_canu test_flye test_shasta test_flye_racon test_shasta_racon test_flye_medaka test_flye_medaka_eval test_canu_racon test_canu_medaka test_miniasm_racon check test_pipeline_all_fast_assm_polish test_pipeline_all_standard_assm_polish test_pipeline_all_medaka_eval test_pipeline_all_medaka_feat test_pipeline_all_medaka_train 

test/config.yaml:
	mkdir -p test
	${IN_VENV} && katuali_config $@ 

test/Snakefile: test/config.yaml
	${IN_VENV} && katuali_datafile Snakefile | xargs -I {} cp {} $@ 

reads:
	mkdir -p test/MinIonRun1
	${IN_VENV} && cd test/MinIonRun1 && katuali_datafile test/reads.tgz | xargs -I {} tar -xf {}
	mkdir -p test/MinIonRun2
	${IN_VENV} && cd test/MinIonRun2 && katuali_datafile test/reads.tgz | xargs -I {} tar -xf {}
	mkdir -p test/GridIonRun1
	${IN_VENV} && cd test/GridIonRun1 && katuali_datafile test/reads.tgz | xargs -I {} tar -xf {}
	mkdir -p test/GridIonRun2
	${IN_VENV} && cd test/GridIonRun2 && katuali_datafile test/reads.tgz | xargs -I {} tar -xf {}

test/ref.fasta: test/config.yaml
	${IN_VENV} && cp `katuali_datafile test/ref.fasta` $@ 


# The following targets step through a pipeline

test_basecall: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/basecalls.fastq.gz

test_derived_basecall: reads test/ref.fasta test/config.yaml test/Snakefile
	mkdir -p test/MinIonRun1/bla/bla/bla
	cp -r test/MinIonRun1/reads test/MinIonRun1/bla/bla/bla/fast5
	${TEST} MinIonRun1/bla/bla/bla/guppy/basecalls.fastq.gz

test_align: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/align/calls2ref.bam

test_subsample: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/align/all_contigs/25X/basecalls.fastq.gz

test_canu: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/canu/consensus.fasta.gz

test_flye: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/flye/consensus.fasta.gz

test_shasta: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/shasta/consensus.fasta.gz

test_flye_racon: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/flye/racon/consensus.fasta.gz

test_shasta_racon: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/shasta/consensus.fasta.gz

test_flye_medaka: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/flye/racon/medaka/consensus.fasta.gz

test_flye_medaka_eval: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/flye/racon/medaka/assess/consensus_to_truth_summ.txt

test_canu_racon: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/canu/racon/consensus.fasta.gz

test_canu_medaka: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/canu/racon/medaka/consensus.fasta.gz

test_miniasm_racon: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/guppy/miniasm/racon/consensus.fasta.gz

test_pipeline_all_fast_assm_polish: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} all_fast_assm_polish --dryrun

test_pipeline_all_standard_assm_polish: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} all_standard_assm_polish --dryrun

test_pipeline_all_medaka_eval: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} all_medaka_eval --dryrun

test_pipeline_all_medaka_feat: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} all_medaka_feat --dryrun

test_pipeline_all_medaka_train: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} all_medaka_train --dryrun


clean_test:
	rm -rf test

check:
	grep '100%' test/logs/*.log
	grep 'Exception' test/logs/*.log || echo "No exceptions found"


# Build docs
SPHINXOPTS      =
SPHINXBUILD     = sphinx-build
PAPER           =
BUILDDIR        = _build
PAPEROPT_a4     = -D latex_paper_size=a4
PAPEROPT_letter = -D latex_paper_size=letter
ALLSPHINXOPTS   = -d $(BUILDDIR)/doctrees $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) .
DOCSRC          = docs

docs: venv/bin/activate 
	${IN_VENV} && pip install sphinx sphinx_rtd_theme sphinx-argparse
	${IN_VENV} && cd $(DOCSRC) && $(SPHINXBUILD) -b html $(ALLSPHINXOPTS) $(BUILDDIR)/html
	@echo
	@echo "Build finished. The HTML pages are in $(DOCSRC)/$(BUILDDIR)/html."
	touch $(DOCSRC)/$(BUILDDIR)/html/.nojekyll

