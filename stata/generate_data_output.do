********************************************************************************
*
*						CONSENSUS ECONOMICS DATA
*
********************************************************************************

/*



*/

* PRELIMINARIES
******************

clear all
set more off

cd "/Users/ebollige/Dropbox/1_1_replication_forecasters/localforecastrep/stata/"

* do file location:
local dofile = "`c(pwd)'"
disp "`dofile'" 
local parent = substr("`dofile'", 1, strrpos("`dofile'", "/")-1)

* Append the desired subfolder
local target = "`parent'/inst/data/produced/ce"
global datace "`target'"
local target = "`parent'/inst/data/produced/imf"
global imfvintage "`target'"
local target = "`parent'/inst/data/produced/ce_imf"
global datace_imf "`target'"
local target = "`parent'/inst/data/raw/crises"
global crises "`target'"
local target = "`parent'/inst/data/raw/eikon"
global eikon "`target'"
local target = "`parent'/inst/data/produced/crises"
global crisesf "`target'"
local target = "`parent'/inst/data/produced/eikon"
global eikonf "`target'"
local target = "`parent'/inst/data/raw/recession"
global recession "`target'"
local target = "`parent'/inst/data/produced/recession"
global recessionf "`target'"
local target = "`parent'/inst/data/raw/indprod"
global indprod "`target'"
local target = "`parent'/inst/data/produced/indprod"
global indprodf "`target'"
local target = "`parent'/inst/data/raw/epu"
global epu "`target'"
local target = "`parent'/inst/data/produced/epu"
global epuf "`target'"
local target = "`parent'/inst/data/raw/icrg"
global icrg "`target'"
local target = "`parent'/inst/data/produced/icrg"
global icrgf "`target'"
local target = "`parent'/inst/data/raw/gravity"
global gravity "`target'"
local target = "`parent'/inst/data/produced/gravity"
global gravityf "`target'"
local target = "`parent'/inst/data/raw/bis"
global bis "`target'"
local target = "`parent'/inst/data/produced/bis"
global bisf "`target'"
local target = "`parent'/inst/data/produced/worldbank"
global worldbankf "`target'"
local target = "`parent'/inst/data/produced/vix"
global vixf "`target'"
local target = "`parent'/inst/data/raw/vix"
global vix "`target'"
local target = "`parent'/inst/data/raw/stock_market"
global sm "`target'"
local target = "`parent'/inst/data/produced/stock_market"
global smf "`target'"
local target = "`parent'/inst/data/raw/msci"
global msci "`target'"
local target = "`parent'/inst/data/produced/msci"
global mscif "`target'"
local target = "`parent'/data"
global output "`target'"
local target = "`parent'/inst/data/produced/temp"
global temp "`target'"
local target = "`parent'/inst/data/produced/cultdist"
global cultdistf "`target'"
local target = "`parent'/inst/data/raw/cultdist"
global cultdist "`target'"
local target = "`parent'/inst/data/raw/migration"
global migration "`target'"
local target = "`parent'/inst/data/produced/migration"
global migrationf "`target'"
local target = "`parent'/inst/data/raw/regime"
global regime "`target'"
local target = "`parent'/inst/data/produced/regime"
global regimef "`target'"
local target = "`parent'/inst/data/raw/exp_imp"
global expimp "`target'"
local target = "`parent'/inst/data/produced/exp_imp"
global expimpf "`target'"
local target = "`parent'/inst/data/raw/tariff"
global tariff "`target'"
local target = "`parent'/inst/data/produced/tariff"
global tarifff "`target'"
local target = "`parent'/inst/data/raw/wdi"
global wdi "`target'"
local target = "`parent'/inst/data/produced/wdi"
global wdif "`target'"
local target = "`parent'/inst/data/raw/fkrsu"
global fkrsu "`target'"
local target = "`parent'/inst/data/produced/fkrsu"
global fkrsuf "`target'"
local target = "`parent'/inst/data/produced/stacked_temp"
global stempf "`target'"

* switch to data directory:
cd $datace
* Check


*******************
*				  *
*		GDP 	  *
*				  *
*******************


use "$datace/df_gdp_stata.dta", clear

* transform variables
destring local, replace
destring local_2, replace
destring year_forecast, replace

* get formatting/type of current right:
g Dcurrent = current - 1
drop current
rename Dcurrent current


* FROM WIDE TO LONG
*******************

* from long to wide (partially)
sort country date current local_2

rename value gdp

g gdp_current = gdp if current == 1
g gdp_future = gdp if current == 0

g year_forecast_current_gdp = year_forecast if current == 1
g year_forecast_future_gdp = year_forecast if current == 0
 
keep gdp_current gdp_future institution country date current local local_2 year_forecast_current_gdp year_forecast_future_gdp

collapse gdp_current gdp_future local local_2 year_forecast_current_gdp year_forecast_future_gdp, by(country date institution)

egen id = group(country institution)

* NEW LOCATION VAR
*******************
* Create location variable (simply the same variable as local_2 but rearranged and with labels)
g location = 1 if local_2 == 1
replace location = 2 if local_2 == 3
replace location = 3 if local_2 == 2


label define location 1 "Local" 2 "Foreign" 3 "Multinational", modify
label values location location

* Get numerical variable for country, with labels that correspond to the country
encode country, gen(country_num)


* harmonize date variable
g day = day(date)
g month = month(date)
g year = year(date)

g dates = mdy(month,day,year)

drop day month year

drop date
rename dates date
format date %td

* monthly date variable 
gen datem = mofd(date)
format datem %tm


save "$datace/df_gdp_stata_cleaned.dta", replace


*******************
*				  *
*	 INFLATION 	  *
*				  *
*******************

use "$datace/df_cpi_stata.dta", clear

* recode current
g Dcurrent = current - 1
drop current
rename Dcurrent current

rename value cpi


* some initial cleaning
destring year_forecast, replace

g day = day(date)
g month = month(date)
g year = year(date)

g dates = mdy(month,day,year)

drop day month year

drop date
rename dates date
format date %td


g cpi_current = cpi if current == 1
g cpi_future = cpi if current == 0


g year_forecast_current_cpi = year_forecast if current == 1
g year_forecast_future_cpi = year_forecast if current == 0


keep cpi_current cpi_future institution country date current year_forecast_current_cpi year_forecast_future_cpi

sort country date current

collapse cpi_current cpi_future year_forecast_current_cpi year_forecast_future_cpi, by(country date  institution)


save "$datace/df_cpi_stata_cleaned.dta", replace



*************************
*
*		MERGE
*
*************************

use "$datace/df_gdp_stata_cleaned.dta", clear 

merge 1:1 date country institution using "$datace/df_cpi_stata_cleaned.dta"
drop if _merge == 1
drop _merge


*current account vintage is added later on
g country_upper = upper(country)
rename country country_or
rename country_upper country

drop country
rename country_or country
save "$datace/data_withoutVintage.dta", replace

********************************************************************************
* ADD VINTAGE DATA


use "$imfvintage/vintages.dta" ,clear


* new descriptor variable
g var = ""
replace var = "rGDP" if descriptor == "Gross domestic product, constant prices"
replace var = "cpi" if descriptor == "Inflation"
drop if descriptor == "Unemployment rate"
drop if descriptor == "Current account balance"


drop descriptor
order year country var

* assign narrower format for country variable to make browsing easier
format %24s country
sort country var year  
drop *_EST*


foreach vintage in tp1 tp2 tp3 {
	
	if "`vintage'" == "tp1" {
	
	local ticker = 1999
	}
	else if "`vintage'" == "tp2" {
	
	local ticker = 2000
	}
	else if "`vintage'" == "tp3" {
	
	local ticker = 2001
	}
	


* For the first dataset, april 1999, we keep all data until 1998:

preserve

	keep year country var WEO`ticker'_apr

	drop if year > 1999

	drop if WEO`ticker'_apr == .

	
	sort country var year  
	
	g future = 0 if year == 1998
	replace future = 1 if year == 1999
	
	rename WEO`ticker'_apr vintage_apr
	

	save $imfvintage/weo_apr_1999_`vintage'.dta, replace

	

restore

}



* For all following years, we will keep two datapoints, for current and future vintage. 


	
foreach vintage in tp1 tp2 tp3 {
	
	if "`vintage'" == "tp1" {
	
		local yrmax = 2020
	}
	else if "`vintage'" == "tp2" {
		
		local yrmax = 2019
	}
	else if "`vintage'" == "tp2" {
		
		local yrmax = 2018
	}
	
	
	forval year = 2000(1)`yrmax' {
	

		if "`vintage'" == "tp1" {
		
		local ticker = `year'
		}
		else if "`vintage'" == "tp2" {
		
		local ticker = `year' + 1
		}
		else if "`vintage'" == "tp3" {
		
		local ticker = `year' + 2
		}
	
	
	* april
	preserve
	

		local vr = "WEO" + "`ticker'" + "_apr"
		
		disp("`vr'")
		
		
		capture confirm variable `vr'
		if !_rc {
                    
			
			keep year country var `vr'
			
			local yr = `year' - 1 
			
			drop if year > `year'
			
			drop if `vr' == .
			
			drop if year < `year' - 1
			
			sort country var year  
			
			rename `vr' vintage_apr
			
			g future = 0 if year == `year'-1
			replace future = 1 if year == `year'
			
			
			* reshape from long to wide for matching
			*reshape wide WEO_ , i(country) j(year)
			
			sleep 500
			
			save "$imfvintage/weo_apr_`year'_`vintage'.dta", replace
		}
               

	restore


		* september
	preserve

		local vr = "WEO" + "`ticker'" + "_sep"
		
		disp("`vr'")
		
		
		capture confirm variable `vr'
		if !_rc {
		
			keep year country var `vr'
			
			local yr = `year' - 1 
			
			drop if year > `year'
			
			drop if `vr' == .
			
			drop if year < `year' - 1
			
			sort country var year  
			
			rename `vr' vintage_sep
			
			g future = 0 if year == `year'-1
			replace future = 1 if year == `year'
			
			
			save "$imfvintage/weo_sep_`year'_`vintage'.dta", replace
			
		}


	restore
	
	}

}


* Now, we append all april vintage data

foreach vintage in tp1 tp2 tp3 {
	
		if "`vintage'" == "tp1" {
	
		local yrmax = 2020
	}
	else if "`vintage'" == "tp2" {
		
		local yrmax = 2019
	}
	else if "`vintage'" == "tp2" {
		
		local yrmax = 2018
	}
	
	* APRIL
	use $imfvintage/weo_apr_1999_`vintage'.dta, clear

	forval year = 2000(1)`yrmax' {

	
	capture confirm file $imfvintage/weo_apr_`year'_`vintage'.dta
	if !_rc {
	
	append using $imfvintage/weo_apr_`year'_`vintage'.dta
	
	}

	}

	sort country var year 

	g country_upper = country

	drop country

	replace future = 0 if year < 1999

	save $imfvintage/weo_apr_vintage_`vintage'.dta, replace


	* same for september updates
	* SEPTEMBER
	use $imfvintage/weo_apr_1999_`vintage'.dta, clear

	rename vintage_apr vintage_sep

	forval year = 2000(1)`yrmax' {

	
	capture confirm file $imfvintage/weo_sep_`year'_`vintage'.dta
	if !_rc {
		append using $imfvintage/weo_sep_`year'_`vintage'.dta
	}
	
	

	}

	sort country var year 

	g country_upper = country

	drop country


	replace future = 0 if year < 1999

	save $imfvintage/weo_sep_vintage_`vintage'.dta, replace

	forval year = 1999(1)`yrmax' {

	capture erase $imfvintage/weo_apr_`year'_`vintage'.dta
	}
	forval year = 2000(1)`yrmax' {
	capture erase $imfvintage/weo_sep_`year'_`vintage'.dta
	}

}



* NOW, WE CREATE THE VINTAGE SERIES: TAKE FROM EACH FILE THE VALUES FOR CURRENT AND FUTURE GDP, CPI, ETC.


foreach vintage in tp1 tp2 tp3 {
use $imfvintage/weo_sep_vintage_`vintage'.dta, clear


* SEPTEMBER FILES:
******************

* cpi current and future

foreach hor in current future {
		
	preserve

	keep if var == "cpi"

	* reshape it from wide to long

	reshape wide vintage_sep, i(year country) j(future) 

	sort country_upper year

	rename vintage_sep0 vintage_cpi_current_sep`vintage'

	rename vintage_sep1 vintage_cpi_future_sep`vintage'

	drop var

	keep year country_upper vintage_cpi_`hor'_sep`vintage'
	
	rename year year_forecast_`hor'_cpi

	save $imfvintage/weo_sep_vintage_cpi_`hor'_`vintage'.dta,replace

	restore

}


* gdp current and future


foreach hor in current future {
	
	preserve

	keep if var == "rGDP"

	* reshape it from wide to long

	reshape wide vintage_sep, i(year country) j(future) 

	sort country_upper year

	rename vintage_sep0 vintage_gdp_current_sep`vintage'

	rename vintage_sep1 vintage_gdp_future_sep`vintage'

	drop var

	keep year country_upper vintage_gdp_`hor'_sep`vintage'
	
	rename year year_forecast_`hor'_gdp

	save $imfvintage/weo_sep_vintage_gdp_`hor'_`vintage'.dta,replace

restore
}






* APRIL FILES
**************

use $imfvintage/weo_apr_vintage_`vintage'.dta, clear


* cpi current and future

foreach hor in current future {
		
	preserve

	keep if var == "cpi"

	* reshape it from wide to long

	reshape wide vintage_apr, i(year country) j(future) 

	sort country_upper year

	rename vintage_apr0 vintage_cpi_current_apr`vintage'

	rename vintage_apr1 vintage_cpi_future_apr`vintage'

	drop var

	keep year country_upper vintage_cpi_`hor'_apr`vintage'
	
	rename year year_forecast_`hor'_cpi

	save $imfvintage/weo_apr_vintage_cpi_`hor'_`vintage'.dta,replace

	restore

}


* gdp current and future


foreach hor in current future {
	
	preserve

	keep if var == "rGDP"

	* reshape it from wide to long

	reshape wide vintage_apr, i(year country) j(future) 

	sort country_upper year

	rename vintage_apr0 vintage_gdp_current_apr`vintage'

	rename vintage_apr1 vintage_gdp_future_apr`vintage'

	drop var

	keep year country_upper vintage_gdp_`hor'_apr`vintage'
	
	rename year year_forecast_`hor'_gdp

	save $imfvintage/weo_apr_vintage_gdp_`hor'_`vintage'.dta,replace

restore
}



}



/*
Now, we can merge this data with our original database! Note that we will 
merge as follows:

For the forecast of year 2010 gdp, we will use data from the IMF that was published at least 1 year later 
hence, we will use data from the file 2011 april file, for vintage series 

Then, we will use the april file to match for months april to august (or septemer), and then the september file, to match from september (or october)
to march.

*/


* APRIL VINTAGES
use "$datace/data_withoutVintage.dta", replace

g month = month(date)

order country country_num institution id date datem   month

g country_upper = upper(country)


foreach vintage in tp1 tp2 tp3{
* gdp:
foreach hor in current future {
merge m:1 country_upper year_forecast_`hor'_gdp using $imfvintage/weo_apr_vintage_gdp_`hor'_`vintage'.dta
drop if _merge == 2
drop _merge

}


* cpi:
foreach hor in current future {
merge m:1 country_upper year_forecast_`hor'_cpi using $imfvintage/weo_apr_vintage_cpi_`hor'_`vintage'.dta
drop if _merge == 2
drop _merge

}




* SEPTEMBER VINTAGES

* gdp:
foreach hor in current future {
merge m:1 country_upper year_forecast_`hor'_gdp using $imfvintage/weo_sep_vintage_gdp_`hor'_`vintage'.dta
drop if _merge == 2
drop _merge

}


* cpi:
foreach hor in current future {
merge m:1 country_upper year_forecast_`hor'_cpi using $imfvintage/weo_sep_vintage_cpi_`hor'_`vintage'.dta
drop if _merge == 2
drop _merge

}


}



* now we have all vintage series. depending on the month, we use now data from vintage september of october
g year = year(date)


******************************

* add vintage data from the US that comes from FRED

/*
preserve

use "$empRes/us_vintage.dta",clear

g country = "United States"

save us_vintage_ctry.dta, replace

restore


merge 1:1 date datem institution country using us_vintage_ctry.dta
drop _merge
*/





********************************************************************************
* standard stuff
foreach var in gdp_current gdp_future cpi_current cpi_future  {

	* Generate the mean of all local institutions for each date and country
	egen mean_local_`var' = mean(`var')  if local_2 == 1, by(country date)
	egen max_mean_local_`var' = max(mean_local_`var'), by(country date)

	cap drop `var'_diff_local
	g `var'_diff_local = `var' - max_mean_local_`var'


	* Create the share of foreign institutions versus multinational versus local pS = per servey
	cap drop `var'_nobs_pS
	* number of observations per survey (total number of forecasts for each date and horizon). Missing values are not counted
	egen `var'_nobs_pS = count(`var') , by(country date)

	* count number of forecasts for each date and horizon conditional on the location. note that, if there is a missing observation
	* it is excluded!
	egen `var'_nobs_local_pS = count(`var') if local_2 == 1, by(country date)
	egen `var'_nobs_foreign_pS = count(`var') if local_2 == 3, by(country date)
	egen `var'_nobs_multi_pS = count(`var') if local_2 == 2, by(country date)

	egen `var'_nobs_by_location = rowmax(`var'_nobs_local_pS `var'_nobs_foreign_pS `var'_nobs_multi_pS)

	* Share
	g `var'_share = `var'_nobs_by_location / `var'_nobs_pS

}


 
 
 
*****************
* LABELLING
*****************

label var id "Unique id for each institution per country"


foreach var in gdp_future_share gdp_current_share cpi_future_share cpi_current_share {

label var `var' "Share Control"

}


foreach var in gdp_future_nobs_pS gdp_current_nobs_pS cpi_future_nobs_pS cpi_current_nobs_pS {

label var `var' "\$ \# \$ Obs. Control"

}


*rop *harm*

order country country_num institution id date datem gdp_current gdp_future cpi_current cpi_future 





* With the variable minbyid you can condition on instiutionts that have certain number of observations.

foreach var in gdp_current gdp_future cpi_current cpi_future  {

cap drop totalbyid_`var'
egen totalbyid_`var' = total(!missing(`var')), by(id)

}

egen minbyid = rowmin(totalbyid_gdp_current totalbyid_gdp_future totalbyid_cpi_current totalbyid_cpi_future)



save "$datace_imf/DATA2_NewVintage.dta", replace


foreach var in gdp cpi  {
	foreach hor in current future {
		foreach month in sep apr {
			foreach vintage in tp1 tp2 tp3{
			
				capture erase "$imfvintage/weo_`month'_vintage_`var'_`hor'_`vintage'.dta"
				
				capture erase "$imfvintage/weo_`month'_vintage_`vintage'.dta"
			
			}
		
		}
		
	}
	
}



********************************************************************************



* clean names of institutions

replace institution = upper(institution)
replace institution = stritrim(institution)
replace institution = strtrim(institution)
sort institution


replace institution = "ABN AMRO BANK" if strmatch(institution, "*ABN AMRO*")
replace institution = "ACRA" if strmatch(institution, "*ACRA*")
replace institution = "ANZ BANK" if strmatch(institution, "ANZ*BANK")
replace institution = "ALBARAKA TURK BANK" if strmatch(institution, "ALBARAKA*")
replace institution = "ALPHA FINANCE" if strmatch(institution, "ALPHA*")
replace institution = "AM SECURITIES" if strmatch(institution, "AM*SEC*")
replace institution = "AMP" if strmatch(institution, "AMP*")
replace institution = "AZPURUA GARCIA VELAZQUEZ" if strmatch(institution, "AZPURUA*")
replace institution = "BANCA NZLE DEL LAVORO" if strmatch(institution, "*NZLE*")
replace institution = "BANCO DE CREDITO DEL PERU" if strmatch(institution, "*CREDITO*PERU")
replace institution = "BANCO DI ROMA" if strmatch(institution, "*BANCA DI ROMA*")
replace institution = "BANCO SANTIAGO" if strmatch(institution, "BANCO*SANTIAGO*")
replace institution = "BANCOLOMBIA" if strmatch(institution, "BANCOLOMBIA*")
replace institution = "BANESCO BANCO UNIVERSAL" if strmatch(institution, "BANESCO*")
replace institution = "BANK AMERICA CORP" if strmatch(institution, "BANK OF AMERICA*")
replace institution = "BANK AMERICA MERRILL LYNCH" if strmatch(institution, "*MERRILL*")
replace institution = "BANK OF CHINA" if strmatch(institution, "BANK OF CHINA*")
replace institution = "BANK OF TOKYO-MITSUBISHI UFJ" if strmatch(institution, "*TOKYO*MITSUBISHI*") // changed
replace institution = "BANK OF BOSTON" if strmatch(institution, "*BANKBOSTON*")
replace institution = "BANQUE POPULAIRE" if strmatch(institution, "BANQUES POP*")
replace institution = "BARCLAYS CAPITAL" if strmatch(institution, "BARCLAYS CAPITAL*") //changed
replace institution = "BARING SECURITIES" if strmatch(institution, "BARING*")
replace institution = "BAYERISCHE LBANK" if strmatch(institution, "BAYERISCHE L*") // changed
replace institution = "BAYERN LB" if strmatch(institution, "BAYERN*LB*") // changed
replace institution = "BBVA" if strmatch(institution, "BBVA*")
replace institution = "BERLINER SPARKASSE" if strmatch(institution, "BERLINER BANK*")
replace institution = "BIPE" if strmatch(institution, "BIPE*")
replace institution = "PARIBAS" if strmatch(institution, "*PARIBAS*")
replace institution = "BPH" if strmatch(institution, "BPH*")
replace institution = "C COMERCIO SANTIAGO" if strmatch(institution, "*COMERCIO SANTIAGO*")
replace institution = "CAISSE DE DEPOT" if strmatch(institution, "CAISSE DES DEPOTS*")
replace institution = "CAMBRIDGE ECONOMETRICS" if strmatch(institution, "CAMBRIDGE ECON*")
replace institution = "CDE - DSE" if strmatch(institution, "CDE*DSE*")
replace institution = "CENTRO EUROPA RICERCHE" if strmatch(institution, "CENTRO EUROP*")
replace institution = "CHASE MANHATTAN" if strmatch(institution, "CHASE*")
replace institution = "CIBC" if strmatch(institution, "CIBC*MARK*") // changed
replace institution = "CIMB" if strmatch(institution, "CIMB*")
replace institution = "CITADELE BANK" if strmatch(institution, "CITADELE*")
replace institution = "CITIGROUP" if strmatch(institution, "*CITI*") & institution != "CITIGROUP 2" // changed
replace institution = "CITY UNIV BUSINESS SCHOOL" if strmatch(institution, "CITY UNIV*")
replace institution = "CONFED OF BRITISH INDUSTRY" if strmatch(institution, "CON*BRITISH IND*")
replace institution = "CORFICOLOMBIANA" if strmatch(institution, "CORFICOL*")
replace institution = "CORP GROUP" if strmatch(institution, "CORP*")
replace institution = "COYUNTURA" if strmatch(institution, "COYUNTURA*")
replace institution = "CREDIT COMM DE FRANCE" if strmatch(institution, "CREDIT COMM*")
replace institution = "CREDIT LYONNAIS" if strmatch(institution, "CREDIT LYONNAIS*")
replace institution = "CREDIT NATIONAL BFCE" if strmatch(institution, "*CREDIT NATIONAL*")
replace institution = "CREDIT SUISSE" if strmatch(institution, "*CREDIT SUISSE*")
replace institution = "CSOB" if strmatch(institution, "CSOB*")
replace institution = "DAEWOO" if strmatch(institution, "DAEWOO*")
replace institution = "CHRYSLER SECURITIES" if strmatch(institution, "*CHRYSLER")
replace institution = "DAISHIN RESEARCH" if strmatch(institution, "DAISHIN*")
replace institution = "DAIWA SECURITIES" if strmatch(institution, "DAIWA*")
replace institution = "DANARESKSA SECURITIES" if strmatch(institution, "DANAREKSA*")
replace institution = "DBS BANK" if strmatch(institution, "DBS*")
replace institution = "DELBRUCK & CO" if strmatch(institution, "DELBRUCK*")
replace institution = "DESORMEAUX Y ASOC" if strmatch(institution, "DESORMEAUX*")
replace institution = "DEUTSCHE BANK" if strmatch(institution, "DEUTSCHE*BANK*") // changed
replace institution = "DEXIA BANK" if strmatch(institution, "DEXIA*")
replace institution = "DIW BERLIN" if strmatch(institution, "DIW*")
replace institution = "DNB" if strmatch(institution, "DNB*")
replace institution = "DONGSUH SECURITIES" if strmatch(institution, "DONGSUH*")
replace institution = "DUPONT" if strmatch(institution, "DUPONT*")
replace institution = "EATON CORPORATION" if strmatch(institution, "EATON*")
replace institution = "ECO GO" if strmatch(institution, "ECO GO*")
replace institution = "ECONOMIST INTELLIGENCE UNIT" if strmatch(institution, "ECON*INTELLIGENCE*")
replace institution = "ERSTE BANK" if strmatch(institution, "ERSTE*")
replace institution = "EUROMONITOR INTERNATIONAL" if strmatch(institution, "EUROMONITOR*")
replace institution = "EXANE BNP" if strmatch(institution, "EXANE*")
replace institution = "EXPERIAN" if strmatch(institution, "EXPERIAN*")
replace institution = "FAZ INSTITUTE" if strmatch(institution, "FAZ*")
replace institution = "FERI EURORATING" if strmatch(institution, "FERI*")
replace institution = "FERNANDEZ RIVA" if strmatch(institution, "FERNANDEZ RIVA*")
replace institution = "FG VALORES Y BOLSA" if strmatch(institution, "FG VALORES*")
replace institution = "FIAT" if strmatch(institution, "FIAT*")
replace institution = "FONTAINE Y PAUL" if strmatch(institution, "FONTAINE Y P*")
replace institution = "BNP PARIBAS FORTIS" if strmatch(institution, "*FORTIS*")
replace institution = "GK GOH" if strmatch(institution, "*GOH*")
replace institution = "GKI ECONOMIC RESEARCH" if strmatch(institution, "GKI*")
replace institution = "GOLDMAN SACHS" if strmatch(institution, "*GOLDMAN SACHS*")
replace institution = "GOODMORNING SECURITIES" if strmatch(institution, "GOODMORNING*")
replace institution = "HALIFAX" if strmatch(institution, "HALIFAX*")
replace institution = "HANDELSBANKEN" if strmatch(institution, "HANDELSBANKEN*")
replace institution = "HANSABANK" if strmatch(institution, "HANSABANK*")
replace institution = "HESSISCHE LANDESBANK" if strmatch(institution, "HESSISCHE*")
replace institution = "HSBC JAMES CAPEL" if strmatch(institution, "HSBC JAMES*") // added
replace institution = "HSBC" if strmatch(institution, "HSBC*") & institution != "HSBC JAMES CAPEL" // changed
replace institution = "HYPO ALPE ADRIA" if strmatch(institution, "HYPO ALPE*")
replace institution = "ICICI" if strmatch(institution, "ICICI*")
replace institution = "IDEA GLOBAL" if strmatch(institution, "IDEAGLOBAL*")
replace institution = "IFO MUNICH" if strmatch(institution, "IFO*")
replace institution = "IFW - KIEL INSTITUTE" if strmatch(institution, "IFW*")
replace institution = "IMPERIAL CHEMICAL INDS" if strmatch(institution, "IMPERIAL CHEM*")
replace institution = "INDUSTRIE KREDITBANK" if strmatch(institution, "INDUSTRIEKREDITBANK*")
replace institution = "ING BANK" if strmatch(institution, "ING*")
replace institution = "INST LR KLEIN (GAUSS)" if strmatch(institution, "INST*KLEIN*")
replace institution = "INSTITUTO DE CREDITO OFFICIAL" if strmatch(institution, "INSTITUTO DE CREDITO OFICIAL*")
replace institution = "INVESCO BANK" if strmatch(institution, "INVESCO*")
replace institution = "REXECODE" if strmatch(institution, "IPECODE*")
replace institution = "IW - COLOGNE INSTITUTE" if strmatch(institution, "IW*COL*")
replace institution = "IWH - HALLE INSTITUTE" if strmatch(institution, "IWH*")
replace institution = "JAMES CAPEL" if strmatch(institution, "JAMES CAPEL*")
replace institution = "JARDINE FLEMING" if strmatch(institution, "JARDINE FLEMING*")
replace institution = "JP MORGAN" if strmatch(institution, "J*P M*RGAN*")
replace institution = "KASIKORNBANK" if strmatch(institution, "KASIKORN*")
replace institution = "KAY HIAN RESEARCH" if strmatch(institution, "KAY HIAN*")
replace institution = "KEMPEN & CO" if strmatch(institution, "KEMPEN*")
replace institution = "KLEINWORT BENSON" if strmatch(institution, "KLEINWORT*")
replace institution = "KOKUMIN KEIZEI RESEARCH INSTITUTE" if strmatch(institution, "KOKUMIN*")
replace institution = "KOMERCNI BANK" if strmatch(institution, "KOMERCNI*")
replace institution = "LEHMAN BROTHERS" if strmatch(institution, "LEHMAN*")
replace institution = "LIVERPOOL MACRO RESEARCH" if strmatch(institution, "LIVERPOOL*")
replace institution = "LLOYDS BANK" if strmatch(institution, "LLOYDS*")
replace institution = "LOMBARD STREET RESEARCH" if strmatch(institution, "LOMBARD*")
replace institution = "LONDON BUSINESS SCHOOL" if strmatch(institution, "LONDON BUSINESS*")
replace institution = "M B ASSOCIADOS" if strmatch(institution, "M B ASSI*")
replace institution = "MACQUARIE GROUP" if strmatch(institution, "MACQUARIE*")
replace institution = "MEES PIERSON" if strmatch(institution, "MEESPIERSON*")
** replace institution = "MIZUHO FINANCIAL GROUP" if strmatch(institution, "MIZUHO*") not needed
replace institution = "MOODY'S CORPORATION" if strmatch(institution, "MOODY*")
replace institution = "MORGAN GRENFELL" if strmatch(institution, "*MORGAN GRENFELL*")
replace institution = "MORGAN GUARANTY" if strmatch(institution, "MORGAN GUARANTY*")
replace institution = "MORGAN STANLEY" if strmatch(institution, "MORGAN STANLEY*")
replace institution = "NATEXIS BANQUE" if strmatch(institution, "NATEXIS*")
replace institution = "NATWEST GROUP" if strmatch(institution, "NATWEST*SEC*") // changed
replace institution = "NATWEST GROUP" if strmatch(institution, "NAT WEST*")
replace institution = "NHO CONFED NOR ENTERPRISE" if strmatch(institution, "NHO CONF*")
replace institution = "NIB CAPITAL" if strmatch(institution, "NIBC*")
replace institution = "NIKKO RESEARCH" if strmatch(institution, "NIKKO*")
replace institution = "NOMURA" if strmatch(institution, "NOMURA*")
replace institution = "NORDEA BANK" if strmatch(institution, "NORDEA*")
replace institution = "NORWEGIAN FIN SERV ASSN" if strmatch(institution, "NORWEGIAN FIN*")
replace institution = "OCBC BANK" if strmatch(institution, "OCBC*")
replace institution = "OXFORD ECONOMICS" if strmatch(institution, "OXFORD ECON*")
** replace institution = "OYAK BANK" if strmatch(institution, "OYAK*") not needed
replace institution = "PHATRA" if strmatch(institution, "PHATRA*")
replace institution = "PRIVREDNA BANKA" if strmatch(institution, "PRIVREDNA*")
replace institution = "PRUDENTIAL FINANCIAL" if strmatch(institution, "PRUDENT*")
replace institution = "RABOBANK" if strmatch(institution, "RABOBANK*")
replace institution = "RAIFFEISEN" if strmatch(institution, "RAIFFEISEN*")
replace institution = "RBC DS" if strmatch(institution, "RBC*")
replace institution = "RBS FINANCIAL MARKETS" if strmatch(institution, "RBS*")
replace institution = "REF RICERCHE" if strmatch(institution, "REF*")
replace institution = "ROBERT FLEMING" if strmatch(institution, "ROBERT FLEMING*")
replace institution = "ROSBANK" if strmatch(institution, "ROSBANK*")
replace institution = "S G WARBURG" if strmatch(institution, "*WARBURG BACOT")
replace institution = "SAKURA INSTITUTE OF RESEARCH" if strmatch(institution, "SAKURA INST*")
replace institution = "SALOMON BROTHERS" if strmatch(institution, "SALOMON*")
replace institution = "SAMSUNG SECURITIES" if strmatch(institution, "SAMSUNG*")
replace institution = "SANTANDER GROUP" if strmatch(institution, "*SANTANDER*")
replace institution = "SBC WARBURG" if strmatch(institution, "SBC WARBURG*")
replace institution = "SCB SECURITIES" if strmatch(institution, "SCB*")
replace institution = "SCHRODERS" if strmatch(institution, "SCHRODER*")
replace institution = "SCHRODER MUNCHMEYER" if strmatch(institution, "*DER MUNCHMEYER")
replace institution = "SCOTIA BANK" if strmatch(institution, "SCOTIA*")
replace institution = "SEB BANKA" if strmatch(institution, "SE BANKEN*")
replace institution = "SEB BANKA" if strmatch(institution, "SEB*")
replace institution = "SG WARBURG" if strmatch(institution, "SG WARBURG*")
replace institution = "SHAWMUT BANK" if strmatch(institution, "SHAWMUT*")
replace institution = "SMITH BARNEY SHEARSON" if strmatch(institution, "SMITH BARNEY*")
replace institution = "SG SECURITIES" if strmatch(institution, "*CROSBY*")
replace institution = "SOCGEN" if strmatch(institution, "*SG SECURITIES*")
replace institution = "SUNG HUNG KAI" if strmatch(institution, "SUNG HUNG KAI*")
replace institution = "HANDELSBANKEN" if strmatch(institution, "*HANDELSBANKEN")
replace institution = "SWEDBANK" if strmatch(institution, "SWEDBANK*")
replace institution = "UBS" if strmatch(institution, "SWISS BANK CORP*")
replace institution = "SWISS LIFE" if strmatch(institution, "SWISS LIFE*")
replace institution = "TEKFEN BANK" if strmatch(institution, "TEKFEN*")
replace institution = "TOTAL" if strmatch(institution, "TOTAL*")
replace institution = "UBS" if strmatch(institution, "UBS*")
replace institution = "UNICREDIT" if strmatch(institution, "UNI*CREDIT*")
replace institution = "THE UNIVERSITY OF MICHIGAN" if strmatch(institution, "UNIV OF MICHIGAN*")
replace institution = "UOB KAY HIAN" if strmatch(institution, "UOB KAY*") // changed
replace institution = "UNITED OVERSEAS BANK" if strmatch(institution, "UOB") // added
replace institution = "US CHAMBER OF COMMERCE" if strmatch(institution, "AMERICAN CHAMBER*")
replace institution = "VENECONOMIA" if strmatch(institution, "VENECON*")
replace institution = "VESTCOR PARTNERS" if strmatch(institution, "VESTCOR*")
replace institution = "VIEN INSTITUTE - WIIW" if strmatch(institution, "VIENNA*")
replace institution = "VTB BANK" if strmatch(institution, "VTB*")
replace institution = "WARBURG DILLON READ" if strmatch(institution, "WARBURG DILLON*")
replace institution = "WELLS CAPITAL" if strmatch(institution, "WELLS C*") // changed
replace institution = "WEST LB" if strmatch(institution, "WEST LB*")
replace institution = "WESTDEUTSCHE LANDESBANK" if strmatch(institution, "WESTDEUTSCHE*")
replace institution = "WESTLB" if strmatch(institution, "WEST LB*")
replace institution = "WESTLB" if strmatch(institution, "WESTLB BANK*")
replace institution = "ZURCHER KANTONALBANK" if strmatch(institution, "Z*KANTONALBANK")
replace institution = "ANZ BANK" if strmatch(institution, "ANZ*")
replace institution = "BANCA INTESA" if strmatch(institution, "BANCA INTESA*")
replace institution = "BNP PARIBAS" if strmatch(institution, "BNP*")
replace institution = "FIRST BOSTON" if strmatch(institution, "*FIRST BOSTON")
replace institution = "CAJA MADRID" if strmatch(institution, "CAJA*MADRID")
replace institution = "CESLA KLEIN" if strmatch(institution, "CESLA*")
replace institution = "EFG" if strmatch(institution, "EFG*")
replace institution = "KIEL INSTITUTE" if strmatch(institution, "KIEL*")
replace institution = "OXFORD - LBS" if strmatch(institution, "OXFORD*LBS")
replace institution = "SG SECURITIES" if strmatch(institution, "SOC*GEN*")
replace institution = "TEB" if strmatch(institution, "TEB*")
replace institution = "W I CARR" if strmatch(institution, "W*CARR")
replace institution = "YAMAICHI" if strmatch(institution, "YAMAICHI*")

