
* reproduce data in section 4:


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

*****************************
*****************************
** 2. Behavioral biases *****
*****************************
*****************************


* ---------------------------------------------
*# Overextrapolation - Mean-group regressions (2nd approach)
* ---------------------------------------------

***** By country and Foreign (2nd approach) *****

use $data/baseline.dta, clear

local varlist gdp cpi
		

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen country_num2 = .
	gen Foreign2 = .
	forval i = 1(1)51 {
			capture qui reghdfe `var'_future `var'_current if country_num==`i' & Foreign==0, absorb(idi#month)
			capture replace b_FR_`var' = _b[`var'_current]    if _n == `i'
			capture replace N_FR_`var' = e(N)	              if _n == `i'
			capture replace sd_FR_`var' = _se[`var'_current]  if _n == `i'
			capture replace country_num2 = `i' 			 	  if _n == `i'
			capture replace Foreign2 = 0 				 	  if _n == `i'
			capture qui reghdfe `var'_future `var'_current if country_num==`i' & Foreign==1, absorb(idi#month)
			capture replace b_FR_`var' = _b[`var'_current]    if _n == `i'+51
			capture replace N_FR_`var' = e(N)	         	  if _n == `i'+51
			capture replace sd_FR_`var' = _se[`var'_current]  if _n == `i'+51
			capture replace country_num2 = `i' 			 	  if _n == `i'+51
			capture replace Foreign2 = 1 				 	  if _n == `i'+51
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2
	sort country_num2 Foreign2
	rename country_num2 country_num
	rename Foreign2 Foreign
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR_overextrapolation, replace

use $data/baseline.dta, clear
keep country country_num Emerging Foreign
sort country_num Foreign
collapse Emerging, by(country country_num Foreign)
merge 1:1 country_num Foreign using $temp_data/mg_FR_overextrapolation, nogen
save $temp_data/mg_FR_overextrapolation_cty2, replace

use $temp_data/mg_FR_overextrapolation_cty2, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
		if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num) vce(robust)
	regsave using "$temp_data/overextr_mg_cty_`var'_a2_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", FE3, "", FE4, "", FE5, "", MG1, "\checkmark", MG2, "", MG3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
			
}


**** By institution-country pair (2nd approach) ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(`var'_current), by(institution country month)
	egen Nobs2 = count(`var'_future), by(institution country month)
	drop if Nobs1<10 | Nobs2<10
	egen id2 = group(institution country)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen idci2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reghdfe `var'_future `var'_current if id2==`i', absorb(month)
		capture replace b_FR_`var' = _b[`var'_current]    if _n == `i'
		capture replace N_FR_`var' = e(N)	         	  if _n == `i'
		capture replace sd_FR_`var' = _se[`var'_current]  if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 	  if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2
	sort idci2
	rename idci2 idci
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR_overextrapolation, replace


use $data/baseline.dta, clear
keep country institution idci idi country_num Foreign Multinational N_cty Emerging
sort idci
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num)
merge 1:1 idci using $temp_data/mg_FR_overextrapolation, nogen
save $temp_data/mg_FR_overextrapolation_cty_inst2, replace


use $temp_data/mg_FR_overextrapolation_cty_inst2, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	
		if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num idi) vce(cluster country_num idi)
	regsave using "$temp_data/overextr_mg_cty_inst_`var'_a2_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "", FE4, "", FE5, "", MG1, "", MG2, "\checkmark", MG3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
			
}


**** By institution-country pair and month (2nd approach) ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(`var'_current), by(institution country month)
	egen Nobs2 = count(`var'_future), by(institution country month)
	drop if Nobs1<10 | Nobs2<10
	egen id2 = group(institution country month)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen month2 = .
	gen idci2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg `var'_future `var'_current if id2==`i'
		capture replace b_FR_`var' = _b[`var'_current]    if _n == `i'
		capture replace N_FR_`var' = e(N)	         	  if _n == `i'
		capture replace sd_FR_`var' = _se[`var'_current]  if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 	  if _n == `i'
		capture sum month if id2==`i'
		capture replace month2 = r(mean) 			 	  if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2 month2
	sort idci2 month2
	rename idci2 idci
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR_overextrapolation, replace


use $data/baseline.dta, clear
keep country institution idci idi country_num month Foreign Multinational N_cty Emerging
sort idci month
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num month)
merge 1:1 idci month using $temp_data/mg_FR_overextrapolation, nogen
save $temp_data/mg_FR_overextrapolation_cty_inst_month2, replace


use $temp_data/mg_FR_overextrapolation_cty_inst_month2, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	
		if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num#month idi#month) vce(cluster country_num idi)
	regsave using "$temp_data/overextr_mg_cty_inst_month_`var'_a2.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", MG1, "", MG2, "", MG3, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(idi country_num month) vce(cluster country_num idi)
	regsave using "$temp_data/overextr_mg_cty_inst_month_`var'_a2_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", MG1, "", MG2, "", MG3, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(idi#month country_num#month) vce(cluster country_num idi)
	regsave using "$temp_data/overextr_mg_cty_inst_month_`var'_a2_baseline.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", MG1, "", MG2, "", MG3, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

}

*------------------------------
**# Table Over-Extrapolation (2nd approach)
*------------------------------


	**********************************
	* Over-extrapolation mean-group (by cty, forecaster, month)
	**********************************
	
	* CPI
	******
	
	* all
	use $temp_data/overextr_mg_cty_inst_month_cpi_a2, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_overextr_mg.dta, replace 
	
	* GDP
	******
	
	* all
	use  $temp_data/overextr_mg_cty_inst_month_gdp_a2, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	*g n = _n
	rename col_1 col_2
	
	g n = _n
	
	drop var
	
	* merge with CPI
	*********
	merge 1:1 database n using $temp_data/cpi_overextr_mg.dta
	drop _merge
	
	order var col_1 col_2 
	
	save $temp_data/overextr_mg, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi2
	label var cpi2 "$ \text{CPI}_{t} $"
	rename col_2 gdp2
	label var gdp2 "$ \text{GDP}_{t} $"

	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country $\times$ month FE" if var == "FE1"	
	replace var = "Forecaster $\times$ month FE" if var == "FE2"
	replace var = "MG by ctry and month" if var=="MG1"
	replace var = "MG by ctry, loc., and month" if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	order  var cpi2 gdp2
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/overextr_mg, replace

	/*
	* produce the tables
	

texsave var cpi1 gdp1 using "$tables/overextr_main.tex", ///
				title(Behavioral Biases - Over-extrapolation  regressions) varlabels nofix hlines(0) headersep(0pt) autonumber ///
			frag  size(footnotesize)  align( l l C C C C C C) location(H) replace label(tab:overextr_main) footnote(		"\begin{minipage}{1\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} The table shows the results of a regression of the perceived autocorrelation coefficients $\hat\rho$ on the Foreign dummy, where the $\hat\rho$ is estimated using Equation \eqref{eq:rhohat} on different sub-groups of our sample. \textit{Average locals} corresponds to the constant term (or average fixed effect). \textit{Foreign} corresponds to the coefficient of the Foreign dummy. The obervations are clustered at the country level in specifications (1) and (2), and at the country and forecaster levels in specifications (3) to (6).  \end{tabnote} \end{minipage}  ") 
	
*/

**************
* Robustness
**************

	**********************************
	* Over-extrapolation mean-group (by cty, forecaster, month)
	**********************************
	
	* CPI
	******
	
	use $temp_data/overextr_mg_cty_cpi_a2_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_overextr_mg_rob1.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/overextr_mg_cty_gdp_a2_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_2
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_overextr_mg_rob1.dta, replace 

	
	* CPI
	******
	
	use $temp_data/overextr_mg_cty_inst_cpi_a2_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_3
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_overextr_mg_rob2.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/overextr_mg_cty_inst_gdp_a2_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_4
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_overextr_mg_rob2.dta, replace 
	
	* CPI
	******
	
	use $temp_data/overextr_mg_cty_inst_month_cpi_a2_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_5
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_overextr_mg_rob3.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/overextr_mg_cty_inst_month_gdp_a2_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_6
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_overextr_mg_rob3.dta, replace 
	
	
	* CPI
	******
	
	use $temp_data/overextr_mg_cty_inst_month_cpi_a2_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_7
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_overextr_mg_rob4.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/overextr_mg_cty_inst_month_gdp_a2_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_8
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_overextr_mg_rob4.dta, replace 
		
	
	* merge
	*********
	use $temp_data/cpi_overextr_mg_rob1, clear
	merge 1:1 database n using $temp_data/gdp_overextr_mg_rob1.dta, nogen
	merge 1:1 database n using $temp_data/cpi_overextr_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/gdp_overextr_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/cpi_overextr_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_overextr_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/cpi_overextr_mg_rob4.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_overextr_mg_rob4.dta, nogen	
	order var col_1 col_2 col_3 col_4 col_5 col_6 col_7 col_8
	
	save $temp_data/overextr_mg_rob, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi2
	label var cpi2 "$ \text{CPI}_{t} $"
	rename col_2 gdp2
	label var gdp2 "$ \text{GDP}_{t} $"
	rename col_3 cpi3
	label var cpi3 "$ \text{CPI}_{t} $"
	rename col_4 gdp3
	label var gdp3 "$ \text{GDP}_{t} $"
	rename col_5 cpi4
	label var cpi4 "$ \text{CPI}_{t} $"
	rename col_6 gdp4
	label var gdp4 "$ \text{GDP}_{t} $"
	rename col_7 cpi5
	label var cpi5 "$ \text{CPI}_{t} $"
	rename col_8 gdp5
	label var gdp5 "$ \text{GDP}_{t} $"
	
	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country FE" if var == "FE1"	
	replace var = "Forecaster FE" if var == "FE2"
	replace var = "Month FE" if var == "FE3"	
	replace var = "Ctry $\times$ month FE" if var == "FE4"
	replace var = "For. $\times$ month FE" if var == "FE5"
	replace var = "MG by ctry and loc." if var=="MG1"
	replace var = "MG by ctry and for." if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	*order  var cpi2 gdp2
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/overextr_mg_rob, replace
	
	

	
* -------------------------------
* Persistence - Mean-group regressions
* -------------------------------
	

use $data/baseline.dta, clear

local varlist gdp cpi
		

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	collapse `var'_current_a1, by(country country_num year)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen country_num2 = .
	xtset country_num year
	forval i = 1(1)51 {
			capture qui reg `var'_current_a1 l.`var'_current_a1 if country_num==`i'
			capture replace b_FR_`var' = _b[l.`var'_current_a1]    if _n == `i'
			capture replace N_FR_`var' = e(N)	              if _n == `i'
			capture replace sd_FR_`var' = _se[l.`var'_current_a1]  if _n == `i'
			capture replace country_num2 = `i' 			 	  if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2
	sort country_num2
	rename country_num2 country_num
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR_persistence, replace

use $data/baseline.dta, clear
keep country country_num Emerging
sort country_num
collapse Emerging, by(country country_num)
merge 1:1 country_num using $temp_data/mg_FR_persistence, nogen
save $temp_data/mg_FR_persistence_cty2, replace

use $temp_data/mg_FR_persistence_cty2, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
		if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
reg b_FR_`var' [aweight=weight_`var'], robust
			
}


* -------------------------------
* BGMS - Mean-group regressions
* -------------------------------

**** By country and Foreign ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	local FE idci#month
	preserve
	egen id2 = group(country Foreign)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen country_num2 = .
	gen Foreign2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reghdfe FE_`var'_current_a1 FR_`var' if id2==`i', absorb(`FE')
		capture replace b_FR_`var' = _b[FR_`var']    if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture replace sd_FR_`var' = _se[FR_`var']  if _n == `i'
		capture sum country_num if id2==`i'
		capture replace country_num2 = r(mean) 			 if _n == `i'
		capture sum Foreign if id2==`i'
		capture replace Foreign2 = r(mean) 			 if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2
	sort country_num2 Foreign2
	rename country_num2 country_num
	rename Foreign2 Foreign
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country country_num Foreign Emerging
sort country_num Foreign
collapse Emerging, by(country country_num Foreign)
merge 1:1 country_num Foreign using $temp_data/mg_FR, nogen
save $temp_data/mg_BGMS_cty, replace

* To be added
/*
reghdfe b_FR_gdp Foreign [aweight=N_FR_gdp], absorb(country_num) vce(robust)
reghdfe b_FR_cpi Foreign [aweight=N_FR_cpi], absorb(country_num) vce(robust)

reghdfe b_FR_gdp Foreign [aweight=N_FR_gdp], noabsorb vce(robust)
reghdfe b_FR_cpi Foreign [aweight=N_FR_cpi], noabsorb vce(robust)

sort country_num
by country_num: egen mb_FR_cpi_cty = median(b_FR_cpi)
egen country_num1 = group(mb_FR_cpi_cty)
by country_num: egen mb_FR_gdp_cty = median(b_FR_gdp)
egen country_num2 = group(mb_FR_gdp_cty)
twoway (scatter b_FR_cpi country_num1) (scatter b_FR_cpi country_num1 if Emerging==1) (scatter b_FR_cpi country_num1 if country=="United States")
twoway (scatter b_FR_gdp country_num2) (scatter b_FR_gdp country_num2 if Emerging==1) (scatter b_FR_gdp country_num2 if country=="United States")
hist b_FR_gdp 
hist b_FR_cpi
reghdfe b_FR_gdp Foreign [aweight=N_FR_gdp], absorb(country_num idi) vce(cluster country_num idi)
reghdfe b_FR_cpi Foreign [aweight=N_FR_cpi], absorb(country_num idi) vce(cluster country_num idi)
*/


use $temp_data/mg_BGMS_cty, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num) vce(robust)
	regsave using "$temp_data/bgms_mg_cty_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", FE3, "", FE4, "", FE5, "", MG1, "\checkmark", MG2, "", MG3, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
			
}


***** By institution-country pair ****

use $data/baseline.dta, clear


local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(institution country month)
	egen Nobs2 = count(FR_`var'), by(institution country month)
	drop if Nobs1<10 | Nobs2<10
	egen id2 = group(institution country)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen idci2 = .
	gen month2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg FE_`var'_current_a1 FR_`var' if id2==`i'
		capture replace b_FR_`var' = _b[FR_`var']    if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture replace sd_FR_`var' = _se[FR_`var']  if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2
	sort idci2
	rename idci2 idci
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country institution idci idi country_num Foreign Multinational N_cty Emerging
sort idci
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num)
merge 1:1 idci using $temp_data/mg_FR, nogen
save $temp_data/mg_BGMS_cty_inst, replace

use $temp_data/mg_BGMS_cty_inst, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
		
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num idi) vce(cluster country_num idi)
	regsave using "$temp_data/bgms_mg_cty_inst_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "", FE4, "", FE5, "", MG1, "", MG2, "\checkmark", MG3, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
				
}

* Figures

use $temp_data/mg_BGMS_cty_inst, clear

sort country_num
by country_num: egen mb_FR_cpi_cty = median(b_FR_cpi)
egen country_num1 = group(mb_FR_cpi_cty)
by country_num: egen mb_FR_gdp_cty = median(b_FR_gdp)
egen country_num2 = group(mb_FR_gdp_cty)
label var b_FR_cpi "BGMS coefficient - CPI"
label var b_FR_gdp "BGMS coefficient - GDP"
label var country_num1 "Country"
label var country_num2 "Country"
twoway (scatter b_FR_cpi country_num1) (scatter b_FR_cpi country_num1 if Emerging==1) (scatter b_FR_cpi country_num1 if country=="United States"), legend(label(1 "Advanced") label(2 "Emerging") label(3 "United States"))
		graph export "$figures//dist_beta_cpi_cty.pdf", as(pdf) replace
twoway (scatter b_FR_gdp country_num2) (scatter b_FR_gdp country_num2 if Emerging==1) (scatter b_FR_gdp country_num2 if country=="United States"), legend(label(1 "Advanced") label(2 "Emerging") label(3 "United States"))
		graph export "$figures//dist_beta_gdp_cty.pdf", as(pdf) replace
hist b_FR_gdp 
		graph export "$figures//dist_beta_gdp.pdf", as(pdf) replace
hist b_FR_cpi
		graph export "$figures//dist_beta_cpi.pdf", as(pdf) replace

* Figures (with KOF)

use $temp_data/mg_BGMS_cty_inst, clear

sort country_num
by country_num: egen mb_FR_cpi_cty = median(b_FR_cpi)
egen country_num1 = group(mb_FR_cpi_cty)
by country_num: egen mb_FR_gdp_cty = median(b_FR_gdp)
egen country_num2 = group(mb_FR_gdp_cty)
label var b_FR_cpi "BGMS coefficient - CPI"
label var b_FR_gdp "BGMS coefficient - GDP"
label var country_num1 "Country"
label var country_num2 "Country"
twoway (scatter b_FR_cpi country_num1) (scatter b_FR_cpi country_num1 if Emerging==1) (scatter b_FR_cpi country_num1 if country=="United States") (scatter b_FR_cpi country_num1 if institution=="KOF/ETH") (scatter b_FR_cpi country_num1 if institution=="INSTITUT CREA"), legend(label(1 "Advanced") label(2 "Emerging") label(3 "United States") label(4 "KOF") label(5 "CREA"))
		graph export "$figures//dist_beta_cpi_cty_kof.pdf", as(pdf) replace
twoway (scatter b_FR_gdp country_num2) (scatter b_FR_gdp country_num2 if Emerging==1) (scatter b_FR_gdp country_num2 if country=="United States") (scatter b_FR_gdp country_num1 if institution=="KOF/ETH") (scatter b_FR_gdp country_num1 if institution=="INSTITUT CREA"), legend(label(1 "Advanced") label(2 "Emerging") label(3 "United States") label(4 "KOF") label(5 "CREA"))
		graph export "$figures//dist_beta_gdp_cty_kof.pdf", as(pdf) replace
		
**** By country, institution and month ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(institution country month)
	egen Nobs2 = count(FR_`var'), by(institution country month)
	drop if Nobs1<10 | Nobs2<10
	egen id2 = group(institution country month)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen idci2 = .
	gen month2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg FE_`var'_current_a1 FR_`var' if id2==`i'
		capture replace b_FR_`var' = _b[FR_`var']    if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture replace sd_FR_`var' = _se[FR_`var']  if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 if _n == `i'
		capture sum month if id2==`i'
		capture replace month2 = r(mean) 			 if _n == `i'
		}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2 month2
	sort idci2
	sort idci2 month2
	rename idci2 idci
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country institution idci idi country_num Foreign Multinational N_cty Emerging month
sort idci month
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num month)
merge 1:1 idci month using $temp_data/mg_FR, nogen
save $temp_data/mg_FR_BGMS_cty_inst_month, replace

use $temp_data/mg_FR_BGMS_cty_inst_month, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(idi#month country_num#month) vce(cluster country_num idi)
	regsave using "$temp_data/bgms_mg_cty_inst_month_`var'_a.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(idi country_num month) vce(cluster country_num idi)
	regsave using "$temp_data/bgms_mg_cty_inst_month_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
				
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num#month idi#month) vce(cluster country_num idi)
	regsave using "$temp_data/bgms_mg_cty_inst_month_`var'_a_baseline.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
				
}


*--------------------
**# Table BGMS
*--------------------


	**********************************
	* BGMS mean-group (by cty & inst & month)
	**********************************
	
	* CPI
	******
	
	* all
	use $temp_data/bgms_mg_cty_inst_month_cpi_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_bgms_mg.dta, replace 
	
	* GDP
	******
	
	* all
	use  $temp_data/bgms_mg_cty_inst_month_gdp_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	*g n = _n
	rename col_1 col_2
	
	g n = _n
	
	drop var
	
	* merge with CPI
	*********
	merge 1:1 database n using $temp_data/cpi_bgms_mg.dta
	drop _merge
	
	order var col_1 col_2 
	
	save $temp_data/bgms_mg, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi1
	label var cpi1 "$ \text{CPI}_{t} $"
	rename col_2 gdp1
	label var gdp1 "$ \text{GDP}_{t} $"

	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country $\times$ month FE" if var == "FE1"	
	replace var = "Forecaster $\times$ month FE" if var == "FE2"
	replace var = "MG by ctry and month" if var=="MG1"
	replace var = "MG by ctry, loc., and month" if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	order  var cpi1 gdp1
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/bgms_mg, replace

/*
	* produce the tables
	
	drop if _n >12
	drop sample

texsave var cpi gdp cpi2 gdp2 cpi3 gdp3 using "$tables/bgms_main.tex", ///
				title(Behavioral Biases - BGMS regressions) varlabels nofix hlines(0) headersep(0pt) autonumber ///
			frag  size(footnotesize)  align( l C C C C C C) location(H) replace label(tab:bgms_main) footnote(		"\begin{minipage}{1\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} The table shows the results of a regression of the $\beta^{BGMS}$ coefficients on the Foreign dummy, where the $\beta^{BGMS}$ are estimated using Equation \eqref{eq:BGMS} on different sub-groups of our sample. \textit{Average locals} corresponds to the constant term (or average fixed effect). \textit{Foreign} corresponds to the coefficient of the Foreign dummy. The observations are clustered at the country level in specifications (1) and (2), and at the country and forecaster levels in specifications (3) to (6). \end{tabnote} \end{minipage}  ") 
	
*/


**************
* Robustness
**************

	**********************************
	* BGMS mean-group (by cty, forecaster, month)
	**********************************
	
	* CPI
	******
	
	use $temp_data/bgms_mg_cty_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_bgms_mg_rob1.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/bgms_mg_cty_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_2
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_bgms_mg_rob1.dta, replace 

	
	* CPI
	******
	
	use $temp_data/bgms_mg_cty_inst_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_3
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_bgms_mg_rob2.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/bgms_mg_cty_inst_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_4
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_bgms_mg_rob2.dta, replace 
	
	* CPI
	******
	
	use $temp_data/bgms_mg_cty_inst_month_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_5
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_bgms_mg_rob3.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/bgms_mg_cty_inst_month_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_6
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_bgms_mg_rob3.dta, replace 
	
	
	* CPI
	******
	
	use $temp_data/bgms_mg_cty_inst_month_cpi_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_7
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_bgms_mg_rob4.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/bgms_mg_cty_inst_month_gdp_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_8
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_bgms_mg_rob4.dta, replace 
		
	
	* merge
	*********
	use $temp_data/cpi_bgms_mg_rob1, clear
	merge 1:1 database n using $temp_data/gdp_bgms_mg_rob1.dta, nogen
	merge 1:1 database n using $temp_data/cpi_bgms_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/gdp_bgms_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/cpi_bgms_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_bgms_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/cpi_bgms_mg_rob4.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_bgms_mg_rob4.dta, nogen	
	order var col_1 col_2 col_3 col_4 col_5 col_6 col_7 col_8
	
	save $temp_data/bgms_mg_rob, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi2
	label var cpi2 "$ \text{CPI}_{t} $"
	rename col_2 gdp2
	label var gdp2 "$ \text{GDP}_{t} $"
	rename col_3 cpi3
	label var cpi3 "$ \text{CPI}_{t} $"
	rename col_4 gdp3
	label var gdp3 "$ \text{GDP}_{t} $"
	rename col_5 cpi4
	label var cpi4 "$ \text{CPI}_{t} $"
	rename col_6 gdp4
	label var gdp4 "$ \text{GDP}_{t} $"
	rename col_7 cpi5
	label var cpi5 "$ \text{CPI}_{t} $"
	rename col_8 gdp5
	label var gdp5 "$ \text{GDP}_{t} $"
	
	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country FE" if var == "FE1"	
	replace var = "Forecaster FE" if var == "FE2"
	replace var = "Month FE" if var == "FE3"	
	replace var = "Ctry $\times$ month FE" if var == "FE4"
	replace var = "For. $\times$ month FE" if var == "FE5"
	replace var = "MG by ctry and loc." if var=="MG1"
	replace var = "MG by ctry and for." if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	*order  var cpi2 gdp2
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/bgms_mg_rob, replace
	

