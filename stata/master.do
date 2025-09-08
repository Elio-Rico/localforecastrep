********************************************************************************
*
*				Do Local Forecasters Have Better Information?
*						replication code
********************************************************************************

/*

run this do-file to produce all data and reproduce the results from the paper.
you might want to run the dependencies.do file first, or add the zipped ado 
files that are located in the stata/ado folder.

*/


clear all
set more off

cd "/Users/ebollige/Dropbox/1_1_replication_forecasters/localforecastrep/stata/"

* generate main data
do generate_data_output.do

* produce results
do results_section2.do
do results_section3.do
do results_section4.do
do results_section5and6.do

********************************************************************************
********************************************************************************
