#  Do Local Forecasters Have Better Information?
This repository contains the replication files for the paper "Do Local Forecasters Have Better Information?" (Benhima & Bolliger, 2025)

## 1. Replication process
Below, we provide an overview of the folders, the inputs required, and the scripts. It is in chronological order to re-create the dataset from scratch. Note that many input data is confidential and we used a placeholder instead, such that the code can run through.

### 1.1 scripts

The folder scripts contains the main R-script which is needed to produce the initial data from consensus economics. It reads the excel files with the forecasts for GDP and inflation, does an initial cleaning of institution names, and writes the result as rds and stata data file.

Inputs are stored in "inst/data/raw/ce/", which 4 different folders, named "Asia-Pacific", "Eastern-Europe", "G7-Europe", "Latin-America", and the corresponding excel files in them. This data corresponds to the raw files received from [consensus economics](https://www.consensuseconomics.com/).

### 1.2 stata

This folder contains the do-files, which are numbered and must be run in that order. It saves the final dataset in the folder data.


### 1.3 data

This folder contains the final files/output that are used in the paper.
