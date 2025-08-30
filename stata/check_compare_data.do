/*
* check and compare data:
use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's_File/Company_Trees/data_final_newVintage_3.dta", clear

keep country country_num institution id date datem  month gdp_current gdp_future  cpi_current cpi_future year_forecast_current_gdp year_forecast_future_gdp year_forecast_current_cpi year_forecast_future_cpi Foreign ForeignHQ ForeignSubsidiary Local Foreign idci

sort idci datem
save "/Users/ebollige/Dropbox/1_1_replication_forecasters/compare_data_for_you_only/to_replicate.dta", replace

use "/Users/ebollige/Dropbox/1_1_replication_forecasters/localforecastrep/inst/data/produced/ce_imf/data_final_newVintage_3.dta", clear

keep country country_num institution id date datem  month gdp_current gdp_future  cpi_current cpi_future  year_forecast_current_gdp year_forecast_future_gdp year_forecast_current_cpi year_forecast_future_cpi Foreign ForeignHQ ForeignSubsidiary Local Foreign idci


sort idci datem


merge 1:1 country country_num institution id date datem  month gdp_current gdp_future  cpi_current cpi_future  year_forecast_current_gdp year_forecast_future_gdp year_forecast_current_cpi year_forecast_future_cpi Foreign ForeignHQ ForeignSubsidiary Local Foreign using "/Users/ebollige/Dropbox/1_1_replication_forecasters/compare_data_for_you_only/to_replicate.dta"

*/






cd "/Users/ebollige/Dropbox/1_1_replication_forecasters/localforecastrep/stata/"

* do file location:
local dofile = "`c(pwd)'"
disp "`dofile'" 
local parent = substr("`dofile'", 1, strrpos("`dofile'", "/")-1)
disp "`parent'" 


* Append the desired subfolder
local target = "`parent'/output/figures"
global figures "`target'"
local target = "`parent'/output/regressions"
global regressions "`target'"
local target = "`parent'/output/tables"
global tables "`target'"


use "/Users/ebollige/Dropbox/1_1_replication_forecasters/localforecastrep/inst/data/produced/ce_imf/data_final_newVintage_3.dta", clear


* set gridstyle for figures:
grstyle init
grstyle set plain, horizontal grid dotted

****************************************************************
****************************************************************
* DATA PREP
****************************************************************
****************************************************************

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


save "/Users/ebollige/Dropbox/1_1_replication_forecasters/localforecastrep/inst/data/produced/ce_imf/TempE.dta", replace





use "/Users/ebollige/Dropbox/1_1_replication_forecasters/localforecastrep/inst/data/produced/ce_imf/TempE.dta", clear



preserve
collapse (count) cpi_current gdp_current cpi_future gdp_future, by(country country_num idi idci year Foreign LocFor)

sum cpi_current gdp_current cpi_future gdp_future

* histograms
label var cpi_current "Number of yearly current CPI updates"
label var gdp_current "Number of yearly current GDP updates"
label var cpi_future "Number of yearly future CPI updates"
label var gdp_future "Number of yearly future GDP updates"
hist cpi_current
graph export "$figures//hist_update_cpi_current.pdf", as(pdf) replace
hist gdp_current
graph export "$figures//hist_update_gdp_current.pdf", as(pdf) replace
hist cpi_future
graph export "$figures//hist_update_cpi_future.pdf", as(pdf) replace
hist gdp_future
graph export "$figures//hist_update_gdp_future.pdf", as(pdf) replace

