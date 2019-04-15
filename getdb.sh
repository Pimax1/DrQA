#!/bin/bash
#make new db script
#make sure the file is executable

set -e

DBPATH=~/git/DrQA/data/$1/docs.db
TFPATH=~/git/DrQA/data/$1/docs-tfidf-ngram=2-hash=16777216-tokenizer=corenlp.npz

if not test -f "$DBPATH"; then
    echo "download db"
    gsutil cp  gs://pimax/drqa/data/$1/docs.db $DBPATH
fi

if not test -f "$TFPATH"; then
    echo "download tf"
    gsutil cp  gs://pimax/drqa/data/$1/docs-tfidf-ngram=2-hash=16777216-tokenizer=corenlp.npz $TFPATH
fi

echo "done"