**********************************************
* 3. Foreigns update their information less **
**********************************************

* -------------------------------
* FE regressions - Pooled
* -------------------------------

use $data/baseline.dta, clear


* Pooled fixed-effect regressions (year-on-year revisions)
foreach var in cpi gdp {
	
	
	local FE country_num#datem#Foreign idci#month
	local se cluster country_num year#country_num 

	reghdfe FE_`var'_current_a1 c.FR_`var'##c.Foreign, absorb(`FE') vce(`se')
	regsave using "$temp_data/FE_reg_pooled_`var'_a.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "", FE4, "", MG1, "", MG2, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

}

* -------------------------------
* FE regressions - Mean group
* -------------------------------

***** By country *****

use $data/baseline.dta, clear

local varlist gdp cpi
		
* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve 
	gen country_num2 = .
	gen Foreign2 = .
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	sort idci datem
	xtset idci datem
	forval i = 1(1)51 {
			capture reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & Foreign==0, absorb(datem idi)
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'
			capture replace N_FR_`var' = e(N)	        if _n == `i'
			capture replace country_num2 = `i'		 	if _n == `i'
			capture replace Foreign2 = 0		 		if _n == `i'
			capture reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & Foreign==1, absorb(datem idi) 
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+51
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+51
			capture replace N_FR_`var' = e(N)	        if _n == `i'+51
			capture replace country_num2 = `i'		 	if _n == `i'+51
			capture replace Foreign2 = 1		 		if _n == `i'+51
		}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2
	sort country_num2 Foreign2
	rename country_num2 country_num
	rename Foreign2 Foreign
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

* Results
use $data/baseline.dta, clear
keep country country_num Emerging Foreign
sort country_num Foreign
collapse Emerging , by(country country_num Foreign)
merge 1:1 country_num Foreign using $temp_data/mg_FR, nogen
save $temp_data/mg_FE_reg_cty, replace

use $temp_data/mg_FE_reg_cty, clear

gen weight_gdp=1/sd_FR_gdp
gen weight_cpi=1/sd_FR_cpi

foreach var in cpi gdp {
	
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num) vce(cluster country_num)
	regsave using "$temp_data/FE_reg_mg_cty_`var'_a_rob.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", FE3, "", MG1, "\checkmark", MG2, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	
}

*** by country and month ***

use $data/baseline.dta, clear

local varlist gdp cpi
		
* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(country month Foreign)
	egen Nobs2 = count(FR_`var'), by(country month Foreign)
	drop if Nobs1<10 | Nobs2<10
	gen country_num2 = .
	gen Foreign2 = .
	gen month2 = .
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	forval i = 1(1)51 {
		forval k=1(1)12 {
			capture reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & month==`k' & Foreign==0, absorb(datem idi)
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+102*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+102*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == `i'+102*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == `i'+102*(`k'-1)
			capture replace Foreign2 = 0		 		if _n == `i'+102*(`k'-1)
			capture replace month2 = `k'		 		if _n == `i'+102*(`k'-1)
			capture reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & month==`k' & Foreign==1, absorb(datem idi)
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+51+102*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+51+102*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == `i'+51+102*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == `i'+51+102*(`k'-1)
			capture replace Foreign2 = 1		 		if _n == `i'+51+102*(`k'-1)
			capture replace month2 = `k'		 		if _n == `i'+51+102*(`k'-1)
		}
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2 month2
	sort country_num2 Foreign2 month2
	rename country_num2 country_num
	rename Foreign2 Foreign
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

* Results
use $data/baseline.dta, clear
keep country country_num Emerging Foreign month
sort country_num Foreign month
collapse Emerging , by(country country_num Foreign month)
merge 1:1 country_num Foreign month using $temp_data/mg_FR, nogen
save $temp_data/mg_FE_reg_cty_month, replace

use $temp_data/mg_FE_reg_cty_month, clear

gen weight_gdp=1/sd_FR_gdp
gen weight_cpi=1/sd_FR_cpi

foreach var in cpi gdp {
	
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'] if weight_`var'<1000000, absorb(month#country_num) vce(cluster country_num)
	regsave using "$temp_data/FE_reg_mg_cty_month_`var'_a.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", MG1, "", MG2, "\checkmark", MG3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'] if weight_`var'<1000000, absorb(month country_num) vce(cluster country_num)
	regsave using "$temp_data/FE_reg_mg_cty_month_`var'_a_rob.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "", MG1, "", MG2, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'] if weight_`var'<1000000, absorb(month#country_num) vce(cluster country_num)
	regsave using "$temp_data/FE_reg_mg_cty_month_`var'_a_baseline.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", FE3, "\checkmark", MG1, "", MG2, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
}

	
* -------------------------------
* Table - FE regressions
* -------------------------------
	
	
	******************************************
	* FE regressions mean-group (by cty & month)
	******************************************
	
	* CPI
	******
	
	* all
	use $temp_data/FE_reg_mg_cty_month_cpi_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_FE_mg.dta, replace 
	
	* GDP
	******
	
	* all
	use  $temp_data/FE_reg_mg_cty_month_gdp_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	*g n = _n
	rename col_1 col_2
	
	g n = _n
	
	drop var
	
	* merge with CPI
	*********
	merge 1:1 database n using $temp_data/cpi_FE_mg.dta
	drop _merge
	
	order var col_1 col_2 
	
	save $temp_data/FE_mg, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi4
	label var cpi4 "$ \text{CPI}_{t} $"
	rename col_2 gdp4
	label var gdp4 "$ \text{GDP}_{t} $"

	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country $\times$ month FE" if var == "FE1"	
	replace var = "Forecaster $\times$ month FE" if var == "FE2"
	replace var = "MG by ctry and month" if var=="MG1"
	replace var = "MG by ctry, loc., and month" if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	order  var cpi4 gdp4
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/FE_mg, replace
	
/*
* Produce the tables
			
			drop if _n > 10
			drop sample

	texsave var cpi gdp cpi2 gdp2 using "$tables/FE_reg_main.tex", ///
				title(Information Asymmetries - Fixed-effect regressions) varlabels nofix hlines(0) headersep(0pt) autonumber ///
			frag  size(footnotesize)  align( l C C C C) location(H) replace label(tab:FE_reg_main) footnote(		"\begin{minipage}{1\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} The table shows the results of a regression of the $\beta^{FE}$ coefficients on the Foreign dummy, where the $\beta^{FE}$ are estimated using Equation \eqref{eq:pooledFE} on different sub-groups of our sample. \textit{Average locals} corresponds to the constant term (or average fixed effect). \textit{Foreign} corresponds to the coefficient of the Foreign dummy. The observations are clustered at the country level in specifications (1) to (4). \end{tabnote} \end{minipage}  ") 
	
*/


**************
* Robustness
**************
	
	* CPI
	******
	
	use $temp_data/FE_reg_mg_cty_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_FE_mg_rob1.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/FE_reg_mg_cty_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_2
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_FE_mg_rob1.dta, replace 

	
	* CPI
	******
	
	use $temp_data/FE_reg_mg_cty_month_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_3
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_FE_mg_rob2.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/FE_reg_mg_cty_month_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_4
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_FE_mg_rob2.dta, replace 
	
	* CPI
	******
	
	use $temp_data/FE_reg_mg_cty_month_cpi_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_5
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_FE_mg_rob3.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/FE_reg_mg_cty_month_gdp_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_6
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_FE_mg_rob3.dta, replace		
	
	* merge
	*********
	use $temp_data/cpi_FE_mg_rob1, clear
	merge 1:1 database n using $temp_data/gdp_FE_mg_rob1.dta, nogen
	merge 1:1 database n using $temp_data/cpi_FE_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/gdp_FE_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/cpi_FE_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_FE_mg_rob3.dta, nogen	
	order var col_1 col_2 col_3 col_4 col_5 col_6
	
	save $temp_data/FE_mg_rob, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi2
	label var cpi2 "$ \text{CPI}_{t} $"
	rename col_2 gdp2
	label var gdp2 "$ \text{GDP}_{t} $"
	rename col_3 cpi3
	label var cpi3 "$ \text{CPI}_{t} $"
	rename col_4 gdp3
	label var gdp3 "$ \text{GDP}_{t} $"
	rename col_5 cpi4
	label var cpi4 "$ \text{CPI}_{t} $"
	rename col_6 gdp4
	label var gdp4 "$ \text{GDP}_{t} $"
	
	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country FE" if var == "FE1"	
	replace var = "Month FE" if var == "FE2"	
	replace var = "Ctry $\times$ month FE" if var == "FE3"
	replace var = "MG by ctry and loc." if var=="MG1"
	replace var = "MG by ctry, loc., and month" if var=="MG2"
	drop if var == "rhs"
	
	drop n
	
	*order  var cpi2 gdp2
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/FE_mg_rob, replace
	
	
	
********************************************************
* 4. Foreigners put more weight on public signals ******
********************************************************

* -------------------------------
* Disagreement - Mean group
* -------------------------------

***** by country ******

use $data/baseline.dta, clear

local varlist gdp cpi
		
* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	collapse FR_`var' `var'_current_a1 `var'_future dFR_`var'_locfor d`var'_locfor, by(country_num datem year month Foreign)
	gen `var'_future_loc = `var'_future if Foreign==0
	gen `var'_future_for = `var'_future if Foreign==1
	collapse FR_`var' `var'_current_a1 `var'_future dFR_`var'_locfor d`var'_locfor `var'_future_loc `var'_future_for, by(country_num datem year month)	
	xtset country_num datem
	gen country_num2 = .
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	forval i = 1(1)51 {
		capture qui reghdfe d`var'_locfor l12.(`var'_future_loc `var'_future_for) `var'_current_a1 FR_`var' if country_num==`i', absorb(month) vce(robust)			
		capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'
		capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'
		capture replace N_FR_`var' = e(N)	        if _n == `i'
		capture replace country_num2 = `i'		 	if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2
	sort country_num2
	rename country_num2 country_num
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

* Results
use $data/baseline.dta, clear
keep country country_num Emerging
sort country_num
collapse Emerging , by(country country_num)
merge 1:1 country_num using $temp_data/mg_FR, nogen
save $temp_data/disag_mg_cty, replace

use $temp_data/disag_mg_cty, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi


foreach var in cpi gdp {
	
	reghdfe b_FR_`var' [aweight=weight_`var'] , noabsorb vce(robust)
		regsave using "$temp_data/disag_mg_cty_`var'_a_rob.dta", replace  ///
			addlabel(rhs,"`capvarp'" , MG1, "\checkmark", MG2, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
			
}



******** by country and month *******

use $data/baseline.dta, clear

local varlist gdp cpi
		
* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	collapse FR_`var' `var'_current_a1 `var'_future dFR_`var'_locfor d`var'_locfor, by(country_num datem year month Foreign)
	gen `var'_future_loc = `var'_future if Foreign==0
	gen `var'_future_for = `var'_future if Foreign==1
	collapse FR_`var' `var'_current_a1 `var'_future dFR_`var'_locfor d`var'_locfor `var'_future_loc `var'_future_for, by(country_num datem year month)	
	egen Nobs1 = count(d`var'_locfor), by(country month)
	drop if Nobs1<10
	xtset country_num datem
	gen country_num2 = .
	gen month2 = .
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	forval i = 1(1)51 {
		forval k=1(1)12 {
			capture qui reghdfe d`var'_locfor l12.(`var'_future_loc `var'_future_for) `var'_current_a1 FR_`var' if country_num==`i' & month==`k', noabsorb vce(robust)			
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+51*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+51*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == `i'+51*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == `i'+51*(`k'-1)
			capture replace month2 = `k'		 		if _n == `i'+51*(`k'-1)
		}
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 month2
	sort country_num2 month2
	rename country_num2 country_num
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

* Results
use $data/baseline.dta, clear
keep country country_num Emerging month
sort country_num month
collapse Emerging , by(country country_num month)
merge 1:1 country_num month using $temp_data/mg_FR, nogen
save $temp_data/disag_mg_cty_month, replace

use $temp_data/disag_mg_cty_month, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	reghdfe b_FR_`var' [aweight=weight_`var'] , noabsorb vce(cluster country_num)
		regsave using "$temp_data/disag_mg_cty_month_`var'_a.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", MG1, "\checkmark", MG2, "", MG3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' [aweight=weight_`var'] , noabsorb vce(cluster country_num)
		regsave using "$temp_data/disag_mg_cty_month_`var'_a_baseline.dta", replace  ///
			addlabel(rhs,"`capvarp'" , MG1, "", MG2, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
			
}


* -------------------------------
* Table - Disagreement
* -------------------------------
	

	******************************************
	* Disagreement mean-group (by cty & month)
	******************************************
	
	* CPI
	******
	
	* all
	use $temp_data/disag_mg_cty_month_cpi_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_disag_mg.dta, replace 
	
	* GDP
	******
	
	* all
	use  $temp_data/disag_mg_cty_month_gdp_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	*g n = _n
	rename col_1 col_2
	
	g n = _n
	
	drop var
	
	* merge with CPI
	*********
	merge 1:1 database n using $temp_data/cpi_disag_mg.dta
	drop _merge
	
	order var col_1 col_2 
	
	save $temp_data/disag_mg, replace
	

	drop database 
	
	
	replace var = "Average" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
		
	rename col_1 cpi5
	label var cpi5 "$ \text{CPI}_{t} $"
	rename col_2 gdp5
	label var gdp5 "$ \text{GDP}_{t} $"

	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country $\times$ month FE" if var == "FE1"	
	replace var = "Forecaster $\times$ month FE" if var == "FE2"
	replace var = "MG by ctry and month" if var=="MG1"
	replace var = "MG by ctry, loc., and month" if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	order  var cpi5 gdp5
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/disag_mg, replace
	
/*
* Produce the tables		
			
			drop if _n > 6
			drop sample

	texsave var cpi gdp cpi2 gdp2 using "$tables/disag_main.tex", ///
				title(Information Asymmetries - Disagreement regressions) varlabels nofix hlines(0) headersep(0pt) autonumber ///
			frag  size(footnotesize)  align( l C C C C) location(H) replace label(tab:disag_main) footnote(		"\begin{minipage}{1\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} The table shows the results of a regression of the $\beta^{Dis}$ coefficients on the constant, where the $\beta^{Dis}$ are estimated using Equation \eqref{eq:disagreement} on different sub-groups of our sample. ``Disagreement'' corresponds to the constant term. In specifications (1) and (2), we show robust standard errors in specifications (3) to (6), standard errors are clustered at the country level. \end{tabnote} \end{minipage}  ") 
*/			
		
**************
* Robustness
**************
	
	* CPI
	******
	
	use $temp_data/disag_mg_cty_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_disag_mg_rob1.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/disag_mg_cty_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_2
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_disag_mg_rob1.dta, replace 

	
	* CPI
	******
	
	use $temp_data/disag_mg_cty_month_cpi_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_3
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_disag_mg_rob2.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/disag_mg_cty_month_gdp_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_4
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_disag_mg_rob2.dta, replace 
	
	* merge
	*********
	use $temp_data/cpi_disag_mg_rob1, clear
	merge 1:1 database n using $temp_data/gdp_disag_mg_rob1.dta, nogen
	merge 1:1 database n using $temp_data/cpi_disag_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/gdp_disag_mg_rob2.dta, nogen
	order var col_1 col_2 col_3 col_4
	
	save $temp_data/disag_mg_rob, replace
	
	drop database 
	
	
	replace var = "Average" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
		
	rename col_1 cpi2
	label var cpi2 "$ \text{CPI}_{t} $"
	rename col_2 gdp2
	label var gdp2 "$ \text{GDP}_{t} $"
	rename col_3 cpi3
	label var cpi3 "$ \text{CPI}_{t} $"
	rename col_4 gdp3
	label var gdp3 "$ \text{GDP}_{t} $"
	
	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
	replace var = "MG by ctry" if var=="MG1"
	replace var = "MG by ctry and month" if var=="MG2"
	drop if var == "rhs"
	
	drop n
	
	*order  var cpi2 gdp2
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/disag_mg_rob, replace
	
	

******** IMF WEO updated (for R3) *******

use $data/baseline.dta, clear

local varlist gdp cpi
		
* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	collapse FR_`var' `var'_current_a1 `var'_future dFR_`var'_locfor d`var'_locfor vintage_`var'_current_t_* vintage_`var'_future_t_*, by(country_num datem year month Foreign)
	gen `var'_future_loc = `var'_future if Foreign==0
	gen `var'_future_for = `var'_future if Foreign==1
	collapse FR_`var' `var'_current_a1 `var'_future dFR_`var'_locfor d`var'_locfor `var'_future_loc `var'_future_for vintage_`var'_current_t_* vintage_`var'_future_t_*, by(country_num datem year month)	
	egen Nobs1 = count(d`var'_locfor), by(country month)
	drop if Nobs1<10
	xtset country_num datem
	gen IMFupdate = 0
	*replace IMFupdate = l.l12.vintage_`var'_current_t_a1 - l.l19.vintage_`var'_future_t_s1 if month==5
	*replace IMFupdate = l.l12.vintage_`var'_current_t_s1 - l.l16.vintage_`var'_current_t_a1 if month==10
	replace IMFupdate = l12.vintage_`var'_current_t_a1 - l19.vintage_`var'_future_t_s1 if month==4
	replace IMFupdate = l12.vintage_`var'_current_t_s1 - l16.vintage_`var'_current_t_a1 if month==9
	gen country_num2 = .
	gen b_FR_`var' = .
	gen b_FR_`var'1 = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen sd_FR_`var'1 = .
	forval i = 1(1)51 {
		forval k=1(1)12 {
			capture qui reghdfe d`var'_locfor l12.(`var'_future_loc `var'_future_for) `var'_current_a1 IMFupdate l.IMFupdate if country_num==`i', noabsorb vce(robust)			
			capture replace b_FR_`var' = _b[IMFupdate]   if _n == `i'
			capture replace sd_FR_`var' = _se[IMFupdate] if _n == `i'
			capture replace b_FR_`var'1 = _b[l.IMFupdate]   if _n == `i'
			capture replace sd_FR_`var'1 = _se[l.IMFupdate] if _n == `i'
			capture replace N_FR_`var' = e(N)	        if _n == `i'
			capture replace country_num2 = `i'		 	if _n == `i'
		}
	}
	keep b_FR_`var' b_FR_`var'1 N_FR_`var' sd_FR_`var' sd_FR_`var'1 country_num2
	sort country_num2
	rename country_num2 country_num
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

* Results
use $data/baseline.dta, clear
keep country country_num Emerging
sort country_num
collapse Emerging , by(country country_num)
merge 1:1 country_num using $temp_data/mg_FR, nogen
save $temp_data/IMF_mg_cty, replace

use $temp_data/IMF_mg_cty, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi
gen weight_gdp1 = 1/sd_FR_gdp1
gen weight_cpi1 = 1/sd_FR_cpi1

foreach var in cpi gdp {
	
	reghdfe b_FR_`var' [aweight=weight_`var'] , noabsorb vce(robust)
	reghdfe b_FR_`var'1 [aweight=weight_`var'1] , noabsorb vce(robust)
		
}


***************************************
* 5. Consensus regressions
***************************************

* -------------------------------
* Consensus - Mean group
* -------------------------------

***** by country ******

use $data/baseline.dta, clear

local varlist gdp cpi
		
* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	collapse (median) FR_`var' FE_`var'_current_a1 , by(country_num datem year month Foreign Emerging)
	egen country_num_For = group(country_num Foreign)
	xtset country_num_For datem	
	local FE month	
	gen country_num2 = .
	gen Foreign2 = .
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	forval i = 1(1)51 {
		capture qui reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & Foreign==0, absorb(`FE')	
		capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'
		capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'
		capture replace N_FR_`var' = e(N)	        if _n == `i'
		capture replace country_num2 = `i'		 	if _n == `i'
		capture replace Foreign2 = 0			 	if _n == `i'
		capture qui reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & Foreign==1, absorb(`FE')	
		capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+51
		capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+51
		capture replace N_FR_`var' = e(N)	        if _n == `i'+51
		capture replace country_num2 = `i'		 	if _n == `i'+51
		capture replace Foreign2 = 1			 	if _n == `i'+51
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2
	sort country_num2 Foreign2
	rename country_num2 country_num
	rename Foreign2 Foreign
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

* Results
use $data/baseline.dta, clear
keep country country_num Emerging Foreign
sort country_num Foreign
collapse Emerging , by(country country_num Foreign)
merge 1:1 country_num Foreign using $temp_data/mg_FR, nogen
save $temp_data/consensus_mg_cty, replace

use $temp_data/consensus_mg_cty, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'] , absorb(country_num) vce(cluster country_num)
		regsave using "$temp_data/consensus_mg_cty_`var'_a_rob.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", FE3, "", MG1, "\checkmark", MG2, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
				
}

******** by country and month *******

use $data/baseline.dta, clear

local varlist gdp cpi
		
* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	collapse (median) FR_`var' FE_`var'_current_a1 , by(country_num datem year month Foreign Emerging)
	egen country_num_For_month = group(country_num Foreign month)
	xtset country_num_For_month datem	
	local FE month	
	gen country_num2 = .
	gen Foreign2 = .
	gen month2 = .
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	forval i = 1(1)51 {
		forval k = 1(1)12 {
			capture qui reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & month==`k' & Foreign==0, absorb(`FE')	
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+51*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+51*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == `i'+51*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == `i'+51*(`k'-1)
			capture replace Foreign2 = 0			 	if _n == `i'+51*(`k'-1)
			capture replace month2 = `k'			 	if _n == `i'+51*(`k'-1)
			capture qui reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & month==`k' & Foreign==1, absorb(`FE')	
			capture replace b_FR_`var' = _b[FR_`var']   if _n == 612+`i'+51*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == 612+`i'+51*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == 612+`i'+51*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == 612+`i'+51*(`k'-1)
			capture replace Foreign2 = 1			 	if _n == 612+`i'+51*(`k'-1)
			capture replace month2 = `k'			 	if _n == 612+`i'+51*(`k'-1)
		}
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2 month2
	sort country_num2 Foreign2 month2
	rename country_num2 country_num
	rename Foreign2 Foreign
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

* Results
use $data/baseline.dta, clear
keep country country_num Emerging Foreign month
sort country_num Foreign month
collapse Emerging , by(country country_num Foreign month)
merge 1:1 country_num Foreign month using $temp_data/mg_FR, nogen
save $temp_data/consensus_mg_cty_month, replace

