#  Do Local Forecasters Have Better Information?
This repository contains the replication files for the paper "Do Local Forecasters Have Better Information?" (Benhima & Bolliger, 2025)

## 1. Replication process
Below, we provide information about the dependencies, the codes, the data, and the manuscript.

### 1.1 Dependencies

#### 1.1.1 R

Codes for R were run with R version 4.3.0.

To install the `localforecastrep` package from GitHub using devtools, you must first ensure you have the `devtools` package installed and loaded.

You can install `devtools` and its dependency remotes with the following commands in your R console:

```r
install.packages("devtools")
install.packages("renv")
devtools::install_github("Elio-Rico/localforecastrep")
renv::restore()
```

#### 1.1.2 Stata

We used Stata version 18.0. We provide a full ado-directory (zipped) in the folder [stata/ado](stata/ado/). Users can un-zip these ado files, and add the following line to the do-files specifying the path.
```r
sysdir set PLUS "$path/to/localforecastrep/stata/ado"
```
Alternatively, we provide a do-file [stata/dependencies.do](stata/dependencies.do/) which installs all packages. However, same version number is not guaranteed with this approach which might lead to problems when running the code.

### 2. R-codes

#### 2.1 [scripts/](scripts/)

The folder [scripts](scripts/) contains the main R-script which is needed to produce the initial data from consensus economics. It reads the excel files with the forecasts for GDP and inflation, does an initial cleaning of institution names, and writes the result as rds and stata data file.

Folder [R](R/) contains all functions needed by the main script to read, prep/initial clean, and write the data to [data/processed](data/processed/).

Inputs are stored in [inst/data/raw/ce](inst/data/raw/ce/), with 4 different folders, named "Asia-Pacific", "Eastern-Europe", "G7-Europe", "Latin-America", and the corresponding excel files in them. This data corresponds to the raw files received from [consensus economics](https://www.consensuseconomics.com/).


### 3. Stata Codes

#### 3.1 [stata/](stata/)
This folder contains the do-files. Users can run the do-file `masters.do`. **Note to adapt the `cd` command in this do-file**. 

The `masters.do` will run the `generate_data_output.do` file, which produces different data stored in the folder [data/](data/) used for the analysis. It then runs the do files `results_section2.do`, `results_section3.do`, `results_section4.do`, `results_section5_and6.do`, which produce all results shown in the paper for the corresponding sections.


### 4. [data/](data/)

This folder contains the final data which is used in the do-files to produce all figures and tables from the paper.



### 5. [inst/](inst/)



This folder contains all the raw and produced data. Several of the folders are empty or contain random data due to data confidentiality. Below, we describe each of the folders of the raw data (data in the "produced" folder are created with the raw data).
#### 5.1 [inst/data/raw/bis](inst/data/raw/bis/)  
The is data from the [Bank for International Settlements Locational Banking Statistics](https://data.bis.org/topics/LBS). We downloaded this data for the countries in our data sample.  

#### 5.1 [inst/data/raw/ce](inst/data/raw/ce/)  
This folder contains the original excel files from [consensus economics](https://www.consensuseconomics.com/). Content is already described in section [scripts](#scripts).  

<!--
#### 5.3 [inst/data/raw/crises](inst/data/raw/crises/)  
This folder contains data for crises periods. Data stems from [Harvard Global Crises Data by Country](https://www.hbs.edu/behavioral-finance-and-financial-stability/data/Pages/global.aspx).  
-->

#### 5.2 [inst/data/raw/cultdist](inst/data/raw/cultdist/)  
This folder contains merged data for a measure about cultural and linguistic distance between countries by Spolaore and Wacziarg (2016) and Fearon (2003), Spolaore
and Wacziarg (2016), available on [The Geo-Political Distance Data Repository](https://www.geopoliticaldistance.org/home). 

#### 5.3 [inst/data/raw/eikon](inst/data/raw/eikon/)  
This folder contains the company tree structure, directly downloaded from Eikon. With manual search on the internet, the information we completed the information for the institutions in our database. This data is **confidential**, and was replaced by a **random** dataset.  

<!--
#### 5.6 [inst/data/raw/epu](inst/data/raw/epu/)  
The is data about the [economic policy uncertainty](https://www.policyuncertainty.com/all_country_data.html), from Baker et al.  
-->

#### 5.4 [inst/data/raw/gravity](inst/data/raw/gravity/)  
The is contains a gravity dataset from Conte and Mayer (2022). The gravity database contains information on the physical distances and trade linkages used in regressions for section "The Geography of Information". This data is merged to the nearest headquarter and nearest subsidiary of the forecaster. The dataset is available [here](https://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=8) - it was not uploaded to our public replication package due to its size. 

#### 5.5 [inst/data/raw/imf](inst/data/raw/imf/)  
This folder contains the vintage series from the world economic outlook of the IMF, accessible [here](https://www.imf.org/en/Publications/WEO). We downloaded all the vintage data, arranged it and saved the resulting data in the folder [inst/data/produced/imf](inst/data/produced/imf/) under "vintages.dta".  

<!--
#### 5.9 [inst/data/raw/tariff](inst/data/raw/tariff/)  
This folder contains data from the [World Trade Organization](https://ttd.wto.org/en). It contains data for tariffs, simple average duty and trade-weighted average duty for each country.  
-->

#### 5.6 [inst/data/raw/migration](inst/data/raw/migration/)  
This folder contains a data extract from the global bilateral migration data base (Ozden et al., 2011), available at the [World Bank Data Page](https://databank.worldbank.org/source/global-bilateral-migration).


#### 5.7 [inst/data/raw/regime](inst/data/raw/fkrsu/)  
This folder contains the data to construct a measure of capital controls from Fernández et al. (2016). The data is available [here](https://www.columbia.edu/~mu2166/fkrsu/) 


#### 5.8 [inst/data/raw/icrg](inst/data/raw/icrg/)  
This folder contains information about the quality of institutions in the target country. We use 6 indicators from this data to perform a principal component analysis. The data stems from the 
[Worldbank Worldwide Governance Indicators Databank](https://www.worldbank.org/en/publication/worldwide-governance-indicators).



### 6. [output/](output/)
This folder contains all figures, tables and data produced with the stata do-files for each section. They are stored in the corresponding folders [output/figures](output/figures) and [output/tables](output/tables).



### 7. [manuscript/](manuscript/)
This folder contains the main latex file to i) generate the main paper ([manuscript/Paper.tex](manuscript/Paper.tex)) and the appendix ([manuscript/Appendix.tex](manuscript/Appendix.tex)). It uses as inputs the files from the subfolder [manuscript/Sections](manuscript/Sections) and the tables as well as figures from the folder [output/](output/).


<!--gravity, cultdist, langdist (cultdist and langdist both in cultdist database), migration, institutions (icrg), capital flows regime (fkrsu), eikon, imf.
-->

