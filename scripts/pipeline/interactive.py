#!/usr/bin/env python3
# Copyright 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
"""Interactive interface to full DrQA pipeline."""

import torch
import argparse
import code
import prettytable
import logging
import time
import json

from termcolor import colored
from drqa import pipeline
from drqa.retriever import utils
from google.cloud import storage


logger = logging.getLogger()
logger.setLevel(logging.INFO)
fmt = logging.Formatter('%(asctime)s: [ %(message)s ]', '%m/%d/%Y %I:%M:%S %p')
console = logging.StreamHandler()
console.setFormatter(fmt)
logger.addHandler(console)

parser = argparse.ArgumentParser()
parser.add_argument('--reader-model', type=str, default=None,
                    help='Path to trained Document Reader model')
parser.add_argument('--retriever-model', type=str, default=None,
                    help='Path to Document Retriever model (tfidf)')
parser.add_argument('--doc-db', type=str, default=None,
                    help='Path to Document DB')
parser.add_argument('--tokenizer', type=str, default=None,
                    help=("String option specifying tokenizer type to "
                          "use (e.g. 'corenlp')"))
parser.add_argument('--candidate-file', type=str, default=None,
                    help=("List of candidates to restrict predictions to, "
                          "one candidate per line"))
parser.add_argument('--no-cuda', action='store_true',
                    help="Use CPU only")
parser.add_argument('--gpu', type=int, default=-1,
                    help="Specify GPU device id to use")
parser.add_argument('--top_n', type=int, default=1,
                    help="number of predictions to return")
parser.add_argument('--docs_n', type=int, default=5,
                    help="number of predictions to return")
parser.add_argument('--wikiname', type=str, default=None,
                    help="source Wiki in data folder")
args = parser.parse_args()

args.cuda = not args.no_cuda and torch.cuda.is_available()
if args.cuda:
    torch.cuda.set_device(args.gpu)
    logger.info('CUDA enabled (GPU %d)' % args.gpu)
else:
    logger.info('Running on CPU only.')

if args.candidate_file:
    logger.info('Loading candidates from %s' % args.candidate_file)
    candidates = set()
    with open(args.candidate_file) as f:
        for line in f:
            line = utils.normalize(line.strip()).lower()
            candidates.add(line)
    logger.info('Loaded %d candidates.' % len(candidates))
else:
    candidates = None

logger.info('Initializing pipeline...')
DrQA = pipeline.DrQA(
    cuda=args.cuda,
    fixed_candidates=candidates,
    reader_model=args.reader_model,
    ranker_config={'options': {'tfidf_path': args.retriever_model}},
    db_config={'options': {'db_path': args.doc_db}},
    tokenizer=args.tokenizer
)

# ------------------------------------------------------------------------------
# Drop in to interactive mode
# ------------------------------------------------------------------------------


def listenQuestions(wikiname, top_n=1, n_docs=5):
    gcs = storage.Client()
    bucket = gcs.get_bucket('pimax')
    question_file = r'drqa/data/' + wikiname + "/question.json"
    prediction_file = r'drqa/data/' + wikiname + "/predictions.json"

    while True:
        if not storage.Blob(bucket=bucket, name=question_file).exists(gcs):
            time.sleep(1)
            continue
        question = json.loads(bucket.get_blob(question_file).download_as_string())["question"]
        try :
            predictions = DrQA.process(
                question, None, top_n, n_docs, return_context=True
            )
            span = []
            span_score = []
            doc_score = []
            doc_id = []
            text = []
            for i, p in enumerate(predictions, 1):
                span.append(p['span'])
                doc_id.append(p['doc_id'])
                span_score.append(p['span_score'])
                doc_score.append(p['doc_score'])
                text.append(p['context']['text'])
            bucket.blob(prediction_file).upload_from_string(json.dumps({"span": span, "span_score": span_score,
                                                                       "doc_score": doc_score, "doc_id": doc_id,
                                                                        "text": text, "wikiname": wikiname}, ensure_ascii=False))
        except:
            bucket.blob(prediction_file).upload_from_string(json.dumps({"span": [], "span_score": [],
                                                                   "doc_score": [], "doc_id": [],
                                                                    "text": [], "wikiname": wikiname}, ensure_ascii=False))
        bucket.blob(question_file).delete()


def process(question, candidates=None, top_n=1, n_docs=5):
    predictions = DrQA.process(
        question, candidates, top_n, n_docs, return_context=True
    )
    table = prettytable.PrettyTable(
        ['Rank', 'Answer', 'Doc', 'Answer Score', 'Doc Score']
    )
    for i, p in enumerate(predictions, 1):
        table.add_row([i, p['span'], p['doc_id'],
                       '%.5g' % p['span_score'],
                       '%.5g' % p['doc_score']])
    print('Top Predictions:')
    print(table)
    print('\nContexts:')
    for p in predictions:
        text = p['context']['text']
        start = p['context']['start']
        end = p['context']['end']
        output = (text[:start] +
                  colored(text[start: end], 'green', attrs=['bold']) +
                  text[end:])
        print('[ Doc = %s ]' % p['doc_id'])
        print(output + '\n')


banner = """
Interactive DrQA
>> process(question, candidates=None, top_n=1, n_docs=5)
>> usage()
"""


def usage():
    print(banner)


listenQuestions(args.wikiname, args.top_n, args.docs_n)
# code.interact(banner=banner, local=locals())