use $temp_data/consensus_mg_cty_month, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'] , absorb(country_num#month) vce(cluster country_num)
		regsave using "$temp_data/consensus_mg_cty_month_`var'_a.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", MG1, "", MG2, "\checkmark", MG3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'] , absorb(country_num month) vce(cluster country_num)
		regsave using "$temp_data/consensus_mg_cty_month_`var'_a_rob.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "", MG1, "", MG2, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'] , absorb(country_num#month) vce(cluster country_num)
		regsave using "$temp_data/consensus_mg_cty_month_`var'_a_baseline.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", FE3, "\checkmark", MG1, "", MG2, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
			
}


* -------------------------------
* Table - Consensus
* -------------------------------
	
	******************************************
	* consensusreement mean-group (by cty & month)
	******************************************
	
	* CPI
	******
	
	* all
	use $temp_data/consensus_mg_cty_month_cpi_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_consensus_mg.dta, replace 
	
	* GDP
	******
	
	* all
	use  $temp_data/consensus_mg_cty_month_gdp_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	*g n = _n
	rename col_1 col_2
	
	g n = _n
	
	drop var
	
	* merge with CPI
	*********
	merge 1:1 database n using $temp_data/cpi_consensus_mg.dta
	drop _merge
	
	order var col_1 col_2 
	
	save $temp_data/consensus_mg, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi3
	label var cpi3 "$ \text{CPI}_{t} $"
	rename col_2 gdp3
	label var gdp3 "$ \text{GDP}_{t} $"

	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country $\times$ month FE" if var == "FE1"	
	replace var = "Forecaster $\times$ month FE" if var == "FE2"
	replace var = "MG by ctry and month" if var=="MG1"
	replace var = "MG by ctry, loc., and month" if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	order  var cpi3 gdp3
	
	label var var "Coefficient"
	
	gen n=_n

	save $temp_data/consensus_mg, replace

/*
* Produce the tables
	
			drop if _n > 8
			drop sample

	texsave var cpi gdp cpi2 gdp2 using "$tables/consensus_main.tex", ///
				title(Information Asymmetries - Consensus regressions) varlabels nofix hlines(0) headersep(0pt) autonumber ///
			frag  size(footnotesize)  align( l C C C C) location(H) replace label(tab:consensus_main) footnote(		"\begin{minipage}{1\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:}  The table shows the results of a regression of the $\beta^{CG}$ coefficients on the Foreign dummy, where the $\beta^{CG}$ are estimated using equation \eqref{eq:consensus} on different sub-groups of our sample. \textit{Average locals} corresponds to the constant term (or average fixed effect). \textit{Foreign} corresponds to the coefficient of the Foreign dummy. The obervations are clustered at the country level. \end{tabnote} \end{minipage}  ") 
*/		
		
**************
* Robustness
**************
	
	* CPI
	******
	
	use $temp_data/consensus_mg_cty_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_consensus_mg_rob1.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/consensus_mg_cty_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_2
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_consensus_mg_rob1.dta, replace 

	
	* CPI
	******
	
	use $temp_data/consensus_mg_cty_month_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_3
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_consensus_mg_rob2.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/consensus_mg_cty_month_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_4
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_consensus_mg_rob2.dta, replace 
	
	* CPI
	******
	
	use $temp_data/consensus_mg_cty_month_cpi_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_5
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_consensus_mg_rob3.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/consensus_mg_cty_month_gdp_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_6
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_consensus_mg_rob3.dta, replace		
	
	* merge
	*********
	use $temp_data/cpi_consensus_mg_rob1, clear
	merge 1:1 database n using $temp_data/gdp_consensus_mg_rob1.dta, nogen
	merge 1:1 database n using $temp_data/cpi_consensus_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/gdp_consensus_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/cpi_consensus_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_consensus_mg_rob3.dta, nogen	
	order var col_1 col_2 col_3 col_4 col_5 col_6
	
	save $temp_data/consensus_mg_rob, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi2
	label var cpi2 "$ \text{CPI}_{t} $"
	rename col_2 gdp2
	label var gdp2 "$ \text{GDP}_{t} $"
	rename col_3 cpi3
	label var cpi3 "$ \text{CPI}_{t} $"
	rename col_4 gdp3
	label var gdp3 "$ \text{GDP}_{t} $"
	rename col_5 cpi4
	label var cpi4 "$ \text{CPI}_{t} $"
	rename col_6 gdp4
	label var gdp4 "$ \text{GDP}_{t} $"
	
	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country FE" if var == "FE1"	
	replace var = "Month FE" if var == "FE2"	
	replace var = "Ctry $\times$ month FE" if var == "FE3"
	replace var = "MG by ctry and loc." if var=="MG1"
	replace var = "MG by ctry, loc., and month" if var=="MG2"
	drop if var == "rhs"
	
	drop n
	
	*order  var cpi2 gdp2
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/consensus_mg_rob, replace
	
**************************************************************************
* ROBUSTNESS (more behavioral biases)
**************************************************************************

use $data/baseline.dta, clear

* -------------------------------
* Vintage - Mean-group regressions
* -------------------------------

**** By country and Foreign ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	local FE idci#month
	preserve
	egen id2 = group(country Foreign)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen country_num2 = .
	gen Foreign2 = .
	sum id2
	local MAX=r(max)
	sort idci datem
	xtset idci datem
	forval i = 1(1)`MAX' {
		capture qui reghdfe FE_`var'_current_a1 l12.`var'_current_a1 if id2==`i', absorb(`FE')
		capture replace b_FR_`var' = _b[l12.`var'_current_a1]    if _n == `i'
		capture replace sd_FR_`var' = _se[l12.`var'_current_a1]    if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture sum country_num if id2==`i'
		capture replace country_num2 = r(mean) 			 if _n == `i'
		capture sum Foreign if id2==`i'
		capture replace Foreign2 = r(mean) 			 if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2
	sort country_num2 Foreign2
	rename country_num2 country_num
	rename Foreign2 Foreign
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country country_num Foreign Emerging
sort country_num Foreign
collapse Emerging, by(country country_num Foreign)
merge 1:1 country_num Foreign using $temp_data/mg_FR, nogen
save $temp_data/mg_vintage_cty, replace


use $temp_data/mg_vintage_cty, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num) vce(robust)
	regsave using "$temp_data/vintage_mg_cty_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", FE3, "", FE4, "", FE5, "", MG1, "\checkmark", MG2, "", MG3, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
				
			
}


***** By institution-country pair ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(institution country month)
	sort idci datem
	xtset idci datem
	gen l12`var'_current_a1 = l12.`var'_current_a1
	egen Nobs2 = count(l12`var'_current_a1), by(institution country month)
	drop if Nobs1<10 | Nobs2<10
	egen id2 = group(institution country)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen idci2 = .
	gen month2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg FE_`var'_current_a1 l12.`var'_current_a1 if id2==`i'
		capture replace b_FR_`var' = _b[l12.`var'_current_a1]    if _n == `i'
		capture replace sd_FR_`var' = _se[l12.`var'_current_a1]    if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2
	sort idci2
	rename idci2 idci
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country institution idci idi country_num Foreign Multinational N_cty Emerging
sort idci
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num)
merge 1:1 idci using $temp_data/mg_FR, nogen
save $temp_data/mg_vintage_cty_inst, replace

use $temp_data/mg_vintage_cty_inst, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
		
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(idi country_num) vce(cluster country_num idi)
	regsave using "$temp_data/vintage_mg_cty_inst_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "", FE4, "", FE5, "", MG1, "", MG2, "\checkmark", MG3, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
				
}
		
**** By country, institution and month ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(institution country month)
	drop if Nobs1<10
	sort idci datem
	xtset idci datem
	gen l12`var'_current_a1 = l12.`var'_current_a1
	egen Nobs2 = count(l12`var'_current_a1), by(institution country month)
	drop if Nobs2<10
	egen id2 = group(institution country month)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen idci2 = .
	gen month2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg FE_`var'_current_a1 l12.`var'_current_a1 if id2==`i'
		capture replace b_FR_`var' = _b[l12.`var'_current_a1]    if _n == `i'
		capture replace sd_FR_`var' = _se[l12.`var'_current_a1]    if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 if _n == `i'
		capture sum month if id2==`i'
		capture replace month2 = r(mean) 			 if _n == `i'
		}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2 month2
	sort idci2
	sort idci2 month2
	rename idci2 idci
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country institution idci idi country_num Foreign Multinational N_cty Emerging month
sort idci month
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num month)
merge 1:1 idci month using $temp_data/mg_FR, nogen
save $temp_data/mg_FR_vintage_cty_inst_month, replace

use $temp_data/mg_FR_vintage_cty_inst_month, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi


foreach var in gdp cpi {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(month#country_num month#idi) vce(cluster country_num idi)
	regsave using "$temp_data/vintage_mg_cty_inst_month_`var'_a.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "No", FE2, "Yes", FE3, "Yes", FE4, "Yes", MG1, "No", MG2, "No", MG3, "Yes")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num idi month) vce(cluster country_num idi)
	regsave using "$temp_data/vintage_mg_cty_inst_month_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(month#idi month#country_num) vce(cluster country_num idi)
	regsave using "$temp_data/vintage_mg_cty_inst_month_`var'_a_baseline.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

}

* Figures

use $temp_data/mg_vintage_cty_inst, clear

sort country_num
by country_num: egen mb_FR_cpi_cty = median(b_FR_cpi)
egen country_num1 = group(mb_FR_cpi_cty)
by country_num: egen mb_FR_gdp_cty = median(b_FR_gdp)
egen country_num2 = group(mb_FR_gdp_cty)
label var b_FR_cpi "Past vintage coefficient - CPI"
label var b_FR_gdp "Past vintage coefficient - GDP"
label var country_num1 "country"
label var country_num2 "country"
twoway (scatter b_FR_cpi country_num1) (scatter b_FR_cpi country_num1 if Emerging==1) (scatter b_FR_cpi country_num1 if country=="United States"), legend(label(1 "Advanced") label(2 "Emerging") label(3 "United States"))
		graph export "$figures//dist_vintage_cpi_cty.pdf", as(pdf) replace
twoway (scatter b_FR_gdp country_num2) (scatter b_FR_gdp country_num2 if Emerging==1) (scatter b_FR_gdp country_num2 if country=="United States"), legend(label(1 "Advanced") label(2 "Emerging") label(3 "United States"))
		graph export "$figures//dist_vintage_gdp_cty.pdf", as(pdf) replace
hist b_FR_gdp 
		graph export "$figures//dist_vintage_cpi.pdf", as(pdf) replace
hist b_FR_cpi
		graph export "$figures//dist_vintage_gdp.pdf", as(pdf) replace
		
*--------------------
**# Table Vintage
*--------------------

**************
* Robustness
**************

	* CPI
	******
	
	use $temp_data/vintage_mg_cty_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_vintage_mg_rob1.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/vintage_mg_cty_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_2
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_vintage_mg_rob1.dta, replace 

	
	* CPI
	******
	
	use $temp_data/vintage_mg_cty_inst_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_3
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_vintage_mg_rob2.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/vintage_mg_cty_inst_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_4
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_vintage_mg_rob2.dta, replace 
	
	* CPI
	******
	
	use $temp_data/vintage_mg_cty_inst_month_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_5
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_vintage_mg_rob3.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/vintage_mg_cty_inst_month_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_6
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_vintage_mg_rob3.dta, replace 
	
	
	* CPI
	******
	
	use $temp_data/vintage_mg_cty_inst_month_cpi_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_7
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_vintage_mg_rob4.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/vintage_mg_cty_inst_month_gdp_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_8
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_vintage_mg_rob4.dta, replace 
		
	
	* merge
	*********
	use $temp_data/cpi_vintage_mg_rob1, clear
	merge 1:1 database n using $temp_data/gdp_vintage_mg_rob1.dta, nogen
	merge 1:1 database n using $temp_data/cpi_vintage_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/gdp_vintage_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/cpi_vintage_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_vintage_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/cpi_vintage_mg_rob4.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_vintage_mg_rob4.dta, nogen	
	order var col_1 col_2 col_3 col_4 col_5 col_6 col_7 col_8
	
	save $temp_data/vintage_mg_rob, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi2
	label var cpi2 "$ \text{CPI}_{t} $"
	rename col_2 gdp2
	label var gdp2 "$ \text{GDP}_{t} $"
	rename col_3 cpi3
	label var cpi3 "$ \text{CPI}_{t} $"
	rename col_4 gdp3
	label var gdp3 "$ \text{GDP}_{t} $"
	rename col_5 cpi4
	label var cpi4 "$ \text{CPI}_{t} $"
	rename col_6 gdp4
	label var gdp4 "$ \text{GDP}_{t} $"
	rename col_7 cpi5
	label var cpi5 "$ \text{CPI}_{t} $"
	rename col_8 gdp5
	label var gdp5 "$ \text{GDP}_{t} $"
	
	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country FE" if var == "FE1"	
	replace var = "Forecaster FE" if var == "FE2"
	replace var = "Month FE" if var == "FE3"	
	replace var = "Ctry $\times$ month FE" if var == "FE4"
	replace var = "For. $\times$ month FE" if var == "FE5"
	replace var = "MG by ctry and loc." if var=="MG1"
	replace var = "MG by ctry and for." if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	*order  var cpi2 gdp2
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/vintage_mg_rob, replace

* -------------------------------
* Past consensus - Mean-group regressions
* -------------------------------

**** By country and Foreign ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	egen m`var'_current = pctile(`var'_current), p(50) by(country datem)
	egen m`var'_future = pctile(`var'_future), p(50) by(country datem)
	sort idci datem
	xtset idci datem
	gen `var'_past_consensus = l.m`var'_current if month!=1
	replace `var'_past_consensus = l.m`var'_future if month==1
	local FE idci#month
	preserve
	egen id2 = group(country Foreign)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen country_num2 = .
	gen Foreign2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reghdfe FE_`var'_current_a1 `var'_past_consensus if id2==`i', absorb(`FE')
		capture replace b_FR_`var' = _b[`var'_past_consensus]    if _n == `i'
		capture replace sd_FR_`var' = _se[`var'_past_consensus]    if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture sum country_num if id2==`i'
		capture replace country_num2 = r(mean) 			 if _n == `i'
		capture sum Foreign if id2==`i'
		capture replace Foreign2 = r(mean) 			 if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2
	sort country_num2 Foreign2
	rename country_num2 country_num
	rename Foreign2 Foreign
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country country_num Foreign Emerging
sort country_num Foreign
collapse Emerging, by(country country_num Foreign)
merge 1:1 country_num Foreign using $temp_data/mg_FR, nogen
save $temp_data/mg_past_consensus_cty, replace


use $temp_data/mg_past_consensus_cty, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num) vce(robust)
	regsave using "$temp_data/past_consensus_mg_cty_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", FE3, "", FE4, "", FE5, "", MG1, "\checkmark", MG2, "", MG3, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
}


***** By institution-country pair ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(institution country month)
	drop if Nobs1<10 
	egen m`var'_current = pctile(`var'_current), p(50) by(country datem)
	egen m`var'_future = pctile(`var'_future), p(50) by(country datem)
	sort idci datem
	xtset idci datem
	gen `var'_past_consensus = l.m`var'_current if month!=1
	replace `var'_past_consensus = l.m`var'_future if month==1
	egen Nobs2 = count(`var'_past_consensus), by(institution country month)
	drop if Nobs2<10 
	egen id2 = group(institution country)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen idci2 = .
	gen month2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg FE_`var'_current_a1 `var'_past_consensus if id2==`i'
		capture replace b_FR_`var' = _b[`var'_past_consensus]    if _n == `i'
		capture replace sd_FR_`var' = _se[`var'_past_consensus]  if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2
	sort idci2
	rename idci2 idci
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country institution idci idi country_num Foreign Multinational N_cty Emerging
sort idci
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num)
merge 1:1 idci using $temp_data/mg_FR, nogen
save $temp_data/mg_past_consensus_cty_inst, replace

use $temp_data/mg_past_consensus_cty_inst, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
		
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num idi) vce(cluster country_num idi)
	regsave using "$temp_data/past_consensus_mg_cty_inst_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "", FE4, "", FE5, "", MG1, "", MG2, "\checkmark", MG3, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
}
		
**** By country, institution and month ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(institution country month)
	drop if Nobs1<10
	egen m`var'_current = pctile(`var'_current), p(50) by(country datem)
	egen m`var'_future = pctile(`var'_future), p(50) by(country datem)
	sort idci datem
	xtset idci datem
	gen `var'_past_consensus = l.m`var'_current if month!=1
	replace `var'_past_consensus = l.m`var'_future if month==1
	egen Nobs2 = count(`var'_past_consensus), by(institution country month)
	drop if Nobs2<10 
	egen id2 = group(institution country month)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen idci2 = .
	gen month2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg FE_`var'_current_a1 `var'_past_consensus if id2==`i'
		capture replace b_FR_`var' = _b[`var'_past_consensus]    if _n == `i'
		capture replace sd_FR_`var' = _se[`var'_past_consensus]  if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 if _n == `i'
		capture sum month if id2==`i'
		capture replace month2 = r(mean) 			 if _n == `i'
		}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2 month2
	sort idci2
	sort idci2 month2
	rename idci2 idci
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country institution idci idi country_num Foreign Multinational N_cty Emerging month
sort idci month
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num month)
merge 1:1 idci month using $temp_data/mg_FR, nogen
save $temp_data/mg_FR_past_consensus_cty_inst_month, replace

use $temp_data/mg_FR_past_consensus_cty_inst_month, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num#month idi#month) vce(cluster country_num idi)
	regsave using "$temp_data/past_consensus_mg_cty_inst_month_`var'_a.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "No", FE2, "Yes", FE3, "Yes", FE4, "Yes", MG1, "No", MG2, "No", MG3, "Yes")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(month country_num idi) vce(cluster country_num idi)
	regsave using "$temp_data/past_consensus_mg_cty_inst_month_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num#month idi#month) vce(cluster country_num idi)
	regsave using "$temp_data/past_consensus_mg_cty_inst_month_`var'_a_baseline.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
}

* Figures

use $temp_data/mg_past_consensus_cty_inst, clear

sort country_num
by country_num: egen mb_FR_cpi_cty = median(b_FR_cpi)
egen country_num1 = group(mb_FR_cpi_cty)
by country_num: egen mb_FR_gdp_cty = median(b_FR_gdp)
egen country_num2 = group(mb_FR_gdp_cty)
label var b_FR_cpi "Past consensus coefficient - CPI"
label var b_FR_gdp "Past consensus coefficient - GDP"
label var country_num1 "country"
label var country_num2 "country"
twoway (scatter b_FR_cpi country_num1) (scatter b_FR_cpi country_num1 if Emerging==1) (scatter b_FR_cpi country_num1 if country=="United States"), legend(label(1 "Advanced") label(2 "Emerging") label(3 "United States"))
		graph export "$figures//dist_past_consensus_cpi_cty.pdf", as(pdf) replace
twoway (scatter b_FR_gdp country_num2) (scatter b_FR_gdp country_num2 if Emerging==1) (scatter b_FR_gdp country_num2 if country=="United States"), legend(label(1 "Advanced") label(2 "Emerging") label(3 "United States"))
		graph export "$figures//dist_past_consensus_gdp_cty.pdf", as(pdf) replace
hist b_FR_gdp 
		graph export "$figures//dist_past_consensus_cpi.pdf", as(pdf) replace
hist b_FR_cpi
		graph export "$figures//dist_past_consensus_gdp.pdf", as(pdf) replace
		

*--------------------
**# Table Past consensus
*--------------------


**************
* Robustness
**************

	* CPI
	******
	
	use $temp_data/past_consensus_mg_cty_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_past_consensus_mg_rob1.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/past_consensus_mg_cty_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_2
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_past_consensus_mg_rob1.dta, replace 

	
	* CPI
	******
	
	use $temp_data/past_consensus_mg_cty_inst_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_3
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_past_consensus_mg_rob2.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/past_consensus_mg_cty_inst_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_4
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_past_consensus_mg_rob2.dta, replace 
	
	* CPI
	******
	
	use $temp_data/past_consensus_mg_cty_inst_month_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_5
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_past_consensus_mg_rob3.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/past_consensus_mg_cty_inst_month_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_6
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_past_consensus_mg_rob3.dta, replace 
	
	
	* CPI
	******
	
	use $temp_data/past_consensus_mg_cty_inst_month_cpi_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_7
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_past_consensus_mg_rob4.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/past_consensus_mg_cty_inst_month_gdp_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_8
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_past_consensus_mg_rob4.dta, replace 
		
	
	* merge
	*********
	use $temp_data/cpi_past_consensus_mg_rob1, clear
	merge 1:1 database n using $temp_data/gdp_past_consensus_mg_rob1.dta, nogen
	merge 1:1 database n using $temp_data/cpi_past_consensus_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/gdp_past_consensus_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/cpi_past_consensus_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_past_consensus_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/cpi_past_consensus_mg_rob4.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_past_consensus_mg_rob4.dta, nogen	
	order var col_1 col_2 col_3 col_4 col_5 col_6 col_7 col_8
	
	save $temp_data/past_consensus_mg_rob, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi2
	label var cpi2 "$ \text{CPI}_{t} $"
	rename col_2 gdp2
	label var gdp2 "$ \text{GDP}_{t} $"
	rename col_3 cpi3
	label var cpi3 "$ \text{CPI}_{t} $"
	rename col_4 gdp3
	label var gdp3 "$ \text{GDP}_{t} $"
	rename col_5 cpi4
	label var cpi4 "$ \text{CPI}_{t} $"
	rename col_6 gdp4
	label var gdp4 "$ \text{GDP}_{t} $"
	rename col_7 cpi5
	label var cpi5 "$ \text{CPI}_{t} $"
	rename col_8 gdp5
	label var gdp5 "$ \text{GDP}_{t} $"
	
	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country FE" if var == "FE1"	
	replace var = "Forecaster FE" if var == "FE2"
	replace var = "Month FE" if var == "FE3"	
	replace var = "Ctry $\times$ month FE" if var == "FE4"
	replace var = "For. $\times$ month FE" if var == "FE5"
	replace var = "MG by ctry and loc." if var=="MG1"
	replace var = "MG by ctry and for." if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	*order  var cpi2 gdp2
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/past_consensus_mg_rob, replace
	
	
	
* -------------------------------
* Local bias - Mean-group regressions
* -------------------------------