foreach hor in current future {
	foreach var in cpi gdp  {
		
		local rnge 0 12
			
		*preserve
		*collapse FE_`var'_`hor'_a1 `var'_`hor'_a1 Emerging Foreign Multinational N_cty2, by(year idi country_num)
		local vtext : variable label `var'_`hor'
			
		twoway (hist `var'_`hor' if Foreign ==0 , color(blue%30) frac ///
				fintensity(inten100) xlabel(0(2)12,grid gstyle(dot)) ylabel(,grid gstyle(dot)) ) ///
				(hist `var'_`hor'  if Foreign==1  ,  color(red%30) frac ///
				fintensity(inten100) xlabel(0(2)12,grid gstyle(dot)) ylabel(,grid gstyle(dot)) ), ///
				legend(size(small) label(1 "Local") label(2 "Foreign") position(0) bplacement(nwest) ) ///
				ytitle("Kernel density") xtitle("") graphregion(fcolor(white)  lcolor(white))  ///
				bgcolor(white)
				
		graph export "$figures//`var'_`hor'_N_density.pdf", as(pdf) replace
	
	}
}

replace cpi_current = log(cpi_current)
replace gdp_current = log(gdp_current)
replace cpi_future = log(cpi_future)
replace gdp_future = log(gdp_future)

* regressions

