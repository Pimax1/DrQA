#!/bin/bash
#make new db script
#make sure the file is executable

set -e

DBPATH=~/git/DrQA/data/$1/docs.db
TFPATH=~/git/DrQA/data/$1/docs-tfidf-ngram=2-hash=16777216-tokenizer=corenlp.npz

if [test -f "$DBPATH"]; then
     echo "db already here"
else
    echo "download db"
    gsutil cp  gs://pimax/drqa/data/$1/docs.db $DBPATH
fi

if [test -f "$TFPATH"]; then
    echo "tf already here"
else
    echo "download tf"
    gsutil cp  gs://pimax/drqa/data/$1/docs-tfidf-ngram=2-hash=16777216-tokenizer=corenlp.npz $TFPATH
fi
echo "done"