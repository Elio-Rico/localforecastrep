********************************************************************************
*
*						CONSENSUS ECONOMICS DATA
*
********************************************************************************




* PRELIMINARIES
******************


clear all
set more off


global data "C:\Users\eliob\Dropbox\4Foreign vs local expectations\Data\data_output"
global path "C:\Users\eliob\Dropbox\4Foreign vs local expectations\EmpiricalResults"
global figures "$path\Results_AnalysisRegressions\Figures"


cd "$path"


* create folders if non-existant:

/*
mata : mata clear

mata : st_numscalar("OK", direxists("Results_AnalysisRegressions"))
 if scalar(OK) == 0 {
	mkdir "Results_AnalysisRegressions"

 }
mata : mata clear


mata : st_numscalar("OK", direxists("Results_AnalysisRegressions\Figures"))
 if scalar(OK) == 0 {
	mkdir "Results_AnalysisRegressions\Figures"
}


mata : mata clear


mata : st_numscalar("OK", direxists("Results_AnalysisRegressions\Tables"))
 if scalar(OK) == 0 {
	mkdir "Results_AnalysisInstitutions\Tables"
}

*/



********************************************************************************


use "$data/DATA.dta", clear


* We do have quite large errors between 1995 and 2000. 

/*
preserve

	keep if country == "United States"

	collapse FE_gdp_current gdp_current gdp_imf_current, by (date)

	graph twoway (line  gdp_current date) (line  gdp_imf_current date)

restore

*/

* we will load additional GDP data from the vintage series from the FRED. 

* note: if we compare the newest "vintage" data, with the IMF gdp of the United States, they are the same.

import excel "C:\Users\eliob\Dropbox\4Foreign vs local expectations\Data\vintage\FRED\ROUTPUTQvQd.xlsx", sheet("ROUTPUT") firstrow clear

gen date = yq(real(substr(DATE, 1,4)),real(substr(DATE, -1,1)))
format date %tq

drop DATE
order date


foreach var of varlist ROUTPUT* {
	
	 capture confirm string variable `var'
       if !_rc {
	   
	   replace `var' = "" if `var' == "#N/A"
        destring `var', replace
        }

}



* We can only keep those variables with "Q1" because they contain all information to calculate the yearly growth rate.
* Note that Q1 just refers to the published series at first quarter, which contains values (normally) up to the 4th quarter of GDP.

drop ROUTPUT*Q3
drop ROUTPUT*Q2
drop ROUTPUT*Q4


g year = yofd(dofq(date))


* We calculate the sum of all quarterly GDP outcomes
collapse (sum) ROUTPUT*, by(year)



foreach var of varlist ROUTPUT* {
	
replace `var' = . if `var' == 0

}


* Now, we can calculate the growth rates of yearly GDP

tset year


foreach var of varlist ROUTPUT* {
	
g g`var' = (`var'[_n]/`var'[_n-1] -1)*100

}


keep year g*

keep if year > 1978

dropmiss, force





* create single dataset for each vintage:
foreach var of varlist gROUTPUT* {

preserve


	keep year `var'


	local dte = substr("`var'", 9, 4) // substring indicating the date of the release
	g strdate = "`dte'"

	local yr = substr("`var'", 9, 2) // substring indicating the year
	g yr = "`yr'"
	destring yr, replace

	* formatting the year
	if yr >22 {

	replace strdate = "19" + strdate  
		
	} 
	else {

	replace strdate = "20" + strdate 
	}


	gen dateyear = substr(strdate, 1,4)
	gen datequarter = substr(strdate, 6,1)

	destring dateyear, replace
	destring datequarter, replace
	drop strdate
	drop yr

	gen date = yq(dateyear, datequarter)

	format date %tq

	drop dateyear
	drop datequarter
	drop if year == .


	*local savedt = substr(date, 9, 4)


	su date if year < 2020
	local date: disp %tq r(mean)
	di "`date'"

	rename `var' gdp_fred_vintage

	save "us_`date'.dta", replace

restore


}


