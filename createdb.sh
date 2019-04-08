#!/bin/bash
#make new db script
#make sure the file is executable

set -e

cd ~/git/DrQA/
export CLASSPATH=~/git/DrQA/data/corenlp/*

rm -rf ~/git/DrQA/data/$1/ || true
mkdir ~/git/DrQA/data/$1/extract/

echo "download db dump"
wget -O ~/git/DrQA/data/$1/ $2

#https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles-multistream.xml.bz2 Current revisions only, no talk or user pages; this is probably what you want, and is approximately 14 GB compressed (expands to over 58 GB when decompressed).
#https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-abstract.xml.gz – page abstracts #page abstracts
#https://s3.amazonaws.com/wikia_xml_dumps/w/wa/warframe_pages_current.xml.7z   https://warframe.fandom.com/wiki/Special:Statistics
#https://s3.amazonaws.com/wikia_xml_dumps/s/sh/shadowsdietwice_pages_current.xml.7z   https://sekiro-shadows-die-twice.fandom.com/wiki/Special:Statistics

echo "wikiextractor"
python3  WikiExtractor.py --output ~/git/DrQA/data/$1/extract/ --json --no-templates --min_text_length 3 --filter_disambig_pages --processes 18 ~/git/DrQA/data/$1/

echo "building db"
python build_db.py ~/git/DrQA/data/$1/extract/ ~/git/DrQA/data/$1/docs.db

echo "building TF"
python3 scripts/retriever/build_tfidf.py ~/git/DrQA/data/$1/docs.db ~/git/DrQA/data/$1/ --num-workers 18 --ngram 2 --hash-size 16777216 --tokenizer 'simple'

echo "exporting to storage"
gsutil cp ~/git/DrQA/data/$1/docs.db gs://pimax/drqa/data/$1/docs.db
gsutil cp ~/git/DrQA/data/$1/docs-tfidf-ngram=2-hash=16777216-tokenizer=simple.npz gs://pimax/drqa/data/$1/docs-tfidf-ngram=2-hash=16777216-tokenizer=simple.npz

echo "done"