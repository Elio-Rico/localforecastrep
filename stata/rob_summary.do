

********************************************************************************
********************************************************************************
* 							ROBUSTNESS CHECKS
********************************************************************************
********************************************************************************

clear all
set more off

cd "/Users/ebollige/Dropbox/1_1_replication_forecasters/localforecastrep/stata/"

* do file location:
local dofile = "`c(pwd)'"
disp "`dofile'" 
local parent = substr("`dofile'", 1, strrpos("`dofile'", "/")-1)

* Append the desired subfolder
local target = "`parent'/data"
global dataout "`target'"
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

save $dataout/rob_a2.dta, replace


/*

* note that LocFor is
drop if location==.

gen Foreign = (location_narrow==2)
gen Local = (location_narrow==1)

sort institution datem
by institution datem: egen loc = max(Local)
by institution datem: egen for = max(Foreign)
gen locfor = loc*for
*/


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