*** replace institution = "" if strmatch(institution, "**")

*** dealing with duplicates ***


*egen indicator_duplicates = count(date), by(date country institution)

*** replace institution = "" if strmatch(institution, "**")

cap drop id

egen id = group(country institution)

sort country date institution id


save "$datace_imf/DATA2_NewVintage.dta", replace


use "$datace_imf/DATA2_NewVintage.dta",clear


* ADD CRISIS DATA:
********************************************************************************
merge m:1 country year using "$crises/Crises - Harvard - modified.dta"
drop _merge
drop if institution == ""

cap drop id

egen id = group(country institution)

sort country date institution id


// some corrections regarding the institution names
replace institution = "ALPHA FINANCE ROMANIA" if strmatch(institution, "ALPHA*") & country == "Romania" // modified
replace institution = "ALPHA" if strmatch(institution, "ALPHA*") & country == "Argentina" // modified
replace institution = "BANKBOSTON" if institution == "BANK OF BOSTON" & country == "Peru" // modified
replace institution = "CAISSE DES DEPOTS" if strmatch(institution, "CAISSE DE DEPOT") & country == "France" // modified
replace institution = "DANAREKSA SECURITIES" if strmatch(institution, "DANARESKSA SECURITIES") // modified


save "$datace_imf/DATA2_crisis_NewVintage.dta", replace



/*
Note for Elio: There is a lot of data management in this do-file. We start defining
the location around line 377 with the title "Matching with the main dataset"
*/


********************************************************************************
************************** Company Tree Structure ******************************
********************************************************************************

// load the excel dataset
clear all
import excel "$eikon/Trees.xlsx", sheet("Sheet1") firstrow

// render the company ID more visible
*format CompanyPermID %15.0f

// drop unnecessary variables
drop A*

// destring variables
destring Employees, replace ignore(",")
destring OwnershipPercentage, force replace ignore("%")
destring MarketCap TotalRevenue, force replace ignore("$" ",")

// dealing with currencies
format MarketCap TotalRevenue %15.0f
label variable MarketCap "Market Cap in US dollars"
label variable TotalRevenue "Total Revenue in US dollars"

// dealing with the percentage
replace OwnershipPercentage = OwnershipPercentage*100 if OwnershipPercentage <= 1

// let's get rid of ownership percentages if they are
// between 0 and 1 as they may be erroneous due to heterogenous percentage types
replace OwnershipPercentage =. if OwnershipPercentage <= 1

// dealing with the date
gen e_IncorporatedDate = date(IncorporatedDate, "MDY")
format e_IncorporatedDate %td

destring IncorporatedDate, force replace
replace IncorporatedDate = e_IncorporatedDate
format IncorporatedDate %td
drop e_IncorporatedDate

// there are some errors in the excel dataset (ex. country = 2001). Let's correct them
// correction 1 - concerns only one observation
replace IncorporatedDate = date("01jan2001","DMY") in 22609
replace PEBackedStatus = "" in 22609
replace Employees = 35 in 22609
replace TotalRevenue = 7078280 in 22609

// correction 2
replace Headquarters = "Austria" if Headquarters == "Austia"
replace Headquarters = "Finland" if Headquarters == "Finalnd"
replace Headquarters = "New Zealand" if Headquarters == "New Zealnd"
replace Headquarters = "United States" if Headquarters == "Unites States"

// let's make sure that the countries have the same names across both datasets
replace Headquarters = "United Kingdom" if Headquarters == "UK"
replace IncorporatedCountry = "China" if strpos(IncorporatedCountry, "China") > 0
replace CountryRegion = "China" if strpos(CountryRegion, "China") > 0
replace CountryRegion = "Ireland" if strpos(CountryRegion, "Ireland") > 0
replace CountryRegion = "South Korea" if strpos(CountryRegion, "Korea") > 0
replace CountryRegion = "Slovakia" if strpos(CountryRegion, "Slovak") > 0
replace CountryRegion = "United States" if strpos(CountryRegion, "United States") > 0

rename Institution institution

// defining a variable per relationship type
gen Affiliate = (RelationshipType == "Affiliate")
label variable Affiliate "Relation is Affiliate"
gen JV = (RelationshipType == "JointVenture")
label variable JV "Relation is Joint Venture"
gen Subsidiary = (RelationshipType == "Subsidiary")
label variable Subsidiary "Relation is Subsidiary"

// some of the institution names don't match:
replace institution = "ABECEB.COM" if institution == "ABECEB COM"
replace institution = "BANCA COMERZ. ITAL" if institution == "BANCA COMERZ.  ITAL"
replace institution = "BANK OF THE PHILIPPINES ISLANDS" if institution == "BANK OF THE PHILIPPINES ISLAND"
replace institution = "COLEGIO DE ECON. DE LIMA" if institution == "COLEGIO DE ECON  DE LIMA"
replace institution = "CRT GOVT. SECURITIES" if institution == "CRT GOVT.  SECURITIES"
replace institution = "DRESDNER KLEINWORT BEN." if institution == "DRESDNER KLEINWORT BEN "
replace institution = "ECON. INSTITUTE ZAGREB" if institution == "ECON  INSTITUTE ZAGREB"
replace institution = "NIPPON STEEL RESEARCH INSTITUTE" if institution == "NIPPON STEEL RESEARCH INSTITUT"
replace institution = "SEO - UNIV. AMSTERDAM" if institution == "SEO - UNIV  AMSTERDAM"
replace institution = "SEO - UNIV. VAN AMSTERDAM" if institution == "SEO - UNIV  VAN AMSTERDAM"

// generate a variable for the number of countries in which an institution is present
egen tag = tag(institution CountryRegion)
egen n_countries = total(tag), by(institution)
drop tag
replace n_countries = 1 if n_countries == 0

/*
the following code is because in the beginning of the excel file I did not systematically
add a country/region if data was not available on eikon but the company headquarters was known
*/
replace CountryRegion = Headquarters if CountryRegion == "" & Headquarters != "" & n_countries ==1

// now the dataset is ready!
// save the stata dataset
save "$eikonf/Trees.dta", replace



********************************************************************************
********************************************************************************
********************************************************************************

************************** Matching the Datasets *******************************

// load the main datasets
/*
clear all
use "/Users/eliob/Desktop/Data/Data to match/Trees/DATA2_crisis.dta"

// some corrections regarding the institution names
replace institution = "ALPHA FINANCE ROMANIA" if strmatch(institution, "ALPHA*") & country == "Romania" // modified
replace institution = "ALPHA" if strmatch(institution, "ALPHA*") & country == "Argentina" // modified
replace institution = "BANKBOSTON" if institution == "BANK OF BOSTON" & country == "Peru" // modified
replace institution = "CAISSE DES DEPOTS" if strmatch(institution, "CAISSE DE DEPOT") & country == "France" // modified
replace institution = "DANAREKSA SECURITIES" if strmatch(institution, "DANARESKSA SECURITIES") // modified
This part is already added to Elio's do-file
*/

// making a list of counntries per institution
// for subsidiaries

clear all
use "$eikonf/Trees.dta", clear

drop Level*
drop RIC
drop PEBackedStatus
drop IncorporatedDate IncorporatedCountry
drop CompanyPermID
replace RelationshipType = trim(RelationshipType)
drop CompanyName
drop OwnershipPercentage
drop Type


* is indicator for relationshipType only always missing for the parent?:
sort institution
by institution: g nid = _n 

*br if nid > 1 & RelationshipType == ""

* there are three exceptions where we do not know whether subsidiary, affiliate or JV. We can ignore them I guess

replace RelationshipType = "Parent" if RelationshipType == "" & nid == 1

drop nid

drop if RelationshipType == ""


* drop as many variables as possible for first try, focus only on subsidaries/jv/aff
drop Affiliate JV Subsidiary Industry TotalRevenue Employees MarketCap ImpliedRating MoodysRating FitchRating


* in a first step, we focus on subsidaries only
drop if RelationshipType == "Affiliate" | RelationshipType == "JointVenture"

egen id = group(institution)


* get unique subsidaries for each instiutiton:
preserve

	drop if RelationshipType == "Parent"
	collapse (mean) id , by(institution Headquarters CountryRegion)

	* generate number of observation for each pair of institution and headquarters for reshape
	sort institution Headquarters
	by institution Headquarters: g nid = _n 

	rename CountryRegion subsidiaryCountry

	reshape wide subsidiaryCountry, i(institution Headquarters) j(nid)
	drop id
	save $eikonf/subsidiary.dta, replace

restore

* now, you can do the same for the affiliates and joint venture, and add other variables
// for affiliates

clear all
use "$eikonf/Trees.dta", clear

drop Level*
drop RIC
drop PEBackedStatus
drop IncorporatedDate IncorporatedCountry
drop CompanyPermID
replace RelationshipType = trim(RelationshipType)
drop CompanyName
drop OwnershipPercentage
drop Type


* is indicator for relationshipType only always missing for the parent?:
sort institution
by institution: g nid = _n 

*br if nid > 1 & RelationshipType == ""

* there are three exceptions where we do not know whether subsidiary, affiliate or JV. We can ignore them I guess

replace RelationshipType = "Parent" if RelationshipType == "" & nid == 1

drop nid

drop if RelationshipType == ""


* drop as many variables as possible for first try, focus only on subsidaries/jv/aff
drop Affiliate JV Subsidiary Industry TotalRevenue Employees MarketCap ImpliedRating MoodysRating FitchRating


* we focus now on affiliates
drop if RelationshipType == "Subsidiary" | RelationshipType == "JointVenture"

egen id = group(institution)


* get unique subsidaries for each instiutiton:
preserve

	drop if RelationshipType == "Parent"
	collapse (mean) id , by(institution Headquarters CountryRegion)

	* generate number of observation for each pair of institution and headquarters for reshape
	sort institution Headquarters
	by institution Headquarters: g nid = _n 

	rename CountryRegion affiliateCountry

	reshape wide affiliateCountry, i(institution Headquarters) j(nid)

	drop id
	save $eikonf/affiliate.dta, replace


restore

// for Joint Ventures

clear all
use "$eikonf/Trees.dta", clear

drop Level*
drop RIC
drop PEBackedStatus
drop IncorporatedDate IncorporatedCountry
drop CompanyPermID
replace RelationshipType = trim(RelationshipType)
drop CompanyName
drop OwnershipPercentage
drop Type


* is indicator for relationshipType only always missing for the parent?:
sort institution
by institution: g nid = _n 

*br if nid > 1 & RelationshipType == ""

* there are three exceptions where we do not know whether subsidiary, affiliate or JV. We can ignore them I guess

replace RelationshipType = "Parent" if RelationshipType == "" & nid == 1

drop nid

drop if RelationshipType == ""


* drop as many variables as possible for first try, focus only on subsidaries/jv/aff
drop Affiliate JV Subsidiary Industry TotalRevenue Employees MarketCap ImpliedRating MoodysRating FitchRating


* now we focus in JVs
drop if RelationshipType == "Subsidiary" | RelationshipType == "Affiliate"

egen id = group(institution)


* get unique subsidaries for each instiutiton:
preserve

	drop if RelationshipType == "Parent"
	collapse (mean) id , by(institution Headquarters CountryRegion)

	* generate number of observation for each pair of institution and headquarters for reshape
	sort institution Headquarters
	by institution Headquarters: g nid = _n 

	rename CountryRegion jvCountry

	reshape wide jvCountry, i(institution Headquarters) j(nid)
	drop id
	save $eikonf/jointventure.dta, replace


restore

***************** Merging the three files that we created **********************

clear all
use "$eikonf/subsidiary.dta"
merge 1:1 institution using "$eikonf/affiliate.dta"
drop _merge
merge 1:1 institution using "$eikonf/jointventure.dta"
drop _merge

save $eikonf/countries_trees.dta, replace

// now, we should merge this with the big company tree data set in order to have parents and other variables

clear all
use "$eikonf/Trees.dta"

sort institution
by institution: g nid = _n 
replace RelationshipType = "Parent" if RelationshipType == "" & nid == 1
drop nid

// we are only interested in the parents institutions

keep if RelationshipType == "Parent"

drop Level*
drop RIC
drop PEBackedStatus
drop IncorporatedDate IncorporatedCountry
drop CompanyPermID
replace RelationshipType = trim(RelationshipType)
drop CompanyName
drop OwnershipPercentage
drop Type
drop Affiliate JV Subsidiary

label variable n_countries "Number of countries in which the institution is present"

/*
We have some institutions that we know are present in more than one country but
we did not find data on them on eikon. The first adopted solution (repeating the
institution over many rows and adding a different country each time) does not agree
well for the merging that we are about to do. We will keep one of the countries
as headquarters and the others as subsidiaries
*/

drop if institution == "CENTER KLEIN FORECASTING" & Headquarters != "Colombia"
drop if institution == "CESLA KLEIN" & Headquarters != "Colombia"
drop if institution == "CIEMEX-WEFA" & Headquarters != "Mexico"
drop if institution == "CREDICORP CAPITAL" & Headquarters != "Chile"
drop if institution == "INTERCAPITAL SECURITIES" & Industry == ""

merge 1:1 institution using "$eikonf/countries_trees.dta"
drop _merge

// now we add the other countries where the institution is present as subsidaries
replace subsidiaryCountry1 = "Mexico" if institution == "CENTER KLEIN FORECASTING"
replace subsidiaryCountry2 = "Peru" if institution == "CENTER KLEIN FORECASTING"

replace subsidiaryCountry1 = "Mexico" if institution == "CESLA KLEIN"
replace subsidiaryCountry2 = "Peru" if institution == "CESLA KLEIN"

replace subsidiaryCountry1 = "United States" if institution == "CIEMEX-WEFA"

replace subsidiaryCountry1 = "Colombia" if institution == "CREDICORP CAPITAL"
replace subsidiaryCountry2 = "Peru" if institution == "CREDICORP CAPITAL"

// done

drop RelationshipType CountryRegion

save $eikonf/trees_final.dta, replace

********************* Matching with the main dataset ***************************


clear all
use "$datace_imf/DATA2_crisis_NewVintage.dta"

// some corrections regarding the institution names
replace institution = "ALPHA FINANCE ROMANIA" if strmatch(institution, "ALPHA*") & country == "Romania" // modified
replace institution = "ALPHA" if strmatch(institution, "ALPHA*") & country == "Argentina" // modified
replace institution = "BANKBOSTON" if institution == "BANK OF BOSTON" & country == "Peru" // modified
replace institution = "CAISSE DES DEPOTS" if strmatch(institution, "CAISSE DE DEPOT") & country == "France" // modified
replace institution = "DANAREKSA SECURITIES" if strmatch(institution, "DANARESKSA SECURITIES") // modified

merge m:1 institution using "$eikonf/trees_final.dta"
drop _merge
// defining the location variable for ONLY the subsidiaries
gen location_sub = ""
label variable location_sub "institution location defined by its subsidaries locations"

// counting the number of subsidaries
egen sub_counter = rownonmiss(subsidiaryCountry1 subsidiaryCountry2 subsidiaryCountry3 subsidiaryCountry4 ///
subsidiaryCountry5 subsidiaryCountry6 subsidiaryCountry7 subsidiaryCountry8 subsidiaryCountry9 ///
subsidiaryCountry10 subsidiaryCountry11 subsidiaryCountry12 subsidiaryCountry13 subsidiaryCountry14 ///
subsidiaryCountry15 subsidiaryCountry16 subsidiaryCountry17 subsidiaryCountry18 subsidiaryCountry19 ///
subsidiaryCountry20 subsidiaryCountry21 subsidiaryCountry22 subsidiaryCountry23 subsidiaryCountry24 ///
subsidiaryCountry25 subsidiaryCountry26 subsidiaryCountry27 subsidiaryCountry28 subsidiaryCountry29 ///
subsidiaryCountry30 subsidiaryCountry31 subsidiaryCountry32 subsidiaryCountry33 subsidiaryCountry34 ///
subsidiaryCountry35 subsidiaryCountry36 subsidiaryCountry37 subsidiaryCountry38 subsidiaryCountry39 ///
subsidiaryCountry40 subsidiaryCountry41 subsidiaryCountry42 subsidiaryCountry43 subsidiaryCountry44 ///
subsidiaryCountry45 subsidiaryCountry46 subsidiaryCountry47 subsidiaryCountry48 subsidiaryCountry49 ///
subsidiaryCountry50 subsidiaryCountry51 subsidiaryCountry52 subsidiaryCountry53 subsidiaryCountry54 ///
subsidiaryCountry55 subsidiaryCountry56 subsidiaryCountry57 subsidiaryCountry58 subsidiaryCountry59 ///
subsidiaryCountry60 subsidiaryCountry61 subsidiaryCountry62 subsidiaryCountry63 subsidiaryCountry64 ///
subsidiaryCountry65 subsidiaryCountry66 subsidiaryCountry67 subsidiaryCountry68 subsidiaryCountry69 ///
subsidiaryCountry70 subsidiaryCountry71 subsidiaryCountry72 subsidiaryCountry73 subsidiaryCountry74 ///
subsidiaryCountry75 subsidiaryCountry76 subsidiaryCountry77 subsidiaryCountry78 subsidiaryCountry79 ///
subsidiaryCountry80 subsidiaryCountry81 subsidiaryCountry82 subsidiaryCountry83 subsidiaryCountry84 ///
subsidiaryCountry85 subsidiaryCountry86 subsidiaryCountry87 subsidiaryCountry88 subsidiaryCountry89 ///
subsidiaryCountry90 subsidiaryCountry91 subsidiaryCountry92 subsidiaryCountry93 subsidiaryCountry94 ///
subsidiaryCountry95 subsidiaryCountry96 subsidiaryCountry97 subsidiaryCountry98 subsidiaryCountry99 ///
subsidiaryCountry100 subsidiaryCountry101 subsidiaryCountry102 subsidiaryCountry103 subsidiaryCountry104 ///
subsidiaryCountry105 subsidiaryCountry106 subsidiaryCountry107 subsidiaryCountry108 subsidiaryCountry109 ///
subsidiaryCountry110 subsidiaryCountry111 subsidiaryCountry112 subsidiaryCountry113 subsidiaryCountry114 ///
subsidiaryCountry115 subsidiaryCountry116 subsidiaryCountry117 subsidiaryCountry118 subsidiaryCountry119 ///
subsidiaryCountry120 subsidiaryCountry121), strok

label variable sub_counter "Number of countries in which the instituion's subsidiaries are present"