**** By country and Foreign ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	gen FR_`var'_current_local = FR_`var'_current if country==Headquarters
	egen FR_`var'_current_loc = max(FR_`var'_current_local), by(idi datem)
	sort idci datem
	xtset idci datem
	local FE idci#month
	preserve
	egen id2 = group(country Foreign)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen country_num2 = .
	gen Foreign2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reghdfe FE_`var'_current_a1 FR_`var'_current_loc if id2==`i', absorb(`FE')
		capture replace b_FR_`var' = _b[FR_`var'_current_loc]    if _n == `i'
		capture replace sd_FR_`var' = _se[FR_`var'_current_loc]    if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture sum country_num if id2==`i'
		capture replace country_num2 = r(mean) 			 if _n == `i'
		capture sum Foreign if id2==`i'
		capture replace Foreign2 = r(mean) 			 if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2
	sort country_num2 Foreign2
	rename country_num2 country_num
	rename Foreign2 Foreign
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country country_num Foreign Emerging
sort country_num Foreign
collapse Emerging, by(country country_num Foreign)
merge 1:1 country_num Foreign using $temp_data/mg_FR, nogen
save $temp_data/mg_local_cty, replace


use $temp_data/mg_local_cty, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num) vce(robust)
	regsave using "$temp_data/local_mg_cty_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", FE3, "", FE4, "", FE5, "", MG1, "\checkmark", MG2, "", MG3, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
}


***** By institution-country pair ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(institution country month)
	drop if Nobs1<10 
	gen FR_`var'_current_local = FR_`var'_current if country==Headquarters
	egen FR_`var'_current_loc = max(FR_`var'_current_local), by(idi datem)
	egen Nobs2 = count(FR_`var'_current_loc), by(institution country month)
	drop if Nobs2<10 
	egen id2 = group(institution country)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen idci2 = .
	gen month2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg FE_`var'_current_a1 FR_`var'_current_loc if id2==`i'
		capture replace b_FR_`var' = _b[FR_`var'_current_loc]    if _n == `i'
		capture replace sd_FR_`var' = _se[FR_`var'_current_loc]  if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2
	sort idci2
	rename idci2 idci
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country institution idci idi country_num Foreign Multinational N_cty Emerging
sort idci
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num)
merge 1:1 idci using $temp_data/mg_FR, nogen
save $temp_data/mg_local_cty_inst, replace

use $temp_data/mg_local_cty_inst, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
		
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num idi) vce(cluster country_num idi)
	regsave using "$temp_data/local_mg_cty_inst_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "", FE4, "", FE5, "", MG1, "", MG2, "\checkmark", MG3, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
}
		
**** By country, institution and month ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(institution country month)
	drop if Nobs1<10
	gen FR_`var'_current_local = FR_`var'_current if country==Headquarters
	egen FR_`var'_current_loc = max(FR_`var'_current_local), by(idi datem)
	egen Nobs2 = count(FR_`var'_current_loc), by(institution country month)
	drop if Nobs2<10 
	egen id2 = group(institution country month)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen idci2 = .
	gen month2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg FE_`var'_current_a1 FR_`var'_current_loc if id2==`i'
		capture replace b_FR_`var' = _b[FR_`var'_current_loc]    if _n == `i'
		capture replace sd_FR_`var' = _se[FR_`var'_current_loc]  if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 if _n == `i'
		capture sum month if id2==`i'
		capture replace month2 = r(mean) 			 if _n == `i'
		}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2 month2
	sort idci2
	sort idci2 month2
	rename idci2 idci
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country institution idci idi country_num Foreign Multinational N_cty Emerging month
sort idci month
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num month)
merge 1:1 idci month using $temp_data/mg_FR, nogen
save $temp_data/mg_FR_local_cty_inst_month, replace

use $temp_data/mg_FR_local_cty_inst_month, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num#month idi#month) vce(cluster country_num idi)
	regsave using "$temp_data/local_mg_cty_inst_month_`var'_a.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "No", FE2, "Yes", FE3, "Yes", FE4, "Yes", MG1, "No", MG2, "No", MG3, "Yes")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(month country_num idi) vce(cluster country_num idi)
	regsave using "$temp_data/local_mg_cty_inst_month_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num#month idi#month) vce(cluster country_num idi)
	regsave using "$temp_data/local_mg_cty_inst_month_`var'_a_baseline.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
}

*--------------------
**# Table Local bias
*--------------------


**************
* Robustness
**************

	* CPI
	******
	
	use $temp_data/local_mg_cty_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_local_mg_rob1.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/local_mg_cty_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_2
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_local_mg_rob1.dta, replace 

	
	* CPI
	******
	
	use $temp_data/local_mg_cty_inst_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_3
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_local_mg_rob2.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/local_mg_cty_inst_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_4
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_local_mg_rob2.dta, replace 
	
	* CPI
	******
	
	use $temp_data/local_mg_cty_inst_month_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_5
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_local_mg_rob3.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/local_mg_cty_inst_month_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_6
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_local_mg_rob3.dta, replace 
	
	
	* CPI
	******
	
	use $temp_data/local_mg_cty_inst_month_cpi_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_7
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_local_mg_rob4.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/local_mg_cty_inst_month_gdp_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_8
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_local_mg_rob4.dta, replace 
		
	
	* merge
	*********
	use $temp_data/cpi_local_mg_rob1, clear
	merge 1:1 database n using $temp_data/gdp_local_mg_rob1.dta, nogen
	merge 1:1 database n using $temp_data/cpi_local_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/gdp_local_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/cpi_local_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_local_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/cpi_local_mg_rob4.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_local_mg_rob4.dta, nogen	
	order var col_1 col_2 col_3 col_4 col_5 col_6 col_7 col_8
	
	save $temp_data/local_mg_rob, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi2
	label var cpi2 "$ \text{CPI}_{t} $"
	rename col_2 gdp2
	label var gdp2 "$ \text{GDP}_{t} $"
	rename col_3 cpi3
	label var cpi3 "$ \text{CPI}_{t} $"
	rename col_4 gdp3
	label var gdp3 "$ \text{GDP}_{t} $"
	rename col_5 cpi4
	label var cpi4 "$ \text{CPI}_{t} $"
	rename col_6 gdp4
	label var gdp4 "$ \text{GDP}_{t} $"
	rename col_7 cpi5
	label var cpi5 "$ \text{CPI}_{t} $"
	rename col_8 gdp5
	label var gdp5 "$ \text{GDP}_{t} $"
	
	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country FE" if var == "FE1"	
	replace var = "Forecaster FE" if var == "FE2"
	replace var = "Month FE" if var == "FE3"	
	replace var = "Ctry $\times$ month FE" if var == "FE4"
	replace var = "For. $\times$ month FE" if var == "FE5"
	replace var = "MG by ctry and loc." if var=="MG1"
	replace var = "MG by ctry and for." if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	*order  var cpi2 gdp2
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/local_mg_rob, replace
	
	

* -------------------------------
* Systematic bias - Mean-group regressions
* -------------------------------

**** By country and Foreign ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen id2 = group(country Foreign)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen country_num2 = .
	gen Foreign2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reghdfe FE_`var'_current_a1 if id2==`i', noabsorb
		capture replace b_FR_`var' = _b[_cons]    if _n == `i'
		capture replace sd_FR_`var' = _se[_cons]    if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture sum country_num if id2==`i'
		capture replace country_num2 = r(mean) 			 if _n == `i'
		capture sum Foreign if id2==`i'
		capture replace Foreign2 = r(mean) 			 if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2
	sort country_num2 Foreign2
	rename country_num2 country_num
	rename Foreign2 Foreign
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country country_num Foreign Emerging
sort country_num Foreign
collapse Emerging, by(country country_num Foreign)
merge 1:1 country_num Foreign using $temp_data/mg_FR, nogen
save $temp_data/mg_bias_cty, replace


use $temp_data/mg_bias_cty, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num) vce(robust)
	regsave using "$temp_data/bias_mg_cty_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", FE3, "", FE4, "", FE5, "", MG1, "\checkmark", MG2, "", MG3, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
}


***** By institution-country pair ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(institution country month)
	drop if Nobs1<10 
	egen id2 = group(institution country)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen idci2 = .
	gen month2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg FE_`var'_current_a1 if id2==`i'
		capture replace b_FR_`var' = _b[_cons]    if _n == `i'
		capture replace sd_FR_`var' = _se[_cons]  if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2
	sort idci2
	rename idci2 idci
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country institution idci idi country_num Foreign Multinational N_cty Emerging
sort idci
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num)
merge 1:1 idci using $temp_data/mg_FR, nogen
save $temp_data/mg_bias_cty_inst, replace

use $temp_data/mg_bias_cty_inst, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
		
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num idi) vce(cluster country_num idi)
	regsave using "$temp_data/bias_mg_cty_inst_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "", FE4, "", FE5, "", MG1, "", MG2, "\checkmark", MG3, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
}
		
**** By country, institution and month ****

use $data/baseline.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(institution country month)
	drop if Nobs1<10
	egen id2 = group(institution country month)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen idci2 = .
	gen month2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg FE_`var'_current_a1 if id2==`i'
		capture replace b_FR_`var' = _b[_cons]    if _n == `i'
		capture replace sd_FR_`var' = _se[_cons]  if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 if _n == `i'
		capture sum month if id2==`i'
		capture replace month2 = r(mean) 			 if _n == `i'
		}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2 month2
	sort idci2
	sort idci2 month2
	rename idci2 idci
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $data/baseline.dta, clear
keep country institution idci idi country_num Foreign Multinational N_cty Emerging month
sort idci month
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num month)
merge 1:1 idci month using $temp_data/mg_FR, nogen
save $temp_data/mg_FR_bias_cty_inst_month, replace

use $temp_data/mg_FR_bias_cty_inst_month, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(idi#month country_num#month) vce(cluster country_num idi)
	regsave using "$temp_data/bias_mg_cty_inst_month_`var'_a.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "No", FE2, "Yes", FE3, "Yes", FE4, "Yes", MG1, "No", MG2, "No", MG3, "Yes")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(month country_num idi) vce(cluster country_num idi)
	regsave using "$temp_data/bias_mg_cty_inst_month_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(idi#month country_num#month) vce(cluster country_num idi)
	regsave using "$temp_data/bias_mg_cty_inst_month_`var'_a_baseline.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
}

*--------------------
**# Table Local bias
*--------------------


**************
* Robustness
**************

	* CPI
	******
	
	use $temp_data/bias_mg_cty_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_bias_mg_rob1.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/bias_mg_cty_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_2
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_bias_mg_rob1.dta, replace 

	
	* CPI
	******
	
	use $temp_data/bias_mg_cty_inst_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_3
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_bias_mg_rob2.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/bias_mg_cty_inst_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_4
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_bias_mg_rob2.dta, replace 
	
	* CPI
	******
	
	use $temp_data/bias_mg_cty_inst_month_cpi_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_5
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_bias_mg_rob3.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/bias_mg_cty_inst_month_gdp_a_rob, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_6
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i

	g n = _n
	
	save $temp_data/gdp_bias_mg_rob3.dta, replace 
	
	
	* CPI
	******
	
	use $temp_data/bias_mg_cty_inst_month_cpi_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_7
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_bias_mg_rob4.dta, replace 
	
	* GDP
	******
	
	use  $temp_data/bias_mg_cty_inst_month_gdp_a_baseline, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_8
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	g n = _n
	
	save $temp_data/gdp_bias_mg_rob4.dta, replace 
		
	
	* merge
	*********
	use $temp_data/cpi_bias_mg_rob1, clear
	merge 1:1 database n using $temp_data/gdp_bias_mg_rob1.dta, nogen
	merge 1:1 database n using $temp_data/cpi_bias_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/gdp_bias_mg_rob2.dta, nogen
	merge 1:1 database n using $temp_data/cpi_bias_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_bias_mg_rob3.dta, nogen	
	merge 1:1 database n using $temp_data/cpi_bias_mg_rob4.dta, nogen	
	merge 1:1 database n using $temp_data/gdp_bias_mg_rob4.dta, nogen	
	order var col_1 col_2 col_3 col_4 col_5 col_6 col_7 col_8
	
	save $temp_data/bias_mg_rob, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi2
	label var cpi2 "$ \text{CPI}_{t} $"
	rename col_2 gdp2
	label var gdp2 "$ \text{GDP}_{t} $"
	rename col_3 cpi3
	label var cpi3 "$ \text{CPI}_{t} $"
	rename col_4 gdp3
	label var gdp3 "$ \text{GDP}_{t} $"
	rename col_5 cpi4
	label var cpi4 "$ \text{CPI}_{t} $"
	rename col_6 gdp4
	label var gdp4 "$ \text{GDP}_{t} $"
	rename col_7 cpi5
	label var cpi5 "$ \text{CPI}_{t} $"
	rename col_8 gdp5
	label var gdp5 "$ \text{GDP}_{t} $"
	
	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country FE" if var == "FE1"	
	replace var = "Forecaster FE" if var == "FE2"
	replace var = "Month FE" if var == "FE3"	
	replace var = "Ctry $\times$ month FE" if var == "FE4"
	replace var = "For. $\times$ month FE" if var == "FE5"
	replace var = "MG by ctry and loc." if var=="MG1"
	replace var = "MG by ctry and for." if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	*order  var cpi2 gdp2
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/bias_mg_rob, replace
	
	
	
	
***********************
* Main table **********
***********************

use $temp_data/disag_mg, clear
set obs 15
replace var = "Average Locals" if _n==12
replace var = "Foreign" if _n==14
replace n = n + 4
replace n = 1 if _n==12
replace n = 2 if _n==13
replace n = 3 if _n==14
replace n = 4 if _n==15
replace n = -2 if n==5
replace n = -1 if n==6
sort n
save $temp_data/disag_mg_new, replace

use $temp_data/bgms_mg, clear
merge 1:1 _n using $temp_data/overextr_mg, nogen
merge 1:1 _n using $temp_data/consensus_mg, nogen
merge 1:1 _n using $temp_data/FE_mg, nogen
set obs 15
replace var = "Average" if _n==14
replace n = -1 if _n==15
replace n = -2 if _n==14
sort n
merge 1:1 _n using $temp_data/disag_mg_new, nogen
drop n

gen col_1=.
label var col_1 ""
gen col_2=.
label var col_2 ""
gen col_3=.
label var col_3 ""
gen col_4=.
label var col_4 ""

drop if _n>13

texsave var cpi1 gdp1 col_1 cpi2 gdp2 col_2 cpi3 gdp3 col_3 cpi4 gdp4 col_4 cpi5 gdp5 using "$tables/tab_main.tex", ///
	title(Behavioral Biases and Information Asymmetries) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C m{0.005\textwidth} C C m{0.005\textwidth} C C m{0.005\textwidth} C C m{0.005\textwidth} C C) location(H) replace label(tab:tab_main) headerlines("&\multicolumn{5}{c}{Behavioral biases}&& & &&\multicolumn{5}{c}{Information asymmetries} \tabularnewline \cline{2-6} \cline{11-15}\tabularnewline &\multicolumn{2}{c}{$\beta^{BGMS}$}&&\multicolumn{2}{c}{$\hat\rho$}&&\multicolumn{2}{c}{$\beta^{CG}$}&&\multicolumn{2}{c}{$\beta^{FE}$}&&\multicolumn{2}{c}{$\beta^{Dis}$} \tabularnewline \cline{2-3} \cline{5-6} \cline{8-9} \cline{11-12} \cline{14-15}\tabularnewline &{(1)}&{(2)}&&{(3)}&{(4)}&&{(5)}&{(6)}&&{(7)}&{(8)}&&{(9)}&{(10)}") footnote(		"\begin{minipage}{1.35\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) and (2) show the results of a regression of the $\beta^{BGMS}$ coefficients on the Foreign dummy, where the $\beta^{BGMS}$ are estimated using Equation \eqref{eq:BGMS} on different sub-groups of our sample. Columns (3) and (4) show the results of a regression of the perceived autocorrelation coefficients $\hat\rho$ on the Foreign dummy, where the $\hat\rho$ is estimated using Equation \eqref{eq:rhohat} on different sub-groups of our sample. Column (5) and (6) show the results of a regression of the $\beta^{CG}$ coefficients on the Foreign dummy, where the $\beta^{CG}$ are estimated using equation \eqref{eq:consensus} on different sub-groups of our sample. Columns (7) and (8) show the results of a regression of the $\beta^{FE}$ coefficients on the Foreign dummy, where the $\beta^{FE}$ are estimated using Equation \eqref{eq:pooledFE} on different sub-groups of our sample. In columns (1) to (8), \textit{Average locals} corresponds to the constant term (or average fixed effect). \textit{Foreign} corresponds to the coefficient of the Foreign dummy. Columns (9) and (10) show the results of a regression of the $\beta^{Dis}$ coefficients on the constant, where the $\beta^{Dis}$ are estimated using Equation \eqref{eq:disagreement} on different sub-groups of our sample. ``Average'' corresponds to the constant term. Standard errors are clustered at the country and forecaster levels in Columns (1) to (4). Standard errors are clustered at the country and forecaster levels in Columns (5) to (10). All observations are weighted by the inverse of the estimated standard error of the corresponding $\beta$. \end{tabnote} \end{minipage}  ") 



***********************
* Robustness tables ***
***********************

use $temp_data/BGMS_mg_rob, clear

texsave var cpi2-gdp5 using "$tables/tab_rob_BGMS.tex", ///
	title(Over-reaction - Aternative MG and Fixed Effects) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C C C C C) location(H) replace label(tab:tab_rob_BGMS) headerlines("&\multicolumn{8}{c}{$\beta^{BGMS}$} \tabularnewline \cline{2-9} &\multicolumn{6}{c}{}& \multicolumn{2}{c}{Baseline}  \tabularnewline \cline{8-9} &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)}&{(8)}") footnote(		"\begin{minipage}{1.35\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) to (8) show the results of a regression of the $\beta^{BGMS}$ coefficients on the Foreign dummy, where the $\beta^{BGMS}$ are estimated using Equation \eqref{eq:BGMS} with different fixed effects and mean-groups. The obervations are clustered at the country level in Columns (1) and (2), and at the country and forecaster levels in Columns (3) to (8). All observations are weighted by the inverse of the estimated standard error of the $\beta^{BGMS}$ coefficient. \end{tabnote} \end{minipage}  ") 


use $temp_data/overextr_mg_rob, clear

texsave var cpi2-gdp5 using "$tables/tab_rob_overextr.tex", ///
	title(Overextrapolation - Aternative MG and Fixed Effects) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C C C C C) location(H) replace label(tab:tab_rob_overextr) headerlines("&\multicolumn{8}{c}{$\hat\rho$} \tabularnewline \cline{2-9} &\multicolumn{6}{c}{}& \multicolumn{2}{c}{Baseline} \tabularnewline \cline{8-9} &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)}&{(8)}") footnote(		"\begin{minipage}{1.35\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) to (8) show the results of a regression of the perceived autocorrelation coefficients $\hat\rho$ on the Foreign dummy, where the $\hat\rho$ is estimated using Equation \eqref{eq:rhohat} with different fixed effects and mean-groups. The obervations are clustered at the country level in Columns (1)) and (2), and at the country and forecaster levels in Columns (3) to (8). All observations are weighted by the inverse of the estimated standard error of the $\hat\rho$ coefficient. \end{tabnote} \end{minipage}  ") 

use $temp_data/consensus_mg_rob, clear

texsave var cpi2-gdp4 using "$tables/tab_rob_consensus.tex", ///
	title(Consensus regressions - Aternative MG and Fixed Effects) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C C C) location(H) replace label(tab:tab_rob_consensus) headerlines("&\multicolumn{6}{c}{$\beta^{CG}$} \tabularnewline \cline{2-7} &\multicolumn{4}{c}{}& \multicolumn{2}{c}{Baseline} \tabularnewline \cline{6-7} &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}") footnote(		"\begin{minipage}{1.35\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) to (6) show the results of a regression of the $\beta^{CG}$ coefficients on the Foreign dummy, where the $\beta^{CG}$ are estimated using equation \eqref{eq:consensus} with different fixed effects and mean-groups. The obervations are clustered at the country level. All observations are weighted by the inverse of the estimated standard error of the $\beta^{CG}$ coefficient. \end{tabnote} \end{minipage}  ") 

use $temp_data/FE_mg_rob, clear

texsave var cpi2-gdp4 using "$tables/tab_rob_FE.tex", ///
	title(Fixed-effect regressions - Aternative MG and Fixed Effects) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C C C) location(H) replace label(tab:tab_rob_FE) headerlines("&\multicolumn{6}{c}{$\beta^{FE}$} \tabularnewline \cline{2-7} &\multicolumn{4}{c}{}& \multicolumn{2}{c}{Baseline} \tabularnewline \cline{6-7} &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}") footnote(		"\begin{minipage}{1.35\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) to (6) show the regression of the $\beta^{FE}$ coefficients on the Foreign dummy, where the $\beta^{FE}$ are estimated using Equation \eqref{eq:pooledFE} with different fixed effects and mean-groups. The obervations are clustered at the country level. All observations are weighted by the inverse of the estimated standard error of the $\beta^{FE}$ coefficient. \end{tabnote} \end{minipage}  ") 

use $temp_data/disag_mg_rob, clear

texsave var cpi2-gdp3 using "$tables/tab_rob_disag.tex", ///
	title(Disagreement regressions - Aternative MG and Fixed Effects) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C) location(H) replace label(tab:tab_rob_disag) headerlines("&\multicolumn{4}{c}{$\beta^{Dis}$} \tabularnewline \cline{2-5} &\multicolumn{2}{c}{}& \multicolumn{2}{c}{Baseline} \tabularnewline \cline{4-5} &{(1)}&{(2)}&{(3)}&{(4)}") footnote(		"\begin{minipage}{1.35\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) to (4) show the regression of the $\beta^{Dis}$ coefficients on the constant, where the $\beta^{Dis}$ are estimated using Equation \eqref{eq:disagreement} with different fixed effects and mean-groups. The obervations are clustered at the country level. All observations are weighted by the inverse of the estimated standard error of the $\beta^{Dis}$ coefficient. \end{tabnote} \end{minipage}  ") 


use $temp_data/past_consensus_mg_rob, clear

texsave var cpi2-gdp5 using "$tables/tab_rob_past_consensus.tex", ///
	title(Past consensus - Aternative MG and Fixed Effects) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C C C C C) location(H) replace label(tab:tab_rob_past_consensus) headerlines("&\multicolumn{8}{c}{$\beta^{PastConsensus}$} \tabularnewline \cline{2-9} &\multicolumn{6}{c}{}& \multicolumn{2}{c}{Baseline}  \tabularnewline \cline{8-9} &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)}&{(8)}") footnote(		"\begin{minipage}{1.35\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) to (8) show the results of a regression of the $\beta^{PastConsensus}$ coefficients on the Foreign dummy, where the $\beta^{PastConsensus}$ are estimated using $ Error_{ijt}^m=\beta^{PastConsensus,m}_{ij}E^{m-1}_{jt} (x_{jt})+\delta_{ij}^m+\lambda_{ijt}^m$, with different fixed effects and mean-groups. The obervations are clustered at the country level in Columns (1) and (2), and at the country and forecaster levels in Columns (3) to (8). All observations are weighted by the inverse of the estimated standard error of the $\beta^{PastConsensus}$ coefficient. \end{tabnote} \end{minipage}") 

use $temp_data/vintage_mg_rob, clear