***************************************************************************



forval x = 1979(1)2020{



* 1979 is the first year we include GDP data from. However, the first RELEASE that contains this information is the dataset of 1980.
* Hence, we increase x by one to access the data. 
local set = `x' + 1

local strset = "us_" + "`set'" + "q1.dta"

disp("`strset'")


use "`strset'", clear

* We then only keep the most recent estimate, hence, from the database use 1980q1 we only keep the estimate of 1979
drop if year != `set' -1


drop date


save "`strset'", replace

sleep 500


}


***************************************************************************




* CALCULATE FORECAST REVISION
use "$data/DATA.dta", clear

keep if country == "United States"

keep date datem gdp_current gdp_future year_forecast_current_gdp year_forecast_future_gdp institution

sort date

* match current gdp

*preserve

* we rename the variable year_forecasT_current_gdp which corresponds to the date that the current forecast refers to, to "year".
* We then match this year with the year in the vintage data series.
rename year_forecast_current_gdp year

forval x = 1979(1)2020{

	local set = `x' + 1

	local strset = "us_" + "`set'" + "q1.dta"

	merge m:1 year using `strset', update
	drop _merge

}

rename year year_forecast_current_gdp
rename gdp_fred_vintage gdp_fred_vintage_current


drop if institution == ""


* For the future forecast, we do the same. We now match the future value with the closest "information set"
* future forecast
rename year_forecast_future_gdp year

forval x = 1979(1)2020{

	local set = `x' + 1

	local strset = "us_" + "`set'" + "q1.dta"

	merge m:1 year using `strset', update
	drop _merge

}

rename year year_forecast_future_gdp
rename gdp_fred_vintage gdp_fred_vintage_future


drop if institution == ""



keep institution date datem gdp_fred*


save us_vintage.dta, replace



forval x = 1979(1)2020{

	local set = `x' + 1

	local strset = "us_" + "`set'" + "q1.dta"

	erase `strset'

	sleep 500
}


********************************************************************************

* ONLY UNTIED STATES

* CALCULATE FORECAST REVISION
use "$data/DATA.dta", clear

keep if country == "United States"


merge 1:1 date datem institution using us_vintage.dta
drop _merge





************************
* FORECAST ERRORS
************************

* GDP
bysort  id (date): gen FE_gdp_current_vint = gdp_fred_vintage_current - gdp_current
bysort  id (date): gen FE_gdp_future_vint = gdp_fred_vintage_future - gdp_future




* We do have quite large errors between 1995 and 2000. 
preserve
	
	g year = yofd(dofm(datem))
	
	drop if year == 1995

	
	drop if year > 2018
	
	collapse FE_gdp_current gdp_current gdp_imf_current FE_gdp_current_vint FE_gdp_future_vint gdp_fred_vintage_current gdp_fred_vintage_future, by (date)

	graph twoway (line  gdp_current date) (line  gdp_imf_current date) , name(g1,replace)
	graph export "Results_Vintage\average_FC_withoutVintage.pdf",  replace 
	
	graph twoway (line  gdp_current date) (line  gdp_fred_vintage_current date) , name(g2,replace)
	graph export "Results_Vintage\average_FC_withVintage.pdf",  replace 
	
restore

preserve

collapse FE_gdp_current FR_gdp_current gdp_current  gdp_imf_current FE_gdp_current_vint FE_gdp_future_vint gdp_fred_vintage_current gdp_fred_vintage_future, by (date local_2)

reg FE_gdp_current_vint FR_gdp_current

reg FE_gdp_current_vint FR_gdp_current if local_2 == 1

reg FE_gdp_current_vint FR_gdp_current if local_2 == 2



*reg FE_gdp_current FR_gdp_current 

restore




reghdfe FE_gdp_current_vint FR_gdp_current , absorb(institution datem) vce(clu id date)