foreach var in cpi gdp {
	foreach hor in current future {

		reghdfe `var'_`hor' Foreign, absorb(idi#year country_num#year) vce(cluster country_num idi)
regsave using "$regressions/reg_update_`var'_`hor'_FE1.dta", replace  ///
	addlabel(FE1, "", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", FE6, "", FE7, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

	* robustness
		reghdfe `var'_`hor' Foreign, noabsorb vce(cluster country_num idi)
regsave using "$regressions/reg_update_`var'_`hor'_FE1_rob.dta", replace  ///
	addlabel(FE1, "", FE2, "", FE3, "", FE4, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
		reghdfe `var'_`hor' Foreign, absorb(country_num) vce(cluster country_num idi)
regsave using "$regressions/reg_update_`var'_`hor'_FE1_rob.dta", append  ///
	addlabel(FE1, "\checkmark", FE2, "", FE3, "", FE4, "")  table(col_2, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
		reghdfe `var'_`hor' Foreign, absorb(country_num idi) vce(cluster country_num idi)
regsave using "$regressions/reg_update_`var'_`hor'_FE1_rob.dta", append  ///
	addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "", FE4, "")  table(col_3, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
		reghdfe `var'_`hor' Foreign, absorb(country_num#year idi) vce(cluster country_num idi)
regsave using "$regressions/reg_update_`var'_`hor'_FE1_rob.dta", append  ///
	addlabel(FE1, "", FE2, "\checkmark", FE3, "\checkmark", FE4, "")  table(col_4, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
		reghdfe `var'_`hor' Foreign, absorb(idi#year country_num#year) vce(cluster country_num idi)
regsave using "$regressions/reg_update_`var'_`hor'_FE1_rob.dta", append  ///
	addlabel(FE1, "", FE2, "", FE3, "\checkmark", FE4, "\checkmark")  table(col_5, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	
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
hist cpi_current
graph export "$figures//hist_update_cpi_current2.pdf", as(pdf) replace
hist gdp_current
graph export "$figures//hist_update_gdp_current2.pdf", as(pdf) replace
hist cpi_current
graph export "$figures//hist_update_cpi_future2.pdf", as(pdf) replace
hist gdp_current
graph export "$figures//hist_update_gdp_future2.pdf", as(pdf) replace

foreach hor in current future {
	foreach var in cpi gdp  {
		
		local rnge 0 12
			
		*preserve
		*collapse FE_`var'_`hor'_a1 `var'_`hor'_a1 Emerging Foreign Multinational N_cty2, by(year idi country_num)
		local vtext : variable label `var'_`hor'
			
		twoway (hist `var'_`hor' if Foreign ==0 , color(blue%30)  ///
				fintensity(inten100) xlabel(0(2)12,grid gstyle(dot)) ylabel(,grid gstyle(dot)) ) ///
				(hist `var'_`hor'  if Foreign==1  ,  color(red%30) ///
				fintensity(inten100) xlabel(0(2)12,grid gstyle(dot)) ylabel(,grid gstyle(dot)) ), ///
				legend(size(small) label(1 "Local") label(2 "Foreign") position(0) bplacement(nwest) ) ///
				ytitle("Kernel density") xtitle("") graphregion(fcolor(white)  lcolor(white))  ///
				bgcolor(white)
				
		graph export "$figures//`var'_`hor'_N_density2.pdf", as(pdf) replace
	
	}
}

replace cpi_current = log(cpi_current)
replace gdp_current = log(gdp_current)
replace cpi_future = log(cpi_future)
replace gdp_future = log(gdp_future)
* regressions
foreach var in cpi gdp {
	foreach hor in current future {
	
		reghdfe `var'_`hor' Foreign, absorb(idi#year country_num#year) vce(cluster country_num idi)
regsave using "$regressions/reg_update_`var'_`hor'_FE2.dta", replace  ///
	addlabel(FE1, "", FE2, "\checkmark", FE3, "\checkmark", FE4, "", FE5, "", FE6, "\checkmark", FE7, "")  table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

	}
}

restore


* combine results for cpi and gdp:
use $regressions/reg_update_cpi_current_FE1.dta, clear
g database = 1
append using $regressions/reg_update_gdp_current_FE1
replace database = 2 if database == .
append using $regressions/reg_update_cpi_future_FE1
replace database = 3 if database == .
append using $regressions/reg_update_gdp_future_FE1
replace database = 4 if database == .
g n = _n
rename col_1 col_1

save $regressions/reg_update_cpi_gdp_current_future_FE1.dta, replace

use $regressions/reg_update_cpi_current_FE2.dta, clear
g database = 1
append using $regressions/reg_update_gdp_current_FE2
replace database = 2 if database == .
append using $regressions/reg_update_cpi_future_FE2
replace database = 3 if database == .
append using $regressions/reg_update_gdp_future_FE2
replace database = 4 if database == .
g n = _n
rename col_1 col_2

save $regressions/reg_update_cpi_gdp_current_future_FE2.dta, replace

* merge results to have wide table:
use $regressions/reg_update_cpi_gdp_current_future_FE1.dta, clear
merge 1:1 database n using $regressions/reg_update_cpi_gdp_current_future_FE2
drop _merge

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

save $regressions/reg_updating, replace





use $regressions/reg_updating, clear

merge 1:1 _n using reg_lsd, nogen
merge 1:1 _n using reg_labs, nogen
merge 1:1 _n using reg_labs_non_mult, nogen
merge 1:1 _n using ©, nogen
merge 1:1 _n using reg_labs_distinct, nogen

gen n = _n
set obs 31
replace n = 2.1 if _n == 24
replace n = 2.2 if _n == 25
replace n = 6.1 if _n == 26
replace n = 6.2 if _n == 27
replace n = 10.1 if _n == 28
replace n = 10.2 if _n == 29
replace n = 14.1 if _n == 30
replace n = 14.2 if _n == 31

replace var = "Local Subsidiary" if _n == 24 | n == 26 | n== 28 | n == 30

sort n

merge 1:1 _n using reg_labs_mult_sub, nogen
drop n

gen col_9 = .
label var col_9 ""
gen col_10 = .
label var col_10 ""

label var col_2 "Distinct updates"
label var col_8 "Distinct updates"

drop if _n > 29

preserve
drop if _n>12 & _n<23
texsave indicator var col_1 col_2 col_9 col_3 col_10 col_4-col_7 using "$tables/tab_updating_errors_main.tex", ///
	title(Forecast Errors, Updating, and the Location of the Forecaster) varlabels nofix hlines(0) headersep(0pt) ///
	headerlines("{}&{}&\multicolumn{2}{c}{$\ln(N_{ijt})$}&&{$\ln(\sigma^m_{\text{FE},i,j})$}&&\multicolumn{4}{c}{$\ln(|Error_{ijt,t}^m|)$} \tabularnewline \cline{3-4} \cline{6-6} \cline{8-11} \tabularnewline &&{(1)}&{(2)}&&{(3)}&&{(4)}&{(5)}&{(6)}&{(7)}") ///
frag  size(footnotesize)  align(l l C C m{0.01\textwidth} C m{0.01\textwidth} C C C C) location(H) replace label(tab:updating_errors_main) footnote("\begin{minipage}{1\linewidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Columns (1) and (2) show the results of regression of the number of forecast updates within a year on the location of the forecaster. Column (3) shows the regression of the log standard deviation of the errors on the location of the forecaster. Columns (4) to (7) show the regression of the log absolute forecast error on the location of the forecaster. Standard errors are clustered at the country and forecaster level in columns (1) to (3), and at the country, forecaster and date level in columns (4) to (7). \end{tabnote} \end{minipage}  ") 
restore

preserve
drop if _n<13
texsave indicator var col_3 col_9 col_4-col_6 col_10 col_1 col_2 col_7 using "$tables/tab_updating_errors_app.tex", ///
	title(Forecast Errors, Updating, and the Location of the Forecaster - Future year) varlabels nofix hlines(0) headersep(0pt) ///
	headerlines("{}&{}&{$\ln(\sigma^m_{\text{FE},i,j})$}&&\multicolumn{3}{c}{$\ln(|Error_{ijt+1,t}^m|)$}&&\multicolumn{3}{c}{$\ln(N_{ijt})$} \tabularnewline \cline{3-3} \cline{5-7} \cline{9-11} \tabularnewline &&{(1)}&&{(2)}&{(3)}&{(4)}&&{(5)}&{(6)}&{(7)}") ///
frag  size(footnotesize)  align(l l C m{0.01\textwidth} C C C m{0.01\textwidth} C C C) location(H) replace label(tab:updating_errors_app) footnote("\begin{minipage}{1\linewidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Column (1) shows the regression of the log standard deviation of the errors on the location of the forecaster. Columns (2) to (4) show the regression of the log absolute forecast error on the location of the forecaster. Columns (5) and (7) show the results of regression of the number of forecast updates within a year on the location of the forecaster. Subsample 1 is restricted to the forecasts that are distinct from their last release. Subsample 2 is restricted to the forecasters that produce both local and foreign forecasts. Standard errors are clustered at the country and forecaster level in columns (1) and (5) to (7), and at the country, forecaster and date level in columns (2) to (4). \end{tabnote} \end{minipage}  ") 
restore

* parcimonious

preserve
drop if (_n>12 & _n<25) | _n==3 | _n==4 | _n==9 | _n==10
texsave indicator var col_3 col_9 col_4 col_8 col_10 col_1 col_2 using "$tables/tab_updating_errors_main_small.tex", ///
	title(Forecast Errors, Updating, and the Location of the Forecaster - Forecasts on the Current Year) varlabels nofix hlines(0) headersep(0pt) ///
	headerlines("{}&{}&{$\ln(\sigma^m_{\text{FE},i,j})$}&&\multicolumn{2}{c}{$\ln(|Error_{ijt,t}^m|)$}&&\multicolumn{2}{c}{$\ln(N_{ijt})$} \tabularnewline \cline{3-3} \cline{5-6} \cline{8-9} \tabularnewline &&{(1)}&&{(2)}&{(3)}&&{(4)}&{(5)}") ///
frag  size(footnotesize)  align(l l C m{0.01\textwidth} C C m{0.01\textwidth} C C ) location(H) replace label(tab:updating_errors_main_small) footnote("\begin{minipage}{1\linewidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} Column (1) shows the regression of the log standard deviation of the errors on the location of the forecaster. Columns (2) and (3) show the regression of the log absolute forecast error on the location of the forecaster. Columns (4) and (5)) show the results of regression of the number of forecast updates within a year on the location of the forecaster. Standard errors are clustered at the country and forecaster level in columns (1), (4) and (5), and at the country, forecaster and date level in Columns (2) and (3). In Columns (3) and (5), the sample is restricted to the published forecasts that are distinct from the last published one. \end{tabnote} \end{minipage}  ") 
restore