texsave var cpi2-gdp5 using "$tables/tab_rob_last_vintage.tex", ///
	title(Last Vintage - Aternative MG and Fixed Effects) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C C C C C) location(H) replace label(tab:tab_rob_last_vintage) headerlines("&\multicolumn{8}{c}{$\beta^{LastVintage}$} \tabularnewline \cline{2-9} &\multicolumn{6}{c}{}& \multicolumn{2}{c}{Baseline}  \tabularnewline \cline{8-9} &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)}&{(8)}") footnote(		"\begin{minipage}{1.35\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) to (8) show the results of a regression of the $\beta^{LastVintage}$ coefficients on the Foreign dummy, where the $\beta^{LastVintage}$ are estimated using $ Error_{ijt}^m=\beta^{LastVintage,m}_{ij}x_{jt-1}+\delta_{ij}^m+\lambda_{ijt}^m$, where $\frac{1}{N(j)}\sum_{i\in \textit{S}(j)}E^m_{ijt}(x_{jt})$ is the average expectation across all forecasters, with different fixed effects and mean-groups. The obervations are clustered at the country level in Columns (1) and (2), and at the country and forecaster levels in Columns (3) to (8). All observations are weighted by the inverse of the estimated standard error of the $\beta^{LastVintage}$ coefficient. \end{tabnote} \end{minipage}")

use $temp_data/local_mg_rob, clear

texsave var cpi2-gdp5 using "$tables/tab_rob_local.tex", ///
	title(Local Forecast - Aternative MG and Fixed Effects) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C C C C C) location(H) replace label(tab:tab_rob_local) headerlines("&\multicolumn{8}{c}{$\beta^{LastVintage}$} \tabularnewline \cline{2-9} &\multicolumn{6}{c}{}& \multicolumn{2}{c}{Baseline}  \tabularnewline \cline{8-9} &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)}&{(8)}") footnote(		"\begin{minipage}{1.35\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) to (8) show the results of a regression of the $\beta^{LocalForecast}$ coefficients on the Foreign dummy, where the $\beta^{LocalForecast}$ are estimated using $ Error_{ijt}^m=\beta^{LocalForecast,m}_{ij}Revision_{it}+\delta_{ij}^m+\lambda_{ijt}^m$, where $Revision_{it}$ is the forecast revision of forecaster $i$ about the country where its headquarters are located, with different fixed effects and mean-groups. The obervations are clustered at the country level in Columns (1) and (2), and at the country and forecaster levels in Columns (3) to (8). All observations are weighted by the inverse of the estimated standard error of the $\beta^{LocalForecast}$ coefficient. \end{tabnote} \end{minipage}")

use $temp_data/bias_mg_rob, clear

texsave var cpi2-gdp5 using "$tables/tab_rob_bias.tex", ///
	title(Systematic error - Aternative MG and Fixed Effects) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C C C C C) location(H) replace label(tab:tab_rob_bias) headerlines("&\multicolumn{8}{c}{$\beta^{Systematic}$} \tabularnewline \cline{2-9} &\multicolumn{6}{c}{}& \multicolumn{2}{c}{Baseline}  \tabularnewline \cline{8-9} &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)}&{(8)}") footnote(		"\begin{minipage}{1.35\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) to (8) show the results of a regression of the $\beta^{Systematic}$ coefficients on the Foreign dummy, where the $\beta^{Systematic}$ are estimated using $ Error_{ijt}^m=\beta^{Systematic,m}_{ij}+\lambda_{ijt}^m$, with different fixed effects and mean-groups. The obervations are clustered at the country level in Columns (1) and (2), and at the country and forecaster levels in Columns (3) to (8). All observations are weighted by the inverse of the estimated standard error of the $\beta^{Systematic}$ coefficient. \end{tabnote} \end{minipage}")


***********************
* Table for R3 ********
***********************



******************************************************
** National forecasters only (for R3)
******************************************************

*** FE regressions by country and month ***

use $data/baseline.dta, clear


local varlist gdp cpi
		
* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(country month Foreign)
	egen Nobs2 = count(FR_`var'), by(country month Foreign)
	drop if Nobs1<10 | Nobs2<10
	gen country_num2 = .
	gen Foreign2 = .
	gen month2 = .
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	forval i = 1(1)51 {
		forval k=1(1)12 {
			capture reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & month==`k' & Foreign==0 & Multinational==0, absorb(datem idi)
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+102*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+102*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == `i'+102*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == `i'+102*(`k'-1)
			capture replace Foreign2 = 0		 		if _n == `i'+102*(`k'-1)
			capture replace month2 = `k'		 		if _n == `i'+102*(`k'-1)
			capture reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & month==`k' & Foreign==1 & Multinational==0, absorb(datem idi)
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+51+102*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+51+102*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == `i'+51+102*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == `i'+51+102*(`k'-1)
			capture replace Foreign2 = 1		 		if _n == `i'+51+102*(`k'-1)
			capture replace month2 = `k'		 		if _n == `i'+51+102*(`k'-1)
		}
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2 month2
	sort country_num2 Foreign2 month2
	rename country_num2 country_num
	rename Foreign2 Foreign
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

* Results
use $data/baseline.dta, clear

keep country country_num Emerging Foreign month
sort country_num Foreign month
collapse Emerging , by(country country_num Foreign month)
merge 1:1 country_num Foreign month using $temp_data/mg_FR, nogen
save $temp_data/mg_FE_reg_cty_month, replace

use $temp_data/mg_FE_reg_cty_month, clear

gen weight_gdp=1/sd_FR_gdp
gen weight_cpi=1/sd_FR_cpi

