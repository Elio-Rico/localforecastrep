

clear all
set more off

cd "/Users/ebollige/Dropbox/1_1_replication_forecasters/localforecastrep/stata/"

* do file location:
local dofile = "`c(pwd)'"
disp "`dofile'" 
local parent = substr("`dofile'", 1, strrpos("`dofile'", "/")-1)

* Append the desired subfolder
local target = "`parent'/data"
global data "`target'"
local target = "`parent'/output"
global output "`target'"
local target = "`parent'/output/tables"
global tables "`target'"
local target = "`parent'/output/figures"
global figures "`target'"
local target = "`parent'/output/temp_data"
global temp_data "`target'"


* switch to data directory:
cd $output
* Check



use $data/baseline.dta, clear


********* OVERVIEW TABLE WHICH COUNTRIES ARE EMERGING WHICH ARE NOT:


preserve


	collapse Emerging, by(country)

	g emerging = "Emerging" if Emerging == 1
	replace emerging = "Developed" if Emerging == 0

	drop Emerging

	g n = _n

	g database = 1 if _n < 18
	replace database = 2 if _n >=18 & _n < 35
	replace database = 3 if database == .

	cap drop n2
	bysort database: g na = _n
	
	save $temp_data/ctry_all.dta, replace
	
	use $temp_data/ctry_all.dta, clear
	
	drop if n > 17
	
	save $temp_data/ctry17.dta, replace
	
	
	use $temp_data/ctry_all.dta, clear
	
	drop if n >= 35 
	drop if n <= 17
	
	rename emerging emerging2
	rename country country2
	rename n n1
	
	save $temp_data/ctry34.dta, replace
	
	
	use $temp_data/ctry_all.dta, clear
	
	drop if n < 35 
	
	rename emerging emerging3
	rename country country3
	rename n n3
	
	save $temp_data/ctry51.dta, replace
	
	
	use $temp_data/ctry17, clear
	
	merge 1:1 na using $temp_data/ctry34
	drop _merge
	
	merge 1:1 na using $temp_data/ctry51
	drop _merge
	
	
	drop na
	
	order n country emerging n1 country2 emerging2 n3 country3 emerging3
	
	drop database
	
	
	label var n ""
	label var country "Country"
	label var emerging "DS\textsuperscript{*}"
	label var n1 ""
	label var country2 "Country"
	label var emerging2 "DS\textsuperscript{*}"
	label var n3 ""
	label var country3 "Country"
	label var emerging3 "DS\textsuperscript{*}"
	
		texsave n country emerging n1 country2 emerging2 n3 country3 emerging3 using "$tables/emerging_advanced_sum.tex", ///
			title(Development Status of all Countries) varlabels nofix hlines(0) headersep(0pt)  ///
		frag  size(footnotesize)  align(l l l l l l l l l) location(t) replace label(tab:app_emerging_advanced) footnote(		"\begin{minipage}{1\textwidth} \vspace{-10pt} \begin{tabnote} \textsuperscript{*} Development Status \end{tabnote} \end{minipage}  ") 
			
	

restore