// defining the location_sub variable
replace location_sub = "Foreign" if country != Headquarters & ///
subsidiaryCountry1 != country & subsidiaryCountry2 != country & subsidiaryCountry3 != country & ///
subsidiaryCountry4 != country & subsidiaryCountry5 != country & subsidiaryCountry6 != country & ///
subsidiaryCountry7 != country & subsidiaryCountry8 != country & subsidiaryCountry9 != country & ///
subsidiaryCountry10 != country & subsidiaryCountry11 != country & subsidiaryCountry12 != country & ///
subsidiaryCountry13 != country & subsidiaryCountry14 != country & subsidiaryCountry15 != country & ///
subsidiaryCountry16 != country & subsidiaryCountry17 != country & subsidiaryCountry18 != country & ///
subsidiaryCountry19 != country & subsidiaryCountry20 != country & subsidiaryCountry21 != country & ///
subsidiaryCountry22 != country & subsidiaryCountry23 != country & subsidiaryCountry24 != country & ///
subsidiaryCountry25 != country & subsidiaryCountry26 != country & subsidiaryCountry27 != country & ///
subsidiaryCountry28 != country & subsidiaryCountry29 != country & subsidiaryCountry30 != country & ///
subsidiaryCountry31 != country & subsidiaryCountry32 != country & subsidiaryCountry33 != country & ///
subsidiaryCountry34 != country & subsidiaryCountry35 != country & subsidiaryCountry36 != country & ///
subsidiaryCountry37 != country & subsidiaryCountry38 != country & subsidiaryCountry39 != country & ///
subsidiaryCountry40 != country & subsidiaryCountry41 != country & subsidiaryCountry42 != country & ///
subsidiaryCountry43 != country & subsidiaryCountry44 != country & subsidiaryCountry45 != country & ///
subsidiaryCountry46 != country & subsidiaryCountry47 != country & subsidiaryCountry48 != country & ///
subsidiaryCountry49 != country & subsidiaryCountry50 != country & subsidiaryCountry51 != country & ///
subsidiaryCountry52 != country & subsidiaryCountry53 != country & subsidiaryCountry54 != country & ///
subsidiaryCountry55 != country & subsidiaryCountry56 != country & subsidiaryCountry57 != country & ///
subsidiaryCountry58 != country & subsidiaryCountry59 != country & subsidiaryCountry60 != country & ///
subsidiaryCountry61 != country & subsidiaryCountry62 != country & subsidiaryCountry63 != country & ///
subsidiaryCountry64 != country & subsidiaryCountry65 != country & subsidiaryCountry66 != country & ///
subsidiaryCountry67 != country & subsidiaryCountry68 != country & subsidiaryCountry69 != country & ///
subsidiaryCountry70 != country & subsidiaryCountry71 != country & subsidiaryCountry72 != country & ///
subsidiaryCountry73 != country & subsidiaryCountry74 != country & subsidiaryCountry75 != country & ///
subsidiaryCountry76 != country & subsidiaryCountry77 != country & subsidiaryCountry78 != country & ///
subsidiaryCountry79 != country & subsidiaryCountry80 != country & subsidiaryCountry81 != country & ///
subsidiaryCountry82 != country & subsidiaryCountry83 != country & subsidiaryCountry84 != country & ///
subsidiaryCountry85 != country & subsidiaryCountry86 != country & subsidiaryCountry87 != country & ///
subsidiaryCountry88 != country & subsidiaryCountry89 != country & subsidiaryCountry90 != country & ///
subsidiaryCountry91 != country & subsidiaryCountry92 != country & subsidiaryCountry93 != country & ///
subsidiaryCountry94 != country & subsidiaryCountry95 != country & subsidiaryCountry96 != country & ///
subsidiaryCountry97 != country & subsidiaryCountry98 != country & subsidiaryCountry99 != country & ///
subsidiaryCountry100 != country & subsidiaryCountry101 != country & subsidiaryCountry102 != country & ///
subsidiaryCountry103 != country & subsidiaryCountry104 != country & subsidiaryCountry105 != country & ///
subsidiaryCountry106 != country & subsidiaryCountry107 != country & subsidiaryCountry108 != country & ///
subsidiaryCountry109 != country & subsidiaryCountry110 != country & subsidiaryCountry111 != country & ///
subsidiaryCountry112 != country & subsidiaryCountry113 != country & subsidiaryCountry114 != country & ///
subsidiaryCountry115 != country & subsidiaryCountry116 != country & subsidiaryCountry117 != country & ///
subsidiaryCountry118 != country & subsidiaryCountry119 != country & subsidiaryCountry120 != country & ///
subsidiaryCountry121 != country


replace location_sub = "Multinational" if country != Headquarters & ///	
(subsidiaryCountry1 == country | subsidiaryCountry2 == country | subsidiaryCountry3 == country | ///
subsidiaryCountry4 == country | subsidiaryCountry5 == country | subsidiaryCountry6 == country | ///
subsidiaryCountry7 == country | subsidiaryCountry8 == country | subsidiaryCountry9 == country | ///
subsidiaryCountry10 == country | subsidiaryCountry11 == country | subsidiaryCountry12 == country | ///
subsidiaryCountry13 == country | subsidiaryCountry14 == country | subsidiaryCountry15 == country | ///
subsidiaryCountry16 == country | subsidiaryCountry17 == country | subsidiaryCountry18 == country | ///
subsidiaryCountry19 == country | subsidiaryCountry20 == country | subsidiaryCountry21 == country | ///
subsidiaryCountry22 == country | subsidiaryCountry23 == country | subsidiaryCountry24 == country | ///
subsidiaryCountry25 == country | subsidiaryCountry26 == country | subsidiaryCountry27 == country | ///
subsidiaryCountry28 == country | subsidiaryCountry29 == country | subsidiaryCountry30 == country | ///
subsidiaryCountry31 == country | subsidiaryCountry32 == country | subsidiaryCountry33 == country | ///
subsidiaryCountry34 == country | subsidiaryCountry35 == country | subsidiaryCountry36 == country | ///
subsidiaryCountry37 == country | subsidiaryCountry38 == country | subsidiaryCountry39 == country | ///
subsidiaryCountry40 == country | subsidiaryCountry41 == country | subsidiaryCountry42 == country | ///
subsidiaryCountry43 == country | subsidiaryCountry44 == country | subsidiaryCountry45 == country | ///
subsidiaryCountry46 == country | subsidiaryCountry47 == country | subsidiaryCountry48 == country | ///
subsidiaryCountry49 == country | subsidiaryCountry50 == country | subsidiaryCountry51 == country | ///
subsidiaryCountry52 == country | subsidiaryCountry53 == country | subsidiaryCountry54 == country | ///
subsidiaryCountry55 == country | subsidiaryCountry56 == country | subsidiaryCountry57 == country | ///
subsidiaryCountry58 == country | subsidiaryCountry59 == country | subsidiaryCountry60 == country | ///
subsidiaryCountry61 == country | subsidiaryCountry62 == country | subsidiaryCountry63 == country | ///
subsidiaryCountry64 == country | subsidiaryCountry65 == country | subsidiaryCountry66 == country | ///
subsidiaryCountry67 == country | subsidiaryCountry68 == country | subsidiaryCountry69 == country | ///
subsidiaryCountry70 == country | subsidiaryCountry71 == country | subsidiaryCountry72 == country | ///
subsidiaryCountry73 == country | subsidiaryCountry74 == country | subsidiaryCountry75 == country | ///
subsidiaryCountry76 == country | subsidiaryCountry77 == country | subsidiaryCountry78 == country | ///
subsidiaryCountry79 == country | subsidiaryCountry80 == country | subsidiaryCountry81 == country | ///
subsidiaryCountry82 == country | subsidiaryCountry83 == country | subsidiaryCountry84 == country | ///
subsidiaryCountry85 == country | subsidiaryCountry86 == country | subsidiaryCountry87 == country | ///
subsidiaryCountry88 == country | subsidiaryCountry89 == country | subsidiaryCountry90 == country | ///
subsidiaryCountry91 == country | subsidiaryCountry92 == country | subsidiaryCountry93 == country | ///
subsidiaryCountry94 == country | subsidiaryCountry95 == country | subsidiaryCountry96 == country | ///
subsidiaryCountry97 == country | subsidiaryCountry98 == country | subsidiaryCountry99 == country | ///
subsidiaryCountry100 == country | subsidiaryCountry101 == country | subsidiaryCountry102 == country | ///
subsidiaryCountry103 == country | subsidiaryCountry104 == country | subsidiaryCountry105 == country | ///
subsidiaryCountry106 == country | subsidiaryCountry107 == country | subsidiaryCountry108 == country | ///
subsidiaryCountry109 == country | subsidiaryCountry110 == country | subsidiaryCountry111 == country | ///
subsidiaryCountry112 == country | subsidiaryCountry113 == country | subsidiaryCountry114 == country | ///
subsidiaryCountry115 == country | subsidiaryCountry116 == country | subsidiaryCountry117 == country | ///
subsidiaryCountry118 == country | subsidiaryCountry119 == country | subsidiaryCountry120 == country | ///
subsidiaryCountry121 == country)

replace location_sub = "Multinational" if country == Headquarters & subsidiaryCountry1 != "" & ///
(Headquarters != subsidiaryCountry1 | sub_counter > 1)

replace location_sub = "Local" if country == Headquarters & country == subsidiaryCountry1 & ///
sub_counter == 1
replace location_sub = "Local" if country == Headquarters & sub_counter == 0

// Now, defining the location variable for ONLY the affiliates
gen location_aff = ""
label variable location_aff "institution location defined by its affiliates locations"

// counting the number of affiliates
egen aff_counter = rownonmiss(affiliateCountry1 affiliateCountry2 affiliateCountry3 ///
 affiliateCountry4 affiliateCountry5 affiliateCountry6 affiliateCountry7 affiliateCountry8 ///
 affiliateCountry9 affiliateCountry10 affiliateCountry11 affiliateCountry12 affiliateCountry13 ///
 affiliateCountry14 affiliateCountry15 affiliateCountry16 affiliateCountry17 affiliateCountry18 ///
 affiliateCountry19 affiliateCountry20 affiliateCountry21 affiliateCountry22 affiliateCountry23 ///
 affiliateCountry24 affiliateCountry25 affiliateCountry26 affiliateCountry27 affiliateCountry28 ///
 affiliateCountry29 affiliateCountry30 affiliateCountry31 affiliateCountry32 affiliateCountry33 ///
 affiliateCountry34 affiliateCountry35 affiliateCountry36 affiliateCountry37 affiliateCountry38), strok

label variable aff_counter "Number of countries in which the instituion's affiliates are present"

// defining the location_aff variable
replace location_aff = "Foreign" if country != Headquarters & ///
affiliateCountry1 != country & affiliateCountry2 != country & affiliateCountry3 != country & ///
affiliateCountry4 != country & affiliateCountry5 != country & affiliateCountry6 != country & ///
affiliateCountry7 != country & affiliateCountry8 != country & affiliateCountry9 != country & ///
affiliateCountry10 != country & affiliateCountry11 != country & affiliateCountry12 != country & ///
affiliateCountry13 != country & affiliateCountry14 != country & affiliateCountry15 != country & ///
affiliateCountry16 != country & affiliateCountry17 != country & affiliateCountry18 != country & ///
affiliateCountry19 != country & affiliateCountry20 != country & affiliateCountry21 != country & ///
affiliateCountry22 != country & affiliateCountry23 != country & affiliateCountry24 != country & ///
affiliateCountry25 != country & affiliateCountry26 != country & affiliateCountry27 != country & ///
affiliateCountry28 != country & affiliateCountry29 != country & affiliateCountry30 != country & ///
affiliateCountry31 != country & affiliateCountry32 != country & affiliateCountry33 != country & ///
affiliateCountry34 != country & affiliateCountry35 != country & affiliateCountry36 != country & ///
affiliateCountry37 != country & affiliateCountry38 != country


replace location_aff = "Multinational" if country != Headquarters & ///	
(affiliateCountry1 == country | affiliateCountry2 == country | affiliateCountry3 == country | ///
affiliateCountry4 == country | affiliateCountry5 == country | affiliateCountry6 == country | ///
affiliateCountry7 == country | affiliateCountry8 == country | affiliateCountry9 == country | ///
affiliateCountry10 == country | affiliateCountry11 == country | affiliateCountry12 == country | ///
affiliateCountry13 == country | affiliateCountry14 == country | affiliateCountry15 == country | ///
affiliateCountry16 == country | affiliateCountry17 == country | affiliateCountry18 == country | ///
affiliateCountry19 == country | affiliateCountry20 == country | affiliateCountry21 == country | ///
affiliateCountry22 == country | affiliateCountry23 == country | affiliateCountry24 == country | ///
affiliateCountry25 == country | affiliateCountry26 == country | affiliateCountry27 == country | ///
affiliateCountry28 == country | affiliateCountry29 == country | affiliateCountry30 == country | ///
affiliateCountry31 == country | affiliateCountry32 == country | affiliateCountry33 == country | ///
affiliateCountry34 == country | affiliateCountry35 == country | affiliateCountry36 == country | ///
affiliateCountry37 == country | affiliateCountry38 == country)

replace location_aff = "Multinational" if country == Headquarters & affiliateCountry1 != "" & ///
(Headquarters != affiliateCountry1 | aff_counter > 1)

replace location_aff = "Multinational" if country == Headquarters & aff_counter > 1



replace location_aff = "Local" if country == Headquarters & country == affiliateCountry1 & ///
aff_counter == 1
replace location_aff = "Local" if country == Headquarters & aff_counter == 0

// Now, defining the variable location_all which determines the location as Foreign,
// Multinational, or Local by taking account all subsidaries, affiliates, and JVs

gen location_all = ""
label variable location_all "institution location defined by all companies in its tree"

// we already have the variable n_countries that counts the number of countries in
// which the institutions subsidiaries, affiliates and JVs are present

// defining the variable location_all

replace location_all = "Foreign" if country != Headquarters & ///
subsidiaryCountry1 != country & subsidiaryCountry2 != country & subsidiaryCountry3 != country & ///
subsidiaryCountry4 != country & subsidiaryCountry5 != country & subsidiaryCountry6 != country & ///
subsidiaryCountry7 != country & subsidiaryCountry8 != country & subsidiaryCountry9 != country & ///
subsidiaryCountry10 != country & subsidiaryCountry11 != country & subsidiaryCountry12 != country & ///
subsidiaryCountry13 != country & subsidiaryCountry14 != country & subsidiaryCountry15 != country & ///
subsidiaryCountry16 != country & subsidiaryCountry17 != country & subsidiaryCountry18 != country & ///
subsidiaryCountry19 != country & subsidiaryCountry20 != country & subsidiaryCountry21 != country & ///
subsidiaryCountry22 != country & subsidiaryCountry23 != country & subsidiaryCountry24 != country & ///
subsidiaryCountry25 != country & subsidiaryCountry26 != country & subsidiaryCountry27 != country & ///
subsidiaryCountry28 != country & subsidiaryCountry29 != country & subsidiaryCountry30 != country & ///
subsidiaryCountry31 != country & subsidiaryCountry32 != country & subsidiaryCountry33 != country & ///
subsidiaryCountry34 != country & subsidiaryCountry35 != country & subsidiaryCountry36 != country & ///
subsidiaryCountry37 != country & subsidiaryCountry38 != country & subsidiaryCountry39 != country & ///
subsidiaryCountry40 != country & subsidiaryCountry41 != country & subsidiaryCountry42 != country & ///
subsidiaryCountry43 != country & subsidiaryCountry44 != country & subsidiaryCountry45 != country & ///
subsidiaryCountry46 != country & subsidiaryCountry47 != country & subsidiaryCountry48 != country & ///
subsidiaryCountry49 != country & subsidiaryCountry50 != country & subsidiaryCountry51 != country & ///
subsidiaryCountry52 != country & subsidiaryCountry53 != country & subsidiaryCountry54 != country & ///
subsidiaryCountry55 != country & subsidiaryCountry56 != country & subsidiaryCountry57 != country & ///
subsidiaryCountry58 != country & subsidiaryCountry59 != country & subsidiaryCountry60 != country & ///
subsidiaryCountry61 != country & subsidiaryCountry62 != country & subsidiaryCountry63 != country & ///
subsidiaryCountry64 != country & subsidiaryCountry65 != country & subsidiaryCountry66 != country & ///
subsidiaryCountry67 != country & subsidiaryCountry68 != country & subsidiaryCountry69 != country & ///
subsidiaryCountry70 != country & subsidiaryCountry71 != country & subsidiaryCountry72 != country & ///
subsidiaryCountry73 != country & subsidiaryCountry74 != country & subsidiaryCountry75 != country & ///
subsidiaryCountry76 != country & subsidiaryCountry77 != country & subsidiaryCountry78 != country & ///
subsidiaryCountry79 != country & subsidiaryCountry80 != country & subsidiaryCountry81 != country & ///
subsidiaryCountry82 != country & subsidiaryCountry83 != country & subsidiaryCountry84 != country & ///
subsidiaryCountry85 != country & subsidiaryCountry86 != country & subsidiaryCountry87 != country & ///
subsidiaryCountry88 != country & subsidiaryCountry89 != country & subsidiaryCountry90 != country & ///
subsidiaryCountry91 != country & subsidiaryCountry92 != country & subsidiaryCountry93 != country & ///
subsidiaryCountry94 != country & subsidiaryCountry95 != country & subsidiaryCountry96 != country & ///
subsidiaryCountry97 != country & subsidiaryCountry98 != country & subsidiaryCountry99 != country & ///
subsidiaryCountry100 != country & subsidiaryCountry101 != country & subsidiaryCountry102 != country & ///
subsidiaryCountry103 != country & subsidiaryCountry104 != country & subsidiaryCountry105 != country & ///
subsidiaryCountry106 != country & subsidiaryCountry107 != country & subsidiaryCountry108 != country & ///
subsidiaryCountry109 != country & subsidiaryCountry110 != country & subsidiaryCountry111 != country & ///
subsidiaryCountry112 != country & subsidiaryCountry113 != country & subsidiaryCountry114 != country & ///
subsidiaryCountry115 != country & subsidiaryCountry116 != country & subsidiaryCountry117 != country & ///
subsidiaryCountry118 != country & subsidiaryCountry119 != country & subsidiaryCountry120 != country & ///
subsidiaryCountry121 != country & ///
affiliateCountry1 != country & affiliateCountry2 != country & affiliateCountry3 != country & ///
affiliateCountry4 != country & affiliateCountry5 != country & affiliateCountry6 != country & ///
affiliateCountry7 != country & affiliateCountry8 != country & affiliateCountry9 != country & ///
affiliateCountry10 != country & affiliateCountry11 != country & affiliateCountry12 != country & ///
affiliateCountry13 != country & affiliateCountry14 != country & affiliateCountry15 != country & ///
affiliateCountry16 != country & affiliateCountry17 != country & affiliateCountry18 != country & ///
affiliateCountry19 != country & affiliateCountry20 != country & affiliateCountry21 != country & ///
affiliateCountry22 != country & affiliateCountry23 != country & affiliateCountry24 != country & ///
affiliateCountry25 != country & affiliateCountry26 != country & affiliateCountry27 != country & ///
affiliateCountry28 != country & affiliateCountry29 != country & affiliateCountry30 != country & ///
affiliateCountry31 != country & affiliateCountry32 != country & affiliateCountry33 != country & ///
affiliateCountry34 != country & affiliateCountry35 != country & affiliateCountry36 != country & ///
affiliateCountry37 != country & affiliateCountry38 != country & ///
jvCountry1 != country & jvCountry2 != country & jvCountry3 != country & jvCountry4 != country


replace location_all = "Multinational" if country != Headquarters & ///	
(subsidiaryCountry1 == country | subsidiaryCountry2 == country | subsidiaryCountry3 == country | ///
subsidiaryCountry4 == country | subsidiaryCountry5 == country | subsidiaryCountry6 == country | ///
subsidiaryCountry7 == country | subsidiaryCountry8 == country | subsidiaryCountry9 == country | ///
subsidiaryCountry10 == country | subsidiaryCountry11 == country | subsidiaryCountry12 == country | ///
subsidiaryCountry13 == country | subsidiaryCountry14 == country | subsidiaryCountry15 == country | ///
subsidiaryCountry16 == country | subsidiaryCountry17 == country | subsidiaryCountry18 == country | ///
subsidiaryCountry19 == country | subsidiaryCountry20 == country | subsidiaryCountry21 == country | ///
subsidiaryCountry22 == country | subsidiaryCountry23 == country | subsidiaryCountry24 == country | ///
subsidiaryCountry25 == country | subsidiaryCountry26 == country | subsidiaryCountry27 == country | ///
subsidiaryCountry28 == country | subsidiaryCountry29 == country | subsidiaryCountry30 == country | ///
subsidiaryCountry31 == country | subsidiaryCountry32 == country | subsidiaryCountry33 == country | ///
subsidiaryCountry34 == country | subsidiaryCountry35 == country | subsidiaryCountry36 == country | ///
subsidiaryCountry37 == country | subsidiaryCountry38 == country | subsidiaryCountry39 == country | ///
subsidiaryCountry40 == country | subsidiaryCountry41 == country | subsidiaryCountry42 == country | ///
subsidiaryCountry43 == country | subsidiaryCountry44 == country | subsidiaryCountry45 == country | ///
subsidiaryCountry46 == country | subsidiaryCountry47 == country | subsidiaryCountry48 == country | ///
subsidiaryCountry49 == country | subsidiaryCountry50 == country | subsidiaryCountry51 == country | ///
subsidiaryCountry52 == country | subsidiaryCountry53 == country | subsidiaryCountry54 == country | ///
subsidiaryCountry55 == country | subsidiaryCountry56 == country | subsidiaryCountry57 == country | ///
subsidiaryCountry58 == country | subsidiaryCountry59 == country | subsidiaryCountry60 == country | ///
subsidiaryCountry61 == country | subsidiaryCountry62 == country | subsidiaryCountry63 == country | ///
subsidiaryCountry64 == country | subsidiaryCountry65 == country | subsidiaryCountry66 == country | ///
subsidiaryCountry67 == country | subsidiaryCountry68 == country | subsidiaryCountry69 == country | ///
subsidiaryCountry70 == country | subsidiaryCountry71 == country | subsidiaryCountry72 == country | ///
subsidiaryCountry73 == country | subsidiaryCountry74 == country | subsidiaryCountry75 == country | ///
subsidiaryCountry76 == country | subsidiaryCountry77 == country | subsidiaryCountry78 == country | ///
subsidiaryCountry79 == country | subsidiaryCountry80 == country | subsidiaryCountry81 == country | ///
subsidiaryCountry82 == country | subsidiaryCountry83 == country | subsidiaryCountry84 == country | ///
subsidiaryCountry85 == country | subsidiaryCountry86 == country | subsidiaryCountry87 == country | ///
subsidiaryCountry88 == country | subsidiaryCountry89 == country | subsidiaryCountry90 == country | ///
subsidiaryCountry91 == country | subsidiaryCountry92 == country | subsidiaryCountry93 == country | ///
subsidiaryCountry94 == country | subsidiaryCountry95 == country | subsidiaryCountry96 == country | ///
subsidiaryCountry97 == country | subsidiaryCountry98 == country | subsidiaryCountry99 == country | ///
subsidiaryCountry100 == country | subsidiaryCountry101 == country | subsidiaryCountry102 == country | ///
subsidiaryCountry103 == country | subsidiaryCountry104 == country | subsidiaryCountry105 == country | ///
subsidiaryCountry106 == country | subsidiaryCountry107 == country | subsidiaryCountry108 == country | ///
subsidiaryCountry109 == country | subsidiaryCountry110 == country | subsidiaryCountry111 == country | ///
subsidiaryCountry112 == country | subsidiaryCountry113 == country | subsidiaryCountry114 == country | ///
subsidiaryCountry115 == country | subsidiaryCountry116 == country | subsidiaryCountry117 == country | ///
subsidiaryCountry118 == country | subsidiaryCountry119 == country | subsidiaryCountry120 == country | ///
subsidiaryCountry121 == country | ///
affiliateCountry1 == country | affiliateCountry2 == country | affiliateCountry3 == country | ///
affiliateCountry4 == country | affiliateCountry5 == country | affiliateCountry6 == country | ///
affiliateCountry7 == country | affiliateCountry8 == country | affiliateCountry9 == country | ///
affiliateCountry10 == country | affiliateCountry11 == country | affiliateCountry12 == country | ///
affiliateCountry13 == country | affiliateCountry14 == country | affiliateCountry15 == country | ///
affiliateCountry16 == country | affiliateCountry17 == country | affiliateCountry18 == country | ///
affiliateCountry19 == country | affiliateCountry20 == country | affiliateCountry21 == country | ///
affiliateCountry22 == country | affiliateCountry23 == country | affiliateCountry24 == country | ///
affiliateCountry25 == country | affiliateCountry26 == country | affiliateCountry27 == country | ///
affiliateCountry28 == country | affiliateCountry29 == country | affiliateCountry30 == country | ///
affiliateCountry31 == country | affiliateCountry32 == country | affiliateCountry33 == country | ///
affiliateCountry34 == country | affiliateCountry35 == country | affiliateCountry36 == country | ///
affiliateCountry37 == country | affiliateCountry38 == country | ///
jvCountry1 == country | jvCountry2 == country | jvCountry3 == country | jvCountry4 == country)

replace location_all = "Multinational" if country == Headquarters & n_countries > 1

replace location_all = "Local" if country == Headquarters & n_countries == 1

gen all_counter = n_countries
drop n_countries
label variable all_counter "# of countries in which an institution is present through all its company tree"

// one small mistake to correct
replace Industry = "" if Industry == "8321.T^C01"


save "$datace_imf/data_final_newVintage.dta", replace


cap drop month
g month = month(date)

order country country_num institution id date datem   month

cap drop country_upper
g country_upper = upper(country)

save "$datace_imf/data_final_newVintage.dta", replace


********************************************************************************
********************************************************************************
* ADD RECESSION INDICATOR (MONHTLY DATA)


import delimited "$recession/CLI-components-and-turning-points.csv" , clear

drop if _n == 1 | _n == 2

rename v1 date


foreach var of varlist v2 - v10 {
   rename `var' `=`var'[1]' 
}


rename v11 Czech_Republic

foreach var of varlist v12 - v17 {
   rename `var' `=`var'[1]'
}

rename v18 United_Kingdom

foreach var of varlist v19 - v34 {
   rename `var' `=`var'[1]'
}

rename v35 New_Zealand

foreach var of varlist v36 - v38 {
   rename `var' `=`var'[1]' 
}

rename v39 Slovakia


foreach var of varlist v40 - v42 {
   rename `var' `=`var'[1]'
}

rename v43 United_States
rename v44 South_Africa
rename v45 Asia
rename v46 Europe


drop v47 v48 v49 v50 v51 v52


drop in 1 
destring, replace 

cap drop day
g day = substr(date, 1, 2)

cap drop month
g month = substr(date, 4, 2)

cap drop year 
g year = substr(date, 7, 2)

destring day month year, replace

replace year = 1900 + year if _n < 636
replace year = 2000 + year if _n >= 636

drop date
/*
g date  = mdy(month, day, year)
format date %td
*/
gen date=ym(year,month)
format date %tm

drop day month year

order date

foreach x of var * { 
	rename `x' v_`x' 
} 

rename v_date date


* generate recession varaible

foreach var of varlist v_* {
	
	g `var'_r = 1 if `var'[_n-1] == 1
	replace `var'_r = 2 if `var' == -1
	replace `var'_r = 1 if `var'_r[_n-1] == 1 & `var'_r[_n] != 2

replace `var'_r = 1 if `var'_r == 2
replace `var'_r = 0 if `var'_r[_n-1] == 1 & `var'_r == .

replace `var'_r = 0 if `var'_r[_n-1] == 0 & `var'_r == .

	
}



drop v_Australia v_Austria v_Belgium v_Brazil v_Canada v_Switzerland v_Chile v_China v_Colombia v_Czech_Republic v_Germany v_Denmark v_Spain v_Estonia v_Finland v_France v_United_Kingdom v_Greece v_Hungary v_Indonesia v_India v_Ireland v_Iceland v_Israel v_Italy v_Japan v_Korea v_Luxembourg v_Lithuania v_Latvia v_Mexico v_Netherlands v_Norway v_New_Zealand v_Poland v_Portugal v_Russia v_Slovakia v_Slovenia v_Sweden v_Turkey v_United_States v_South_Africa v_Asia v_Europe

reshape long v_, i(date) j(country) string

sort country date 

rename v_ ri


replace country = subinstr(country, "_r", "",.) 
replace country = subinstr(country, "_", " ",.) 


rename date datem


replace country = "South Korea" if country == "Korea"



* finale regression indicator data:
save "$recessionf/ri.dta", replace


********************************************************************************

use "$datace_imf/data_final_newVintage.dta", clear

merge m:1 country datem using "$recessionf/ri.dta"

drop if _merge == 2

drop _merge


save "$datace_imf/data_final_newVintage.dta", replace

********************************************************************************



* add industrial production to the database:

use "$datace_imf/data_final_newVintage.dta", clear

preserve

	import delimited "$indprod/IndustrialProduction_monthly.csv", clear

	drop flagcodes subject measure frequency indicator

	rename location country_short


	kountry country_short, from(iso3c) 

	drop country_short

	rename NAMES_STD country

	drop if country == "ea19"

	drop if country == "eu27_2020"

	generate year = substr(time,1,4)
	
	generate month = substr(time,6,8)
	
	destring year, replace
	destring month, replace
	
	g datem = ym(year, month)
	format datem %tm
	
	drop year month 
	
	rename value indProd
	
	
	encode country, gen(country_num)
	
	xtset country_num datem 
	sort country_num   datem
	
	
	bysort  country_num (datem): gen indProdgm = indProd / l.indProd - 1

	cap drop indProdgy
	bysort  country_num (datem): gen indProdgy = indProd / s12.indProd - 1

	
	bysort country : egen med_indProdgm =median(indProdgm)
	bysort country : egen med_indProdgy =median(indProdgy)
	bysort country : egen med_indProd 	=median(indProd)
	
	save $indprodf/indProd.dta, replace
	
restore


merge m:1 country datem using $indprodf/indProd.dta
drop if _merge == 2
drop _merge


label var med_indProdgm "Median Industrial Production (Monthly Growth Rate) for each Country"
label var med_indProdgy "Median Industrial Production (YoY (S12) Growth Rate) for each Country"
label var med_indProd "Median Industrial Production (Level) for each Country"




save "$datace_imf/data_final_newVintage.dta", replace


**********************************************************************************


use "$datace_imf/data_final_newVintage.dta", clear

* dummy indicator for crisis and recession

cap drop idci

egen idci = group(country institution)


egen crisis = rowmax(Banking_Crisis Currency_Crises Systemic_Crises Inflation_Crises Domestic* External* Sovereign*)
replace crisis = 1 if crisis==2

* generate crisis dummy that is equal to 1 only at the start of a crisis and zero o/w
sort country date institution

cap drop Dcrisis
g Dcrisis = .
bysort idci (datem): replace Dcrisis = 1 if crisis == 1 & crisis[_n-1] == 0
bysort idci (datem): replace Dcrisis = 0 if crisis == 1 & crisis[_n-1] == 1
bysort idci (datem): replace Dcrisis = 0 if crisis == 0 

label var Dcrisis "Onset Dummy for Crisis"


cap drop Drec

g rec = ri

label var rec "Recession turning points"

label var ri "Recession and Boom turning points"


g Drec = .
bysort idci (datem): replace Drec = 1 if ri == 1 & ri[_n-1] == 0
bysort idci (datem): replace Drec = 0 if ri == 1 & ri[_n-1] == 1
bysort idci (datem): replace Drec = 0 if ri == 0 

*sort country institution date
*br country institution date crisis Dcrisis

label var Drec "Onset Dummy for Recession (monthly)"


drop idci

save "$datace_imf/data_final_newVintage.dta", replace




********************************************************************************
***						Industries: correction								 ***
********************************************************************************

use "$datace_imf/data_final_newVintage.dta", clear


replace Industry = "" if institution == "ACM RESEARCH"
replace Industry = "Economic Research and Analytics" if institution == "ACRA"
replace Industry = "Consulting" if institution == "APOYO CONSULTORIA"
replace Industry = "Investment Banking and Securities Brokerage" if institution == "BAHANA SECURITIES"
replace Industry = "Management Consultancy" if institution == "BAIN & COMPANY"
replace Industry = "Economic Research and Consulting Institute" if institution == "BAK BASEL"
replace Industry = "Public Financial Institution" if institution == "CAISSE DES DEPOTS"
replace Industry = "" if institution == "CHRYSLER SECURITIES"
replace Industry = "Wealth Management Services" if institution == "CIBC WOOD GUNDY"
replace Industry = "Not-for-profit Membership Organisation" if institution == "CONFED OF BRITISH INDUSTRY"
replace Industry = "Banks" if institution == "CORP GROUP"
replace Industry = "Ratings, Research and Anlytics" if institution == "CRISIL"
replace Industry = "Data and Analytics" if institution == "D & B"
replace Industry = "Data and Analytics" if institution == "D&B"
replace Industry = "Economic Research Institute" if institution == "DAISHIN RESEARCH"
replace Industry = "Banks" if institution == "DEKA BANK"
replace Industry = "Banks" if institution == "DEKABANK"
replace Industry = "Financial Consulting" if institution == "DSP FINANCIAL CONSULT"
replace Industry = "Data and Analytics" if institution == "DUN & BRADSTREET"
replace Industry = "Economic Research and Analytics" if institution == "ECONOMIST INTELLIGENCE UNIT"
replace Industry = "Bond Credit Rating" if institution == "ECONOMY.COM"
replace Industry = "Investment and Financial Services" if institution == "ECONSULT"
replace Industry = "Investment Banking & Brokerage" if institution == "ECZACIBASI SECURITIES"
replace Industry = "Export Credit Agency" if institution == "EDC ECONOMICS"
replace Industry = "Banks" if institution == "EUROBANK TEKFENBANK"
replace Industry = "Market Research" if institution == "EUROMONITOR INTERNATIONAL"
replace Industry = "Business Services" if institution == "EXPERIAN"
replace Industry = "Mortgage Loan" if institution == "FANNIE MAE"
replace Industry = "Macroeconomic Advisory" if institution == "FATHOM CONSULTING"
replace Industry = "Business Support Services" if institution == "FAZ INSTITUTE"
replace Industry = "Financial Advisory Services" if institution == "FIRST NZ CAPITAL"
replace Industry = "Financial Advisory Services" if institution == "FIRST TRUST ADVISORS"
replace Industry = "Credit Rating" if institution == "FITCH RATINGS"
replace Industry = "Financial Advisory Services" if institution == "FNZC"
replace Industry = "Automotive Manufacturer" if institution == "GENERAL MOTORS"
replace Industry = "Investment Management" if institution == "GENERALI INVESTMENTS"
replace Industry = "Investment Management" if institution == "GK GOH"
replace Industry = "Investment Management" if institution == "GLOBAL SECURITIES"
replace Industry = "Analytics and Consulting" if institution == "GLOBALDATA"
replace Industry = "Investment Management" if institution == "GOOD MORNING SECURITIES"
replace Industry = "Investment Management" if institution == "GOODMORNING SECURITIES"
replace Industry = "Economic Research Institute" if institution == "HWWI"
replace Industry = "" if institution == "IDEA"
replace Industry = "" if institution == "IDEA GLOBAL"
replace Industry = "Chemicals" if institution == "IMPERIAL CHEMICAL INDS"
replace Industry = "Ratings, Research and Analytics" if institution == "INDIA RATINGS & RESEARCH"
replace Industry = "" if institution == "INFORMETRICA"
replace Industry = "Brokerage Services" if institution == "INTERFIP"
replace Industry = "Brokerage Services" if institution == "INTERFIP BOLSA"
replace Industry = "Economic Research Institute" if institution == "IWH - HALLE INSTITUTE"
replace Industry = "Asset Management and Merchant Banking" if institution == "KEMPEN & CO"
replace Industry = "Insurance" if institution == "KEMPER FINANCIAL"
replace Industry = "Investment Banking" if institution == "KLEINWORT BENSON"
replace Industry = "Investment Holding" if institution == "KOC SECURITIES"
replace Industry = "Economic Research" if institution == "KOPINT-DATORG"
replace Industry = "Insurance" if institution == "KOTAK SECURITIES"
replace Industry = "Professional Services" if institution == "KPMG"
replace Industry = "Trade Insurance and Trade Finance" if institution == "KUKE"
replace Industry = "Economic Consulting" if institution == "LCA CONSULTORES"
replace Industry = "Economic Research" if institution == "LG ECONOMIC RSRCH INST"
replace Industry = "Macroeconomic Forecasting Consultancy" if institution == "LOMBARD STREET RESEARCH"
replace Industry = "Economic Research and Consulting" if institution == "MACROCONSULT"
replace Industry = "Brokerage Services" if institution == "MATTEUS FONDKOMMISSION"
replace Industry = "Economic Research and Consulting" if institution == "MITSUBISHI RESEARCH INSTITUTE"
replace Industry = "Economic Research and Consulting" if institution == "MITSUBISHI UFJ RESEARCH"
replace Industry = "Banks" if institution == "MM WARBURG"
replace Industry = "Credit Ratings and Research" if institution == "MOODY'S CORPORATION"
replace Industry = "Brokerage Services" if institution == "MULTIVALORES"
replace Industry = "Commercial Banking Services" if institution == "NATIONALE INVESTERINGSBK"
replace Industry = "Economic Research Institute" if institution == "NIESR"
replace Industry = "Research and Analytics" if institution == "NIKKO RESEARCH"
replace Industry = "Financial Services" if institution == "NORDBANKEN"
replace Industry = "Retail Banking" if institution == "OP FINANCIAL GROUP"
replace Industry = "Investment Banking" if institution == "ORKLA ENSKILDA SECURITIES"
replace Industry = "Investment Management" if institution == "ORKLA FINANS"
replace Industry = "Economic Research and Consulting" if institution == "OXFORD - BAK BASEL"
replace Industry = "Economic Research" if institution == "OXFORD ECONOMICS"
replace Industry = "Banks" if institution == "OYAK BANK"
replace Industry = "Brokerage Services" if institution == "OYAK SECURITIES"
replace Industry = "Private Equity" if institution == "PANTHEON"
replace Industry = "Economic Research and Analytics" if institution == "PROMETEIA"
replace Industry = "Financial Services" if institution == "PRUDENTIAL FINANCIAL"
replace Industry = "Securities and Commodity Exchanges" if institution == "PUENTE HNOS"
replace Industry = "Wealth Management" if institution == "RBC DS"
replace Industry = "Economic Consulting" if institution == "RDQ ECONOMICS"
replace Industry = "Consulting" if institution == "ROSENBERG CONSULTORIA"
replace Industry = "Economic and Financial Analytics" if institution == "ROUBINI GLOBAL ECON"
replace Industry = "Economics Research Institute" if institution == "RWI ESSEN"
replace Industry = "Investment Banking" if institution == "SALOMON BROTHERS"
replace Industry = "Brokerage Services" if institution == "SMITH BARNEY SHEARSON"
replace Industry = "Credit Rating" if institution == "STANDARD & POOR'S"
replace Industry = "Alternative Investment" if institution == "SUN HUNG KAI RESEARCH"
replace Industry = "Alternative Investment" if institution == "SUN HUNG KAI SECURITIES"
replace Industry = "Financial Services" if institution == "SUN LIFE"
replace Industry = "Professional Services" if institution == "TATA SERVICES (DES)"
replace Industry = "Banks" if institution == "TEKFEN BANK"
replace Industry = "Economic Research and Consulting" if institution == "UFJ INSTITUTE"
replace Industry = "Financial Services" if institution == "UNION ASIA FINANCE"
replace Industry = "Banks" if institution == "UNITED STATES TRUST"
replace Industry = "Schools, Colleges & Universities" if institution == "UNIVERSIDAD DE CHILE"
replace Industry = "Mutual Fund" if institution == "UTI SECURITIES"
replace Industry = "Automotive Manufacturer" if institution == "VOLVO"
replace Industry = "Economic Consulting" if institution == "WELLERSHOFF & PARTNERS"
replace Industry = "Economic Forecasting" if institution == "WHARTON ECONOMETRIC FORECASTING ASSOCIATES"
replace Industry = "Investment Management" if institution == "WILLIAMS DE BROE"
replace Industry = "Investment Services" if institution == "WOOD GUNDY"



********************************************************************************
**************                    Risk Measure                    **************
********************************************************************************

// EPU
import excel "$epu/EPU_All_Country_Data.xlsx", sheet("EPU") firstrow clear

destring Year, force replace
drop if Year ==.

drop Australia Singapore SCMPChina HybridChina
drop A*

gen datem = ym(Year, Month)
format datem %tm

drop Year Month
order datem

preserve
	keep datem GEPU*
	save "$epuf/GEPU.dta", replace
restore

drop GEPU*

local vars Brazil Canada Chile Colombia France Germany Greece India Ireland Italy Japan Korea Netherlands Russia Spain UK US MainlandChina Sweden Mexico
foreach v of local vars{
	rename `v' X_`v'
}

reshape long X_, i(datem) j(country, string)

ren X_ EPU
label variable EPU "Economic Policy Uncertainty"

replace country = "South Korea" if country == "Korea"
replace country = "United Kingdom" if country == "UK"
replace country = "United States" if country == "US"
replace country = "China" if country == "MainlandChina"

merge m:1 datem using "$epuf/GEPU.dta"

drop _merge
label variable GEPU_current "Global Economic Policy Uncertainty: based on current-price GDP"
label variable GEPU_ppp "Global Economic Policy Uncertainty: based on PPP-adjusted GDP"

save "$epuf/EPU.dta", replace



// ICRG T3B: Political Risk

local components GovStab Socioeco InvProf IntConf ExtConf Corrupt Military Religious Law Ethnic DemoAcct Bureau
foreach c of local components{
	import excel "$icrg/ICRG_T3B_for stata.xlsx", sheet("`c'") firstrow clear

	gen datem = mofd(PubDate)
	format datem %tm
	drop PubDate
	order datem
	
	keep datem Argentina Austria Belgium Brazil Bulgaria Canada Chile China Colombia Croatia CzechRepublic Denmark Estonia Finland France Germany Greece Hungary India Indonesia Ireland Israel Italy Japan Latvia Lithuania Malaysia Mexico Netherlands NewZealand Nigeria Norway Peru Philippines Poland Portugal Russia SaudiArabia Slovakia Slovenia SouthAfrica SouthKorea Spain Sweden Switzerland Thailand Turkey UnitedKingdom UnitedStates Venezuela

	foreach var of varlist _all {
		if `var' != datem{
			ren `var' X_`var'
		}
	}

	reshape long X_, i(datem) j(country, string)
	rename X_ ICRG_`c'
	
	replace country = "Czech Republic" if country == "CzechRepublic"
	replace country = "New Zealand" if country == "NewZealand"
	replace country = "Saudi Arabia" if country == "SaudiArabia"
	replace country = "South Africa" if country == "SouthAfrica"
	replace country = "South Korea" if country == "SouthKorea"
	replace country = "United Kingdom" if country == "UnitedKingdom"
	replace country = "United States" if country == "UnitedStates"
	
	

	save "$icrgf/`c'.dta", replace

}

// merge all in one

use "$icrgf/GovStab.dta", clear

local components Socioeco InvProf IntConf ExtConf Corrupt Military Religious Law Ethnic DemoAcct Bureau
foreach c of local components{
	merge 1:1 datem country using "$icrgf/`c'.dta"
	drop _merge
}

save "$icrgf/ICRGT3B.dta", replace

// erase individual datasets
local components GovStab Socioeco InvProf IntConf ExtConf Corrupt Military Religious Law Ethnic DemoAcct Bureau
foreach c of local components{
	erase "$icrgf/`c'.dta"
}





// ICRG T4B: Financial Risk

local components ForDebt XRStab DebtServ CAXGS IntLiq
foreach c of local components{
	import excel "$icrg/ICRG_T4B_for stata.xlsx", sheet("`c'") firstrow clear

	gen datem = mofd(PubDate)
	format datem %tm
	drop PubDate
	order datem
	
	keep datem Argentina Austria Belgium Brazil Bulgaria Canada Chile China Colombia Croatia CzechRepublic Denmark Estonia Finland France Germany Greece Hungary India Indonesia Ireland Israel Italy Japan Latvia Lithuania Malaysia Mexico Netherlands NewZealand Nigeria Norway Peru Philippines Poland Portugal Russia SaudiArabia Slovakia Slovenia SouthAfrica SouthKorea Spain Sweden Switzerland Thailand Turkey UnitedKingdom UnitedStates Venezuela

	foreach var of varlist _all {
		if `var' != datem{
			ren `var' X_`var'
		}
	}

	reshape long X_, i(datem) j(country, string)
	rename X_ ICRG_`c'
	
	replace country = "Czech Republic" if country == "CzechRepublic"
	replace country = "New Zealand" if country == "NewZealand"
	replace country = "Saudi Arabia" if country == "SaudiArabia"
	replace country = "South Africa" if country == "SouthAfrica"
	replace country = "South Korea" if country == "SouthKorea"
	replace country = "United Kingdom" if country == "UnitedKingdom"
	replace country = "United States" if country == "UnitedStates"
	
	

	save "$icrgf/`c'.dta", replace

}

// merge all in one

use "$icrgf/ForDebt.dta", clear

local components XRStab DebtServ CAXGS IntLiq
foreach c of local components{
	merge 1:1 datem country using "$icrgf/`c'.dta"
	drop _merge
}

save "$icrgf/ICRGT4B.dta", replace

// erase individual datasets
local components ForDebt XRStab DebtServ CAXGS IntLiq
foreach c of local components{
	erase "$icrgf/`c'.dta"
}

// merge the two files together

use "$icrgf/ICRGT3B.dta", replace

merge 1:1 datem country using "$icrgf/ICRGT4B.dta"
drop _merge

save "$icrgf/ICRG_All.dta", replace


********************************************************************************
**************          Merge With the Main Dataset               **************
********************************************************************************

// EPU

use "$datace_imf/data_final_newVintage.dta", clear

merge m:1 country datem using "$epuf/EPU.dta"

// drop the dates that are not observed in the main dataset
drop if _merge == 2
drop _merge

// ICRG

merge m:1 country datem using "$icrgf/ICRG_All.dta"

// drop the dates that are not observed in the main dataset
drop if _merge == 2
drop _merge

// ICRG T3B variables: political risk
label variable ICRG_GovStab "Government stability"
label variable ICRG_Socioeco "Socioeconomic conditions"
label variable ICRG_InvProf "Investment Profile"
label variable ICRG_IntConf "Internal conflict"
label variable ICRG_ExtConf "External conflict"
label variable ICRG_Corrupt "Corruption"
label variable ICRG_Military "Military in politics"
label variable ICRG_Religious "Religious tensions"
label variable ICRG_Law "Law and order"
label variable ICRG_Ethnic "Ethnic tensions"
label variable ICRG_DemoAcct "Democratic accountability"
label variable ICRG_Bureau "Bureacracy quality"

// ICRG T4B variables: financial risk
label variable ICRG_ForDebt "Foreign Debt as a % of GDP"
label variable ICRG_XRStab "Exchange Rate Stability"
label variable ICRG_DebtServ "Debt Service as a % of XGS"
label variable ICRG_CAXGS "Current Account as % of XGS"
label variable ICRG_IntLiq "International Liquidity"

save "$datace_imf/data_final_newVintage_withRisk.dta", replace

********************************************************************************



* data
gen Emerging = (country == "Argentina" | country== "Brazil" | country==  "Bulgaria" | country==  "Chile" | country==  "China" | ///
country==  "Colombia"  | country== "Croatia"  | country== "Czech Republic"  | country== "Estonia"  | country=="Hungary"  | country=="India" ///
 | country== "Indonesia"  | country== "Israel"  | country== "Latvia"  | country== "Lithuania"  | country== "Malaysia"  | country== "Mexico"  ///
 | country==  "Nigeria"   | country== "Peru"  | country== "Philippines"  | country== "Poland"  | country== "Romania"  | country== "Russia" ///
 | country== "Saudi Arabia"  | country== "Slovakia"  | country==  "Slovenia"  | country== "South Africa"  | country=="South Korea"  | ///
 country== "Thailand"  | country== "Turkey"  | country== "Venezuela") 
 
gen Advanced = (Emerging==0)

egen idi = group(institution) 

egen N = count(gdp_current), by(institution date)

*egen crisis = rowmax(Banking_Crisis Currency_Crises Systemic_Crises Inflation_Crises Domestic* External* Sovereign*)
*replace crisis = 1 if crisis==2

egen idci = group(country institution)

g location_sub_n = .
replace location_sub_n = 1 if location_sub == "Local"
replace location_sub_n = 2 if location_sub == "Foreign"
replace location_sub_n = 3 if location_sub == "Multinational"

label define loc 1 "Local" 2 "Foreign" 3 "Multinational", modify
label values location_sub_n loc  

drop location

rename location_sub_n location

* we only keep observations for 1998 and later due to vintage series availability (for all countries not US)


*** FORECAST ERRORS ***
***********************


foreach hor in current future {
foreach var in gdp cpi {
	
	g FE_`var'_`hor'_s1 = vintage_`var'_`hor'_septp1 - `var'_`hor'
	g FE_`var'_`hor'_s2 = vintage_`var'_`hor'_septp2 - `var'_`hor'
	g FE_`var'_`hor'_s3 = vintage_`var'_`hor'_septp3 - `var'_`hor'
	
	g FE_`var'_`hor'_a1 = vintage_`var'_`hor'_aprtp1 - `var'_`hor'
	g FE_`var'_`hor'_a2 = vintage_`var'_`hor'_aprtp2 - `var'_`hor'
	g FE_`var'_`hor'_a3 = vintage_`var'_`hor'_aprtp3 - `var'_`hor'
	
}
}
	
	

* we only keep observations for 1998 and later due to vintage series availability (for all countries not US)
foreach month in s a {
	foreach y in 1 2 3 {
		foreach var in FE_gdp_current FE_gdp_future FE_cpi_current FE_cpi_future {
			replace `var'_`month'`y' = . if year<1998 
		}
	}
}



* Location variables

gen location_hea = location
replace location_hea = 1 if Headquarters == country

label value location_hea location
label define Emerging 0 "Advanced" 1 "Emerging"
label value Emerging Emerging

gen location_narrow = location
replace location_narrow = 1 if location ==3
label value location_narrow location
label var location_narrow "Location"

sort institution datem
by institution: egen Multinational = max(location)
replace Multinational = (Multinational==3)
label define Multinational 0 "National" 1 "Multinational"
label value Multinational Multinational

gen location_broad = location
replace location_broad = 4 if location==2 & Multinational==1
label define location_broad 1 "Local - National" 2 "Foreign - National" 3 "Local - Multinational" 4 "Foreign - Multinational"
label value location_broad location_broad

drop if location==.

gen Foreign = (location_narrow==2)
gen Local = (location_narrow==1)

sort institution datem
by institution datem: egen loc = max(Local)
by institution datem: egen for = max(Foreign)
gen locfor = loc*for


* Industry classification

encode Industry , generate(Ind) label(Industry)

gen Industry2 = .
replace Industry2 = 1 if Ind != .
replace Industry2 = 2 if Ind == 3
replace Industry2 = 3 if Ind == 21
replace Industry2 = 4 if Ind == 23 | Ind == 41 | Ind == 22
replace Industry2 = 5 if Ind == 25 | Ind == 37 | Ind == 38
replace Industry2 = 6 if Ind == 14 | Ind ==10
replace Industry2 = 7 if Ind == 36
replace Industry2 = 8 if Ind == 5 | Ind == 4 | Ind == 9
replace Industry2 = 9 if Ind == 1
replace Industry2 = 10 if Ind == 39 | Ind == 28 | Ind == 15
label define Industry2 2 "Commercial Banks" 3 "Investment Banks" 4 "Funds" 5 "Insurance Companies" 6 "Other Financial Services" 7 "Professional Information Services" 8 "Economic Intelligence" 9 "Advertising & Marketing" 10 "Education" 1 "Other Industries"
label values Industry2 Industry2

gen Industry3 = .
replace Industry3 = 1 if Ind != .
replace Industry3 = 2 if Ind == 3
replace Industry3 = 3 if Ind == 21
replace Industry3 = 4 if Ind == 23 | Ind == 41 | Ind == 22
replace Industry3 = 5 if Ind == 25 | Ind == 37 | Ind == 38
replace Industry3 = 6 if Ind == 14 | Ind ==10
replace Industry3 = 7 if Ind == 36 | Ind == 5 | Ind == 4 | Ind == 9 | Ind == 1
replace Industry3 = 8 if Ind == 39 | Ind == 28 | Ind == 15
label define Industry3 2 "Commercial Banks" 3 "Investment Banks" 4 "Funds" 5 "Insurance Companies" 6 "Other Financial Services" 7 "Economic Intelligence" 8 "Education" 1 "Other Industries"
label values Industry3 Industry3

gen Rating = (institution=="MOODY'S CORPORATION") + (institution=="FITCH RATINGS") + (institution=="STANDARD & POOR'S") + (institution=="STANDARD & POORS DRI") 

gen Industry4 = .
replace Industry4 = 1 if Ind != .
replace Industry4 = 2 if Ind == 3
replace Industry4 = 3 if Ind == 21
replace Industry4 = 4 if Ind == 23 | Ind == 41 | Ind == 22
replace Industry4 = 5 if Ind == 25 | Ind == 37 | Ind == 38
replace Industry4 = 6 if Ind == 14 | Ind ==10
replace Industry4 = 7 if (Ind == 36 | Ind == 5 | Ind == 4 | Ind == 9 | Ind == 1) & Rating==0
replace Industry4 = 8 if Rating==1
replace Industry4 = 9 if Ind == 39 | Ind == 28 | Ind == 15
label define Industry4 2 "Commercial Banks" 3 "Investment Banks" 4 "Funds" 5 "Insurance Companies" 6 "Other Financial Services" 7 "Economic Intelligence" 8 "Rating Agencies" 9 "Education" 10 "Other Industries"
label values Industry4 Industry4

gen Industry5 = .
replace Industry5 = 1 if Ind != .
replace Industry5 = 2 if Ind == 3
replace Industry5 = 3 if Ind == 21
replace Industry5 = 4 if Ind == 23 | Ind == 41 | Ind == 22
replace Industry5 = 5 if (Ind == 36 | Ind == 5 | Ind == 4 | Ind == 9 | Ind == 1) & Rating==0
replace Industry5 = 6 if Rating==1
replace Industry5 = 7 if Ind == 39 | Ind == 28 | Ind == 15
label define Industry5 2 "Commercial Banks" 3 "Investment Banks" 4 "Funds" 5 "Economic Intelligence" 6 "Rating Agencies" 7 "Education" 1 "Other Industries"
label values Industry5 Industry5

gen Industry6 = .
replace Industry6 = 1 if Ind != .
replace Industry6 = 2 if Ind == 3
replace Industry6 = 3 if Ind == 21
replace Industry6 = 4 if Ind == 23 | Ind == 41 | Ind == 22
replace Industry6 = 5 if Ind == 36 | Ind == 5 | Ind == 4 | Ind == 9 | Ind == 1 | Ind == 39 | Ind == 28 | Ind == 15
label define Industry6 2 "Commercial Banks" 3 "Investment Banks" 4 "Funds" 5 "Economic Intelligence" 1 "Other Industries"
label values Industry6 Industry6

gen Industry7 = Industry6
replace Industry7 = 3 if Industry6==4
replace Industry7 = 4 if Industry6==5
label define Industry7 2 "Commercial Banks" 3 "Other Financial" 4 "Non financial"
label values Industry7 Industry7

gen Banks = (Industry5==2)
gen Investment = (Industry5==3)
gen Funds = (Industry5==4)
gen Intelligence = (Industry5==5)
gen Education = (Industry5==7)
gen Other = (Industry5==1)

* Categorical variables

gen TotRev = .
replace TotRev = 1 if TotalRevenue<100000000
replace TotRev = 2 if TotalRevenue>=100000000 & TotalRevenue<1000000000
replace TotRev = 3 if TotalRevenue>=1000000000 & TotalRevenue<10000000000
replace TotRev = 4 if TotalRevenue>=10000000000 & TotalRevenue<100000000000
replace TotRev = 5 if TotalRevenue>=100000000000 & TotalRevenue<1000000000000
replace TotRev = 6 if TotalRevenue>=1000000000000
replace TotRev = . if TotalRevenue==.
label define TotRev 1 "Tot. rev.<100 mil." 2 "100 mil.<Tot. rev.<1 bil." 3 "1 bil.<Tot. rev.<10 bil." 4 "10 bil.<Tot. rev.<100 bil." 5 "100 bil.<Tot. rev.<1 tril." 6 "Tot. rev.>1 tril."
label value TotRev TotRev