foreach var in cpi gdp {
	
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'] if weight_`var'<1000000, absorb(month#country_num) vce(cluster country_num)
	regsave using "$temp_data/FE_reg_mg_cty_month_`var'_a_r3.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", MG1, "", MG2, "\checkmark", MG3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
}



*****************************
** Save results in table

* CPI
******

* all
use $temp_data/FE_reg_mg_cty_month_cpi_a_r3, clear
g database = 1
replace database = 1 if database == .
rename col_1 col_1

g i = _n
replace i = 0 if var == "_cons_coef"
replace i = 0.5 if var == "_cons_stderr"

sort i

drop i

g n = _n

save $temp_data/cpi_FE_mg_r3.dta, replace 

* GDP
******

* all
use  $temp_data/FE_reg_mg_cty_month_gdp_a_r3, clear
g database = 1
replace database = 1 if database == .
rename col_1 col_1

g i = _n
replace i = 0 if var == "_cons_coef"
replace i = 0.5 if var == "_cons_stderr"

sort database i
	
drop i

*g n = _n
rename col_1 col_2

g n = _n

drop var

* merge with CPI
*********
merge 1:1 database n using $temp_data/cpi_FE_mg_r3.dta
drop _merge

order var col_1 col_2 

save $temp_data/FE_mg_r3, replace

drop database 


replace var = "Average Locals" if var == "_cons_coef"
replace var = "" if var == "_cons_stderr"
replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
replace var = "" if var == "Foreign_stderr"
	
rename col_1 cpi4
label var cpi4 "$ \text{CPI}_{t} $"
rename col_2 gdp4
label var gdp4 "$ \text{GDP}_{t} $"

* clean the data
drop if var == "restr" | var == "_id" 

replace var = "$ R^2 $" if var == "r2"

	
replace var = "Country $\times$ month FE" if var == "FE1"	
replace var = "Forecaster $\times$ month FE" if var == "FE2"
replace var = "MG by ctry and month" if var=="MG1"
replace var = "MG by ctry, loc., and month" if var=="MG2"
replace var = "MG by ctry, for., and month" if var=="MG3"
drop if var == "rhs"

drop n

order  var cpi4 gdp4

label var var "Coefficient"

gen n=_n

save $temp_data/FE_mg_r3, replace




******** Disagreement by country and month *******

use $data/baseline.dta, clear

local varlist gdp cpi
		
* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	collapse FR_`var' `var'_current_a1 `var'_future dFR_`var'_locfor d`var'_locfor if Multinational==0, by(country_num datem year month Foreign)
	gen `var'_future_loc = `var'_future if Foreign==0
	gen `var'_future_for = `var'_future if Foreign==1
	collapse FR_`var' `var'_current_a1 `var'_future dFR_`var'_locfor d`var'_locfor `var'_future_loc `var'_future_for, by(country_num datem year month)	
	egen Nobs1 = count(d`var'_locfor), by(country month)
	drop if Nobs1<10
	xtset country_num datem
	gen country_num2 = .
	gen month2 = .
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	forval i = 1(1)51 {
		forval k=1(1)12 {
			capture qui reghdfe d`var'_locfor l12.(`var'_future_loc `var'_future_for) `var'_current_a1 FR_`var' if country_num==`i' & month==`k', noabsorb vce(robust)			
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+51*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+51*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == `i'+51*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == `i'+51*(`k'-1)
			capture replace month2 = `k'		 		if _n == `i'+51*(`k'-1)
		}
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 month2
	sort country_num2 month2
	rename country_num2 country_num
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

* Results
use $data/baseline.dta, clear
keep country country_num Emerging month
sort country_num month
collapse Emerging , by(country country_num month)
merge 1:1 country_num month using $temp_data/mg_FR, nogen
save $temp_data/disag_mg_cty_month, replace

use $temp_data/disag_mg_cty_month, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	reghdfe b_FR_`var' [aweight=weight_`var'] , noabsorb vce(cluster country_num)
		regsave using "$temp_data/disag_mg_cty_month_`var'_a_r3.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", MG1, "\checkmark", MG2, "", MG3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
			
}

*****************************
** Save results in table

* CPI
******

* all
use $temp_data/disag_mg_cty_month_cpi_a_r3, clear
g database = 1
replace database = 1 if database == .
rename col_1 col_1

g i = _n
replace i = 0 if var == "_cons_coef"
replace i = 0.5 if var == "_cons_stderr"

sort i

drop i

g n = _n

save $temp_data/cpi_disag_mg_r3.dta, replace 

* GDP
******

* all
use  $temp_data/disag_mg_cty_month_gdp_a_r3, clear
g database = 1
replace database = 1 if database == .
rename col_1 col_1

g i = _n
replace i = 0 if var == "_cons_coef"
replace i = 0.5 if var == "_cons_stderr"

sort database i
	
drop i

*g n = _n
rename col_1 col_2

g n = _n

drop var

* merge with CPI
*********
merge 1:1 database n using $temp_data/cpi_disag_mg_r3.dta
drop _merge

order var col_1 col_2 

save $temp_data/disag_mg_r3, replace


drop database 


replace var = "Average" if var == "_cons_coef"
replace var = "" if var == "_cons_stderr"
	
rename col_1 cpi5
label var cpi5 "$ \text{CPI}_{t} $"
rename col_2 gdp5
label var gdp5 "$ \text{GDP}_{t} $"

* clean the data
drop if var == "restr" | var == "_id" 

replace var = "$ R^2 $" if var == "r2"

	
replace var = "Country $\times$ month FE" if var == "FE1"	
replace var = "Forecaster $\times$ month FE" if var == "FE2"
replace var = "MG by ctry and month" if var=="MG1"
replace var = "MG by ctry, loc., and month" if var=="MG2"
replace var = "MG by ctry, for., and month" if var=="MG3"
drop if var == "rhs"

drop n

order  var cpi5 gdp5

label var var "Coefficient"

gen n=_n

save $temp_data/disag_mg_r3, replace
	
	
	

	
	
use $temp_data/disag_mg_r3, clear
set obs 15
replace var = "Average Locals" if _n==12
replace var = "Foreign" if _n==14
replace n = n + 4
replace n = 1 if _n==12
replace n = 2 if _n==13
replace n = 3 if _n==14
replace n = 4 if _n==15
replace n = -2 if n==5
replace n = -1 if n==6
sort n
save $temp_data/disag_mg_new_r3, replace




use $temp_data/FE_mg_r3, clear
set obs 15
replace var = "Average" if _n==14
replace n = -1 if _n==15
replace n = -2 if _n==14
sort n
merge 1:1 _n using $temp_data/disag_mg_new_r3, nogen
drop n

gen col_1=.
label var col_1 ""

drop if _n>13

texsave var cpi4 gdp4 col_1 cpi5 gdp5 using "$tables/tab_r3.tex", ///
	title(Information Asymmetries - Non-multinationals only) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C m{0.005\textwidth} C C) location(H) replace label(tab:tab_r3) ///
headerlines("&\multicolumn{2}{c}{$\beta^{FE}$}&&\multicolumn{2}{c}{$\beta^{Dis}$} \tabularnewline \cline{2-3} \cline{5-6}\tabularnewline &{(1)}&{(2)}&&{(3)}&{(4)}") ///
footnote("\begin{minipage}{1.35\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) and (2) show the results of a regression of the $\beta^{FE}$ coefficients on the Foreign dummy, where the $\beta^{FE}$ are estimated using Equation \eqref{eq:pooledFE} on different sub-groups of our sample. \textit{Average locals} corresponds to the constant term (or average fixed effect). \textit{Foreign} corresponds to the coefficient of the Foreign dummy. Columns (3) and (4) show the results of a regression of the $\beta^{Dis}$ coefficients on the constant, where the $\beta^{Dis}$ are estimated using Equation \eqref{eq:disagreement} on different sub-groups of our sample. \textit{Average}  corresponds to the constant term. Standard errors are clustered at the country and forecaster levels in Columns (1) to (4). All observations are weighted by the inverse of the estimated standard error of the corresponding $\beta$. The sample is restricted to forecasts produced by non-multinational firms \end{tabnote} \end{minipage}  ") 






********************************************************************************
********************************************************************************
* 				ROBUSTNESS CHECKS SUMMARY SECTION 4
********************************************************************************
********************************************************************************



********************************************************************************
* DATA PREP

********************************************************************************
* 1. CREATE SAME DATASET, BUT USE ALTERNATIVE VINTAGE SERIES:
********************************************************************************

use "$datace_imf/data_final_newVintage_3.dta", clear

sort idci datem
xtset idci datem

drop if year < 1998
drop if year > 2019

local varlist gdp cpi
local horlist current future
foreach var in `varlist' {
	foreach hor in `horlist' {
		if "`hor'"=="current" {
		    rename vintage_`var'_current_aprtp2 `var'_current_a1 // PART THAT NEEDS TO BE ADAPTED TO CHANGE VINTAGE SERIES
			}
		if "`hor'"=="future" {
		    rename vintage_`var'_future_aprtp3 `var'_future_a1 // PART THAT NEEDS TO BE ADAPTED TO CHANGE VINTAGE SERIES
			}
			
		
		* vintage untrimmed
		gen `var'_`hor'_a1_ut = `var'_`hor'_a1
		* forecasts untrimmed
		gen `var'_`hor'_ut = `var'_`hor'
		* quantiles over emerging countries
		egen `var'_`hor'_p25 = pctile(`var'_`hor'), p(25) by(Emerging)
		egen `var'_`hor'_p75 = pctile(`var'_`hor'), p(75) by(Emerging)
		egen `var'_`hor'_p50 = pctile(`var'_`hor'), p(50) by(Emerging)
		* quantiles over country and datem
		egen `var'_`hor'_cd_p25 = pctile(`var'_`hor'), p(25) by(country datem)
		egen `var'_`hor'_cd_p75 = pctile(`var'_`hor'), p(75) by(country datem)
		egen `var'_`hor'_cd_p50 = pctile(`var'_`hor'), p(50) by(country datem)
		
		* remove if forecasts are further away than 5*IQR calculated over emerging countries and by country datem.
		replace `var'_`hor' = . if (`var'_`hor'>`var'_`hor'_p50 + 5*(`var'_`hor'_p75-`var'_`hor'_p25) | `var'_`hor'<`var'_`hor'_p50 - 5*(`var'_`hor'_p75-`var'_`hor'_p25)) | (`var'_`hor'>`var'_`hor'_cd_p50 + 5*(`var'_`hor'_cd_p75-`var'_`hor'_cd_p25) | `var'_`hor'<`var'_`hor'_cd_p50 - 5*(`var'_`hor'_cd_p75-`var'_`hor'_cd_p25))
		egen `var'_`hor'_a1_p25 = pctile(`var'_`hor'_a1), p(25) by(Emerging)
		egen `var'_`hor'_a1_p75 = pctile(`var'_`hor'_a1), p(75) by(Emerging)
		egen `var'_`hor'_a1_p50 = pctile(`var'_`hor'_a1), p(50) by(Emerging)
		replace `var'_`hor'_a1 = . if (`var'_`hor'_a1>`var'_`hor'_a1_p50 + 5*(`var'_`hor'_a1_p75-`var'_`hor'_a1_p25) | `var'_`hor'_a1<`var'_`hor'_a1_p50 - 5*(`var'_`hor'_a1_p75-`var'_`hor'_a1_p25))
		replace `var'_`hor'=. if `var'_`hor'_a1==.
		}
}





* Revisions
local varlist gdp cpi
local horlist current future
foreach var in `varlist' {
	replace FR_`var' = `var'_current - l12.`var'_future
	label var FR_`var' "Revision Y-o-Y"
	replace FR_`var'_current = `var'_current - l1.`var'_current if month!=1
	replace FR_`var'_current = `var'_current - l1.`var'_future if month==1
	label var FR_`var'_current  "Revision current `var' M-o-M"
	replace FR_`var'_future = `var'_future - l1.`var'_future if month!=1
	label var FR_`var'_future  "Revision future `var' M-o-M"
	foreach hor in `horlist' {
		replace FE_`var'_`hor'_a1 = `var'_`hor'_a1 - `var'_`hor'
		replace labs_FE_`var'_`hor'_a1 = log(abs(FE_`var'_`hor'_a1))
		replace labs_FE_`var'_`hor'_a1 = max(-6.9,labs_FE_`var'_`hor'_a1) if labs_FE_`var'_`hor'_a1!=.
		replace labs_FE_`var'_`hor'_a1 = -6.9 if FE_`var'_`hor'_a1==0
	}
}



foreach var in gdp cpi {
	egen FR_`var'_jt = mean(FR_`var'), by(country datem)
	label var FR_`var'_jt "Mean Revision by country-date"
	
	egen FR_`var'_local = mean(FR_`var') if Foreign==0, by(country datem)
	label var FR_`var'_local "Mean Revision by country-date if Local"
	
	egen FR_`var'_local2 = max(FR_`var'_local), by(country datem)
	label var FR_`var'_local2 "Maximum Revision by country-date if Local"
	
	gen dFR_`var'_local = FR_`var'_local2 - FR_`var'_jt
	label var dFR_`var'_local "Maximum Revision by country-date and if local minus mean revision by country-date"
	
	egen FR_`var'_foreign = mean(FR_`var') if Foreign==1, by(country datem)
	label var FR_`var'_foreign  "Mean Revision by country-date if Foreign"
	
	egen FR_`var'_foreign2 = max(FR_`var'_foreign), by(country datem)
	label var FR_`var'_foreign2 "Maximum Revision by country-date if Local"
	
	gen dFR_`var'_foreign = FR_`var'_foreign2 - FR_`var'_jt
	label var dFR_`var'_local "Maximum Revision by country-date and if foreign minus mean revision by country-date"
	
	gen dFR_`var'_locfor = FR_`var'_local2 - FR_`var'_foreign2
	label var dFR_`var'_local "Difference of max forecast revision by country-date locals minus those of foreigns"
	
	egen `var'_local = mean(`var'_current) if Foreign==0, by(country datem)
	label var `var'_local "Mean of `var'_current by locals, country date"
	
	egen `var'_local2 = max(`var'_local), by(country datem)
	label var `var'_local2  "Maximum of mean of `var' current by locals, country date"
	
	egen `var'_foreign = mean(`var'_current) if Foreign==1, by(country datem)
	label var `var'_local "Mean of `var'_current by foreigns, country date"
	
	egen `var'_foreign2 = max(`var'_foreign), by(country datem)
	label var `var'_foreign2  "Maximum of mean of `var' current by foreigns, country date"
	
	gen d`var'_locfor = `var'_local2 - `var'_foreign2
	label var `var'_foreign2  "Difference of max of mean of `var'_current between local and foreigns, by countyr-date"
	
	
	
}

sort institution
by institution: egen Loc = max(Local)
by institution: egen For = max(Foreign)
gen LocFor = Loc*For

gen LocalHQ = 1-ForeignHQ
sort institution
by institution: egen LocHQ = max(LocalHQ)
by institution: egen ForHQ = max(ForeignHQ)
gen LocForHQ = LocHQ*ForHQ

save $dataout/rob_a2.dta, replace



********************************************************************************
* 2. CREATE SAME DATASET, BUT ONLY USE LOCFOR == 1:
********************************************************************************

use "$datace_imf/data_final_newVintage_3.dta", clear


sort idci datem
xtset idci datem

drop if year < 1998
drop if year > 2019

local varlist gdp cpi
local horlist current future
foreach var in `varlist' {
	foreach hor in `horlist' {
		if "`hor'"=="current" {
		    rename vintage_`var'_current_aprtp1 `var'_current_a1
			}
		if "`hor'"=="future" {
		    rename vintage_`var'_future_aprtp2 `var'_future_a1
			}
			
		* vintage untrimmed
		gen `var'_`hor'_a1_ut = `var'_`hor'_a1
		* forecasts untrimmed
		gen `var'_`hor'_ut = `var'_`hor'
		* quantiles over emerging countries
		egen `var'_`hor'_p25 = pctile(`var'_`hor'), p(25) by(Emerging)
		egen `var'_`hor'_p75 = pctile(`var'_`hor'), p(75) by(Emerging)
		egen `var'_`hor'_p50 = pctile(`var'_`hor'), p(50) by(Emerging)
		* quantiles over country and datem
		egen `var'_`hor'_cd_p25 = pctile(`var'_`hor'), p(25) by(country datem)
		egen `var'_`hor'_cd_p75 = pctile(`var'_`hor'), p(75) by(country datem)
		egen `var'_`hor'_cd_p50 = pctile(`var'_`hor'), p(50) by(country datem)
		
		* remove if forecasts are further away than 5*IQR calculated over emerging countries and by country datem.
		replace `var'_`hor' = . if (`var'_`hor'>`var'_`hor'_p50 + 5*(`var'_`hor'_p75-`var'_`hor'_p25) | `var'_`hor'<`var'_`hor'_p50 - 5*(`var'_`hor'_p75-`var'_`hor'_p25)) | (`var'_`hor'>`var'_`hor'_cd_p50 + 5*(`var'_`hor'_cd_p75-`var'_`hor'_cd_p25) | `var'_`hor'<`var'_`hor'_cd_p50 - 5*(`var'_`hor'_cd_p75-`var'_`hor'_cd_p25))
		egen `var'_`hor'_a1_p25 = pctile(`var'_`hor'_a1), p(25) by(Emerging)
		egen `var'_`hor'_a1_p75 = pctile(`var'_`hor'_a1), p(75) by(Emerging)
		egen `var'_`hor'_a1_p50 = pctile(`var'_`hor'_a1), p(50) by(Emerging)
		replace `var'_`hor'_a1 = . if (`var'_`hor'_a1>`var'_`hor'_a1_p50 + 5*(`var'_`hor'_a1_p75-`var'_`hor'_a1_p25) | `var'_`hor'_a1<`var'_`hor'_a1_p50 - 5*(`var'_`hor'_a1_p75-`var'_`hor'_a1_p25))
		replace `var'_`hor'=. if `var'_`hor'_a1==.
		}
}



*** loss due to trimming:

* - 3.7
su cpi_current
su cpi_current_ut

* - 1.2
su gdp_current
su gdp_current_ut

* -9.7
su cpi_future
su cpi_future_ut

* - 7.15
su gdp_future
su gdp_future_ut
****




* Revisions
local varlist gdp cpi
local horlist current future
foreach var in `varlist' {
	replace FR_`var' = `var'_current - l12.`var'_future
	label var FR_`var' "Revision Y-o-Y"
	replace FR_`var'_current = `var'_current - l1.`var'_current if month!=1
	replace FR_`var'_current = `var'_current - l1.`var'_future if month==1
	label var FR_`var'_current  "Revision current `var' M-o-M"
	replace FR_`var'_future = `var'_future - l1.`var'_future if month!=1
	label var FR_`var'_future  "Revision future `var' M-o-M"
	foreach hor in `horlist' {
		replace FE_`var'_`hor'_a1 = `var'_`hor'_a1 - `var'_`hor'
		replace labs_FE_`var'_`hor'_a1 = log(abs(FE_`var'_`hor'_a1))
		replace labs_FE_`var'_`hor'_a1 = max(-6.9,labs_FE_`var'_`hor'_a1) if labs_FE_`var'_`hor'_a1!=.
		replace labs_FE_`var'_`hor'_a1 = -6.9 if FE_`var'_`hor'_a1==0
	}
}



foreach var in gdp cpi {
	egen FR_`var'_jt = mean(FR_`var'), by(country datem)
	label var FR_`var'_jt "Mean Revision by country-date"
	
	egen FR_`var'_local = mean(FR_`var') if Foreign==0, by(country datem)
	label var FR_`var'_local "Mean Revision by country-date if Local"
	
	egen FR_`var'_local2 = max(FR_`var'_local), by(country datem)
	label var FR_`var'_local2 "Maximum Revision by country-date if Local"
	
	gen dFR_`var'_local = FR_`var'_local2 - FR_`var'_jt
	label var dFR_`var'_local "Maximum Revision by country-date and if local minus mean revision by country-date"
	
	egen FR_`var'_foreign = mean(FR_`var') if Foreign==1, by(country datem)
	label var FR_`var'_foreign  "Mean Revision by country-date if Foreign"
	
	egen FR_`var'_foreign2 = max(FR_`var'_foreign), by(country datem)
	label var FR_`var'_foreign2 "Maximum Revision by country-date if Local"
	
	gen dFR_`var'_foreign = FR_`var'_foreign2 - FR_`var'_jt
	label var dFR_`var'_local "Maximum Revision by country-date and if foreign minus mean revision by country-date"
	
	gen dFR_`var'_locfor = FR_`var'_local2 - FR_`var'_foreign2
	label var dFR_`var'_local "Difference of max forecast revision by country-date locals minus those of foreigns"
	
	egen `var'_local = mean(`var'_current) if Foreign==0, by(country datem)
	label var `var'_local "Mean of `var'_current by locals, country date"
	
	egen `var'_local2 = max(`var'_local), by(country datem)
	label var `var'_local2  "Maximum of mean of `var' current by locals, country date"
	
	egen `var'_foreign = mean(`var'_current) if Foreign==1, by(country datem)
	label var `var'_local "Mean of `var'_current by foreigns, country date"
	
	egen `var'_foreign2 = max(`var'_foreign), by(country datem)
	label var `var'_foreign2  "Maximum of mean of `var' current by foreigns, country date"
	
	gen d`var'_locfor = `var'_local2 - `var'_foreign2
	label var `var'_foreign2  "Difference of max of mean of `var'_current between local and foreigns, by countyr-date"
	
	
	
}

sort institution
by institution: egen Loc = max(Local)
by institution: egen For = max(Foreign)
gen LocFor = Loc*For

gen LocalHQ = 1-ForeignHQ
sort institution
by institution: egen LocHQ = max(LocalHQ)
by institution: egen ForHQ = max(ForeignHQ)
gen LocForHQ = LocHQ*ForHQ

keep if LocFor == 1

save $dataout/rob_locfor1, replace

 
********************************************************************************
* 3. ALTERNATIVE TRIMMING
********************************************************************************

use "$datace_imf/data_final_newVintage_3.dta", clear


sort idci datem
xtset idci datem

drop if year < 1998
drop if year > 2019

local varlist gdp cpi
local horlist current future
foreach var in `varlist' {
	foreach hor in `horlist' {
		if "`hor'"=="current" {
		    rename vintage_`var'_current_aprtp1 `var'_current_a1
			}
		if "`hor'"=="future" {
		    rename vintage_`var'_future_aprtp2 `var'_future_a1
			}
		
		* vintage untrimmed
		gen `var'_`hor'_a1_ut = `var'_`hor'_a1
		* forecasts untrimmed
		gen `var'_`hor'_ut = `var'_`hor'
		* quantiles over emerging countries
		egen `var'_`hor'_p25 = pctile(`var'_`hor'), p(25) by(Emerging)
		egen `var'_`hor'_p75 = pctile(`var'_`hor'), p(75) by(Emerging)
		egen `var'_`hor'_p50 = pctile(`var'_`hor'), p(50) by(Emerging)
		* quantiles over country and datem
		egen `var'_`hor'_cd_p25 = pctile(`var'_`hor'), p(25) by(country datem)
		egen `var'_`hor'_cd_p75 = pctile(`var'_`hor'), p(75) by(country datem)
		egen `var'_`hor'_cd_p50 = pctile(`var'_`hor'), p(50) by(country datem)
		
		* remove if forecasts are further away than 5*IQR calculated over emerging countries and by country datem.
		replace `var'_`hor' = . if (`var'_`hor'>`var'_`hor'_p50 + 6*(`var'_`hor'_p75-`var'_`hor'_p25) | `var'_`hor'<`var'_`hor'_p50 - 6*(`var'_`hor'_p75-`var'_`hor'_p25)) | (`var'_`hor'>`var'_`hor'_cd_p50 + 6*(`var'_`hor'_cd_p75-`var'_`hor'_cd_p25) | `var'_`hor'<`var'_`hor'_cd_p50 - 6*(`var'_`hor'_cd_p75-`var'_`hor'_cd_p25))
		egen `var'_`hor'_a1_p25 = pctile(`var'_`hor'_a1), p(25) by(Emerging)
		egen `var'_`hor'_a1_p75 = pctile(`var'_`hor'_a1), p(75) by(Emerging)
		egen `var'_`hor'_a1_p50 = pctile(`var'_`hor'_a1), p(50) by(Emerging)
		replace `var'_`hor'_a1 = . if (`var'_`hor'_a1>`var'_`hor'_a1_p50 + 6*(`var'_`hor'_a1_p75-`var'_`hor'_a1_p25) | `var'_`hor'_a1<`var'_`hor'_a1_p50 - 6*(`var'_`hor'_a1_p75-`var'_`hor'_a1_p25))
		replace `var'_`hor'=. if `var'_`hor'_a1==.
		}
}



*** loss due to trimming:

* - 3.7
su cpi_current
su cpi_current_ut

* - 1.2
su gdp_current
su gdp_current_ut

* -9.7
su cpi_future
su cpi_future_ut

* - 7.15
su gdp_future
su gdp_future_ut
****




* Revisions
local varlist gdp cpi
local horlist current future
foreach var in `varlist' {
	replace FR_`var' = `var'_current - l12.`var'_future
	label var FR_`var' "Revision Y-o-Y"
	replace FR_`var'_current = `var'_current - l1.`var'_current if month!=1
	replace FR_`var'_current = `var'_current - l1.`var'_future if month==1
	label var FR_`var'_current  "Revision current `var' M-o-M"
	replace FR_`var'_future = `var'_future - l1.`var'_future if month!=1
	label var FR_`var'_future  "Revision future `var' M-o-M"
	foreach hor in `horlist' {
		replace FE_`var'_`hor'_a1 = `var'_`hor'_a1 - `var'_`hor'
		replace labs_FE_`var'_`hor'_a1 = log(abs(FE_`var'_`hor'_a1))
		replace labs_FE_`var'_`hor'_a1 = max(-6.9,labs_FE_`var'_`hor'_a1) if labs_FE_`var'_`hor'_a1!=.
		replace labs_FE_`var'_`hor'_a1 = -6.9 if FE_`var'_`hor'_a1==0
	}
}



foreach var in gdp cpi {
	egen FR_`var'_jt = mean(FR_`var'), by(country datem)
	label var FR_`var'_jt "Mean Revision by country-date"
	
	egen FR_`var'_local = mean(FR_`var') if Foreign==0, by(country datem)
	label var FR_`var'_local "Mean Revision by country-date if Local"
	
	egen FR_`var'_local2 = max(FR_`var'_local), by(country datem)
	label var FR_`var'_local2 "Maximum Revision by country-date if Local"
	
	gen dFR_`var'_local = FR_`var'_local2 - FR_`var'_jt
	label var dFR_`var'_local "Maximum Revision by country-date and if local minus mean revision by country-date"
	
	egen FR_`var'_foreign = mean(FR_`var') if Foreign==1, by(country datem)
	label var FR_`var'_foreign  "Mean Revision by country-date if Foreign"
	
	egen FR_`var'_foreign2 = max(FR_`var'_foreign), by(country datem)
	label var FR_`var'_foreign2 "Maximum Revision by country-date if Local"
	
	gen dFR_`var'_foreign = FR_`var'_foreign2 - FR_`var'_jt
	label var dFR_`var'_local "Maximum Revision by country-date and if foreign minus mean revision by country-date"
	
	gen dFR_`var'_locfor = FR_`var'_local2 - FR_`var'_foreign2
	label var dFR_`var'_local "Difference of max forecast revision by country-date locals minus those of foreigns"
	
	egen `var'_local = mean(`var'_current) if Foreign==0, by(country datem)
	label var `var'_local "Mean of `var'_current by locals, country date"
	
	egen `var'_local2 = max(`var'_local), by(country datem)
	label var `var'_local2  "Maximum of mean of `var' current by locals, country date"
	
	egen `var'_foreign = mean(`var'_current) if Foreign==1, by(country datem)
	label var `var'_local "Mean of `var'_current by foreigns, country date"
	
	egen `var'_foreign2 = max(`var'_foreign), by(country datem)
	label var `var'_foreign2  "Maximum of mean of `var' current by foreigns, country date"
	
	gen d`var'_locfor = `var'_local2 - `var'_foreign2
	label var `var'_foreign2  "Difference of max of mean of `var'_current between local and foreigns, by countyr-date"
	
	
	
}

sort institution
by institution: egen Loc = max(Local)
by institution: egen For = max(Foreign)
gen LocFor = Loc*For

gen LocalHQ = 1-ForeignHQ
sort institution
by institution: egen LocHQ = max(LocalHQ)
by institution: egen ForHQ = max(ForeignHQ)
gen LocForHQ = LocHQ*ForHQ


save $dataout/rob_trimming, replace

********************************************************************************
* 4. HEADQUARTER ONLY AS FOREIGN DEFINITION 
********************************************************************************


use $dataout/baseline.dta, clear


cap drop Foreign
g Foreign = country != Headquarters

gen LocalSub = (ForeignHQ==1)*(Foreign==0)

save $dataout/rob_headquarter.dta, replace



********************************************************************************
* 5. KEEP ONLY FORECASTS THAT UPDATED
********************************************************************************



use $dataout/baseline.dta, clear

sort idci datem
xtset idci datem
replace labs_FE_cpi_current_a1 = . if l.cpi_current == cpi_current & month != 1
replace labs_FE_cpi_current_a1 = . if l.cpi_future == cpi_current & month == 1
replace labs_FE_gdp_current_a1 = . if l.gdp_current == gdp_current & month != 1
replace labs_FE_gdp_current_a1 = . if l.gdp_current == gdp_current & month == 1
replace labs_FE_cpi_future_a1 = . if l.cpi_future == cpi_future & month != 1
replace labs_FE_gdp_future_a1 = . if l.gdp_future == gdp_future & month != 1



save $dataout/rob_changeForecastCurrent.dta, replace



********************************************************************************
********************************************************************************
********************************************************************************

* do robustness checks with the above data files:



foreach data in rob_a2 rob_locfor1 rob_trimming rob_headquarter rob_changeForecastCurrent{



	use $dataout/`data'.dta, clear




********************************************************************************
* FE_MG
********************************************************************************

*** by country and month ***


local varlist gdp cpi
		
* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(country month Foreign)
	egen Nobs2 = count(FR_`var'), by(country month Foreign)
	drop if Nobs1<10 | Nobs2<10
	gen country_num2 = .
	gen Foreign2 = .
	gen month2 = .
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	forval i = 1(1)51 {
		forval k=1(1)12 {
			capture reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & month==`k' & Foreign==0, absorb(datem idi)
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+102*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+102*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == `i'+102*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == `i'+102*(`k'-1)
			capture replace Foreign2 = 0		 		if _n == `i'+102*(`k'-1)
			capture replace month2 = `k'		 		if _n == `i'+102*(`k'-1)
			capture reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & month==`k' & Foreign==1, absorb(datem idi)
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+51+102*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+51+102*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == `i'+51+102*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == `i'+51+102*(`k'-1)
			capture replace Foreign2 = 1		 		if _n == `i'+51+102*(`k'-1)
			capture replace month2 = `k'		 		if _n == `i'+51+102*(`k'-1)
		}
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2 month2
	sort country_num2 Foreign2 month2
	rename country_num2 country_num
	rename Foreign2 Foreign
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

* Results
use $dataout/`data'.dta, clear
keep country country_num Emerging Foreign month
sort country_num Foreign month
collapse Emerging , by(country country_num Foreign month)
merge 1:1 country_num Foreign month using $temp_data/mg_FR, nogen
save $temp_data/mg_FE_reg_cty_month, replace

use $temp_data/mg_FE_reg_cty_month, clear

gen weight_gdp=1/sd_FR_gdp
gen weight_cpi=1/sd_FR_cpi

foreach var in cpi gdp {
	
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(month#country_num) vce(cluster country_num)
	regsave using "$temp_data/FE_reg_mg_cty_month_`var'_a.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", MG1, "", MG2, "\checkmark", MG3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(month country_num) vce(cluster country_num)
	regsave using "$temp_data/FE_reg_mg_cty_month_`var'_a_rob.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "", MG1, "", MG2, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(month#country_num) vce(cluster country_num)
	regsave using "$temp_data/FE_reg_mg_cty_month_`var'_a_baseline.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", FE3, "\checkmark", MG1, "", MG2, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
}

	
* -------------------------------
* Table - FE regressions
* -------------------------------
	
	
	******************************************
	* FE regressions mean-group (by cty & month)
	******************************************
	
	* CPI
	******
	
	* all
	use $temp_data/FE_reg_mg_cty_month_cpi_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_FE_mg.dta, replace 
	
	* GDP
	******
	
	* all
	use  $temp_data/FE_reg_mg_cty_month_gdp_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	*g n = _n
	rename col_1 col_2
	
	g n = _n
	
	drop var
	
	* merge with CPI
	*********
	merge 1:1 database n using $temp_data/cpi_FE_mg.dta
	drop _merge
	
	order var col_1 col_2 
	
	save $temp_data/FE_mg, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi4
	label var cpi4 "$ \text{CPI}_{t} $"
	rename col_2 gdp4
	label var gdp4 "$ \text{GDP}_{t} $"

	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country $\times$ month FE" if var == "FE1"	
	replace var = "Forecaster $\times$ month FE" if var == "FE2"
	replace var = "MG by ctry and month" if var=="MG1"
	replace var = "MG by ctry, loc., and month" if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	order  var cpi4 gdp4
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/FE_mg_`data', replace
	
	

********************************************************************************
* OVEREXTR_MG
********************************************************************************

**** By institution-country pair and month (2nd approach) ****

use $dataout/`data'.dta, clear

local varlist gdp cpi
		
sort idci

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(`var'_current), by(institution country month)
	egen Nobs2 = count(`var'_future), by(institution country month)
	drop if Nobs1<10 | Nobs2<10
	egen id2 = group(institution country month)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen month2 = .
	gen idci2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg `var'_future `var'_current if id2==`i'
		capture replace b_FR_`var' = _b[`var'_current]    if _n == `i'
		capture replace N_FR_`var' = e(N)	         	  if _n == `i'
		capture replace sd_FR_`var' = _se[`var'_current]  if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 	  if _n == `i'
		capture sum month if id2==`i'
		capture replace month2 = r(mean) 			 	  if _n == `i'
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2 month2
	sort idci2 month2
	rename idci2 idci
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR_overextrapolation, replace


use $dataout/`data'.dta, clear
keep country institution idci idi country_num month Foreign Multinational N_cty Emerging
sort idci month
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num month)
merge 1:1 idci month using $temp_data/mg_FR_overextrapolation, nogen
save $temp_data/mg_FR_overextrapolation_cty_inst_month2, replace


use $temp_data/mg_FR_overextrapolation_cty_inst_month2, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	
		if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(idi#month country_num#month) vce(cluster country_num idi)
	regsave using "$temp_data/overextr_mg_cty_inst_month_`var'_a2.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", MG1, "", MG2, "", MG3, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(idi country_num month) vce(cluster country_num idi)
	regsave using "$temp_data/overextr_mg_cty_inst_month_`var'_a2_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", MG1, "", MG2, "", MG3, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(idi#month country_num#month) vce(cluster country_num idi)
	regsave using "$temp_data/overextr_mg_cty_inst_month_`var'_a2_baseline.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", MG1, "", MG2, "", MG3, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

}

*------------------------------
**# Table Over-Extrapolation (2nd approach)
*------------------------------


	**********************************
	* Over-extrapolation mean-group (by cty, forecaster, month)
	**********************************
	
	* CPI
	******
	
	* all
	use $temp_data/overextr_mg_cty_inst_month_cpi_a2, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_overextr_mg.dta, replace 
	
	* GDP
	******
	
	* all
	use  $temp_data/overextr_mg_cty_inst_month_gdp_a2, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	*g n = _n
	rename col_1 col_2
	
	g n = _n
	
	drop var
	
	* merge with CPI
	*********
	merge 1:1 database n using $temp_data/cpi_overextr_mg.dta
	drop _merge
	
	order var col_1 col_2 
	
	save $temp_data/overextr_mg, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi2
	label var cpi2 "$ \text{CPI}_{t} $"
	rename col_2 gdp2
	label var gdp2 "$ \text{GDP}_{t} $"

	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country $\times$ month FE" if var == "FE1"	
	replace var = "Forecaster $\times$ month FE" if var == "FE2"
	replace var = "MG by ctry and month" if var=="MG1"
	replace var = "MG by ctry, loc., and month" if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	order  var cpi2 gdp2
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/overextr_mg_`data', replace
	
	



********************************************************************************
* BGMS_MG:
********************************************************************************


**** By country, institution and month ****

use $dataout/`data'.dta, clear

local varlist gdp cpi
		
sort idci month

* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	egen Nobs1 = count(FE_`var'_current_a1), by(institution country month)
	egen Nobs2 = count(FR_`var'), by(institution country month)
	drop if Nobs1<10 | Nobs2<10
	egen id2 = group(institution country month)
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	gen idci2 = .
	gen month2 = .
	sum id2
	local MAX=r(max)
	forval i = 1(1)`MAX' {
		capture qui reg FE_`var'_current_a1 FR_`var' if id2==`i'
		capture replace b_FR_`var' = _b[FR_`var']    if _n == `i'
		capture replace N_FR_`var' = e(N)	         if _n == `i'
		capture replace sd_FR_`var' = _se[FR_`var']  if _n == `i'
		capture sum idci if id2==`i'
		capture replace idci2 = r(mean) 			 if _n == `i'
		capture sum month if id2==`i'
		capture replace month2 = r(mean) 			 if _n == `i'
		}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' idci2 month2
	sort idci2
	sort idci2 month2
	rename idci2 idci
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 idci month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

use $dataout/`data'.dta, clear
keep country institution idci idi country_num Foreign Multinational N_cty Emerging month
sort idci month
collapse Foreign Multinational N_cty Emerging, by(country institution idci idi country_num month)
merge 1:1 idci month using $temp_data/mg_FR, nogen
save $temp_data/mg_FR_BGMS_cty_inst_month, replace

use $temp_data/mg_FR_BGMS_cty_inst_month, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	if "`var'" == "cpi" {
			local capvarp " $ \text{CPI}_{t} $ "
		}
			else if  "`var'" == "gdp" {
			local capvarp " $ \text{GDP}_{t} $ "
		}
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num#month idi#month) vce(cluster country_num idi)
	regsave using "$temp_data/bgms_mg_cty_inst_month_`var'_a.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(idi country_num month) vce(cluster country_num idi)
	regsave using "$temp_data/bgms_mg_cty_inst_month_`var'_a_rob.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
				
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'], absorb(country_num#month idi#month) vce(cluster country_num idi)
	regsave using "$temp_data/bgms_mg_cty_inst_month_`var'_a_baseline.dta", replace  ///
				addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", MG1, "", MG2, "", MG3, "\checkmark")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
				
}


*--------------------
**# Table BGMS
*--------------------


	**********************************
	* BGMS mean-group (by cty & inst & month)
	**********************************
	
	* CPI
	******
	
	* all
	use $temp_data/bgms_mg_cty_inst_month_cpi_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_bgms_mg.dta, replace 
	
	* GDP
	******
	
	* all
	use  $temp_data/bgms_mg_cty_inst_month_gdp_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	*g n = _n
	rename col_1 col_2
	
	g n = _n
	
	drop var
	
	* merge with CPI
	*********
	merge 1:1 database n using $temp_data/cpi_bgms_mg.dta
	drop _merge
	
	order var col_1 col_2 
	
	save $temp_data/bgms_mg, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi1
	label var cpi1 "$ \text{CPI}_{t} $"
	rename col_2 gdp1
	label var gdp1 "$ \text{GDP}_{t} $"

	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country $\times$ month FE" if var == "FE1"	
	replace var = "Forecaster $\times$ month FE" if var == "FE2"
	replace var = "MG by ctry and month" if var=="MG1"
	replace var = "MG by ctry, loc., and month" if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	order  var cpi1 gdp1
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/bgms_mg_`data', replace



********************************************************************************
* DISAG_MG:
********************************************************************************

use $dataout/`data'.dta, clear

local varlist gdp cpi
		
* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	collapse FR_`var' `var'_current_a1 `var'_future dFR_`var'_locfor d`var'_locfor, by(country_num datem year month Foreign)
	gen `var'_future_loc = `var'_future if Foreign==0
	gen `var'_future_for = `var'_future if Foreign==1
	collapse FR_`var' `var'_current_a1 `var'_future dFR_`var'_locfor d`var'_locfor `var'_future_loc `var'_future_for, by(country_num datem year month)	
	egen Nobs1 = count(d`var'_locfor), by(country month)
	drop if Nobs1<10
	xtset country_num datem
	gen country_num2 = .
	gen month2 = .
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	forval i = 1(1)51 {
		forval k=1(1)12 {
			capture qui reghdfe d`var'_locfor l12.(`var'_future_loc `var'_future_for) `var'_current_a1 FR_`var' if country_num==`i' & month==`k', noabsorb vce(robust)			
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+51*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+51*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == `i'+51*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == `i'+51*(`k'-1)
			capture replace month2 = `k'		 		if _n == `i'+51*(`k'-1)
		}
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 month2
	sort country_num2 month2
	rename country_num2 country_num
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

* Results
use $dataout/`data'.dta, clear
keep country country_num Emerging month
sort country_num month
collapse Emerging , by(country country_num month)
merge 1:1 country_num month using $temp_data/mg_FR, nogen
save $temp_data/disag_mg_cty_month, replace

use $temp_data/disag_mg_cty_month, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	reghdfe b_FR_`var' [aweight=weight_`var'] , noabsorb vce(cluster country_num)
		regsave using "$temp_data/disag_mg_cty_month_`var'_a.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", MG1, "\checkmark", MG2, "", MG3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' [aweight=weight_`var'] , noabsorb vce(cluster country_num)
		regsave using "$temp_data/disag_mg_cty_month_`var'_a_baseline.dta", replace  ///
			addlabel(rhs,"`capvarp'" , MG1, "", MG2, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
			
}


* -------------------------------
* Table - Disagreement
* -------------------------------
	

	******************************************
	* Disagreement mean-group (by cty & month)
	******************************************
	
	* CPI
	******
	
	* all
	use $temp_data/disag_mg_cty_month_cpi_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_disag_mg.dta, replace 
	
	* GDP
	******
	
	* all
	use  $temp_data/disag_mg_cty_month_gdp_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	*g n = _n
	rename col_1 col_2
	
	g n = _n
	
	drop var
	
	* merge with CPI
	*********
	merge 1:1 database n using $temp_data/cpi_disag_mg.dta
	drop _merge
	
	order var col_1 col_2 
	
	save $temp_data/disag_mg, replace
	

	drop database 
	
	
	replace var = "Average" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
		
	rename col_1 cpi5
	label var cpi5 "$ \text{CPI}_{t} $"
	rename col_2 gdp5
	label var gdp5 "$ \text{GDP}_{t} $"

	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country $\times$ month FE" if var == "FE1"	
	replace var = "Forecaster $\times$ month FE" if var == "FE2"
	replace var = "MG by ctry and month" if var=="MG1"
	replace var = "MG by ctry, loc., and month" if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	order  var cpi5 gdp5
	
	label var var "Coefficient"

	gen n=_n

	save $temp_data/disag_mg_`data', replace
	
	
	
	
********************************************************************************
* CONSENSUS_MG
********************************************************************************


******** by country and month *******

use $dataout/`data'.dta, clear

local varlist gdp cpi
		
* Run individual regressions ans save results (b_: coeff., N_: number of observations)
foreach var in `varlist' {
	preserve
	collapse (median) FR_`var' FE_`var'_current_a1 , by(country_num datem year month Foreign Emerging)
	egen country_num_For_month = group(country_num Foreign month)
	xtset country_num_For_month datem	
	local FE month	
	gen country_num2 = .
	gen Foreign2 = .
	gen month2 = .
	gen b_FR_`var' = .
	gen N_FR_`var' = .
	gen sd_FR_`var' = .
	forval i = 1(1)51 {
		forval k = 1(1)12 {
			capture qui reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & month==`k' & Foreign==0, absorb(`FE')	
			capture replace b_FR_`var' = _b[FR_`var']   if _n == `i'+51*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == `i'+51*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == `i'+51*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == `i'+51*(`k'-1)
			capture replace Foreign2 = 0			 	if _n == `i'+51*(`k'-1)
			capture replace month2 = `k'			 	if _n == `i'+51*(`k'-1)
			capture qui reghdfe FE_`var'_current_a1 FR_`var' if country_num==`i' & month==`k' & Foreign==1, absorb(`FE')	
			capture replace b_FR_`var' = _b[FR_`var']   if _n == 612+`i'+51*(`k'-1)
			capture replace sd_FR_`var' = _se[FR_`var'] if _n == 612+`i'+51*(`k'-1)
			capture replace N_FR_`var' = e(N)	        if _n == 612+`i'+51*(`k'-1)
			capture replace country_num2 = `i'		 	if _n == 612+`i'+51*(`k'-1)
			capture replace Foreign2 = 1			 	if _n == 612+`i'+51*(`k'-1)
			capture replace month2 = `k'			 	if _n == 612+`i'+51*(`k'-1)
		}
	}
	keep b_FR_`var' N_FR_`var' sd_FR_`var' country_num2 Foreign2 month2
	sort country_num2 Foreign2 month2
	rename country_num2 country_num
	rename Foreign2 Foreign
	rename month2 month
	keep if b_FR_`var' != .
	save $temp_data/mg_FR_`var', replace
	restore
}

