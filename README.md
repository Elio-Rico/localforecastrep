#  Do Local Forecasters Have Better Information?
This repository contains the replication files for the paper "Do Local Forecasters Have Better Information?" (Benhima & Bolliger, 2025)

## 1. Replication process
Below, we provide an overview of the folders, the inputs required, and the scripts. It is in chronological order to re-create the dataset from scratch. Note that many input data is confidential and we used a placeholder instead, such that the code can run through.

### 2. R-codes

#### 2.1 [scripts/](scripts/)

The folder [scripts](scripts/) contains the main R-script which is needed to produce the initial data from consensus economics. It reads the excel files with the forecasts for GDP and inflation, does an initial cleaning of institution names, and writes the result as rds and stata data file.

Folder [R](R/) contains all functions needed by the main script to read, prep/initial clean, and write the data to [data/processed](data/processed/).

Inputs are stored in [inst/data/raw/ce](inst/data/raw/ce/), with 4 different folders, named "Asia-Pacific", "Eastern-Europe", "G7-Europe", "Latin-America", and the corresponding excel files in them. This data corresponds to the raw files received from [consensus economics](https://www.consensuseconomics.com/).


### 3. Stata Codes

#### 3.1 [stata/](stata/)
This folder contains the do-files, which are numbered and must be run in that order. It saves the final dataset in the folder data.


### 4. [data/](data/)

This folder contains the final data which is used to produce all figures and tables from the paper.



### 5. [inst/](inst/)

This folder contains all the raw and produced data. Several of the folders are empty or contain random data due to data confidentiality. Below, we describe each of the folders of the raw data (data in the "produced" folder are created with the raw data).

#### 5.1 [inst/data/raw/ce](inst/data/raw/ce/)
This folder contains the original excel files from [consensus economics](https://www.consensuseconomics.com/). Content is already described in section [scripts](#scripts).

#### 5.2 [inst/data/raw/imf](inst/data/raw/imf/)
This folder contains the vintage series from the world economic outlook of the IMF, accessible [here](https://www.imf.org/en/Publications/WEO). We downloaded all the vintage data, arranged it and saved the resulting data in the folder [inst/data/produced/imf](inst/data/produced/imf/) under "vintages.dta".


#### 5.3 [inst/data/raw/eikon](inst/data/raw/eikon/)
This folder contains the company tree structure, directly downloaded from Eikon. With manual search on the internet, the information we completed the information for the institutions in our database. This data is **confidential**, and was replaced by a **random** dataset.


#### 5.4 [inst/data/raw/crises](inst/data/raw/crises/)

This folder contains data for crises periods. Data stems from [Harvard Global Crises Data by Country](https://www.hbs.edu/behavioral-finance-and-financial-stability/data/Pages/global.aspx).