gen Emp = .
replace Emp = 1 if Employees<100
replace Emp = 2 if Employees>=100 & Employees<1000
replace Emp = 3 if Employees>=1000 & Employees<10000
replace Emp = 4 if Employees>=10000 & Employees<100000
replace Emp = 5 if Employees>=100000
replace Emp = . if Employees==.
label define Emp 1 "Emp.<100" 2 "100<Emp.<1'000" 3 "1000<Emp.<10'000" 4 "10'000<Emp.<100'000'" 5 "Emp.>100'000"
label value Emp Emp

gen Market = .
replace Market = 1 if MarketCap<1000000000
replace Market = 2 if MarketCap>=1000000000 & MarketCap<10000000000
replace Market = 3 if MarketCap>=10000000000 & MarketCap<100000000000
replace Market = 4 if MarketCap>=100000000000 & MarketCap<1000000000000
replace Market = 5 if MarketCap>=1000000000000
replace Market = . if MarketCap==.
label define Market 1 "Cap.<1 bil." 2 "1 bil.<Cap.<10 bil." 3 "10 bil.<Cap.<100 bil." 4 "100 bil.<Cap.<1 tril." 5 "Cap.>1 tril."
label value Market Market

gen TotRev2 = 1 if TotRev==1 | TotRev==2
replace TotRev2 = 2 if TotRev==3
replace TotRev2 = 3 if TotRev==4 | TotRev==5
label define TotRev2 1 "Tot. rev.<1 bil." 2 "1 bil.<Tot. rev.<10 bil." 3 "10 bil.<Tot. rev."
label value TotRev2 TotRev2

gen Emerging0 = 1 if Emerging==0
gen Emerging1 = 1 if Emerging==1
gen Emerging2 = 1

qui unique country if Foreign!=., by(institution) gen(N_cty)
sort institution
by institution: egen N_cty2=mean(N_cty)
drop N_cty
gen N_cty = 0 if N_cty2<20
replace N_cty = 1 if N_cty2>=20

qui unique country if Foreign!=., by(institution year) gen(N_cty_by_year)
sort institution 
by institution: egen N_cty_by_year2=mean(N_cty_by_year)
drop N_cty_by_year
gen N_cty_by_year = 0 if N_cty_by_year2<10
replace N_cty_by_year = 1 if N_cty_by_year2>=10




********************************************************************************
********************************************************************************


* TRIM ERRORS
*use dat.dta, clear
drop if location==.

*drop if year == 1995 & country == "United States"


* TRIM ERRORS

foreach month in s a {
	foreach y in 1 2 3 {
		foreach var in gdp cpi {
			foreach hor in current future {
				local trimcut 1 99

				cap drop FE_`var'_`hor'_`month'`y'_wd
				cap drop FE_`var'_`hor'_`month'`y'_wd_wc
				cap drop FE_`var'_`hor'_`month'`y'_wd_wc_we

				winsor2 FE_`var'_`hor'_`month'`y' , by(datem) trim  cuts(`trimcut') suffix(_wd)
				winsor2 FE_`var'_`hor'_`month'`y'_wd , by(country) trim  cuts(`trimcut') suffix(_wc)
				winsor2 FE_`var'_`hor'_`month'`y'_wd_wc,  trim  cuts(`trimcut') suffix(_we) by(Emerging)
				
				* we store the old variable as FE_gdp_current_uw (for untrimmed) and replace the old variable name with the newly trimeed version:
				g FE_`var'_`hor'_`month'`y'_ut = FE_`var'_`hor'_`month'`y'
				drop FE_`var'_`hor'_`month'`y'
				g FE_`var'_`hor'_`month'`y' =  FE_`var'_`hor'_`month'`y'_wd_wc_we


			}
		}
	}
	
}



* TRIM ERRORS WITH DIFFERENT BOUNDARIES

foreach month in s a {
	foreach y in 1 2 3 {
		foreach var in gdp cpi {
			foreach hor in current future {
				local trimcut 0.5 99.5

				cap drop FE_`var'_`hor'_`month'`y'_ut_wdd
				cap drop FE_`var'_`hor'_`month'`y'_ut_wdd_wcc
				cap drop FE_`var'_`hor'_`month'`y'_ut_wdd_wcc_wee

				winsor2 FE_`var'_`hor'_`month'`y'_ut , by(datem) trim  cuts(`trimcut') suffix(_wdd)
				winsor2 FE_`var'_`hor'_`month'`y'_ut_wdd , by(country) trim  cuts(`trimcut') suffix(_wcc)
				winsor2 FE_`var'_`hor'_`month'`y'_ut_wdd_wcc,  trim  cuts(`trimcut') suffix(_wee) by(Emerging)
				
				* we store the old variable as FE_gdp_current_uw (for untrimmed) and replace the old variable name with the newly trimeed version:
				g FE_`var'_`hor'_`month'`y'_05995 =  FE_`var'_`hor'_`month'`y'_ut_wdd_wcc_wee


			}
		}
	}
	
}



* We calculate Revisions in two different ways

* REVISIONS VERSION 1:
xtset idci datem
cap drop FR*
local varlist gdp cpi

foreach var in `varlist' {

	g FR_`var' = .
	replace FR_`var' = `var'_current - l12.`var'_future

}

 

* REVISIONS VERSION 2:
xtset idci datem
local varlist gdp cpi
local horizon current future
foreach var in `varlist' {
    foreach hor in `horizon' {
		gen FR_`var'_`hor' = .
		replace FR_`var'_`hor' = `var'_`hor'-l.`var'_`hor' if month!=1
		replace FR_`var'_`hor' = `var'_current-l.`var'_future if month==1 & "`hor'"=="current"
	}
}




*use dat.dta, clear

* TRIM REVISIONS

foreach var in gdp cpi {
	foreach hor in current future {
		local trimcut 1 99

		cap drop FR_`var'_`hor'_wd
		cap drop FR_`var'_`hor'_wd_wc
		cap drop FR_`var'_`hor'_wd_wc_we

		winsor2 FR_`var'_`hor' , by(datem) trim  cuts(`trimcut') suffix(_wd)
		winsor2 FR_`var'_`hor'_wd , by(country) trim  cuts(`trimcut') suffix(_wc)
		winsor2 FR_`var'_`hor'_wd_wc,  trim  cuts(`trimcut') suffix(_we) by(Emerging)
		
		* we store the old variable as FE_gdp_current_uw (for unwinsorized) and replace the old variable name with the newly winsorized version:
		cap drop FR_`var'_`hor'_ut 
		g FR_`var'_`hor'_ut = FR_`var'_`hor'
		cap drop FR_`var'_`hor'
		g FR_`var'_`hor' =  FR_`var'_`hor'_wd_wc_we


	}
}




* TRIM REVISIONS WITH DIFFERENT BOUNDARIES

foreach var in gdp cpi {
	foreach hor in current future {
		local trimcut 0.5 99.5

		cap drop FR_`var'_`hor'_wdd
		cap drop FR_`var'_`hor'_wdd_wcc
		cap drop FR_`var'_`hor'_wdd_wcc_wee

		winsor2 FR_`var'_`hor'_ut , by(datem) trim  cuts(`trimcut') suffix(_wdd)
		winsor2 FR_`var'_`hor'_ut_wdd , by(country) trim  cuts(`trimcut') suffix(_wcc)
		winsor2 FR_`var'_`hor'_ut_wdd_wcc,  trim  cuts(`trimcut') suffix(_wee) by(Emerging)
		
		* we store the old variable as FE_gdp_current_uw (for unwinsorized) and replace the old variable name with the newly winsorized version:
		cap drop FR_`var'_`hor'_05995
		g FR_`var'_`hor'_05995 =  FR_`var'_`hor'_ut_wdd_wcc_wee


	}
}






********************************************************************************
* ABSOLUTE ERRORS
********************************************************************************

foreach x in s1 s2 s3 a1 a2 a3 {
	
	foreach var in FE_gdp FE_cpi  {
		
		foreach hor in current future  {
			
			gen abs_`var'_`hor'_`x' = abs(`var'_`hor'_`x')
		
		}
		
	}
}

	
local varlist gdp cpi  	/* gdp cpi sir lir */
local horlist current future 	/* current future */

foreach x in s1 s2 s3 a1 a2 a3 {
	foreach var in `varlist' {
		foreach hor in `horlist'{
			gen labs_FE_`var'_`hor'_`x' = log(abs_FE_`var'_`hor'_`x')
			replace labs_FE_`var'_`hor'_`x' = log(0.01) if abs_FE_`var'_`hor'_`x' < 0.01
			replace labs_FE_`var'_`hor'_`x' = log(10) if abs_FE_`var'_`hor'_`x' > 10 & abs_FE_`var'_`hor'_`x' != .
		}
	}
}



* april seems the best solution
g FE_gdp = FE_gdp_current_a1
g FE_cpi = FE_cpi_current_a1


* Drop vintage series to correspond to the Forecast Error series:
******************

* april variables
foreach x in 1 2 3 {
	foreach var in gdp cpi {
		foreach hor in current future {
			
			* vintage series:
			g vintage_`var'_`hor'_t_a`x' = vintage_`var'_`hor'_aprtp`x' if FE_`var'_`hor'_a`x' != .
			
		}
		
	}
}

* september variables
foreach x in 1 2 3 {
	foreach var in gdp cpi {
		foreach hor in current future {
			
			* vintage series:
			g vintage_`var'_`hor'_t_s`x' = vintage_`var'_`hor'_septp`x' if FE_`var'_`hor'_s`x' != .
			
		}
		
	}
}



cap drop year
g year = year(date)




* foreign headquarter:
g ForeignHQ = Headquarters != country

* foreign subsidiaries:
g ForeignSubsidiary = Foreign - ForeignHQ


save "$datace_imf/data_final_newVintage_2.dta", replace


*********************************************************************************
* MERGE GRAVITY DATABASE


use "$gravity/gravity.dta", clear

rename country_o country

rename country_d Headquarters

replace country = "United States" if country == "United States of America"

replace Headquarters = "United States" if Headquarters == "United States of America"

merge m:1 country using "C:\Users\eliob\Dropbox\4Foreign vs local expectations\Data\Gravity Data\list_countries_ce.dta"

drop if _merge == 1

drop _merge

save "$gravityf/gravity_to_merge.dta", replace



use "$datace_imf/data_final_newVintage_2.dta", clear


merge m:1 year country Headquarters using "$gravityf/gravity_to_merge.dta"
drop if _merge == 2

* a few observations are not matched because missing headquarter (around 3000). the other 3000 observations are observations after 2019
*br if _merge == 1 & Headquarters != ""

drop _merge

order country country_num institution id date datem month

* note that, for the gravity data, the country of origin is the variable country
* the country of destination is the country of the headquarter


save "$datace_imf/data_final_newVintage_2.dta", replace




use "$datace_imf/data_final_newVintage_2.dta", clear
cap drop dateq
g dateq = qofd(date)
format dateq %tq

* we should also merge the information to the nearest subsidiary! 
* First step: merge the information about the distance variables to all subsidiaries: (we have 121 subsidiaries)

keep subsidiaryCountry* year country country_num date datem dateq month institution id Headquarters dist*

gen subsidiaryCountry0 = Headquarters

save "$datace_imf/data_final_newVintage_2_toMergeGravity.dta" , replace





forval x = 0(1)121{
	
	*preserve
	
	* we match data from the gravity base to the subsidiaries in consensus economics data base.
	* for this, we define the headquarter in the gravity database to dynamically be equal to the
	* name of subsidiarycountryX . Then, we match the distance measures for this country 
	
	*local x = 2
	use "$gravityf/gravity_to_merge.dta", clear
	
	keep year country Headquarters dist distw distcap distwces dist_source
	
	rename dist ABdist`x' 
	rename distw CDdistw`x' 
	rename distcap DEdistcap`x' 
	rename distwces FGdistwces`x' 
	rename dist_source HIdist_source`x'
	
	rename Headquarters subsidiaryCountry`x'
	
	save "$gravityf/gravity_temp.dta", replace
	
	use "$datace_imf/data_final_newVintage_2_toMergeGravity.dta", clear
	
	merge m:1 year country subsidiaryCountry`x' using "$gravityf/gravity_temp.dta"
	drop if _merge == 2
	drop _merge

	save "$datace_imf/data_final_newVintage_2_toMergeGravity.dta", replace
	
	disp("`x'")
	
}


save "$gravityf/gravity_temp.dta", replace


use "$datace_imf/data_final_newVintage_2.dta", clear


gen dateq = qofd(date)
format dateq %tq



merge 1:1 country institution datem dateq Headquarters using "$gravityf/gravity_temp.dta"
drop _merge

rename dist distHQ
rename distw distwHQ
rename distcap distcapHQ
rename distwces distwcesHQ
rename dist_source dist_sourceHQ


* now, we have to identify , for each distance variable, which is the subsidiary that is closest to the country of forecasts
egen min_ABdist_subs = rowmin(ABdist0 ABdist1 ABdist2 ABdist3 ABdist4 ABdist5 ABdist6 ABdist7 ABdist8 ABdist9 ABdist10 ABdist11 ABdist12 ABdist13 ABdist14 ABdist15 ABdist16 ABdist17 ABdist18 ABdist19 ABdist20 ABdist21 ABdist22 ABdist23 ABdist24 ABdist25 ABdist26 ABdist27 ABdist28 ABdist29 ABdist30 ABdist31 ABdist32 ABdist33 ABdist34 ABdist35 ABdist36 ABdist37 ABdist38 ABdist39 ABdist40 ABdist41 ABdist42 ABdist43 ABdist44 ABdist45 ABdist46 ABdist47 ABdist48 ABdist49 ABdist50 ABdist51 ABdist52 ABdist53 ABdist54 ABdist55 ABdist56 ABdist57 ABdist58 ABdist59 ABdist60 ABdist61 ABdist62 ABdist63 ABdist64 ABdist65 ABdist66 ABdist67 ABdist68 ABdist69 ABdist70 ABdist71 ABdist72 ABdist73 ABdist74 ABdist75 ABdist76 ABdist77 ABdist78 ABdist79 ABdist80 ABdist81 ABdist82 ABdist83 ABdist84 ABdist85 ABdist86 ABdist87 ABdist88 ABdist89 ABdist90 ABdist91 ABdist92 ABdist93 ABdist94 ABdist95 ABdist96 ABdist97 ABdist98 ABdist99 ABdist100 ABdist101 ABdist102 ABdist103 ABdist104 ABdist105 ABdist106 ABdist107 ABdist108 ABdist109 ABdist110 ABdist111 ABdist112 ABdist113 ABdist114 ABdist115 ABdist116 ABdist117 ABdist118 ABdist119 ABdist120 ABdist121)

egen min_CDdistw_subs = rowmin(CDdistw0 CDdistw1 CDdistw2 CDdistw3 CDdistw4 CDdistw5 CDdistw6 CDdistw7 CDdistw8 CDdistw9 CDdistw10 CDdistw11 CDdistw12 CDdistw13 CDdistw14 CDdistw15 CDdistw16 CDdistw17 CDdistw18 CDdistw19 CDdistw20 CDdistw21 CDdistw22 CDdistw23 CDdistw24 CDdistw25 CDdistw26 CDdistw27 CDdistw28 CDdistw29 CDdistw30 CDdistw31 CDdistw32 CDdistw33 CDdistw34 CDdistw35 CDdistw36 CDdistw37 CDdistw38 CDdistw39 CDdistw40 CDdistw41 CDdistw42 CDdistw43 CDdistw44 CDdistw45 CDdistw46 CDdistw47 CDdistw48 CDdistw49 CDdistw50 CDdistw51 CDdistw52 CDdistw53 CDdistw54 CDdistw55 CDdistw56 CDdistw57 CDdistw58 CDdistw59 CDdistw60 CDdistw61 CDdistw62 CDdistw63 CDdistw64 CDdistw65 CDdistw66 CDdistw67 CDdistw68 CDdistw69 CDdistw70 CDdistw71 CDdistw72 CDdistw73 CDdistw74 CDdistw75 CDdistw76 CDdistw77 CDdistw78 CDdistw79 CDdistw80 CDdistw81 CDdistw82 CDdistw83 CDdistw84 CDdistw85 CDdistw86 CDdistw87 CDdistw88 CDdistw89 CDdistw90 CDdistw91 CDdistw92 CDdistw93 CDdistw94 CDdistw95 CDdistw96 CDdistw97 CDdistw98 CDdistw99 CDdistw100 CDdistw101 CDdistw102 CDdistw103 CDdistw104 CDdistw105 CDdistw106 CDdistw107 CDdistw108 CDdistw109 CDdistw110 CDdistw111 CDdistw112 CDdistw113 CDdistw114 CDdistw115 CDdistw116 CDdistw117 CDdistw118 CDdistw119 CDdistw120 CDdistw121)


egen min_DEdistcap_subs = rowmin(DEdistcap0 DEdistcap1 DEdistcap2 DEdistcap3 DEdistcap4 DEdistcap5 DEdistcap6 DEdistcap7 DEdistcap8 DEdistcap9 DEdistcap10 DEdistcap11 DEdistcap12 DEdistcap13 DEdistcap14 DEdistcap15 DEdistcap16 DEdistcap17 DEdistcap18 DEdistcap19 DEdistcap20 DEdistcap21 DEdistcap22 DEdistcap23 DEdistcap24 DEdistcap25 DEdistcap26 DEdistcap27 DEdistcap28 DEdistcap29 DEdistcap30 DEdistcap31 DEdistcap32 DEdistcap33 DEdistcap34 DEdistcap35 DEdistcap36 DEdistcap37 DEdistcap38 DEdistcap39 DEdistcap40 DEdistcap41 DEdistcap42 DEdistcap43 DEdistcap44 DEdistcap45 DEdistcap46 DEdistcap47 DEdistcap48 DEdistcap49 DEdistcap50 DEdistcap51 DEdistcap52 DEdistcap53 DEdistcap54 DEdistcap55 DEdistcap56 DEdistcap57 DEdistcap58 DEdistcap59 DEdistcap60 DEdistcap61 DEdistcap62 DEdistcap63 DEdistcap64 DEdistcap65 DEdistcap66 DEdistcap67 DEdistcap68 DEdistcap69 DEdistcap70 DEdistcap71 DEdistcap72 DEdistcap73 DEdistcap74 DEdistcap75 DEdistcap76 DEdistcap77 DEdistcap78 DEdistcap79 DEdistcap80 DEdistcap81 DEdistcap82 DEdistcap83 DEdistcap84 DEdistcap85 DEdistcap86 DEdistcap87 DEdistcap88 DEdistcap89 DEdistcap90 DEdistcap91 DEdistcap92 DEdistcap93 DEdistcap94 DEdistcap95 DEdistcap96 DEdistcap97 DEdistcap98 DEdistcap99 DEdistcap100 DEdistcap101 DEdistcap102 DEdistcap103 DEdistcap104 DEdistcap105 DEdistcap106 DEdistcap107 DEdistcap108 DEdistcap109 DEdistcap110 DEdistcap111 DEdistcap112 DEdistcap113 DEdistcap114 DEdistcap115 DEdistcap116 DEdistcap117 DEdistcap118 DEdistcap119 DEdistcap120 DEdistcap121)

egen min_FGdistwces_subs = rowmin(FGdistwces0 FGdistwces1 FGdistwces2 FGdistwces3 FGdistwces4 FGdistwces5 FGdistwces6 FGdistwces7 FGdistwces8 FGdistwces9 FGdistwces10 FGdistwces11 FGdistwces12 FGdistwces13 FGdistwces14 FGdistwces15 FGdistwces16 FGdistwces17 FGdistwces18 FGdistwces19 FGdistwces20 FGdistwces21 FGdistwces22 FGdistwces23 FGdistwces24 FGdistwces25 FGdistwces26 FGdistwces27 FGdistwces28 FGdistwces29 FGdistwces30 FGdistwces31 FGdistwces32 FGdistwces33 FGdistwces34 FGdistwces35 FGdistwces36 FGdistwces37 FGdistwces38 FGdistwces39 FGdistwces40 FGdistwces41 FGdistwces42 FGdistwces43 FGdistwces44 FGdistwces45 FGdistwces46 FGdistwces47 FGdistwces48 FGdistwces49 FGdistwces50 FGdistwces51 FGdistwces52 FGdistwces53 FGdistwces54 FGdistwces55 FGdistwces56 FGdistwces57 FGdistwces58 FGdistwces59 FGdistwces60 FGdistwces61 FGdistwces62 FGdistwces63 FGdistwces64 FGdistwces65 FGdistwces66 FGdistwces67 FGdistwces68 FGdistwces69 FGdistwces70 FGdistwces71 FGdistwces72 FGdistwces73 FGdistwces74 FGdistwces75 FGdistwces76 FGdistwces77 FGdistwces78 FGdistwces79 FGdistwces80 FGdistwces81 FGdistwces82 FGdistwces83 FGdistwces84 FGdistwces85 FGdistwces86 FGdistwces87 FGdistwces88 FGdistwces89 FGdistwces90 FGdistwces91 FGdistwces92 FGdistwces93 FGdistwces94 FGdistwces95 FGdistwces96 FGdistwces97 FGdistwces98 FGdistwces99 FGdistwces100 FGdistwces101 FGdistwces102 FGdistwces103 FGdistwces104 FGdistwces105 FGdistwces106 FGdistwces107 FGdistwces108 FGdistwces109 FGdistwces110 FGdistwces111 FGdistwces112 FGdistwces113 FGdistwces114 FGdistwces115 FGdistwces116 FGdistwces117 FGdistwces118 FGdistwces119 FGdistwces120 FGdistwces121)

egen min_HIdist_source_subs = rowmin(HIdist_source0 HIdist_source1 HIdist_source2 HIdist_source3 HIdist_source4 HIdist_source5 HIdist_source6 HIdist_source7 HIdist_source8 HIdist_source9 HIdist_source10 HIdist_source11 HIdist_source12 HIdist_source13 HIdist_source14 HIdist_source15 HIdist_source16 HIdist_source17 HIdist_source18 HIdist_source19 HIdist_source20 HIdist_source21 HIdist_source22 HIdist_source23 HIdist_source24 HIdist_source25 HIdist_source26 HIdist_source27 HIdist_source28 HIdist_source29 HIdist_source30 HIdist_source31 HIdist_source32 HIdist_source33 HIdist_source34 HIdist_source35 HIdist_source36 HIdist_source37 HIdist_source38 HIdist_source39 HIdist_source40 HIdist_source41 HIdist_source42 HIdist_source43 HIdist_source44 HIdist_source45 HIdist_source46 HIdist_source47 HIdist_source48 HIdist_source49 HIdist_source50 HIdist_source51 HIdist_source52 HIdist_source53 HIdist_source54 HIdist_source55 HIdist_source56 HIdist_source57 HIdist_source58 HIdist_source59 HIdist_source60 HIdist_source61 HIdist_source62 HIdist_source63 HIdist_source64 HIdist_source65 HIdist_source66 HIdist_source67 HIdist_source68 HIdist_source69 HIdist_source70 HIdist_source71 HIdist_source72 HIdist_source73 HIdist_source74 HIdist_source75 HIdist_source76 HIdist_source77 HIdist_source78 HIdist_source79 HIdist_source80 HIdist_source81 HIdist_source82 HIdist_source83 HIdist_source84 HIdist_source85 HIdist_source86 HIdist_source87 HIdist_source88 HIdist_source89 HIdist_source90 HIdist_source91 HIdist_source92 HIdist_source93 HIdist_source94 HIdist_source95 HIdist_source96 HIdist_source97 HIdist_source98 HIdist_source99 HIdist_source100 HIdist_source101 HIdist_source102 HIdist_source103 HIdist_source104 HIdist_source105 HIdist_source106 HIdist_source107 HIdist_source108 HIdist_source109 HIdist_source110 HIdist_source111 HIdist_source112 HIdist_source113 HIdist_source114 HIdist_source115 HIdist_source116 HIdist_source117 HIdist_source118 HIdist_source119 HIdist_source120 HIdist_source121)





* dummy to identify the subsidiary (or headquarter):
foreach var in ABdist CDdistw DEdistcap FGdistwces HIdist_source {

cap drop countryToMatch_`var'

cap drop flag_`var'

g countryToMatch_`var' = ""

g flag_`var' = .

forval x = 0(1)121{
	
	* replace the minimum distance subsidiary variable with the respective country if the distance matches 
	replace countryToMatch_`var' = subsidiaryCountry`x' if  round(`var'`x',8) == round(min_`var'_subs,8) & countryToMatch_`var' == ""
	
}
	
}


keep country country_num institution id date datem dateq countryToMatch_ABdist countryToMatch_CDdistw countryToMatch_DEdistcap countryToMatch_FGdistwces 

rename countryToMatch_ABdist closest_ctry_dist
rename countryToMatch_CDdistw closest_ctry_distw
rename countryToMatch_DEdistcap closest_ctry_distcap
rename countryToMatch_FGdistwces closest_ctry_distwces

sort country id datem 

save "$gravityf/gravity_temp2.dta", replace



* First, we add this information to the original database:

use "$datace_imf/data_final_newVintage_2.dta", clear

gen dateq = qofd(date)
format dateq %tq

merge 1:1 country country_num institution id date datem dateq using "$gravityf/gravity_temp2.dta"
drop _merge


save "$datace_imf/data_final_newVintage_2.dta", replace



* to match the gravity database with all variables to the different distance measures, we will just add a prefix to all variables of the gravity database 
* such that it is clear which distance measure was used to select the closest country


foreach var in dist distw distcap distwces {
	
use "$gravityf/gravity_to_merge.dta", clear

foreach x of var * { 
	rename `x' `var'_`x' 
} 

rename `var'_Headquarters closest_ctry_`var'
rename `var'_year year
rename `var'_country country

save "$gravityf/gravity_to_merge_`var'.dta", replace

}

use "$datace_imf/data_final_newVintage_2.dta", clear

merge m:1 year country closest_ctry_dist using "$gravityf/gravity_to_merge_dist.dta"
drop if _merge == 2
drop _merge

merge m:1 year country closest_ctry_distw using "$gravityf/gravity_to_merge_distw.dta"
drop if _merge == 2
drop _merge

merge m:1 year country closest_ctry_distcap using "$gravityf/gravity_to_merge_distcap.dta"
drop if _merge == 2
drop _merge

merge m:1 year country closest_ctry_distwces using "$gravityf/gravity_to_merge_distwces.dta"
drop if _merge == 2
drop _merge

save "$datace_imf/data_final_newVintage_2.dta", replace

*********************************************************************************


* ADD BIS LOCATIONAL DATA TO IT:

import delimited "$bis/BIS_locationalStatistics_selected.csv", clear


foreach var of varlist _all {
   local vl = "`vl' `var'"
}

local exclude "v1"
local vl: list vl - exclude
di "`vl'"