* Put results in single dataset 
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp_data/mg_FR_`var'.dta", clear
		}
		else {
			merge 1:1 country_num Foreign month using "$temp_data/mg_FR_`var'.dta", nogen
		}
	}
save $temp_data/mg_FR, replace

* Results
use $dataout/`data'.dta, clear
keep country country_num Emerging Foreign month
sort country_num Foreign month
collapse Emerging , by(country country_num Foreign month)
merge 1:1 country_num Foreign month using $temp_data/mg_FR, nogen
save $temp_data/consensus_mg_cty_month, replace

use $temp_data/consensus_mg_cty_month, clear

gen weight_gdp = 1/sd_FR_gdp
gen weight_cpi = 1/sd_FR_cpi

foreach var in cpi gdp {
	
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'] , absorb(country_num#month) vce(cluster country_num)
		regsave using "$temp_data/consensus_mg_cty_month_`var'_a.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "", MG1, "", MG2, "\checkmark", MG3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'] , absorb(country_num month) vce(cluster country_num)
		regsave using "$temp_data/consensus_mg_cty_month_`var'_a_rob.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "\checkmark", FE2, "\checkmark", FE3, "", MG1, "", MG2, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	reghdfe b_FR_`var' Foreign [aweight=weight_`var'] , absorb(country_num#month) vce(cluster country_num)
		regsave using "$temp_data/consensus_mg_cty_month_`var'_a_baseline.dta", replace  ///
			addlabel(rhs,"`capvarp'" , FE1, "", FE2, "", FE3, "\checkmark", MG1, "", MG2, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
			
}


* -------------------------------
* Table - Consensus
* -------------------------------
	
	******************************************
	* consensusreement mean-group (by cty & month)
	******************************************
	
	* CPI
	******
	
	* all
	use $temp_data/consensus_mg_cty_month_cpi_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort i
	
	drop i
	
	g n = _n
	
	save $temp_data/cpi_consensus_mg.dta, replace 
	
	* GDP
	******
	
	* all
	use  $temp_data/consensus_mg_cty_month_gdp_a, clear
	g database = 1
	replace database = 1 if database == .
	rename col_1 col_1
	
	g i = _n
	replace i = 0 if var == "_cons_coef"
	replace i = 0.5 if var == "_cons_stderr"
	
	sort database i
		
	drop i
	
	*g n = _n
	rename col_1 col_2
	
	g n = _n
	
	drop var
	
	* merge with CPI
	*********
	merge 1:1 database n using $temp_data/cpi_consensus_mg.dta
	drop _merge
	
	order var col_1 col_2 
	
	save $temp_data/consensus_mg, replace
	

	drop database 
	
	
	replace var = "Average Locals" if var == "_cons_coef"
	replace var = "" if var == "_cons_stderr"
	replace var = "$ \text{Foreign} $" if var == "Foreign_coef"
	replace var = "" if var == "Foreign_stderr"
		
	rename col_1 cpi3
	label var cpi3 "$ \text{CPI}_{t} $"
	rename col_2 gdp3
	label var gdp3 "$ \text{GDP}_{t} $"

	* clean the data
	drop if var == "restr" | var == "_id" 
	
	replace var = "$ R^2 $" if var == "r2"
	
		
	replace var = "Country $\times$ month FE" if var == "FE1"	
	replace var = "Forecaster $\times$ month FE" if var == "FE2"
	replace var = "MG by ctry and month" if var=="MG1"
	replace var = "MG by ctry, loc., and month" if var=="MG2"
	replace var = "MG by ctry, for., and month" if var=="MG3"
	drop if var == "rhs"
	
	drop n
	
	order  var cpi3 gdp3
	
	label var var "Coefficient"
	
	gen n=_n

	save $temp_data/consensus_mg_`data', replace
	


********************************************************************************
* FORECAST ERRORS:	
	
	
	
	

	use $dataout/`data'.dta, clear


foreach var in cpi gdp {
	
	foreach hor in current future {
		
		*replace labs_FE_`var'_`hor'_a1 = max(-5,labs_FE_`var'_`hor'_a1) if labs_FE_`var'_`hor'_a1!=.
		*replace labs_FE_`var'_`hor'_a1 = -5 if FE_`var'_`hor'_a1==0
		
		if "`hor'" == "current" {
			local time "t"
		}
		else if "`hor'" == "future"{
			local time "t+1"
		}
		
		if "`var'" == "cpi" {
			local capvar " $ \text{CPI}_{`time'} $ "
		}
		else if  "`var'" == "gdp" {
			local capvar " $ \text{GDP}_{`time'} $ "
		}
		
		
		* clustering
		local se cluster country_num  idi datem
		
		* Fixed Effects:
		local FE country_num#datem idi#datem 
		reghdfe labs_FE_`var'_`hor'_a1 Foreign, absorb(`FE') vce(`se')
		regsave using "$temp_data/reg_labs_`var'_`hor'_FE", replace  ///
			addlabel(rhs,"`capvar'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", FE6, "", FE7, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

	
		
	}
}

* combine results for cpi and gdp:
use $temp_data/reg_labs_cpi_current_FE.dta, clear
g database = 1
append using $temp_data/reg_labs_gdp_current_FE
replace database = 2 if database == .
append using $temp_data/reg_labs_cpi_future_FE
replace database = 3 if database == .
append using $temp_data/reg_labs_gdp_future_FE
replace database = 4 if database == .
g n = _n
rename col_1 col_4
	
* clean the data
drop if var == "restr" | var == "_id" | strpos(var,"_cons")>0

* Fill up indicator variable:
gen indicator = col_4 if var == "rhs"
qui sort database indicator
by database indicator: replace indicator = indicator[_n-1] if indicator == "" 
qui gsort database -indicator
by database : replace indicator = indicator[_n-1] if indicator == ""

sort database n
bysort database: g count = _n 
replace indicator = "" if count >1

g noverall = _n
su noverall
local max = r(max)
drop if strpos(var,"FE") &  noverall < `max' - (7 +3)

drop if var == "rhs"
drop database n count noverall
replace var = "$ R^2 $" if var == "r2"

replace var = "Foreign" if var == "Foreign_coef"
replace var = "" if var == "Foreign_stderr"

replace var = "Country, For., Month FE" if var == "FE1"
replace var = "Country $ \times $ Year FE" if var == "FE2"
replace var = "Forecaster $ \times $ Year FE " if var == "FE3"
replace var = "Country $ \times $ Date FE" if var == "FE4"
replace var = "Forecaster $ \times $ Date FE " if var == "FE5"
replace var = "Subsample 1" if var == "FE6"
replace var = "Subsample 2" if var == "FE7"

order indicator

label var indicator "Variable"
label var var "Coefficient"
label var col_4 ""

save $temp_data/reg_labs_`data', replace


}
	
	


	
********************************************************************************
********************************************************************************

* assemble the results:



foreach data in rob_a2 rob_locfor1 rob_trimming rob_headquarter rob_changeForecastCurrent {
	

	*local data rob_changeForecastCurrent
    // Create suffix based on the value of `data`
    local suffix = ""
    if "`data'" == "rob_a2" {
        local suffix = "a2"
    }
    else if "`data'" == "rob_locfor1" {
        local suffix = "lf"
    }
    else if "`data'" == "rob_trimming" {
        local suffix = "tr"
    }
    else if "`data'" == "rob_headquarter" {
        local suffix = "hq"
    }
    else if "`data'" == "rob_changeForecastCurrent" {
        local suffix = "fc"
    }

    // Process reg_labs data
    use $temp_data/reg_labs_`data'.dta, clear

    // Drop results not needed (t+1)
    drop if _n >= 8
    drop if var == "$ R^2 $"

    // Create an ID variable to identify each block
    gen block_id = sum(indicator != "")
    by block_id, sort: gen row_id = _n

    // Reshape the data to wide format
    reshape wide indicator var col_4, i(row_id) j(block_id)

    // Drop unnecessary row_id variable
    drop row_id

    drop indicator*
    drop var2

    g tableindicator = "$\ln (|Error_{ijt,t}^m|)$"
    order tableindicator

    replace tableindicator = "" if _n > 1

    rename var1 cola`suffix'
    rename col_41 colb`suffix'
    rename col_42 colc`suffix'

    save $temp_data/reg_labs_`data'_finaltable.dta, replace

    // Process bgms_mg data
    use $temp_data/bgms_mg_`data'.dta, clear
    drop if _n >= 6

    g tableindicator = "$\beta^{BGMS}$"
    order tableindicator

    replace tableindicator = "" if _n > 1

    rename var cola`suffix'
    capture rename cpi2 colb`suffix'
    capture rename gdp2 colc`suffix'
    capture rename cpi1 colb`suffix'
    capture rename gdp1 colc`suffix'
    capture rename cpi3 colb`suffix'
    capture rename gdp3 colc`suffix'
    capture rename cpi4 colb`suffix'
    capture rename gdp4 colc`suffix'
    capture rename cpi5 colb`suffix'
    capture rename gdp5 colc`suffix'

    drop n
    save $temp_data/bgms_mg_`data'_finaltable.dta, replace

    // Process overextr_mg data
    use $temp_data/overextr_mg_`data'.dta, clear
    drop if _n >= 6

    g tableindicator = "$\hat\rho$"
    order tableindicator

    replace tableindicator = "" if _n > 1

    rename var cola`suffix'
    capture rename cpi2 colb`suffix'
    capture rename gdp2 colc`suffix'
    capture rename cpi1 colb`suffix'
    capture rename gdp1 colc`suffix'
    capture rename cpi3 colb`suffix'
    capture rename gdp3 colc`suffix'
    capture rename cpi4 colb`suffix'
    capture rename gdp4 colc`suffix'
    capture rename cpi5 colb`suffix'
    capture rename gdp5 colc`suffix'

    drop n
    save $temp_data/overextr_mg_`data'_finaltable.dta, replace

    // Process consensus_mg data
    use $temp_data/consensus_mg_`data'.dta, clear
    drop if _n >= 6

    g tableindicator = "$\beta^{CG}$"
    order tableindicator

    replace tableindicator = "" if _n > 1

    rename var cola`suffix'
    capture rename cpi2 colb`suffix'
    capture rename gdp2 colc`suffix'
    capture rename cpi1 colb`suffix'
    capture rename gdp1 colc`suffix'
    capture rename cpi3 colb`suffix'
    capture rename gdp3 colc`suffix'
    capture rename cpi4 colb`suffix'
    capture rename gdp4 colc`suffix'
    capture rename cpi5 colb`suffix'
    capture rename gdp5 colc`suffix'

    drop n
    save $temp_data/consensus_mg_`data'_finaltable.dta, replace

    // Process FE_mg data
    use $temp_data/FE_mg_`data'.dta, clear
    drop if _n >= 6

    g tableindicator = "$\beta^{FE}$"
    order tableindicator

    replace tableindicator = "" if _n > 1

    rename var cola`suffix'
    capture rename cpi2 colb`suffix'
    capture rename gdp2 colc`suffix'
    capture rename cpi1 colb`suffix'
    capture rename gdp1 colc`suffix'
    capture rename cpi3 colb`suffix'
    capture rename gdp3 colc`suffix'
    capture rename cpi4 colb`suffix'
    capture rename gdp4 colc`suffix'
    capture rename cpi5 colb`suffix'
    capture rename gdp5 colc`suffix'

    drop n
    save $temp_data/FE_mg_`data'_finaltable.dta, replace

    // Process disag_mg data
    use $temp_data/disag_mg_`data'.dta, clear
    drop if _n >= 4

    g tableindicator = "$\beta^{Dis}$"
    order tableindicator

    replace tableindicator = "" if _n > 1

    rename var cola`suffix'
    capture rename cpi2 colb`suffix'
    capture rename gdp2 colc`suffix'
    capture rename cpi1 colb`suffix'
    capture rename gdp1 colc`suffix'
    capture rename cpi3 colb`suffix'
    capture rename gdp3 colc`suffix'
    capture rename cpi4 colb`suffix'
    capture rename gdp4 colc`suffix'
    capture rename cpi5 colb`suffix'
    capture rename gdp5 colc`suffix'

    drop n
    save $temp_data/disag_mg_`data'_finaltable.dta, replace
}




