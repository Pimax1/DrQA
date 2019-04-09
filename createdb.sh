#!/bin/bash
#make new db script
#make sure the file is executable

set -e

cd ~/git/DrQA/
export CLASSPATH=~/git/DrQA/data/corenlp/*
export WKDIR=~/git/DrQA/data/$1/

#rm -rf ${WKDIR} || true
mkdir -p ${WKDIR}extract

echo "download db dump"
wget --timestamping --directory-prefix=${WKDIR} $2

cd ${WKDIR}
for z in ${WKDIR}*.tar.xz; do tar -xf "$z" || true; done
for z in ${WKDIR}*.rar; do unrar e -r "$z" || true; done
for z in ${WKDIR}*.7z; do 7z e "$z"|| true; done
for z in ${WKDIR}*.bz2; do bzip2 -d  "$z"|| true; done
for z in ${WKDIR}*.zip; do unzip -d  "$z"|| true; done
for z in ${WKDIR}*.gz; do gzip -d  "$z"|| true; done
cd ~/git/DrQA/
#https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles-multistream.xml.bz2 Current revisions only, no talk or user pages; this is probably what you want, and is approximately 14 GB compressed (expands to over 58 GB when decompressed).
#https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-abstract.xml.gz – page abstracts #page abstracts
#https://s3.amazonaws.com/wikia_xml_dumps/w/wa/warframe_pages_current.xml.7z   https://warframe.fandom.com/wiki/Special:Statistics
#https://s3.amazonaws.com/wikia_xml_dumps/s/sh/shadowsdietwice_pages_current.xml.7z   https://sekiro-shadows-die-twice.fandom.com/wiki/Special:Statistics

if [ "$1" != "wikiabstract" ]; then
    echo "wikiextractor"
    python WikiExtractor.py --output ${WKDIR}extract/ --json --no-templates --min_text_length 15 --filter_disambig_pages --processes 18 ${WKDIR}*.xml
else
    python3 abstractor.py  ${WKDIR}*.xml ${WKDIR}extract/
fi


python abstractor input=  output=~/git/DrQA/data/$1/extract/

echo "building db"
python scripts/retriever/build_db.py ${WKDIR}extract/ ${WKDIR}docs.db --num-workers 18

echo "building TF"
python scripts/retriever/build_tfidf.py ${WKDIR}docs.db ${WKDIR} --num-workers 18 --ngram 2 --hash-size 16777216 --tokenizer 'corenlp'

echo "exporting to storage"
gsutil cp ${WKDIR}docs.db gs://pimax/drqa/data/$1/docs.db
gsutil cp ${WKDIR}docs-tfidf-ngram=2-hash=16777216-tokenizer=corenlp.npz gs://pimax/drqa/data/$1/docs-tfidf-ngram=2-hash=16777216-tokenizer=corenlp.npz

rm -rf ${WKDIR}extract || true

echo "done"