foreach var of varlist `vl'  {
	
	preserve

		keep v1 `var'
		
	    g reportingCountry = `var'[9]
		g counterpartyCountry = `var'[11]
		g balanceSheet = `var'[3]
		
		drop if _n < 17
		
		rename v1 date
		rename `var' bis
		
		replace bis = "" if bis == "NaN"
		destring bis, replace
		
		cap drop reportingCountry2
		local slash strpos(reportingCountry, ":")
		gen reportingCountry2 = trim(cond(`slash', substr(reportingCountry, 4, `slash' +20), reportingCountry))

		cap drop counterpartyCountry2
		local slash strpos(reportingCountry, ":")
		gen counterpartyCountry2 = trim(cond(`slash', substr(counterpartyCountry, 4, `slash' +20), counterpartyCountry))
		
		local slash strpos(reportingCountry, ":")
		gen varname = trim(cond(`slash', substr(balanceSheet, 3, `slash' +20), balanceSheet))
		replace varname = lower(varname)
		replace varname = subinstr(varname, " ", "", .)
		
		
		destring bis, replace
		
		local name = varname[1] 
		rename bis `name'
		
		drop reportingCountry counterpartyCountry balanceSheet
		rename reportingCountry2 reportingCountry
		rename counterpartyCountry2 counterpartyCountry
		
		gen dateq = quarterly(date, "YQ")
		format dateq %tq
		
		drop date
		
		if varname[1] == "totalclaims"{
			local savestring = "$bisf/" + "`var'" + "claims.dta"
		}
		else {
		local savestring = "$bisf/" + "`var'" + "liabs.dta"
		
		}
		
		disp("`savestring'")
		
		drop varname
		
		save "`savestring'", replace
		
		
	restore
	
	
	
}





use "$bisf/v2claims.dta", clear


forval x = 3(1)2400 {
	
	
	local fl = "$bisf/v" + "`x'" + "claims.dta"
	disp("`fl'")
	capture confirm file "`fl'"
	*display _rc
	
	if _rc==0 {
		append using "`fl'"
		}

}

save "$bisf/all_claims.dta", replace


use "$bisf/v40liabs.dta", clear
forval x = 41(1)2400 {
	
	
	local fl = "$bisf/v" + "`x'" + "liabs.dta"
	disp("`fl'")
	capture confirm file "`fl'"
	*display _rc
	
	if _rc==0 {
		append using "`fl'"
		}

}




merge 1:1 reportingCountry counterpartyCountry dateq using "$bisf/all_claims.dta"

drop _merge

order dateq reportingCountry counterpartyCountry

sort  reportingCountry counterpartyCountry dateq



preserve

	rename reportingCountry country
	rename counterpartyCountry Headquarters
	rename totalliabilities totalliabilities1
	rename totalclaims totalclaims1
	
	label var totalliabilities1 "liabilities - reporting country is country, counterparty country is headquarter"
	label var totalclaims1 "claims - reporting country is country, counterparty country is headquarter"

	save  "$bisf/BIS_all_1.dta", replace

restore

preserve

	rename reportingCountry Headquarters
	rename counterpartyCountry country
	rename totalliabilities totalliabilities2
	rename totalclaims totalclaims2
	
	label var totalliabilities2 "liabilities - reporting country is headquarters, counterparty country is country"
	label var totalclaims2 "claims - reporting country is headquarters, counterparty country is country"
	
	save  "$bisf/BIS_all_2.dta", replace

restore


forval x = 1(1)2400 {
	
	
	local fl = "$bisf/v" + "`x'" + "liabs.dta"
	disp("`fl'")
	capture confirm file "`fl'"
	*display _rc
	
	if _rc==0 {
		capture erase "`fl'"
		}

}

forval x = 1(1)2400 {
	
	
	local fl = "$bisf/v" + "`x'" + "claims.dta"
	disp("`fl'")
	capture confirm file "`fl'"
	*display _rc
	
	if _rc==0 {
		capture erase "`fl'"
		}

}

erase "$bisf/all_claims.dta"




use "$datace_imf/data_final_newVintage_2.dta", clear

sort country date institution
order country country_num institution id date datem dateq

* MERGE  BIS:
merge m:1 country Headquarters dateq using "$bisf/BIS_all_1.dta"
drop if _merge == 2
drop _merge



merge m:1 country Headquarters dateq using "$bisf/BIS_all_2.dta"
drop if _merge == 2
drop _merge






* merge data with main database:


foreach var in dist distw distcap distwces {
	
use "$bisf/BIS_all_1.dta", clear

rename Headquarters closest_ctry_`var'
rename totalliabilities1 totalliabilities1_`var'
rename totalclaims1 totalclaims1_`var'

save "$bisf/BIS_all_1_`var'.dta", replace


use "$bisf/BIS_all_2.dta", clear

rename Headquarters closest_ctry_`var'
rename totalliabilities2 totalliabilities2_`var'
rename totalclaims2 totalclaims2_`var'

save "$bisf/BIS_all_2_`var'.dta", replace


}


* Now, we do he merging also with respect to the nearest subsidiary!

use "$datace_imf/data_final_newVintage_2.dta", clear

foreach var in dist distw distcap distwces {


merge m:1 country closest_ctry_`var' dateq using "$bisf/BIS_all_1_`var'.dta"
drop if _merge == 2
drop _merge

merge m:1 country closest_ctry_`var' dateq using "$bisf/BIS_all_2_`var'.dta"
drop if _merge == 2
drop _merge

}



save "$datace_imf/data_final_newVintage_2.dta", replace



* add additional data from world-bank. note that the original code used to create this data
* is stored in the do-file "generate_wb_indicators". however, these data are not accessible anymore 
* and only stored in the archive. we put the resulting data from the generate_wb_indicators.do file
* in the produced folder to replicate our original database.



* merge with original dataset:
use "$datace_imf/data_final_newVintage_2.dta", clear

merge m:1 year country using "$worldbankf/world_bank_data_yearly.dta"
drop if _merge == 2
drop _merge


* label the variables:

label var cc_est "Control of Corruption: Estimate"
label var ge_est "Government Effectiveness: Estimate"
label var pv_est "Political Stability and Absence of Violence/Terrorism: Estimate"
label var rq_est "Regulatory Quality: Estimate"
label var rl_est "Rule of Law: Estimate"
label var va_est "Voice and Accountability: Estimate"
label var iq_sci_mthd "Methodology assessment of statistical capacity (scale 0 - 100)"
label var iq_sci_prdc "Periodicity and timeliness assessment of statistical capacity (scale 0 - 100)"
label var iq_sci_srce "Source data assessment of statistical capacity (scale 0 - 100)"
label var iq_sci_ovrl "Statistical Capacity Score (Overall Average) (scale 0 - 100)"
label var iq_spi_ovrl "Statistical performance indicators (SPI): Overall score (scale 0-100)"
label var iq_spi_pil1 "Statistical performance indicators (SPI): Pillar 1 data use score (scale 0-100)"
label var iq_spi_pil2 "Statistical performance indicators (SPI): Pillar 2 data services score (scale 0-100)"
label var iq_spi_pil3 "Statistical performance indicators (SPI): Pillar 3 data products score  (scale 0-100)"
label var iq_spi_pil4 "Statistical performance indicators (SPI): Pillar 4 data sources score (scale 0-100)"
label var iq_spi_pil5 "Statistical performance indicators (SPI): Pillar 5 data infrastructure score (scale 0-100)"
label var iq_cpa_hres_xq "CPIA building human resources rating (1=low to 6=high)"
label var iq_cpa_breg_xq "CPIA business regulatory environment rating (1=low to 6=high)"
label var iq_cpa_debt_xq "CPIA debt policy rating (1=low to 6=high)"
label var iq_cpa_econ_xq "CPIA economic management cluster average (1=low to 6=high)"
label var iq_cpa_revn_xq "CPIA efficiency of revenue mobilization rating (1=low to 6=high)"
label var iq_cpa_pres_xq "CPIA equity of public resource use rating (1=low to 6=high)"
label var iq_cpa_fins_xq "CPIA financial sector rating (1=low to 6=high)"
label var iq_cpa_fisp_xq "CPIA fiscal policy rating (1=low to 6=high)"
label var iq_cpa_gndr_xq "CPIA gender equality rating (1=low to 6=high)"
label var iq_cpa_macr_xq "CPIA macroeconomic management rating (1=low to 6=high)"
label var iq_cpa_soci_xq "CPIA policies for social inclusion/equity cluster average (1=low to 6=high)"
label var iq_cpa_envr_xq "CPIA policy and institutions for environmental sustainability rating (1=low to 6=high)"
label var iq_cpa_prop_xq "CPIA property rights and rule-based governance rating (1=low to 6=high)"
label var iq_cpa_pubs_xq "CPIA public sector management and institutions cluster average (1=low to 6=high)"
label var iq_cpa_finq_xq "CPIA quality of budgetary and financial management rating (1=low to 6=high)"
label var iq_cpa_padm_xq "CPIA quality of public administration rating (1=low to 6=high)"
label var iq_cpa_prot_xq "CPIA social protection rating (1=low to 6=high)"
label var iq_cpa_strc_xq "CPIA structural policies cluster average (1=low to 6=high)"
label var iq_cpa_trad_xq "CPIA trade rating (1=low to 6=high)"
label var iq_cpa_tran_xq "CPIA transparency, accountability, and corruption in the public sector rating (1=low to 6=high)"




save "$datace_imf/data_final_newVintage_3.dta", replace



* add data about VIX
***********************

use "$vix/VIX_History.dta", clear

keep close date_m 

collapse (mean) vix = close (sd) sd_vix = close, by(date_m)

rename date_m datem

save "$vixf/VIX_History_merge.dta", replace

***********************
use "$datace_imf/data_final_newVintage_3.dta", clear


merge m:1 datem using "$vixf/VIX_History_merge.dta"
drop if _merge == 2
drop _merge

save "$datace_imf/data_final_newVintage_3.dta", replace


* add more world bank indicators:

use "$datace_imf/data_final_newVintage_3.dta", clear

merge m:1 year country using "$worldbankf/world_bank_data_yearly_transparency.dta"
drop if _merge == 2
drop _merge

save "$datace_imf/data_final_newVintage_3.dta", replace


merge m:1 year country using "$worldbankf/world_bank_data_yearly_transparency2.dta"
drop if _merge == 2
drop _merge

save "$datace_imf/data_final_newVintage_3.dta", replace

* ADD STOCK MARKET DATA
******************************
******************************
******************************


*** Market indices per country ***

// setting the working directory
clear all
cd "$sm/Per country"

local countries ARGENTINA AUSTRIA BELGIUM BRAZIL BULGARIA CANADA ///
CHILE CHINA COLOMBIA CROATIA CZECHREPUBLIC DENMARK ESTONIA FINLAND ///
FRANCE GERMANY GREECE HUNGARY INDIA INDONESIA IRELAND ISRAEL ITALY ///
JAPAN LATVIA LITHUANIA MALAYSIA MEXICO NETHERLANDS NEWZEALAND ///
NIGERIA NORWAY PERU PHILIPPINES POLAND PORTUGAL ROMANIA RUSSIA ///
SAUDIARABIA SLOVAKIA SLOVENIA SOUTHAFRICA SOUTHKOREA SPAIN SWEDEN ///
SWITZERLAND THAILAND TURKEY UNITEDKINGDOM UNITEDSTATES VENEZUELA

foreach c of local countries{
	import delimited `c'.csv, varnames(1) clear
	keep date last*
	rename last* last_`c'
	destring last_`c', replace ignore(" ")
	
	// working with the date
	gen new_date = date(date, "DMY")
	format new_date %td

	drop date
	rename new_date date
	order date

	tset date

	// growth rate of the index using the lag operator
	gen gr_lag_`c' = (last/l.last -1)*100
	label variable gr_lag_`c' "Growth rate (%) with lag operator"

	// growth rate of the index using [_n] operator
	gen gr_n_`c' = (last[_n]/last[_n-1] - 1)*100
	label variable gr_n_`c' "Growth rate (%) with [_n] operator"
	
	save "$smf/`c'.dta", replace
}

// now, merge all the files together
use $smf/ARGENTINA.dta, clear

local countries AUSTRIA BELGIUM BRAZIL BULGARIA CANADA ///
CHILE CHINA COLOMBIA CROATIA CZECHREPUBLIC DENMARK ESTONIA FINLAND ///
FRANCE GERMANY GREECE HUNGARY INDIA INDONESIA IRELAND ISRAEL ITALY ///
JAPAN LATVIA LITHUANIA MALAYSIA MEXICO NETHERLANDS NEWZEALAND ///
NIGERIA NORWAY PERU PHILIPPINES POLAND PORTUGAL ROMANIA RUSSIA ///
SAUDIARABIA SLOVAKIA SLOVENIA SOUTHAFRICA SOUTHKOREA SPAIN SWEDEN ///
SWITZERLAND THAILAND TURKEY UNITEDKINGDOM UNITEDSTATES VENEZUELA

foreach c of local countries{
	merge 1:1 date using $smf/`c'.dta
	drop _merge
}

// we only keep data after 1989
gen year = yofd(date)
drop if year < 1989
drop year

// We are not interested in the lag data: get rid of it
drop gr_lag*

save "$smf/1. Final_indices.dta", replace

// Now, we will make a monthly database with Standard Deviations
gen month = mofd(date)
format month %tm

collapse (sd) gr_n*, by(month)

save "$smf/1. Indices with SD.dta", replace


* stock market indices - data from navid

use "$smf/1. Final_indices.dta", clear

keep date gr*

reshape long gr_n_ , i(date) j(country) string

sort country date 

rename gr_n_ mreturn

g datem =  mofd(date)
format datem %tm


collapse (mean) mreturn = mreturn (sd) sdreturn = mreturn , by(country datem)


g country_merge = lower(country)
replace country_merge = subinstr(country_merge, " ","",.)

drop country


save "$smf/indexlong.dta", replace



* merge

use "$datace_imf/data_final_newVintage_3.dta", clear

cap drop country_merge
g country_merge = lower(country)
replace country_merge = subinstr(country_merge, " ","",.)

merge m:1 datem country_merge using "$smf/indexlong.dta"

drop if _merge == 2

drop _merge

save "$datace_imf/data_final_newVintage_3.dta", replace



* MSCI DATA - data from margaret

local sheets "argentina	australia	austria	belgium	brazil	bulgaria	canada	chile	china	colombia	croatia	czechrepublic	denmark	estonia	finland	france	germany	greece	hungary	india	indonesia	ireland	israel	italy	japan	koreasouth	latvia	lithuania	malaysia	mexico	netherlands	newzealand	nigeria	norway	peru	philippines	poland	portugal	romania	russianfederation	saudiarabia	slovakia	slovenia	southafrica	spain	sweden	switzerland	thailand	turkey	unitedkingdom	unitedstates"


foreach sheet of local sheets {
	
	
	import excel "$msci/equity_indices_clean.xlsx", sheet(`sheet')  clear
	
	rename A date
	rename B usdmsci
	rename C usdreturn
	rename D usdpe
	rename E usddy
	rename F mvalue
	rename G msci
	rename H returni
	rename I pe
	rename J dy
	
	drop if _n < 7
	
	foreach var in usdmsci usdreturn usdpe usddy mvalue msci returni pe dy {
		replace `var' = "" if `var' == "$$ER: 2210,ACCESS DENIED"
		replace `var' = "" if strpos(`var', "DENIE") 
		replace `var' = "" if `var' == "NA"
		destring `var' , replace float
	}
	
	
	split date, parse(/)
	
	g month = date1
	g day = date2
	g year = date3
	
	foreach var in month day year {
		
		destring `var', replace
	}
	
	drop date1 date2 date3 date
	
	g date = mdy(month,day, year)
	
	format date %d
	
	g datem = ym(year,month)
	format datem %tm
	
	drop month day year
	
	drop date
	
	g country = "`sheet'"
	
	save "$mscif/`sheet'_msci_temp.dta", replace
	
	
}



*use "/Users/ebollige/Dropbox/3_PhD/Projects/EPFR_consensus/EPFRdat/bin/argentina_msci_temp.dta", clear

use "$mscif/argentina_msci_temp.dta", clear
local sheets "australia	austria	belgium	brazil	bulgaria	canada	chile	china	colombia	croatia	czechrepublic	denmark	estonia	finland	france	germany	greece	hungary	india	indonesia	ireland	israel	italy	japan	koreasouth	latvia	lithuania	malaysia	mexico	netherlands	newzealand	nigeria	norway	peru	philippines	poland	portugal	romania	russianfederation	saudiarabia	slovakia	slovenia	southafrica	spain	sweden	switzerland	thailand	turkey	unitedkingdom	unitedstates"


foreach sheet of local sheets {
	
	disp("`sheet'")
	
	append using "$mscif/`sheet'_msci_temp.dta"

}


cap drop country_merge
g country_merge = country

drop country
save  "$mscif/msci_temp_all.dta", replace



use "$datace_imf/data_final_newVintage_3.dta", clear

cap drop country_merge
g country_merge = lower(country)
replace country_merge = subinstr(country_merge, " ","",.)

merge m:1 datem country_merge using "$mscif/msci_temp_all.dta"

drop if _merge == 2
drop _merge

cap drop country_merge


label var usdmsci "U$ - PRICE INDEX"
label var usdreturn "U$ - TOT RETURN IND"
label var usdpe "U$ - PER"
label var usddy "U$ - DIVIDEND YIELD"
label var mvalue "U$ - MSCI MKT. VALUE"
label var msci "PRICE INDEX"
label var returni " TOT RETURN IND"
label var pe "PER"
label var dy "DIVIDEND  YIELD"



save "$datace_imf/data_final_newVintage_3.dta", replace


* FINAL BASELINE DATA:
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

save "$output/baseline.dta", replace
********************************************************************************


* extended data:
use "$output/baseline.dta", clear

local varlist gdp cpi
		
* Run individual regressions ans save results (rho, R2, RMSE)
foreach var in `varlist' {
	preserve
	collapse `var'_current_a1, by(country_num country year)
	sort country_num year
	format year %ty
	drop if country_num==.
	xtset country_num year
	gen rho_`var' = .
	gen rmse_`var' = .
	gen r2_`var' = .
	gen N_`var' = .
	gen country_num2 = .
	forval i = 1(1)51 {
			 qui reg `var'_current_a1 l.`var'_current_a1 if country_num==`i'
			 replace rho_`var' = _b[l.`var'_current_a1]    if country_num==`i'
			 replace rmse_`var' = e(rmse)	         if country_num==`i'
			 replace r2_`var'   = e(r2)	         if country_num==`i'
			 replace N_`var' = e(N)	         if country_num==`i'
			 replace country_num2 = `i' 			 if country_num==`i'
	}
	keep rho_`var' rmse_`var' r2_`var' N_`var' country_num2 year
	sort country_num2
	rename country_num2 country_num
	keep if rho_`var' != .
	save "$temp/rho_`var'.dta", replace
	restore
}

* Put results in single dataset 
local varlist gdp cpi
local var1: word 1 of `varlist'

foreach var in `varlist' {
		if "`var'" ==  "`var1'" {
			use "$temp/rho_`var'.dta", clear
		}
		else {
			merge 1:1 country_num year using "$temp/rho_`var'.dta", nogen
		}
	}
save "$temp/rho.dta", replace

use "$output/baseline.dta", clear
sort country_num year
merge m:1 country_num year using "$temp/rho.dta", nogen


pca ICRG_GovStab-ICRG_Bureau
predict ICRG_Pol, score
pca ICRG_ForDebt-ICRG_IntLiq
predict ICRG_Fin, score
pca ICRG_*
predict ICRG, score
pca cc_est-va_est
predict WDI_institutions, score


gen lpop_o = log(pop_o)
gen lpop_d = log(pop_d)
gen lgdp_ppp_o = log(gdp_ppp_o)
gen lgdp_ppp_d = log(gdp_ppp_d)
gen lgdp_cap_ppp_o = lgdp_ppp_o - lpop_o
gen lgdp_cap_ppp_d = lgdp_ppp_d - lpop_d
gen ldist = log(dist)
gen ldistw = log(distw)
gen ldistcap = log(distcap)
gen lTotalRevenue = log(TotalRevenue)
gen lEmployees = log(Employees)
gen lprod = lTotalRevenue - lEmployees
gen lMarketCap = log(MarketCap)
gen Finance = (Industry7==2) + (Industry7==3)
gen trade_link = (tradeflow_comtrade_o+tradeflow_comtrade_d)/(gdp_o+gdp_d)
gen fin_link = (totalclaims2 + totalliabilities2)/(gdp_o+gdp_d)

sort idci year
by idci year: egen N_month = count(labs_FE_gdp_current_a1)
gen w_month = 1/N_month


egen N_FE_cpi_current = count(FE_cpi_current_a1), by(idci month)
egen N_FE_cpi_future = count(FE_cpi_future_a1), by(idci month)
egen N_FE_gdp_current = count(FE_gdp_current_a1), by(idci month)
egen N_FE_gdp_future = count(FE_gdp_future_a1), by(idci month)

sort datem
by datem: egen x = mean(GEPU_ppp) 
replace GEPU_ppp = x
drop x
by datem: egen x = mean(GEPU_current) 
replace GEPU_current = x
drop x

save "$output/extended.dta", replace

* more gravity data

use "$output/extended.dta", clear
drop dist* closest*
sort country id datem

merge m:1 country Head year using "$gravityf/gravity_to_merge.dta"
drop if _merge==2
drop _merge
merge 1:1 country id datem using "$gravityf/gravity_temp2.dta", nogen

gen dist_ = closest_ctry_dist
gen distw_ = closest_ctry_distw

save "$output/extended.dta", replace

**

local varlist dist_ distw_
local Varlist distcap comleg_pretrans sever_year gdp_ppp_o eu_o entry_tp_d iso3_o distwces comleg_posttrans sib_conflict gdp_ppp_d eu_d tradeflow_comtrade_o iso3_d dist_source transition_legalchange pop_o gdpcap_ppp_o rta tradeflow_comtrade_d iso3num_o comlang_off heg_o pop_d gdpcap_ppp_d rta_coverage tradeflow_baci iso3num_d comlang_ethno heg_d gdp_o pop_pwt_o rta_type manuf_tradeflow_baci country_exists_o comcol col_dep_ever gdp_d pop_pwt_d entry_cost_o tradeflow_imf_o country_exists_d comrelig col_dep gdpcap_o gdp_ppp_pwt_o entry_cost_d tradeflow_imf_d gmt_offset_2020_o col45 col_dep_end_year gdpcap_d gdp_ppp_pwt_d entry_proc_o gmt_offset_2020_d legal_old_o col_dep_end_conflict pop_source_o gatt_o entry_proc_d contig legal_old_d empire pop_source_d gatt_d entry_time_o dist legal_new_o sibling_ever gdp_source_o wto_o entry_time_d distw legal_new_d sibling gdp_source_d wto_d entry_tp_o

foreach var in `varlist'{
	
	use "$gravityf/gravity_to_merge.dta", clear

	rename Head `var'
	
	foreach Var in `Varlist' {


		rename `Var' `var'`Var'
	}

	keep country `var' year `var'iso3_o-`var'tradeflow_imf_d

	sort country `var' year

	save "$gravityf/gravity.dta", replace

	use "$output/extended.dta", clear

	sort country `var' year

	merge m:1 country `var' year using "$gravityf/gravity.dta"
	drop if _merge==2
	drop _merge

	save "$output/extended.dta", replace
}

***




use "$cultdist/cultdist.dta", clear

replace country_1 = "United States" if country_1=="U.S.A"
replace country_1 = "South Korea" if country_1=="Korea"
replace country_1 = "Russia" if country_1=="Russian Federation"
replace country_2 = "United States" if country_2=="U.S.A"
replace country_2 = "South Korea" if country_2=="Korea"
replace country_2 = "Russia" if country_2=="Russian Federation"

rename country_1 country
rename country_2 Headquarters

rename total cultural_distance
rename lingdist_dom lingdist_dominant
rename lingdist_wei lingdist_weighted
rename reldist_dominant_formula reldist_dominant
rename reldist_weighted_formula reldist_weighted

keep country Headquarters cultural_distance lingdist_dominant lingdist_weighted reldist_dominant reldist_weighted

save $cultdistf/cultdist, replace

rename Headquarters country1
rename country Headquarters
rename country1 country

append using $cultdistf/cultdist

sort country Headquarters
drop if Headquarters=="" | country==""

save $cultdistf/cultdist2, replace

use "$output/extended.dta", clear

sort country Headquarters

merge m:1 country Headquarters using $cultdistf/cultdist2.dta
drop if _merge == 2
drop _merge

local varlist lingdist_dominant lingdist_weighted reldist_dominant reldist_weighted
foreach VAR in `varlist' {
	replace `VAR' = 0 if country==Headquarters
}

replace cultural_distance = -87 if country==Headquarters

save "$output/extended.dta", replace


local varlist dist_ distw_

foreach var in `varlist'{

	use "$cultdist/cultdist.dta", clear

	replace country_1 = "United States" if country_1=="U.S.A"
	replace country_1 = "South Korea" if country_1=="Korea"
	replace country_1 = "Russia" if country_1=="Russian Federation"
	replace country_2 = "United States" if country_2=="U.S.A"
	replace country_2 = "South Korea" if country_2=="Korea"
	replace country_2 = "Russia" if country_2=="Russian Federation"

	rename country_1 country
	rename country_2 `var'

	rename total `var'cultural_distance
	rename lingdist_dom `var'lingdist_dominant
	rename lingdist_wei `var'lingdist_weighted
	rename reldist_dominant_formula `var'reldist_dominant
	rename reldist_weighted_formula `var'reldist_weighted

	keep country `var' `var'cultural_distance `var'lingdist_dominant `var'lingdist_weighted `var'reldist_dominant `var'reldist_weighted

	save $cultdistf/cultdist, replace

	rename `var' country1
	rename country `var'
	rename country1 country

	append using $cultdistf/cultdist.dta

	sort country `var'

	save $cultdistf/cultdist2.dta, replace

	use "$output/extended.dta", clear

	sort country `var'

	merge m:1 country `var' using $cultdistf/cultdist2
	drop if _merge == 2
	drop _merge
	
	local Varlist `var'lingdist_dominant `var'lingdist_weighted `var'reldist_dominant `var'reldist_weighted
	foreach VAR in `Varlist' {
		replace `VAR' = 0 if country==`var'
	}

	replace `var'cultural_distance = -87 if country==`var'

	save "$output/extended.dta", replace
}



***

import excel "$migration\P_Data_Extract_From_Global_Bilateral_Migration.xlsx", sheet("Data") firstrow clear

drop Migration* CountryOriginCode CountryDestCode G H I J
rename K Migration_2000
rename CountryOriginName country
rename CountryDestName Headquarters

replace country = "South Korea" if country=="Korea, Rep."
replace country = "Russia" if country=="Russian Federation"
replace country = "Slovakia" if country == "Slovak Republic"
replace country = "Venezuela" if country=="Venezuela, RB"
replace country = "Egypt" if country=="Egypt, Arab Rep."
replace country = "Iran" if country=="Iran, Islamic Rep."
replace country = "Taiwan" if country=="Taiwan, China"
replace country = "Hong Kong" if country=="Hong Kong SAR, China"

replace Headquarters = "South Korea" if Headquarters=="Korea, Rep."
replace Headquarters = "Russia" if Headquarters=="Russian Federation"
replace Headquarters = "Slovakia" if Headquarters == "Slovak Republic"
replace Headquarters = "Venezuela" if Headquarters=="Venezuela, RB"
replace Headquarters = "Egypt" if Headquarters=="Egypt, Arab Rep."
replace Headquarters = "Iran" if Headquarters=="Iran, Islamic Rep."
replace Headquarters = "Taiwan" if Headquarters=="Taiwan, China"
replace Headquarters = "Hong Kong" if Headquarters=="Hong Kong SAR, China"

keep country Headquarters Migration_2000
drop if country==""
drop if Headquarters==""

save $migrationf/migration, replace

collapse (sum) Migration_2000, by(Headquarters)
rename Migration_2000 Migration_2000_total
save $migrationf/migration_total, replace

use "$output/extended.dta", clear

sort country Headquarters

merge m:1 country Headquarters using $migrationf/migration
drop if _merge == 2
drop _merge
merge m:1 Headquarters using $migrationf/migration_total
drop if _merge == 2
drop _merge

save "$output/extended.dta", replace


local varlist dist_ distw_

