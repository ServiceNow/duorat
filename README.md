# DuoRAT

---

This repository contains the implementation of the DuoRAT model as described in the respective [technical report](https://arxiv.org/abs/2010.11119).
Using this code you can

- train and evaluate models on the [Spider dataset](https://yale-lily.github.io/spider)
- evaluate models on other single-database text2sql datasets
- use trained models to perform text2sql parsing for any SQLite database or a CSV file

## Setup

Download data and third party submodules:
`git submodule update --init`

Download the Spider dataset:
```
bash scripts/download_and_preprocess_spider.sh
```
This script downloads [Spider](https://yale-lily.github.io/spider), splits the examples by database, and writes a json file to `data/database`.

Now, create the docker image: 
```
make build-image
```

Create a directory to save models, and run interactive container:
```
mkdir logdir
nvidia-docker run -it -u $(id -u ${USER}) --name my_duorat --rm -v $PWD/logdir:/logdir -v $PWD/data/:/app/data duorat
```

(please disregard the "I have not name!" warning)

## Running the code

Train the model:
```
python scripts/train.py --config configs/duorat/duorat-finetune-bert-large.jsonnet --logdir /logdir/duorat-bert
```
This script will first run a preprocessing step that creates the following files in the specified  `--logdir`:
- `target_vocab.pkl`: model's target vocabulary, obtained from the training set
- `train.pkl`, `val.pkl`: preprocessed training and validation sets (tokenization, schema-linking and converting the 
output SQL into a sequence of actions)

Training will further save a number of files in the (mounted) log directory `/logdir/duorat-bert`: the config that was used `config-{date}.json`, model checkpoints `model_{best/last}_checkpoint`, some logs `log.txt`, and the inference outputs `output-{step}`.
If your gpu does not have enough memory to run the model, you can try `config=configs/duorat/duorat-12G.jsonnet` 
instead.
Note that caching of the preprocessed input tensors will significantly speed up training after the second epoch.
During training, inference is run on the dev set once in a while.
Here's how you can run inference manually:
```
python scripts/infer.py --logdir /logdir/duorat-bert --output /logdir/duorat-bert/my_inference_output
python scripts/eval.py --config configs/duorat/duorat-good-no-bert.jsonnet --section val --inferred /logdir/duorat-bert/my_inference_output --output /logdir/duorat-bert/my_inference_output.eval
```

To look at evaluation results:
```
>>> import json
>>> d = json.load(open('<PATH FOR EVAL OUTPUT>')) 
>>> print(d['total_scores']['all']['exact']) # should be ~0.69
```

## Inference on new databases

Simply run

```
python scripts/interactive.py --logdir /logdir/duorat-bert --db-id [your_db]
```

`[your_db]` must be either an SQLite or CSV file. Type a question and the model will convert it into a query, which will then be executed on your database.

A batch mode inference script is also available: `scripts/infer_questions.py`.

## New transition system

This codebase makes it possible to implement and use your own transition system 
(given a grammar, parse SQL to a tree representation and a sequence of actions) with this model.
See the readme in `duorat/asdl/` (from [tranX](https://github.com/pcyin/tranX/tree/master/asdl))

## Evaluation on Text2SQL datasets other than SPIDER

Our code support model evaluation on other Text2SQL datasets using the data from [text2sql-data](https://github.com/jkkummerfeld/text2sql-data).
We follow the methodology proposed by [Suhr et al, 2020](https://www.aclweb.org/anthology/2020.acl-main.742/).

To run the download and conversion code:

#### Step 1

(for now this works only 5 out of 8 datasets; ATIS, Scholar and Advising are still TODO)

Build and start the MySQL docker container (do it outside of the interactive `my_duorat` container):

```
bash scripts/mysql_docker_build_and_run.sh
```

#### Step 2

Download the dataset and convert the dataset of interest, e.g. for GeoQuery:

```
bash scripts/download_michigan.sh geo
```

For IMDB, Yelp and Academic this might take a while.

Edit `data/michigan.libsonnet` to include only the datasets that you downloaded.

#### Step 4

Infer and evaluate the queries for all questions: 

```
python scripts/infer_questions.py --logdir /logdir/duorat-bert --data-config data/michigan.libsonnet --questions data/database/geo_test/examples.json --output-google /logdir/duorat-bert/inferred_geo.json
python scripts/evaluation_google.py --predictions_filepath /logdir/duorat-bert/inferred_geo.json --output_filepath /logdir/duorat-bert/output_geo.json 
    --cache_filepath data/database/geo_test/geo_cache.json  --timeout 180
python scripts/filter_results.py /logdir/duorat-bert/output_geo.json
```

You might want to change the timeout if your system outputs correct but slow to execute queries.

## Who we are

- [Torsten Scholak](mailto:torsten.scholak@elementai.com)
- [Raymond Li](mailto:raymond.li@elementai.com)
- [Dzmitry Bahdanau](mailto:dzmitry.bahdanau@elementai.com)
- [Harm de Vries](mailto:harm.de-vries@elementai.com)

## Acknowledgements

This implementation is originally based on the [seq2struct codebase](https://github.com/rshin/seq2struct).
Further model development in many aspects followed the [RAT-SQL paper](https://www.aclweb.org/anthology/2020.acl-main.677/).

## How to cite

```
@article{scholak_duorat_2020,
title = {{DuoRAT}: {Towards} {Simpler} {Text}-to-{SQL} {Models}},
author = {Scholak, Torsten and Li, Raymond and Bahdanau, Dzmitry and de Vries, Harm and Pal, Chris},
year = {2020},
journal = {arXiv:2010.11119 [cs]},
}
```