foreach data in rob_a2 rob_locfor1 rob_trimming rob_headquarter rob_changeForecastCurrent{


use $temp_data/reg_labs_`data'_finaltable.dta, clear
append using $temp_data/bgms_mg_`data'_finaltable.dta
append using $temp_data/overextr_mg_`data'_finaltable.dta
append using $temp_data/consensus_mg_`data'_finaltable.dta
append using $temp_data/FE_mg_`data'_finaltable.dta
append using $temp_data/disag_mg_`data'_finaltable.dta


g merger = _n

save $temp_data/rob_alltables_`data'.dta, replace


}




use $temp_data/rob_alltables_rob_a2.dta, clear

merge 1:1 merge using $temp_data/rob_alltables_rob_locfor1.dta

drop _merge 

merge 1:1 merge using $temp_data/rob_alltables_rob_trimming.dta

drop _merge 


merge 1:1 merge using $temp_data/rob_alltables_rob_changeForecastCurrent.dta

drop _merge 

merge 1:1 merge using $temp_data/rob_alltables_rob_headquarter.dta

drop _merge 


drop colalf colatr colahq colafc merger


* texsave will output these labels as column headers
label var colaa2 ""
label var colba2 "$ \text{CPI}_{t} $"
label var colca2 "$ \text{GDP}_{t} $"
label var colblf "$ \text{CPI}_{t} $"
label var colclf "$ \text{GDP}_{t} $"
label var colbtr "$ \text{CPI}_{t} $"
label var colctr "$ \text{GDP}_{t} $"
label var colbhq "$ \text{CPI}_{t} $"
label var colchq "$ \text{GDP}_{t} $"
label var colbfc "$ \text{CPI}_{t} $"
label var colcfc "$ \text{GDP}_{t} $"
         
texsave tableindicator colaa2 colba2 colca2 colblf colclf colbtr colctr colbfc colcfc colbhq colchq using "$tables/robustness_alltables_revision.tex",  ///
		title("Robustness Checks - Summary Results") varlabels nofix hlines(0 3 8 13 18 23) headersep(0pt) autonumber ///
	frag  size(scriptsize)  align(l l C C C C C C C C C C) location(H) replace label(tab:rob_sumres) footnote(		"\begin{minipage}{1\linewidth} \vspace{-10pt} \begin{tabnote} {\footnotesize{ \textit{Notes:} This table shows the results of several robustness checks. In columns (2) and (3), we use an alternative vintage series to calculate the forecast error that was published in April of the subsequent year of the forecast. In columns (4) and (5), we restrict the sample to forecasters that forecast for both countries where they are foreign and local. In columns (6) and (7) we use a less conservative trimming strategy to remove outliers for inflation and GDP forecasts. In columns (8) and (9) we restrict the sample to distinct forecasts only. In columns (10) and (11), we only use the headquarter of the forecaster to identify whether the forecaster is local or foreign. For each of these robustness checks, we reproduce the results of tables \ref{tab:updating_errors_main_small} column (2) and all the regressions displayed in table \ref{tab:tab_main}.}} \end{tabnote} \end{minipage}  ")  ///
	 headerlines("& & \multicolumn{2}{c}{\textbf{Vintages April}} & \multicolumn{2}{c}{\textbf{Local and Foreign}} & \multicolumn{2}{c}{\textbf{Trimming}} & \multicolumn{2}{c}{\textbf{Distinct Forecasts}} & \multicolumn{2}{c}{\textbf{Headquarter}} " )
	
	


********************************************************************************
********************************************************************************

* TABLE ROBUSTNESS CHECK USING DIFFERENT STANDARD ERRORS


* ----------------------
**# Information updating
* ----------------------


use $dataout/baseline.dta, clear

preserve
collapse (count) cpi_current gdp_current cpi_future gdp_future, by(country country_num idi idci year Foreign LocFor)

sum cpi_current gdp_current cpi_future gdp_future


replace cpi_current = log(cpi_current)
replace gdp_current = log(gdp_current)
replace cpi_future = log(cpi_future)
replace gdp_future = log(gdp_future)

* regressions
xtset year idci
foreach var in cpi gdp {
	foreach hor in current future {

		cap drop used
		reghdfe `var'_`hor' Foreign, absorb(idi#year country_num#year) vce(cluster country_num idi)
		gen used = e(sample)

		
		ivreghdfe `var'_`hor' Foreign if used == 1, absorb(idi#year country_num#year) cluster(idci year) bw(1)
			regsave using "$temp_data/rob_se_reg_update_`var'_`hor'_FE1_bw1.dta", replace  ///
		addlabel(FE1, "", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", FE6, "", FE7, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

		
		ivreghdfe `var'_`hor' Foreign if used == 1, absorb(idi#year country_num#year) cluster(idci year) bw(2)
			regsave using "$temp_data/rob_se_reg_update_`var'_`hor'_FE1_bw2.dta", replace  ///
		addlabel(FE1, "", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", FE6, "", FE7, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

		ivreghdfe `var'_`hor' Foreign if used == 1, absorb(idi#year country_num#year) cluster(idci year) bw(3)
			regsave using "$temp_data/rob_se_reg_update_`var'_`hor'_FE1_bw3.dta", replace  ///
		addlabel(FE1, "", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", FE6, "", FE7, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

		ivreghdfe `var'_`hor' Foreign if used == 1, absorb(idi#year country_num#year) cluster(idci year) bw(4)
			regsave using "$temp_data/rob_se_reg_update_`var'_`hor'_FE1_bw4.dta", replace  ///
		addlabel(FE1, "", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", FE6, "", FE7, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

	
	}
}

restore


preserve
sort idci datem
xtset idci datem
replace cpi_current = . if l.cpi_current == cpi_current & month != 1
replace cpi_current = . if l.cpi_future == cpi_current & month == 1
replace gdp_current = . if l.gdp_current == gdp_current & month != 1
replace gdp_current = . if l.gdp_current == gdp_current & month == 1
replace cpi_future = . if l.cpi_future == cpi_future & month != 1
replace gdp_future = . if l.gdp_future == gdp_future & month != 1
collapse (count) cpi_current gdp_current cpi_future gdp_future, by(country country_num idi idci year Foreign LocFor)
* histograms
label var cpi_current "Number of yearly current CPI updates"
label var gdp_current "Number of yearly current GDP updates"
label var cpi_future "Number of yearly future CPI updates"
label var gdp_future "Number of yearly future GDP updates"


replace cpi_current = log(cpi_current)
replace gdp_current = log(gdp_current)
replace cpi_future = log(cpi_future)
replace gdp_future = log(gdp_future)
* regressions

xtset year idci

foreach var in cpi gdp {
	foreach hor in current future {
	
		cap drop used
		reghdfe `var'_`hor' Foreign, absorb(idi#year country_num#year) vce(cluster country_num idi)
		gen used = e(sample)
	
		
		ivreghdfe `var'_`hor' Foreign if used == 1, absorb(idi#year country_num#year) cluster(idci year) bw(1)
		regsave using "$temp_data/rob_se_reg_update_`var'_`hor'_FE2_bw1.dta", replace  ///
	addlabel(FE1, "", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", FE6, "\checkmark", FE7, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

		
		ivreghdfe `var'_`hor' Foreign if used == 1, absorb(idi#year country_num#year) cluster(idci year) bw(2)
		regsave using "$temp_data/rob_se_reg_update_`var'_`hor'_FE2_bw2.dta", replace  ///
	addlabel(FE1, "", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", FE6, "\checkmark", FE7, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

	
		ivreghdfe `var'_`hor' Foreign if used == 1, absorb(idi#year country_num#year) cluster(idci year) bw(3)
		regsave using "$temp_data/rob_se_reg_update_`var'_`hor'_FE2_bw3.dta", replace  ///
	addlabel(FE1, "", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", FE6, "\checkmark", FE7, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

	
		ivreghdfe `var'_`hor' Foreign if used == 1, absorb(idi#year country_num#year) cluster(idci year) bw(4)
		regsave using "$temp_data/rob_se_reg_update_`var'_`hor'_FE2_bw4.dta", replace  ///
	addlabel(FE1, "", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", FE6, "\checkmark", FE7, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

	
	}
}

restore


* combine results for cpi and gdp:
use $temp_data/rob_se_reg_update_cpi_current_FE1_bw1.dta, clear
g database = 1
append using $temp_data/rob_se_reg_update_gdp_current_FE1_bw1
replace database = 2 if database == .
append using $temp_data/rob_se_reg_update_cpi_future_FE1_bw1
replace database = 3 if database == .
append using $temp_data/rob_se_reg_update_gdp_future_FE1_bw1
replace database = 4 if database == .
g n = _n
rename col_1 col_1
sort database n
save $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE1_bw1.dta, replace


use $temp_data/rob_se_reg_update_cpi_current_FE1_bw2.dta, clear
g database = 1
append using $temp_data/rob_se_reg_update_gdp_current_FE1_bw2
replace database = 2 if database == .
append using $temp_data/rob_se_reg_update_cpi_future_FE1_bw2
replace database = 3 if database == .
append using $temp_data/rob_se_reg_update_gdp_future_FE1_bw2
replace database = 4 if database == .
g n = _n
rename col_1 col_2
sort database n
save $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE1_bw2.dta, replace


use $temp_data/rob_se_reg_update_cpi_current_FE1_bw3.dta, clear
g database = 1
append using $temp_data/rob_se_reg_update_gdp_current_FE1_bw3
replace database = 2 if database == .
append using $temp_data/rob_se_reg_update_cpi_future_FE1_bw3
replace database = 3 if database == .
append using $temp_data/rob_se_reg_update_gdp_future_FE1_bw3
replace database = 4 if database == .
g n = _n
rename col_1 col_3
sort database n
save $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE1_bw3.dta, replace

use $temp_data/rob_se_reg_update_cpi_current_FE1_bw4.dta, clear
g database = 1
append using $temp_data/rob_se_reg_update_gdp_current_FE1_bw4
replace database = 2 if database == .
append using $temp_data/rob_se_reg_update_cpi_future_FE1_bw4
replace database = 3 if database == .
append using $temp_data/rob_se_reg_update_gdp_future_FE1_bw4
replace database = 4 if database == .
g n = _n
rename col_1 col_4
sort database n
save $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE1_bw4.dta, replace




* combine results for cpi and gdp:
use $temp_data/rob_se_reg_update_cpi_current_FE2_bw1.dta, clear
g database = 1
append using $temp_data/rob_se_reg_update_gdp_current_FE2_bw1
replace database = 2 if database == .
append using $temp_data/rob_se_reg_update_cpi_future_FE2_bw1
replace database = 3 if database == .
append using $temp_data/rob_se_reg_update_gdp_future_FE2_bw1
replace database = 4 if database == .
g n = _n
rename col_1 col_5
sort database n
save $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE2_bw1.dta, replace


use $temp_data/rob_se_reg_update_cpi_current_FE2_bw2.dta, clear
g database = 1
append using $temp_data/rob_se_reg_update_gdp_current_FE2_bw2
replace database = 2 if database == .
append using $temp_data/rob_se_reg_update_cpi_future_FE2_bw2
replace database = 3 if database == .
append using $temp_data/rob_se_reg_update_gdp_future_FE2_bw2
replace database = 4 if database == .
g n = _n
rename col_1 col_6
sort database n
save $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE2_bw2.dta, replace


use $temp_data/rob_se_reg_update_cpi_current_FE2_bw3.dta, clear
g database = 1
append using $temp_data/rob_se_reg_update_gdp_current_FE2_bw3
replace database = 2 if database == .
append using $temp_data/rob_se_reg_update_cpi_future_FE2_bw3
replace database = 3 if database == .
append using $temp_data/rob_se_reg_update_gdp_future_FE2_bw3
replace database = 4 if database == .
g n = _n
rename col_1 col_7
sort database n
save $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE2_bw3.dta, replace

use $temp_data/rob_se_reg_update_cpi_current_FE2_bw4.dta, clear
g database = 1
append using $temp_data/rob_se_reg_update_gdp_current_FE2_bw4
replace database = 2 if database == .
append using $temp_data/rob_se_reg_update_cpi_future_FE2_bw4
replace database = 3 if database == .
append using $temp_data/rob_se_reg_update_gdp_future_FE2_bw4
replace database = 4 if database == .
g n = _n
rename col_1 col_8
sort database n
save $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE2_bw4.dta, replace




* merge results to have wide table:
use $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE1_bw1.dta, clear
sort database n
merge 1:1 database n using $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE1_bw2.dta
drop _merge
sort database n
merge 1:1 database n using $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE1_bw3.dta
drop _merge
sort database n
merge 1:1 database n using $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE1_bw4.dta
drop _merge
sort database n

* now we add distinct updates:
merge 1:1 database n using $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE2_bw1.dta
drop _merge
sort database n
merge 1:1 database n using $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE2_bw2.dta
drop _merge
sort database n
merge 1:1 database n using $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE2_bw3.dta
drop _merge
sort database n
merge 1:1 database n using $temp_data/rob_se_reg_update_cpi_gdp_current_future_FE2_bw4.dta
drop _merge
sort database n


* clean the data
drop if var == "restr" | var == "_id" | strpos(var,"_cons")>0

drop if var == "rhs"
drop database n
replace var = "$ R^2 $" if var == "r2"

replace var = "Foreign" if var == "Foreign_coef"
replace var = "" if var == "Foreign_stderr"

g noverall = _n
su noverall
local max = r(max)
drop if strpos(var,"FE") &  noverall < `max' - (7 +3)
drop n noverall

replace var = "Country, For., Month FE" if var == "FE1"
replace var = "Country $ \times $ Year FE" if var == "FE2"
replace var = "Forecaster $ \times $ Year FE " if var == "FE3"
replace var = "Country $ \times $ Date FE" if var == "FE4"
replace var = "Forecaster $ \times $ Date FE " if var == "FE5"
replace var = "Subsample 1" if var == "FE6"
replace var = "Subsample 2" if var == "FE7"


* Fill up indicator variable:
gen indicator = ""
replace indicator = "$\text{CPI}_t$" if _n==1
replace indicator = "$\text{GDP}_t$" if _n==5
replace indicator = "$\text{CPI}_{t+1}$" if _n==9
replace indicator = "$\text{GDP}_{t+1}$" if _n==13

order indicator var col_1-col_2

label var indicator "Variable"
label var var "Coefficient"
label var col_1 ""
label var col_2 ""

// col 4/5 of table 1, with different standard errors 
save $temp_data/rob_se_reg_updating_bw, replace



* ----------------------
**# Regressions log(abs)
* ----------------------


use $dataout/baseline.dta, clear

sum abs_FE_cpi_current_a1 abs_FE_gdp_current_a1 abs_FE_cpi_future_a1 abs_FE_gdp_future_a1 if Foreign==0

*xtdescribe

foreach var in cpi gdp {
	
	foreach hor in current future {
		
		*replace labs_FE_`var'_`hor'_a1 = max(-5,labs_FE_`var'_`hor'_a1) if labs_FE_`var'_`hor'_a1!=.
		*replace labs_FE_`var'_`hor'_a1 = -5 if FE_`var'_`hor'_a1==0
		
		if "`hor'" == "current" {
			local time "t"
		}
		else if "`hor'" == "future"{
			local time "t+1"
		}
		
		if "`var'" == "cpi" {
			local capvar " $ \text{CPI}_{`time'} $ "
		}
		else if  "`var'" == "gdp" {
			local capvar " $ \text{GDP}_{`time'} $ "
		}
		
		
		* clustering
		local se cluster country_num  idi datem
		
		* Fixed Effects:
		local FE country_num#datem idi#datem 
		
		cap drop used
		reghdfe labs_FE_`var'_`hor'_a1 Foreign, absorb(`FE') vce(`se')
		gen used = e(sample)
		
		
		ivreghdfe labs_FE_`var'_`hor'_a1 Foreign if used == 1, absorb(`FE') cluster(idci datem) bw(4)
		regsave using "$temp_data/rob_se_reg_labs_`var'_`hor'_FE_bw1", replace  ///
			addlabel(rhs,"`capvar'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", FE6, "", FE7, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

		ivreghdfe labs_FE_`var'_`hor'_a1 Foreign if used == 1, absorb(`FE') cluster(idci datem) bw(5)
		regsave using "$temp_data/rob_se_reg_labs_`var'_`hor'_FE_bw2", replace  ///
			addlabel(rhs,"`capvar'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", FE6, "", FE7, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

			
				ivreghdfe labs_FE_`var'_`hor'_a1 Foreign if used == 1, absorb(`FE') cluster(idci datem) bw(6)
		regsave using "$temp_data/rob_se_reg_labs_`var'_`hor'_FE_bw3", replace  ///
			addlabel(rhs,"`capvar'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", FE6, "", FE7, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

			
				ivreghdfe labs_FE_`var'_`hor'_a1 Foreign if used == 1, absorb(`FE') cluster(idci datem) bw(7)
		regsave using "$temp_data/rob_se_reg_labs_`var'_`hor'_FE_bw4", replace  ///
			addlabel(rhs,"`capvar'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", FE6, "", FE7, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

			
			
			
			
			
			
			
			}
}


* combine results for cpi and gdp:
use $temp_data/rob_se_reg_labs_cpi_current_FE_bw1.dta, clear
g database = 1
append using $temp_data/rob_se_reg_labs_gdp_current_FE_bw1
replace database = 2 if database == .
append using $temp_data/rob_se_reg_labs_cpi_future_FE_bw1
replace database = 3 if database == .
append using $temp_data/rob_se_reg_labs_gdp_future_FE_bw1
replace database = 4 if database == .
g n = _n
rename col_1 col_1

save $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE_bw1.dta, replace


use $temp_data/rob_se_reg_labs_cpi_current_FE_bw2.dta, clear
g database = 1
append using $temp_data/rob_se_reg_labs_gdp_current_FE_bw2
replace database = 2 if database == .
append using $temp_data/rob_se_reg_labs_cpi_future_FE_bw2
replace database = 3 if database == .
append using $temp_data/rob_se_reg_labs_gdp_future_FE_bw2
replace database = 4 if database == .
g n = _n
rename col_1 col_2

save $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE_bw2.dta, replace


use $temp_data/rob_se_reg_labs_cpi_current_FE_bw3.dta, clear
g database = 1
append using $temp_data/rob_se_reg_labs_gdp_current_FE_bw3
replace database = 2 if database == .
append using $temp_data/rob_se_reg_labs_cpi_future_FE_bw3
replace database = 3 if database == .
append using $temp_data/rob_se_reg_labs_gdp_future_FE_bw3
replace database = 4 if database == .
g n = _n
rename col_1 col_3

save $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE_bw3.dta, replace


use $temp_data/rob_se_reg_labs_cpi_current_FE_bw4.dta, clear
g database = 1
append using $temp_data/rob_se_reg_labs_gdp_current_FE_bw4
replace database = 2 if database == .
append using $temp_data/rob_se_reg_labs_cpi_future_FE_bw4
replace database = 3 if database == .
append using $temp_data/rob_se_reg_labs_gdp_future_FE_bw4
replace database = 4 if database == .
g n = _n
rename col_1 col_4

save $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE_bw4.dta, replace





* merge results to have wide table:
use $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE_bw1.dta, clear
sort database n
merge 1:1 database n using $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE_bw2.dta
drop _merge
sort database n
merge 1:1 database n using $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE_bw3.dta
drop _merge
sort database n
merge 1:1 database n using $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE_bw4.dta
drop _merge
sort database n

	
* clean the data
drop if var == "restr" | var == "_id" | strpos(var,"_cons")>0

* Fill up indicator variable:
gen indicator = col_4 if var == "rhs"
qui sort database indicator
by database indicator: replace indicator = indicator[_n-1] if indicator == "" 
qui gsort database -indicator
by database : replace indicator = indicator[_n-1] if indicator == ""

sort database n
bysort database: g count = _n 
replace indicator = "" if count >1

g noverall = _n
su noverall
local max = r(max)
drop if strpos(var,"FE") &  noverall < `max' - (7 +3)

drop if var == "rhs"
drop database n count noverall
replace var = "$ R^2 $" if var == "r2"

replace var = "Foreign" if var == "Foreign_coef"
replace var = "" if var == "Foreign_stderr"

replace var = "Country, For., Month FE" if var == "FE1"
replace var = "Country $ \times $ Year FE" if var == "FE2"
replace var = "Forecaster $ \times $ Year FE " if var == "FE3"
replace var = "Country $ \times $ Date FE" if var == "FE4"
replace var = "Forecaster $ \times $ Date FE " if var == "FE5"
replace var = "Subsample 1" if var == "FE6"
replace var = "Subsample 2" if var == "FE7"

order indicator

label var indicator "Variable"
label var var "Coefficient"
label var col_4 ""

save $temp_data/rob_se_reg_labs_bw, replace




* --------------------------
**# Regressions log(abs) for distinct updates
* ----------------------



use $dataout/baseline.dta, clear

sort idci datem
xtset idci datem
replace labs_FE_cpi_current_a1 = . if l.cpi_current == cpi_current & month != 1
replace labs_FE_cpi_current_a1 = . if l.cpi_future == cpi_current & month == 1
replace labs_FE_gdp_current_a1 = . if l.gdp_current == gdp_current & month != 1
replace labs_FE_gdp_current_a1 = . if l.gdp_current == gdp_current & month == 1
replace labs_FE_cpi_future_a1 = . if l.cpi_future == cpi_future & month != 1
replace labs_FE_gdp_future_a1 = . if l.gdp_future == gdp_future & month != 1

foreach var in cpi gdp  {
	
	foreach hor in current future {
		
		
		
		if "`hor'" == "current" {
			local time "t"
		}
		else if "`hor'" == "future"{
			local time "t+1"
		}
		
		if "`var'" == "cpi" {
			local capvar " $ \text{CPI}_{`time'} $ "
		}
		else if  "`var'" == "gdp" {
			local capvar " $ \text{GDP}_{`time'} $ "
		}
		
		cap drop used
		local FE idi#datem country_num#datem
		local se cluster idi datem country_num
		reghdfe labs_FE_`var'_`hor'_a1 Foreign, absorb(`FE') vce(`se')
		gen used = e(sample)
			
			
		
/*

* access lenght of panel:
-> 264
-> rule of thumb: 4 * ((T/100)^((2/9)))
*/


		* Fixed Effects:
		local FE idi#datem country_num#datem
		ivreghdfe labs_FE_`var'_`hor'_a1 Foreign if used == 1, absorb(`FE') cluster(idci datem) bw(4)
		regsave using "$temp_data/rob_se_reg_labs_`var'_`hor'_FE2_bw1", replace  ///
			addlabel(rhs,"`capvar'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", FE6, "\checkmark", FE7, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
			
		local FE idi#datem country_num#datem
		ivreghdfe labs_FE_`var'_`hor'_a1 Foreign if used == 1, absorb(`FE') cluster(idci datem) bw(5)
		regsave using "$temp_data/rob_se_reg_labs_`var'_`hor'_FE2_bw2", replace  ///
			addlabel(rhs,"`capvar'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", FE6, "\checkmark", FE7, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
		
		
		local FE idi#datem country_num#datem
		ivreghdfe labs_FE_`var'_`hor'_a1 Foreign if used == 1, absorb(`FE') cluster(idci datem) bw(6)
		regsave using "$temp_data/rob_se_reg_labs_`var'_`hor'_FE2_bw3", replace  ///
			addlabel(rhs,"`capvar'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", FE6, "\checkmark", FE7, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
			
		
		local FE idi#datem country_num#datem
		ivreghdfe labs_FE_`var'_`hor'_a1 Foreign if used == 1, absorb(`FE') cluster(idci datem) bw(7)
		regsave using "$temp_data/rob_se_reg_labs_`var'_`hor'_FE2_bw4", replace  ///
			addlabel(rhs,"`capvar'" , FE1, "", FE2, "", FE3, "", FE4, "\checkmark", FE5, "\checkmark", FE6, "\checkmark", FE7, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
			
			
			
			
	}
}



* combine results for cpi and gdp:
use $temp_data/rob_se_reg_labs_cpi_current_FE2_bw1.dta, clear
g database = 1
append using $temp_data/rob_se_reg_labs_gdp_current_FE_bw1
replace database = 2 if database == .
append using $temp_data/rob_se_reg_labs_cpi_future_FE_bw1
replace database = 3 if database == .
append using $temp_data/rob_se_reg_labs_gdp_future_FE_bw1
replace database = 4 if database == .
g n = _n
rename col_1 col_5
	
save $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE2_bw1.dta, replace
	
use $temp_data/rob_se_reg_labs_cpi_current_FE2_bw2.dta, clear
g database = 1
append using $temp_data/rob_se_reg_labs_gdp_current_FE_bw2
replace database = 2 if database == .
append using $temp_data/rob_se_reg_labs_cpi_future_FE_bw2
replace database = 3 if database == .
append using $temp_data/rob_se_reg_labs_gdp_future_FE_bw2
replace database = 4 if database == .
g n = _n
rename col_1 col_6
	
save $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE2_bw2.dta, replace	

use $temp_data/rob_se_reg_labs_cpi_current_FE2_bw3.dta, clear
g database = 1
append using $temp_data/rob_se_reg_labs_gdp_current_FE_bw3
replace database = 2 if database == .
append using $temp_data/rob_se_reg_labs_cpi_future_FE_bw3
replace database = 3 if database == .
append using $temp_data/rob_se_reg_labs_gdp_future_FE_bw3
replace database = 4 if database == .
g n = _n
rename col_1 col_7
	
save $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE2_bw3.dta, replace	


use $temp_data/rob_se_reg_labs_cpi_current_FE2_bw4.dta, clear
g database = 1
append using $temp_data/rob_se_reg_labs_gdp_current_FE_bw4
replace database = 2 if database == .
append using $temp_data/rob_se_reg_labs_cpi_future_FE_bw4
replace database = 3 if database == .
append using $temp_data/rob_se_reg_labs_gdp_future_FE_bw4
replace database = 4 if database == .
g n = _n
rename col_1 col_8
	
save $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE2_bw4.dta, replace	


* merge results to have wide table:
use $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE2_bw1.dta, clear
sort database n
merge 1:1 database n using $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE2_bw2.dta
drop _merge
sort database n
merge 1:1 database n using $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE2_bw3.dta
drop _merge
sort database n
merge 1:1 database n using $temp_data/rob_se_reg_labs_cpi_gdp_current_future_FE2_bw4.dta
drop _merge
sort database n



	
* clean the data
drop if var == "restr" | var == "_id" | strpos(var,"_cons")>0

* Fill up indicator variable:
gen indicator = col_8 if var == "rhs"
qui sort database indicator
by database indicator: replace indicator = indicator[_n-1] if indicator == "" 
qui gsort database -indicator
by database : replace indicator = indicator[_n-1] if indicator == ""

sort database n
bysort database: g count = _n 
replace indicator = "" if count >1

g noverall = _n
su noverall
local max = r(max)
drop if strpos(var,"FE") &  noverall < `max' - (7 +3)

drop if var == "rhs"
drop database n count noverall
replace var = "$ R^2 $" if var == "r2"

replace var = "Foreign" if var == "Foreign_coef"
replace var = "" if var == "Foreign_stderr"

replace var = "Country, For., Month FE" if var == "FE1"
replace var = "Country $ \times $ Year FE" if var == "FE2"
replace var = "Forecaster $ \times $ Year FE " if var == "FE3"
replace var = "Country $ \times $ Date FE" if var == "FE4"
replace var = "Forecaster $ \times $ Date FE " if var == "FE5"
replace var = "Subsample 1" if var == "FE6"
replace var = "Subsample 2" if var == "FE7"

order indicator

label var indicator "Variable"
label var var "Coefficient"
label var col_8 ""

save $temp_data/rob_se_reg_labs_distinct_bw, replace



* --------------------------
**# Table labs with all and distinct
* --------------------------


use $temp_data/rob_se_reg_labs_bw, clear
merge 1:1 _n using $temp_data/rob_se_reg_labs_distinct_bw

drop _merge

label var col_1 "BW 4"
label var col_2 "BW 5"
label var col_3 "BW 6"
label var col_4 "BW 7"

label var col_5 "BW 4"
label var col_6 "BW 5"
label var col_7 "BW 6"
label var col_8 "BW 7"


* add empty column:

g empty = ""

order indicator var col_1 col_2 col_3 col_4 empty col_5 col_6 col_7 col_8

preserve
drop if var == "Country, For., Month FE"
drop if var == "Country $ \times $ Year FE"
drop if var == "Forecaster $ \times $ Year FE "
drop if var == "Subsample 1"
drop if var == "Subsample 2"
drop if var == "$ R^2 $"

texsave indicator var col_1 col_2 col_3 col_4 empty col_5 col_6 col_7 col_8 using "$tables/rob_se_tab_labs_withdistinct_bw.tex", ///
	title("Forecast Errors $\ln(|Error_{ijt,t}^m|)$ using Driscoll-Kraay Standard Errors with different Bandwidths") varlabels nofix hlines(0) headersep(0pt) ///
	headerlines("{}&{}&\multicolumn{4}{c}{Entire Sample}&{}&\multicolumn{4}{c}{Distinct Updates} \tabularnewline \cline{3-6} \cline{8-11} \tabularnewline &&{(1)}&{(2)}&{(3)}&{(4)}&&{(5)}&{(6)}&{(7)}&{(8)}") ///
frag  size(footnotesize)  align(l l C C C C m{0.01\textwidth} C C C C) location(H) replace label(tab:rob_se_errors_) footnote("\begin{minipage}{1\linewidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) to (4) show the regression of the log absolute forecast error on the location of the forecaster using different bandwidths. Columns (5) to (6) show the same regression using the subsample of the published forecasts that are distinct from the last published one, again for different bandwidths. \end{tabnote} \end{minipage}  ") 
restore