foreach var in `varlist'{

	import excel "$migration/P_Data_Extract_From_Global_Bilateral_Migration.xlsx", sheet("Data") firstrow clear

	drop Migration* CountryOriginCode CountryDestCode G H I J
	rename K Migration_2000
	rename CountryOriginName country
	rename CountryDestName `var'

	replace country = "South Korea" if country=="Korea, Rep."
	replace country = "Russia" if country=="Russian Federation"
	replace country = "Slovakia" if country == "Slovak Republic"
	replace country = "Venezuela" if country=="Venezuela, RB"
	replace country = "Egypt" if country=="Egypt, Arab Rep."
	replace country = "Iran" if country=="Iran, Islamic Rep."
	replace country = "Taiwan" if country=="Taiwan, China"
	replace country = "Hong Kong" if country=="Hong Kong SAR, China"

	replace `var' = "South Korea" if `var'=="Korea, Rep."
	replace `var' = "Russia" if `var'=="Russian Federation"
	replace `var' = "Slovakia" if `var' == "Slovak Republic"
	replace `var' = "Venezuela" if `var'=="Venezuela, RB"
	replace `var' = "Egypt" if `var'=="Egypt, Arab Rep."
	replace `var' = "Iran" if `var'=="Iran, Islamic Rep."
	replace `var' = "Taiwan" if `var'=="Taiwan, China"
	replace `var' = "Hong Kong" if `var'=="Hong Kong SAR, China"

	rename Migration_2000 `var'Migration_2000
	keep country `var' `var'Migration_2000
	drop if country==""
	drop if `var'==""
	save $migrationf/migration, replace

	collapse (sum) `var'Migration_2000, by(`var')
	rename `var'Migration_2000 `var'Migration_2000_total
	save $migrationf/migration_total, replace
	
	use "$output/extended.dta", clear

	sort country `var'

	merge m:1 country `var' using $migrationf/migration.dta
	drop if _merge == 2
	drop _merge
	merge m:1 `var' using $migrationf/migration_total.dta
	drop if _merge == 2
	drop _merge
	
	save "$output/extended.dta", replace
}

**

**

local varlist dist_ distw_

foreach var in `varlist'{

	use "$output/extended.dta", clear

	collapse totalclaims1 totalclaims2 totalliabilities1 totalliabilities2, by(country Head datem)

	rename Head `var'

	rename totalclaims1 `var'totalclaims1
	rename totalclaims2 `var'totalclaims2
	rename totalliabilities1 `var'totalliabilities1
	rename totalliabilities2 `var'totalliabilities2

	keep country `var'* datem
	sort country `var' datem

	save $bisf/bis.dta, replace

	use "$output/extended.dta", clear

	sort country `var' datem

	merge m:1 country `var' datem using $bisf/bis, nogen

	save "$output/extended.dta", replace
}

drop totalclaims1_* totalclaims2_* totalliabilities1_* totalliabilities2_*
save "$output/extended.dta", replace

********* more gravity

***** De jure regimes

use "$regime/Bilateral_DeJure_Regimes_neu.dta", clear

replace country1 = "South Korea" if country1=="Korea"
replace country1 = "Slovakia" if country1=="Slovak Republic"
replace country1 = "Iran" if country1=="Islamic Republic of Iran"
replace country1 = "Hong Kong" if country1=="Hong Kong SAR"
replace country2 = "South Korea" if country2=="Korea"
replace country2 = "Slovakia" if country2=="Slovak Republic"
replace country2 = "Iran" if country2=="Islamic Republic of Iran"
replace country2 = "Hong Kong" if country2=="Hong Kong SAR"

rename country1 country
rename country2 Headquarters

keep country Headquarters year direct_link indirect_link cu_dummy other_nslt jf_1
sort country Headquarters year

save $regimef/bilateral_regimes, replace


use "$output/extended.dta", clear

sort country Headquarters year
merge m:1 country Headquarters year using $regimef/bilateral_regimes
drop if _merge == 2
drop _merge

replace direct_link = 1 if country==Headquarters
replace indirect_link = 0 if country==Headquarters

save "$output/extended.dta", replace

local varlist dist_ distw_

foreach var in `varlist'{

	use "$regime/Bilateral_DeJure_Regimes_neu.dta", clear

	replace country1 = "South Korea" if country1=="Korea"
	replace country1 = "Slovakia" if country1=="Slovak Republic"
	replace country1 = "Iran" if country1=="Islamic Republic of Iran"
	replace country1 = "Hong Kong" if country1=="Hong Kong SAR"
	replace country2 = "South Korea" if country2=="Korea"
	replace country2 = "Slovakia" if country2=="Slovak Republic"
	replace country2 = "Iran" if country2=="Islamic Republic of Iran"
	replace country2 = "Hong Kong" if country2=="Hong Kong SAR"

	rename country1 country
	rename country2 `var'

	rename direct_link `var'direct_link
	rename indirect_link `var'indirect_link
	rename cu_dummy `var'cu_dummy
	rename other_nslt `var'other_nslt
	rename jf_1 `var'jf_1

	keep country `var' year `var'direct_link `var'indirect_link `var'cu_dummy `var'other_nslt `var'jf_1
	sort country `var' year

	save $regimef/bilateral_regimes, replace

	use "$output/extended.dta", clear

	sort country `var' year
	merge m:1 country `var' year using $regimef/bilateral_regimes
	drop if _merge == 2
	drop _merge

	replace `var'direct_link = 1 if country==`var'
	replace `var'indirect_link = 0 if country==`var'

	save "$output/extended.dta", replace
}





**** Imports and exports *****

import excel "$expimp/Exports_and_Imports_by_Areas_and_Co.xlsx", sheet("Exports, FOB") cellrange(B7:AA247) firstrow clear

reshape long year, i(country)
rename year exports
rename _j year
drop if country==""
encode country, gen(id)
*keep if inlist(id,11,15,16,23,32,34,40,43,46,47,53,57,60,74,83,84,89,92,103,105,106,109,110,111,113,118,124,129,133,141,157,159,162,164,172,173,174,175,177,178,182,190,191,194,196,205,206,212,220,225,226,230)

replace country = "China" if id == 46
replace country = "Croatia" if id == 53
replace country = "Czech Republic" if id == 57
replace country = "Estonia" if id == 74
replace country = "South Korea" if id == 118
replace country = "Netherlands" if id ==157
replace country = "Poland" if id ==174
replace country = "Russia" if id ==178
replace country = "Slovakia" if id ==190
replace country = "Slovenia" if id ==191
replace country = "Turkey" if id ==220
replace country = "Venezuela" if id ==230
replace country = "Bahrain" if id ==19
replace country = "Barbados" if id ==21
replace country = "Belarus" if id ==22
replace country = "Egypt" if id ==65
replace country = "Iran" if id ==107
replace country = "Lesotho" if id ==126
replace country = "Taiwan" if id ==209
replace country = "Hong Kong" if id ==44

drop id
label var exports "Exports in million of USD"
sort country year

save $expimpf/exports, replace


import excel "$expimp/Exports_and_Imports_by_Areas_and_Co.xlsx", sheet("Imports, CIF") cellrange(B7:AA247) firstrow clear

reshape long year, i(country)
rename year imports
rename _j year
drop if country==""
encode country, gen(id)


replace country = "China" if id == 46
replace country = "Croatia" if id == 53
replace country = "Czech Republic" if id == 57
replace country = "Estonia" if id == 74
replace country = "South Korea" if id == 118
replace country = "Netherlands" if id ==157
replace country = "Poland" if id ==174
replace country = "Russia" if id ==178
replace country = "Slovakia" if id ==190
replace country = "Slovenia" if id ==191
replace country = "Turkey" if id ==220
replace country = "Venezuela" if id ==230
replace country = "Bahrain" if id ==19
replace country = "Barbados" if id ==21
replace country = "Belarus" if id ==22
replace country = "Egypt" if id ==65
replace country = "Iran" if id ==107
replace country = "Lesotho" if id ==126
replace country = "Taiwan" if id ==209
replace country = "Hong Kong" if id ==44

drop id
label var imports "Imports in million of USD"
sort country year

save $expimpf/imports, replace



use "$output/extended.dta", clear 

sort country year

merge m:1 country year using $expimpf/exports
drop if _merge==2
drop _merge
merge m:1 country year using $expimpf/imports
drop if _merge==2
drop _merge

save "$output/extended.dta", replace






**** Tariffs *****

import excel "$tariff/WtoData_20240527134544.xlsx", sheet("Report") cellrange(A3:T170) firstrow clear

drop B

rename ReportingEconomy country
reshape long tarriff, i(country) j(year)

replace country = "South Korea" if country=="Korea, Republic of"
replace country = "Russia" if country=="Russian Federation"
replace country = "Turkey" if country=="Türkiye"
replace country = "Venezuela" if country=="Venezuela, Bolivarian Republic of"
replace country = "Bahrain" if country=="Bahrain, Kingdom of"
replace country = "Taiwan" if country=="Chinese Taipei"
replace country = "Hong Kong" if country=="Hong Kong, China"

merge 1:m country year using "$tariff/EU.dta"
sort country country2 year
replace country=country2 if country=="European Union"
drop country2 _merge
drop if tarriff == .

/*
encode country, gen(country_num)
tsset country_num year
tsfill

mipolate tarriff year, gen(tariff)
drop tarriff

preserve
collapse tariff if country!="", by(country country_num)
drop tariff
save countries, replace
restore
drop country
merge m:1 country_num using countries, nogen
drop country_num
*/
rename tarriff tariff

save $tarifff/tariffs, replace


use "$output/extended.dta", clear 

sort country year

merge m:1 country year using $tarifff/tariffs
drop if _merge==2
drop _merge

save "$output/extended.dta", replace


import excel "$tariff/WtoData_20240527134709.xlsx", sheet("Report") cellrange(A3:T162) firstrow clear

drop B

rename ReportingEconomy country
reshape long tarriff, i(country) j(year)

replace country = "South Korea" if country=="Korea, Republic of"
replace country = "Russia" if country=="Russian Federation"
replace country = "Turkey" if country=="Türkiye"
replace country = "Venezuela" if country=="Venezuela, Bolivarian Republic of"
replace country = "Bahrain" if country=="Bahrain, Kingdom of"
replace country = "Taiwan" if country=="Chinese Taipei"
replace country = "Hong Kong" if country=="Hong Kong, China"

merge 1:m country year using "$tariff/EU.dta"
sort country country2 year
replace country=country2 if country=="European Union"
drop country2 _merge
drop if tarriff == .

rename tarriff tariff_weighted

/*
encode country, gen(country_num)
tsset country_num year
tsfill

mipolate tarriff_weighted year, gen(tariff_weighted)
drop tarriff_weighted

preserve
collapse tariff if country!="", by(country country_num)
drop tariff
save countries, replace
restore
drop country
merge m:1 country_num using countries, nogen
drop country_num
*/

save $tarifff/tariffs_weighted, replace



use "$output/extended.dta", clear 

sort country year

merge m:1 country year using $tarifff/tariffs_weighted
drop if _merge==2
drop _merge

save "$output/extended.dta", replace




********* BC and inflation comovement

import excel "$wdi\Inflation_GDP_growth_World_Development_Indicators.xlsx", sheet("Data") firstrow clear

keep if SeriesName == "GDP growth (annual %)"
reshape long YR, i(CountryName)

rename CountryName country
rename _j year
rename YR gdp_wdi

keep country year gdp_wdi
drop if year<1990

replace country = "South Korea" if country=="Korea, Rep."
replace country = "Russia" if country=="Russian Federation"
replace country = "Venezuela" if country=="Venezuela, RB"
replace country = "Slovakia" if country=="Slovak Republic"
replace country = "Turkey" if country=="Turkiye"
replace country = "Czech Republic" if country=="Czechia"
replace country = "Egypt" if country=="Egypt, Arab Rep."
replace country = "Hong Kong" if country=="Hong Kong SAR, China"
replace country = "Iran" if country=="Iran, Islamic Rep."

sort country year

save $wdif/gdp_wdi, replace

*
import excel "$wdi/Inflation_GDP_growth_World_Development_Indicators.xlsx", sheet("Data") firstrow clear

drop if CountryName == "Venezuela, RB" & SeriesName == "Inflation, consumer prices (annual %)"
drop if CountryName == "Argentina" & SeriesName == "Inflation, consumer prices (annual %)"
drop if CountryName == "United Arab Emirates" & SeriesName == "Inflation, consumer prices (annual %)"
drop if CountryName == "Puerto Rico" & SeriesName == "Inflation, consumer prices (annual %)"
drop if CountryName == "Liechtenstein" & SeriesName == "Inflation, consumer prices (annual %)"
drop if CountryName == "Bosnia and Herzegovina" & SeriesName == "Inflation, consumer prices (annual %)"

replace SeriesName = "Inflation, consumer prices (annual %)" if SeriesName == "Inflation, GDP deflator (annual %)" & (CountryName == "Venezuela, RB" | CountryName == "Argentina" | CountryName == "United Arab Emirates" | CountryName == "Puerto Rico" | CountryName == "Liechtenstein" | CountryName == "Bosnia and Herzegovina")

keep if SeriesName == "Inflation, consumer prices (annual %)"
reshape long YR, i(CountryName)

rename CountryName country
rename _j year
rename YR cpi_wdi

keep country year cpi_wdi
drop if year<1990
replace country = "South Korea" if country=="Korea, Rep."
replace country = "Russia" if country=="Russian Federation"
replace country = "Venezuela" if country=="Venezuela, RB"
replace country = "Slovakia" if country=="Slovak Republic"
replace country = "Turkey" if country=="Turkiye"
replace country = "Czech Republic" if country=="Czechia"
replace country = "Egypt" if country=="Egypt, Arab Rep."
replace country = "Hong Kong" if country=="Hong Kong SAR, China"
replace country = "Iran" if country=="Iran, Islamic Rep."

sort country year

save $wdif/cpi_wdi, replace

*

use "$output/extended.dta", clear 

keep gdp_current cpi_current Headquarters country
collapse gdp_current cpi_current, by(Headquarters country)
drop if Headquarters == ""
drop if gdp_current==. & cpi_current==.
drop gdp_current cpi_current
encode country, gen(country_num)
encode Headquarters, gen(Headquarters_num)

sort country

gen n=43
expand n
replace n = 1
bys country Headquarters: gen year = sum(n)
replace year = year + 1989

merge m:1 country year using $wdif/gdp_wdi
drop if _merge==2
drop _merge

rename gdp_wdi gdp_wdi_o
rename country country1
rename Headquarters country

merge m:1 country year using $wdif/gdp_wdi
drop if _merge==2
drop _merge

rename country Headquarters
rename country1 country
rename gdp_wdi gdp_wdi_d
drop n
drop if Headquarters==""
drop if country==""

sort country Headquarters year

by country Headquarters: egen mgdp_wdi_d = mean(gdp_wdi_d)
by country Headquarters: egen mgdp_wdi_o = mean(gdp_wdi_o)
gen COV_gdp_wdi = (gdp_wdi_d-mgdp_wdi_d)*(gdp_wdi_o-mgdp_wdi_o)
by country Headquarters: egen cov_gdp_wdi = mean(COV_gdp_wdi)
by country Headquarters: egen sd_gdp_wdi_d = sd(gdp_wdi_d)
by country Headquarters: egen sd_gdp_wdi_o = sd(gdp_wdi_o)
gen corr_gdp_wdi = cov_gdp_wdi/(sd_gdp_wdi_d*sd_gdp_wdi_o)

by country Headquarters: egen N_d_o = count(COV_gdp_wdi)
drop if N_d_o<20

egen idch = group(country Headquarters)
sort idch year
xtset idch year

by idch: gen roll_mgdp_wdi_d = (l.gdp_wdi_d+l2.gdp_wdi_d+l3.gdp_wdi_d+l4.gdp_wdi_d+l5.gdp_wdi_d)/5
by idch: gen roll_mgdp_wdi_o = (l.gdp_wdi_o+l2.gdp_wdi_o+l3.gdp_wdi_o+l4.gdp_wdi_o+l5.gdp_wdi_o)/5
by idch: gen roll_cov_gdp_wdi = ((l.gdp_wdi_d-roll_mgdp_wdi_d)*(l.gdp_wdi_o-roll_mgdp_wdi_o)+(l2.gdp_wdi_d-roll_mgdp_wdi_d)*(l2.gdp_wdi_o-roll_mgdp_wdi_o)+(l3.gdp_wdi_d-roll_mgdp_wdi_d)*(l3.gdp_wdi_o-roll_mgdp_wdi_o)+(l4.gdp_wdi_d-roll_mgdp_wdi_d)*(l4.gdp_wdi_o-roll_mgdp_wdi_o)+(l5.gdp_wdi_d-roll_mgdp_wdi_d)*(l5.gdp_wdi_o-roll_mgdp_wdi_o))/5
by idch: gen roll_sd_gdp_wdi_d = (((l.gdp_wdi_d-roll_mgdp_wdi_d)^2+(l2.gdp_wdi_d-roll_mgdp_wdi_d)^2+(l3.gdp_wdi_d-roll_mgdp_wdi_d)^2+(l4.gdp_wdi_d-roll_mgdp_wdi_d)^2+(l5.gdp_wdi_d-roll_mgdp_wdi_d)^2)/5)^0.5
by idch: gen roll_sd_gdp_wdi_o = (((l.gdp_wdi_o-roll_mgdp_wdi_o)^2+(l2.gdp_wdi_o-roll_mgdp_wdi_o)^2+(l3.gdp_wdi_o-roll_mgdp_wdi_o)^2+(l4.gdp_wdi_o-roll_mgdp_wdi_o)^2+(l5.gdp_wdi_o-roll_mgdp_wdi_o)^2)/5)^0.5
gen roll_corr_gdp_wdi = roll_cov_gdp_wdi/(roll_sd_gdp_wdi_d*roll_sd_gdp_wdi_o)

xtreg gdp_wdi_d i.country_num#c.l.gdp_wdi_d
predict gdp_wdi_d_res
replace gdp_wdi_d_res = gdp_wdi_d - gdp_wdi_d_res
xtreg gdp_wdi_o i.Headquarters_num#c.l.gdp_wdi_o
predict gdp_wdi_o_res
replace gdp_wdi_o_res = gdp_wdi_o - gdp_wdi_o_res

by idch: egen mgdp_wdi_d_res = mean(gdp_wdi_d_res)
by idch: egen mgdp_wdi_o_res = mean(gdp_wdi_o_res)
gen COV_gdp_wdi_res = (gdp_wdi_d_res-mgdp_wdi_d_res)*(gdp_wdi_o_res-mgdp_wdi_o_res)
by idch: egen cov_gdp_wdi_res = mean(COV_gdp_wdi_res)
by idch: egen sd_gdp_wdi_d_res = sd(gdp_wdi_d_res)
by idch: egen sd_gdp_wdi_o_res = sd(gdp_wdi_o_res)
gen corr_gdp_wdi_res = cov_gdp_wdi_res/(sd_gdp_wdi_d_res*sd_gdp_wdi_o_res)

keep country Headquarters year corr_gdp_wdi roll_corr_gdp_wdi corr_gdp_wdi_res cov_gdp_wdi sd_gdp_wdi_o_res sd_gdp_wdi_o sd_gdp_wdi_d_res sd_gdp_wdi_d

save $wdif/corr_gdp_wdi, replace



*
use "$output/extended.dta", clear 

keep gdp_current cpi_current Headquarters country
collapse gdp_current cpi_current, by(Headquarters country)
drop if Headquarters == ""
drop if gdp_current==. & cpi_current==.
drop gdp_current cpi_current
encode country, gen(country_num)
encode Headquarters, gen(Headquarters_num)

sort country

gen n=43
expand n
replace n = 1
bys country Headquarters: gen year = sum(n)
replace year = year + 1989

merge m:1 country year using $wdif/cpi_wdi
drop if _merge==2
drop _merge

rename cpi_wdi cpi_wdi_o
rename country country1
rename Headquarters country

merge m:1 country year using $wdif/cpi_wdi
drop if _merge==2
drop _merge

rename country Headquarters
rename country1 country
rename cpi_wdi cpi_wdi_d
drop n
drop if Headquarters==""
drop if country==""

sort country Headquarters year

by country Headquarters: egen mcpi_wdi_d = mean(cpi_wdi_d)
by country Headquarters: egen mcpi_wdi_o = mean(cpi_wdi_o)
gen COV_cpi_wdi = (cpi_wdi_d-mcpi_wdi_d)*(cpi_wdi_o-mcpi_wdi_o)
by country Headquarters: egen cov_cpi_wdi = mean(COV_cpi_wdi)
by country Headquarters: egen sd_cpi_wdi_d = sd(cpi_wdi_d)
by country Headquarters: egen sd_cpi_wdi_o = sd(cpi_wdi_o)
gen corr_cpi_wdi = cov_cpi_wdi/(sd_cpi_wdi_d*sd_cpi_wdi_o)

by country Headquarters: egen N_d_o = count(COV_cpi_wdi)
drop if N_d_o<20

egen idch = group(country Headquarters)
sort idch year
xtset idch year

by idch: gen roll_mcpi_wdi_d = (l.cpi_wdi_d+l2.cpi_wdi_d+l3.cpi_wdi_d+l4.cpi_wdi_d+l5.cpi_wdi_d)/5
by idch: gen roll_mcpi_wdi_o = (l.cpi_wdi_o+l2.cpi_wdi_o+l3.cpi_wdi_o+l4.cpi_wdi_o+l5.cpi_wdi_o)/5
by idch: gen roll_cov_cpi_wdi = ((l.cpi_wdi_d-roll_mcpi_wdi_d)*(l.cpi_wdi_o-roll_mcpi_wdi_o)+(l2.cpi_wdi_d-roll_mcpi_wdi_d)*(l2.cpi_wdi_o-roll_mcpi_wdi_o)+(l3.cpi_wdi_d-roll_mcpi_wdi_d)*(l3.cpi_wdi_o-roll_mcpi_wdi_o)+(l4.cpi_wdi_d-roll_mcpi_wdi_d)*(l4.cpi_wdi_o-roll_mcpi_wdi_o)+(l5.cpi_wdi_d-roll_mcpi_wdi_d)*(l5.cpi_wdi_o-roll_mcpi_wdi_o))/5
by idch: gen roll_sd_cpi_wdi_d = (((l.cpi_wdi_d-roll_mcpi_wdi_d)^2+(l2.cpi_wdi_d-roll_mcpi_wdi_d)^2+(l3.cpi_wdi_d-roll_mcpi_wdi_d)^2+(l4.cpi_wdi_d-roll_mcpi_wdi_d)^2+(l5.cpi_wdi_d-roll_mcpi_wdi_d)^2)/5)^0.5
by idch: gen roll_sd_cpi_wdi_o = (((l.cpi_wdi_o-roll_mcpi_wdi_o)^2+(l2.cpi_wdi_o-roll_mcpi_wdi_o)^2+(l3.cpi_wdi_o-roll_mcpi_wdi_o)^2+(l4.cpi_wdi_o-roll_mcpi_wdi_o)^2+(l5.cpi_wdi_o-roll_mcpi_wdi_o)^2)/5)^0.5
gen roll_corr_cpi_wdi = roll_cov_cpi_wdi/(roll_sd_cpi_wdi_d*roll_sd_cpi_wdi_o)

xtreg cpi_wdi_d i.country_num#c.l.cpi_wdi_d
predict cpi_wdi_d_res
replace cpi_wdi_d_res = cpi_wdi_d - cpi_wdi_d_res
xtreg cpi_wdi_o i.Headquarters_num#c.l.cpi_wdi_o
predict cpi_wdi_o_res
replace cpi_wdi_o_res = cpi_wdi_o - cpi_wdi_o_res

by idch: egen mcpi_wdi_d_res = mean(cpi_wdi_d_res)
by idch: egen mcpi_wdi_o_res = mean(cpi_wdi_o_res)
gen COV_cpi_wdi_res = (cpi_wdi_d_res-mcpi_wdi_d_res)*(cpi_wdi_o_res-mcpi_wdi_o_res)
by idch: egen cov_cpi_wdi_res = mean(COV_cpi_wdi_res)
by idch: egen sd_cpi_wdi_d_res = sd(cpi_wdi_d_res)
by idch: egen sd_cpi_wdi_o_res = sd(cpi_wdi_o_res)
gen corr_cpi_wdi_res = cov_cpi_wdi_res/(sd_cpi_wdi_d_res*sd_cpi_wdi_o_res)

keep country Headquarters year corr_cpi_wdi roll_corr_cpi_wdi corr_cpi_wdi_res cov_cpi_wdi sd_cpi_wdi_o_res sd_cpi_wdi_o sd_cpi_wdi_d_res sd_cpi_wdi_d

save $wdif/corr_cpi_wdi, replace

*
use "$output/extended.dta", clear 

merge m:1 country Headquarters year using $wdif/corr_gdp_wdi
drop if _merge==2
drop _merge
merge m:1 country Headquarters year using $wdif/corr_cpi_wdi
drop if _merge==2
drop _merge

save "$output/extended.dta", replace
*
	
local varlist dist_ distw_

