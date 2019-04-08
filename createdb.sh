#!/bin/bash
#make new db script
#make sure the file is executable

set -e

cd ~/git/DrQA/
export CLASSPATH=~/git/DrQA/data/corenlp/*
export WKDIR=~/git/DrQA/data/$1/

rm -rf ${WKDIR} || true
mkdir -p ${WKDIR}extract

echo "download db dump"
wget -P ${WKDIR} $2

for z in ${WKDIR}*.tar.xz; do tar -xf "$z"; done
for z in ${WKDIR}*.rar; do unrar e -r "$"; done
for z in ${WKDIR}*.7z; do 7z e "$z"; done
for z in ${WKDIR}*.bz2; do bzip2 -d  "$z"; done
for z in ${WKDIR}*.zip; do unzip -d  "$z"; done

#https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles-multistream.xml.bz2 Current revisions only, no talk or user pages; this is probably what you want, and is approximately 14 GB compressed (expands to over 58 GB when decompressed).
#https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-abstract.xml.gz – page abstracts #page abstracts
#https://s3.amazonaws.com/wikia_xml_dumps/w/wa/warframe_pages_current.xml.7z   https://warframe.fandom.com/wiki/Special:Statistics
#https://s3.amazonaws.com/wikia_xml_dumps/s/sh/shadowsdietwice_pages_current.xml.7z   https://sekiro-shadows-die-twice.fandom.com/wiki/Special:Statistics

echo "wikiextractor"
python3  WikiExtractor.py --output ${WKDIR}extract/ --json --no-templates --min_text_length 3 --filter_disambig_pages --processes 18 ${WKDIR}*.xml

echo "building db"
python build_db.py ${WKDIR}extract/ ${WKDIR}docs.db

echo "building TF"
python3 scripts/retriever/build_tfidf.py ${WKDIR}docs.db ${WKDIR} --num-workers 18 --ngram 2 --hash-size 16777216 --tokenizer 'simple'

echo "exporting to storage"
gsutil cp ${WKDIR}docs.db gs://pimax/drqa/data/$1/docs.db
gsutil cp ${WKDIR}docs-tfidf-ngram=2-hash=16777216-tokenizer=simple.npz gs://pimax/drqa/data/$1/docs-tfidf-ngram=2-hash=16777216-tokenizer=simple.npz

echo "done"