foreach var in `varlist'{
	
	use "$output/extended.dta", clear 

	keep gdp_current cpi_current `var' country
	collapse gdp_current cpi_current, by(`var' country)
	drop if `var' == ""
	drop if gdp_current==. & cpi_current==.
	drop gdp_current cpi_current
	encode country, gen(country_num)
	encode `var', gen(`var'_num)

	sort country

	gen n=43
	expand n
	replace n = 1
	bys country `var': gen year = sum(n)
	replace year = year + 1989

	merge m:1 country year using $wdif/gdp_wdi
	drop if _merge==2
	drop _merge

	rename gdp_wdi gdp_wdi_o
	rename country country1
	rename `var' country

	merge m:1 country year using $wdif/gdp_wdi
	drop if _merge==2
	drop _merge
	
	rename country `var'
	rename country1 country
	rename gdp_wdi gdp_wdi_d
	drop n
	drop if `var'==""
	drop if country==""

	sort country `var' year

	by country `var': egen mgdp_wdi_d = mean(gdp_wdi_d)
	by country `var': egen mgdp_wdi_o = mean(gdp_wdi_o)
	gen COV_gdp_wdi = (gdp_wdi_d-mgdp_wdi_d)*(gdp_wdi_o-mgdp_wdi_o)
	by country `var': egen cov_gdp_wdi = mean(COV_gdp_wdi)
	by country `var': egen `var'sd_gdp_wdi_d = sd(gdp_wdi_d)
	by country `var': egen `var'sd_gdp_wdi_o = sd(gdp_wdi_o)
	gen `var'corr_gdp_wdi = cov_gdp_wdi/(`var'sd_gdp_wdi_d*`var'sd_gdp_wdi_o)
	gen `var'cov_gdp_wdi = cov_gdp_wdi

	by country `var': egen N_d_o = count(COV_gdp_wdi)
	drop if N_d_o<20
	
	egen idch = group(country `var')
	sort idch year
	xtset idch year

	by idch: gen roll_mgdp_wdi_d = (l.gdp_wdi_d+l2.gdp_wdi_d+l3.gdp_wdi_d+l4.gdp_wdi_d+l5.gdp_wdi_d)/5
	by idch: gen roll_mgdp_wdi_o = (l.gdp_wdi_o+l2.gdp_wdi_o+l3.gdp_wdi_o+l4.gdp_wdi_o+l5.gdp_wdi_o)/5
	by idch: gen roll_cov_gdp_wdi = ((l.gdp_wdi_d-roll_mgdp_wdi_d)*(l.gdp_wdi_o-roll_mgdp_wdi_o)+(l2.gdp_wdi_d-roll_mgdp_wdi_d)*(l2.gdp_wdi_o-roll_mgdp_wdi_o)+(l3.gdp_wdi_d-roll_mgdp_wdi_d)*(l3.gdp_wdi_o-roll_mgdp_wdi_o)+(l4.gdp_wdi_d-roll_mgdp_wdi_d)*(l4.gdp_wdi_o-roll_mgdp_wdi_o)+(l5.gdp_wdi_d-roll_mgdp_wdi_d)*(l5.gdp_wdi_o-roll_mgdp_wdi_o))/5
	by idch: gen roll_sd_gdp_wdi_d = (((l.gdp_wdi_d-roll_mgdp_wdi_d)^2+(l2.gdp_wdi_d-roll_mgdp_wdi_d)^2+(l3.gdp_wdi_d-roll_mgdp_wdi_d)^2+(l4.gdp_wdi_d-roll_mgdp_wdi_d)^2+(l5.gdp_wdi_d-roll_mgdp_wdi_d)^2)/5)^0.5
	by idch: gen roll_sd_gdp_wdi_o = (((l.gdp_wdi_o-roll_mgdp_wdi_o)^2+(l2.gdp_wdi_o-roll_mgdp_wdi_o)^2+(l3.gdp_wdi_o-roll_mgdp_wdi_o)^2+(l4.gdp_wdi_o-roll_mgdp_wdi_o)^2+(l5.gdp_wdi_o-roll_mgdp_wdi_o)^2)/5)^0.5
	gen `var'roll_corr_gdp_wdi = roll_cov_gdp_wdi/(roll_sd_gdp_wdi_d*roll_sd_gdp_wdi_o)
	
	
	xtreg gdp_wdi_d i.country_num#c.l.gdp_wdi_d
	predict gdp_wdi_d_res
	replace gdp_wdi_d_res = gdp_wdi_d - gdp_wdi_d_res
	xtreg gdp_wdi_o i.`var'_num#c.l.gdp_wdi_o
	predict gdp_wdi_o_res
	replace gdp_wdi_o_res = gdp_wdi_o - gdp_wdi_o_res

	by idch: egen mgdp_wdi_d_res = mean(gdp_wdi_d_res)
	by idch: egen mgdp_wdi_o_res = mean(gdp_wdi_o_res)
	gen COV_gdp_wdi_res = (gdp_wdi_d_res-mgdp_wdi_d_res)*(gdp_wdi_o_res-mgdp_wdi_o_res)
	by idch: egen cov_gdp_wdi_res = mean(COV_gdp_wdi_res)
	by idch: egen `var'sd_gdp_wdi_d_res = sd(gdp_wdi_d_res)
	by idch: egen `var'sd_gdp_wdi_o_res = sd(gdp_wdi_o_res)
	gen `var'corr_gdp_wdi_res = cov_gdp_wdi_res/(`var'sd_gdp_wdi_d_res*`var'sd_gdp_wdi_o_res)


	keep country `var' year `var'corr_gdp_wdi `var'roll_corr_gdp_wdi `var'corr_gdp_wdi_res `var'cov_gdp_wdi `var'sd_gdp_wdi_o_res `var'sd_gdp_wdi_o `var'sd_gdp_wdi_d_res `var'sd_gdp_wdi_d

	save $wdif/corr_gdp_wdi, replace

	*
	use "$output/extended.dta", clear 

	keep gdp_current cpi_current `var' country
	collapse gdp_current cpi_current, by(`var' country)
	drop if `var' == ""
	drop if gdp_current==. & cpi_current==.
	drop gdp_current cpi_current
	encode country, gen(country_num)
	encode `var', gen(`var'_num)
	
	sort country

	gen n=43
	expand n
	replace n = 1
	bys country `var': gen year = sum(n)
	replace year = year + 1989

	merge m:1 country year using $wdif/cpi_wdi
	drop if _merge==2
	drop _merge
	
	rename cpi_wdi cpi_wdi_o
	rename country country1
	rename `var' country

	merge m:1 country year using $wdif/cpi_wdi
	drop if _merge==2
	drop _merge
	
	rename country `var'
	rename country1 country
	rename cpi_wdi cpi_wdi_d
	drop n
	drop if `var'==""
	drop if country==""

	sort country `var' year

	by country `var': egen mcpi_wdi_d = mean(cpi_wdi_d)
	by country `var': egen mcpi_wdi_o = mean(cpi_wdi_o)
	gen COV_cpi_wdi = (cpi_wdi_d-mcpi_wdi_d)*(cpi_wdi_o-mcpi_wdi_o)
	by country `var': egen cov_cpi_wdi = mean(COV_cpi_wdi)
	by country `var': egen sd_cpi_wdi_d = sd(cpi_wdi_d)
	by country `var': egen `var'sd_cpi_wdi_o = sd(cpi_wdi_o)
	gen `var'corr_cpi_wdi = cov_cpi_wdi/(sd_cpi_wdi_d*`var'sd_cpi_wdi_o)
	gen `var'cov_cpi_wdi = cov_cpi_wdi

	by country `var': egen N_d_o = count(COV_cpi_wdi)
	drop if N_d_o<20
	
	egen idch = group(country `var')
	sort idch year
	xtset idch year

	by idch: gen roll_mcpi_wdi_d = (l.cpi_wdi_d+l2.cpi_wdi_d+l3.cpi_wdi_d+l4.cpi_wdi_d+l5.cpi_wdi_d)/5
	by idch: gen roll_mcpi_wdi_o = (l.cpi_wdi_o+l2.cpi_wdi_o+l3.cpi_wdi_o+l4.cpi_wdi_o+l5.cpi_wdi_o)/5
	by idch: gen roll_cov_cpi_wdi = ((l.cpi_wdi_d-roll_mcpi_wdi_d)*(l.cpi_wdi_o-roll_mcpi_wdi_o)+(l2.cpi_wdi_d-roll_mcpi_wdi_d)*(l2.cpi_wdi_o-roll_mcpi_wdi_o)+(l3.cpi_wdi_d-roll_mcpi_wdi_d)*(l3.cpi_wdi_o-roll_mcpi_wdi_o)+(l4.cpi_wdi_d-roll_mcpi_wdi_d)*(l4.cpi_wdi_o-roll_mcpi_wdi_o)+(l5.cpi_wdi_d-roll_mcpi_wdi_d)*(l5.cpi_wdi_o-roll_mcpi_wdi_o))/5
	by idch: gen roll_sd_cpi_wdi_d = (((l.cpi_wdi_d-roll_mcpi_wdi_d)^2+(l2.cpi_wdi_d-roll_mcpi_wdi_d)^2+(l3.cpi_wdi_d-roll_mcpi_wdi_d)^2+(l4.cpi_wdi_d-roll_mcpi_wdi_d)^2+(l5.cpi_wdi_d-roll_mcpi_wdi_d)^2)/5)^0.5
	by idch: gen roll_sd_cpi_wdi_o = (((l.cpi_wdi_o-roll_mcpi_wdi_o)^2+(l2.cpi_wdi_o-roll_mcpi_wdi_o)^2+(l3.cpi_wdi_o-roll_mcpi_wdi_o)^2+(l4.cpi_wdi_o-roll_mcpi_wdi_o)^2+(l5.cpi_wdi_o-roll_mcpi_wdi_o)^2)/5)^0.5
	gen `var'roll_corr_cpi_wdi = roll_cov_cpi_wdi/(roll_sd_cpi_wdi_d*roll_sd_cpi_wdi_o)
	
	xtreg cpi_wdi_d i.country_num#c.l.cpi_wdi_d
	predict cpi_wdi_d_res
	replace cpi_wdi_d_res = cpi_wdi_d - cpi_wdi_d_res
	xtreg cpi_wdi_o i.`var'_num#c.l.cpi_wdi_o
	predict cpi_wdi_o_res
	replace cpi_wdi_o_res = cpi_wdi_o - cpi_wdi_o_res

	by idch: egen mcpi_wdi_d_res = mean(cpi_wdi_d_res)
	by idch: egen mcpi_wdi_o_res = mean(cpi_wdi_o_res)
	gen COV_cpi_wdi_res = (cpi_wdi_d_res-mcpi_wdi_d_res)*(cpi_wdi_o_res-mcpi_wdi_o_res)
	by idch: egen cov_cpi_wdi_res = mean(COV_cpi_wdi_res)
	by idch: egen `var'sd_cpi_wdi_d_res = sd(cpi_wdi_d_res)
	by idch: egen `var'sd_cpi_wdi_o_res = sd(cpi_wdi_o_res)
	gen `var'corr_cpi_wdi_res = cov_cpi_wdi_res/(`var'sd_cpi_wdi_d_res*`var'sd_cpi_wdi_o_res)

	drop if country=="Singapore" | country=="Hong Kong"
	drop if `var'=="Singapore" | `var'=="Hong Kong"

	keep country `var' year `var'corr_cpi_wdi `var'roll_corr_cpi_wdi `var'corr_cpi_wdi_res `var'cov_cpi_wdi `var'sd_cpi_wdi_o_res `var'sd_cpi_wdi_o `var'sd_cpi_wdi_d_res `var'sd_cpi_wdi_d

	save $wdif/corr_cpi_wdi, replace

	*
	use "$output/extended.dta", clear 

	merge m:1 country `var' year using $wdif/corr_gdp_wdi
	drop if _merge==2
	drop _merge
	merge m:1 country `var' year using $wdif/corr_cpi_wdi
	drop if _merge==2
	drop _merge
	
	save "$output/extended.dta", replace
}




********* Internet

import excel "$wdi/Internet_World_Development_Indicators.xlsx", sheet("Data") firstrow clear

keep if SeriesName == "Individuals using the Internet (% of population)"
reshape long YR, i(CountryName)

rename CountryName country
rename _j year
rename YR internet_use

keep country year internet_use
drop if year<1998

replace country = "South Korea" if country=="Korea, Rep."
replace country = "Russia" if country=="Russian Federation"
replace country = "Venezuela" if country=="Venezuela, RB"
replace country = "Slovakia" if country=="Slovak Republic"
replace country = "Turkey" if country=="Turkiye"
replace country = "Czech Republic" if country=="Czechia"
replace country = "Egypt" if country=="Egypt, Arab Rep."
replace country = "Hong Kong" if country=="Hong Kong SAR, China"
replace country = "Iran" if country=="Iran, Islamic Rep."

sort country year

save $wdif/internet_use, replace

*
import excel "$wdi/Internet_World_Development_Indicators.xlsx", sheet("Data") firstrow clear

keep if SeriesName == "Secure Internet servers (per 1 million people)"
reshape long YR, i(CountryName)

rename CountryName country
rename _j year
rename YR servers

keep country year servers
drop if year<1998

replace country = "South Korea" if country=="Korea, Rep."
replace country = "Russia" if country=="Russian Federation"
replace country = "Venezuela" if country=="Venezuela, RB"
replace country = "Slovakia" if country=="Slovak Republic"
replace country = "Turkey" if country=="Turkiye"
replace country = "Czech Republic" if country=="Czechia"
replace country = "Egypt" if country=="Egypt, Arab Rep."
replace country = "Hong Kong" if country=="Hong Kong SAR, China"
replace country = "Iran" if country=="Iran, Islamic Rep."

sort country year

save $wdif/servers, replace

*

use "$output/extended.dta", clear 

keep gdp_current cpi_current Headquarters country year
collapse gdp_current cpi_current, by(Headquarters country year)
drop if Headquarters == ""
drop if gdp_current==. & cpi_current==.
drop gdp_current cpi_current

merge m:1 country year using $wdif/internet_use
drop if _merge==2
drop _merge

rename internet_use internet_use_o
rename country country1
rename Headquarters country

merge m:1 country year using $wdif/internet_use
drop if _merge==2
drop _merge

rename country Headquarters
rename country1 country
rename internet_use internet_use_d
drop if Headquarters==""
drop if country==""

sort country Headquarters year

keep country Headquarters year internet_use_o internet_use_d

save $wdif/hq_internet_use, replace

*
use "$output/extended.dta", clear 

keep gdp_current cpi_current Headquarters country year
collapse gdp_current cpi_current, by(Headquarters country year)
drop if Headquarters == ""
drop if gdp_current==. & cpi_current==.
drop gdp_current cpi_current

merge m:1 country year using $wdif/servers
drop if _merge==2
drop _merge

rename servers servers_o
rename country country1
rename Headquarters country

merge m:1 country year using $wdif/servers
drop if _merge==2
drop _merge

rename country Headquarters
rename country1 country
rename servers servers_d
drop if Headquarters==""
drop if country==""

sort country Headquarters year

keep country Headquarters year servers_o servers_d

save $wdif/hq_servers, replace

*
use "$output/extended.dta", clear 

merge m:1 country Headquarters year using $wdif/hq_internet_use
drop if _merge==2
drop _merge
merge m:1 country Headquarters year using $wdif/hq_servers
drop if _merge==2
drop _merge

save "$output/extended.dta", replace
*
	
local varlist dist_ distw_

foreach var in `varlist'{
	
	use "$output/extended.dta", clear 

	keep gdp_current cpi_current `var' country year
	collapse gdp_current cpi_current, by(`var' country year)
	drop if `var' == ""
	drop if gdp_current==. & cpi_current==.
	drop gdp_current cpi_current

	merge m:1 country year using $wdif/internet_use
	drop if _merge==2
	drop _merge

	rename internet_use `var'internet_use_o
	rename country country1
	rename `var' country

	merge m:1 country year using $wdif/internet_use
	drop if _merge==2
	drop _merge
	
	rename country `var'
	rename country1 country
	rename internet_use `var'internet_use_d
	drop if `var'==""
	drop if country==""

	sort country `var' year

	keep country `var' year `var'internet_use_o `var'internet_use_d

	save $wdif/`var'internet_use, replace

	*
	use "$output/extended.dta", clear 

	keep gdp_current cpi_current `var' country year
	collapse gdp_current cpi_current, by(`var' country year)
	drop if `var' == ""
	drop if gdp_current==. & cpi_current==.
	drop gdp_current cpi_current

	merge m:1 country year using $wdif/servers
	drop if _merge==2
	drop _merge
	
	rename servers `var'servers_o
	rename country country1
	rename `var' country

	merge m:1 country year using $wdif/servers
	drop if _merge==2
	drop _merge
	
	rename country `var'
	rename country1 country
	rename servers `var'servers_d
	drop if `var'==""
	drop if country==""

	sort country `var' year

	keep country `var' year `var'servers_o `var'servers_d

	save $wdif/`var'servers, replace

	*
	use "$output/extended.dta", clear 

	merge m:1 country `var' year using $wdif/`var'internet_use
	drop if _merge==2
	drop _merge
	merge m:1 country `var' year using $wdif/`var'servers
	drop if _merge==2
	drop _merge
	
	save "$output/extended.dta", replace
}




********* Capital controls

use "$fkrsu/2021-FKRSU-Update-12-08-2021.dta", clear

gen eqi = (eq_plbn + eq_siar)/2
gen eqo = (eq_siln + eq_pabr)/2
gen eq = (eqi + eqo)/2
gen boi = (bo_plbn + bo_siar)/2
gen boo = (bo_siln + bo_pabr)/2
gen bo = (boi + boo)/2
gen mmi = (mm_plbn + mm_siar)/2
gen mmo = (mm_siln + mm_pabr)/2
gen mm = (mmi + mmo)/2
gen cii = (ci_plbn + ci_siar)/2
gen cio = (ci_siln + ci_pabr)/2
gen ci = (cii + cio)/2
gen dei = (de_plbn + de_siar)/2
gen deo = (de_siln + de_pabr)/2
gen de = (dei + deo)/2
gen cc = (cci + cco)/2
gen fc = (fci + fco)/2
gen gs = (gsi + gso)/2
gen di = (dii + dio)/2
gen rei = re_plbn
gen reo = (re_slbn + re_pabr)/2
gen re = (rei + reo)/2
gen kai = (eqi + boi + mmi + cii + dei + cci + fci + gsi + dii + rei)/10 if Year>1996
replace kai = (eqi + mmi + cii + dei + cci + fci + gsi + dii + rei)/9 if Year<=1996
gen kao = (eqo + boo + mmo + cio + deo + cco + fco + gso + dio + reo)/10 if Year>1996
replace kao = (eqo + mmo + cio + deo + cco + fco + gso + dio + reo)/9 if Year<=1996
gen ka = (kai + kao)/2

keep Country Year eqi eqo boi boo mmi mmo cii cio dei deo cci cco fci fco gsi gso dii dio rei reo kai kao

rename Country country 
rename Year year

replace country = "Hong Kong" if country=="Hong Kong SAR"
replace country = "Iran" if country=="Islamic Republic of Iran"
replace country = "South Korea" if country=="Korea"

sort country year

save $fkrsuf/ka, replace

*

use "$output/extended.dta", clear 

keep gdp_current cpi_current Headquarters country year
collapse gdp_current cpi_current, by(Headquarters country year)
drop if Headquarters == ""
drop if gdp_current==. & cpi_current==.
drop gdp_current cpi_current

merge m:1 country year using $fkrsuf/ka
drop if _merge==2
drop _merge

foreach VAR in eqi eqo boi boo mmi mmo cii cio dei deo cci cco fci fco gsi gso dii dio rei reo kai kao {
	rename `VAR' `VAR'_o
}
rename country country1
rename Headquarters country

merge m:1 country year using $fkrsuf/ka
drop if _merge==2
drop _merge

rename country Headquarters
rename country1 country

foreach VAR in eqi eqo boi boo mmi mmo cii cio dei deo cci cco fci fco gsi gso dii dio rei reo kai kao {
	rename `VAR' `VAR'_d
}
drop if Headquarters==""
drop if country==""

sort country Headquarters year

save $fkrsuf/hq_ka, replace

*
use "$output/extended.dta", clear 

merge m:1 country Headquarters year using $fkrsuf/hq_ka
drop if _merge==2
drop _merge

save "$output/extended.dta", replace

*



	
local varlist dist_ distw_

foreach var in `varlist'{
	
	use "$output/extended.dta", clear 

	keep gdp_current cpi_current `var' country year
	collapse gdp_current cpi_current, by(`var' country year)
	drop if `var' == ""
	drop if gdp_current==. & cpi_current==.
	drop gdp_current cpi_current

	merge m:1 country year using $fkrsuf/ka
	drop if _merge==2
	drop _merge
		
	foreach VAR in eqi eqo boi boo mmi mmo cii cio dei deo cci cco fci fco gsi gso dii dio rei reo kai kao {
		rename `VAR' `var'`VAR'_o
	}
	rename country country1
	rename `var' country


	merge m:1 country year using $fkrsuf/ka
	drop if _merge==2
	drop _merge

	rename country `var'
	rename country1 country

	foreach VAR in eqi eqo boi boo mmi mmo cii cio dei deo cci cco fci fco gsi gso dii dio rei reo kai kao {
		rename `VAR' `var'`VAR'_d
	}
	drop if `var'==""
	drop if country==""

	sort country `var' year

	save $fkrsuf/`var'_ka, replace

	*
	use "$output/extended.dta", clear 

	merge m:1 country `var' year using $fkrsuf/`var'_ka
	drop if _merge==2
	drop _merge

	save "$output/extended.dta", replace
}



save "$output/extended.dta", replace




* ----------------------
*# Stack variables and horizons
* ----------------------

* extended STACKED

use "$output/extended.dta", clear 

gen ka_o = kai_o+kao_o

preserve
drop if country_num==.
drop if Emerging==.
collapse (mean) lgdp_ppp_o lgdp_cap_ppp_d ICRG WDI_institutions iq_spi_ovrl iq_sci_ovrl rho_gdp rho_cpi rmse_gdp rmse_cpi r2_gdp r2_cpi cc_est ICRG_Corrupt gdp_current_a1 cpi_current_a1 tariff ka_o, by(country_num year Emerging country)
collapse (mean) lgdp_ppp_o lgdp_cap_ppp_d ICRG WDI_institutions iq_spi_ovrl iq_sci_ovrl rho_gdp rho_cpi rmse_gdp rmse_cpi r2_gdp r2_cpi cc_est ICRG_Corrupt (sd) sd_gdp = gdp_current_a1 sd_cpi = cpi_current_a1, by(country_num Emerging country)
save $stempf/cty_cs, replace
sort country_num	
restore

preserve
collapse (mean) lTotalRevenue lEmployees lprod Finance Banks Multinational, by(idi)
sort idi
save $stempf/inst_cs, replace
restore


sort country_num
merge m:1 country_num using $stempf/cty_cs, nogen
sort idi
merge m:1 idi using $stempf/inst_cs, nogen
sort country_num idi
gen l_sd_gdp = log(sd_gdp)
gen l_sd_cpi = log(sd_cpi)
gen l_rmse_gdp = log(rmse_gdp)
gen l_rmse_cpi = log(rmse_cpi)
gen l_sdreturn = log(sdreturn)

save $output/extended_stacked.dta, replace

gen var = "gdp"
gen hor = "current"
append using $output/extended_stacked.dta
replace var = "gdp" if var == ""
replace hor = "future" if hor == ""
append using $output/extended_stacked.dta
replace var = "cpi" if var == ""
replace hor = "current" if hor == ""
append using $output/extended_stacked.dta
replace var = "cpi" if var == ""
replace hor = "future" if hor == ""

gen l_sd = l_sd_gdp if var=="gdp"
replace l_sd = l_sd_cpi if var=="cpi"
gen l_rmse = l_rmse_gdp if var=="gdp"
replace l_rmse = l_rmse_cpi if var=="cpi"

gen GDP = (var=="gdp")
replace GDP =. if var!="gdp" & var!="cpi"
gen future = (hor=="future")
replace future =. if hor!="future" & hor!="current"

gen CPI = 1-GDP
gen current = 1-future

encode var, gen(Var)
encode hor, gen(Hor)

gen forecast = gdp_current if var=="gdp" & hor=="current"
replace forecast = gdp_future if var=="gdp" & hor=="future"
replace forecast = cpi_current if var=="cpi" & hor=="current"
replace forecast = cpi_future if var=="cpi" & hor=="future"

gen labs_FE_a1 = labs_FE_gdp_current_a1 if var=="gdp" & hor=="current"
replace labs_FE_a1 = labs_FE_gdp_future_a1 if var=="gdp" & hor=="future"
replace labs_FE_a1 = labs_FE_cpi_current_a1 if var=="cpi" & hor=="current"
replace labs_FE_a1 = labs_FE_cpi_future_a1 if var=="cpi" & hor=="future"

gen FE_a1 = FE_gdp_current_a1 if var=="gdp" & hor=="current"
replace FE_a1 = FE_gdp_future_a1 if var=="gdp" & hor=="future"
replace FE_a1 = FE_cpi_current_a1 if var=="cpi" & hor=="current"
replace FE_a1 = FE_cpi_future_a1 if var=="cpi" & hor=="future"

***** Important!!
replace labs_FE_a1 = max(-6.9,labs_FE_a1) if labs_FE_a1!=.
replace labs_FE_a1 = -6.9 if FE_a1==0
*****

gen pop_2000 = pop_d if year == 2000
gen distw_pop_2000 = distw_pop_d if year == 2000
bys Head: egen Pop_2000 = max(pop_2000)
bys closest_ctry_distw: egen distw_Pop_2000 = max(distw_pop_2000)
gen Natives_2000 = 1000*Pop_2000 - Migration_2000_total
gen distw_Natives_2000 = 1000*distw_Pop_2000 - distw_Migration_2000_total
gen migration_2000 = Migration_2000/(1000*Pop_2000)
replace migration_2000 = Natives_2000/(1000*Pop_2000) if country==Head
gen distw_migration_2000 = distw_Migration_2000/(1000*distw_Pop_2000)
replace distw_migration_2000 = distw_Natives_2000/(1000*distw_Pop_2000) if country==closest_ctry_distw


gen trade = (tradeflow_comtrade_o+tradeflow_comtrade_d)/(gdp_o+gdp_d)
gen ltrade = log(trade)
gen lgdp_o = log(gdp_ppp_o)
gen lgdp_d = log(gdp_ppp_d)
gen absorbtion = gdp_o-exports/1000
gen trade_exports = (tradeflow_comtrade_d)/(gdp_o+gdp_d)
replace trade_exports = (absorbtion)/(gdp_o+gdp_d) if country==Headquarter
gen ltrade_exports = log(trade_exports)
gen trade_imports = (tradeflow_comtrade_o)/(gdp_o+gdp_d)
replace trade_imports = (absorbtion)/(gdp_o+gdp_d) if country==Headquarter
gen ltrade_imports = log(trade_imports)
gen finlink = totalclaims2/(gdp_o+gdp_d)
gen lfinlink = log(finlink)
gen cov_wdi = cov_gdp_wdi if Var == 2
replace cov_wdi = cov_cpi_wdi if Var == 1
gen sd_wdi_d = sd_gdp_wdi_d if Var == 2
replace sd_wdi_d = sd_cpi_wdi_d if Var == 1
gen corr_wdi = corr_gdp_wdi if Var == 2
replace corr_wdi = corr_cpi_wdi if Var == 1
gen corr_wdi_res = corr_gdp_wdi_res if Var == 2
replace corr_wdi_res = corr_cpi_wdi_res if Var == 1
gen time_overlap = max(0,10-abs(gmt_offset_2020_o-gmt_offset_2020_d))
gen internet = min(internet_use_o,internet_use_d)
gen servers = min(servers_o,servers_d)
gen gatt = gatt_o*gatt_d
gen bilateral_ka = max(kai_d,kao_o)
gen bilateral_fc = max(fci_d,fco_o)
gen link = indirect_link+direct_link
gen beta =cov_wdi/sd_wdi_d^2

gen distw_trade = (distw_tradeflow_comtrade_o+distw_tradeflow_comtrade_d)/(distw_gdp_o+distw_gdp_d)
gen ldistw_trade = log(trade)
gen ldistw_gdp_o = log(distw_gdp_ppp_o)
gen ldistw_gdp_d = log(distw_gdp_ppp_d)
gen distw_absorbtion = distw_gdp_o-exports/1000
gen distw_trade_exports = (distw_tradeflow_comtrade_d)/(distw_gdp_o+distw_gdp_d)
replace distw_trade_exports = (absorbtion)/(distw_gdp_o+distw_gdp_d) if country==closest_ctry_distw
gen ldistw_trade_exports = log(trade_exports)
gen distw_trade_imports = (distw_tradeflow_comtrade_o)/(distw_gdp_o+distw_gdp_d)
replace distw_trade_imports = (absorbtion)/(distw_gdp_o+distw_gdp_d) if country==closest_ctry_distw
gen ldistw_trade_imports = log(trade_imports)
gen distw_finlink = distw_totalclaims2/(distw_gdp_o+distw_gdp_d)
gen ldistw_finlink = log(distw_finlink)
gen ldistw_distw = log(distw_distw)
gen distw_cov_wdi = distw_cov_gdp_wdi if Var == 2
replace distw_cov_wdi = distw_cov_cpi_wdi if Var == 1
gen distw_sd_wdi_d = distw_sd_gdp_wdi_d if Var == 2
replace distw_sd_wdi_d = distw_sd_cpi_wdi_d if Var == 1
gen distw_corr_wdi = distw_corr_gdp_wdi if Var == 2
replace distw_corr_wdi = distw_corr_cpi_wdi if Var == 1
gen distw_corr_wdi_res = distw_corr_gdp_wdi_res if Var == 2
replace distw_corr_wdi_res = distw_corr_cpi_wdi_res if Var == 1
gen distw_time_overlap = max(0,10-abs(distw_gmt_offset_2020_o-distw_gmt_offset_2020_d))
gen distw_internet = min(distw_internet_use_o,distw_internet_use_d)
gen distw_servers = min(distw_servers_o,distw_servers_d)
gen distw_gatt = distw_gatt_o*distw_gatt_d
gen distw_bilateral_ka = max(distw_fci_d,distw_fco_o)
gen distw_bilateral_fc = max(distw_fci_d,distw_fco_o)
gen distw_beta =distw_cov_wdi/distw_sd_wdi_d^2


egen id3 = group(country_num Headquarters)
egen id4 = group(country_num closest_ctry_distw)

gen rta_type1 = (rta_type==1)
gen rta_type2 = (rta_type==2)
gen rta_type3 = (rta_type==3)
gen rta_type4 = (rta_type==4)
gen rta_type5 = (rta_type==5)
gen rta_type6 = (rta_type==6)
gen rta_type7 = (rta_type==7)

gen trade_open = (exports+imports)/gdp_o
gen trade_open_exports = (exports)/gdp_o
gen trade_open_imports = (imports)/gdp_o

gen distw_ka_o = dist_kai_o+distw_kao_o

gen distw_corr_wdi_res_abs = abs(distw_corr_wdi_res)

gen t = year-2010

gen CU = (rta_type==1) + (rta_type==2)
gen FTA = (rta_type==4) + (rta_type==5)
replace rta=1 if country==Headquarters
replace CU = 1 if country==Headquarters
gen lexports = log(exports)
gen lexports_2017_ = lexports if year==2017
bys country: egen lexports_2017 = max(lexports_2017_)

gen r2 = corr_wdi^2
gen distw_r2 = distw_corr_wdi^2

egen WDI_bin = xtile(WDI), nq(2)
egen lgdp_ppp_o_bin = xtile(lgdp_ppp_o), nq(2)
egen l_sdreturn_bin = xtile(l_sdreturn), nq(2)
egen vix_bin = xtile(vix), nq(2)

gen large2 = lgdp_ppp_o_bin
gen small2 = 1- lgdp_ppp_o_bin

replace lgdp_ppp_o_bin = lgdp_ppp_o_bin-1
gen large = lgdp_ppp_o_bin
gen small = 1- lgdp_ppp_o_bin

replace rec = 0 if gdp_current_a1!=.
replace rec=1 if gdp_current_a1<0 & gdp_current_a1!=.

gen National =1-Multinational
gen LocalSub = (ForeignHQ==1)*(Foreign==0)
gen lN_cty2 = log(N_cty2)
gen nonFinance = 1-Finance
gen manyCtries = (N_cty2>9)
gen fewCtries = (N_cty2<10)


save "$output/extended_stacked.dta", replace



								* END OF CODE *
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
