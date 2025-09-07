
* reproduce data in section 5:


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
local target = "`parent'/inst/data/produced/stacked_temp"
global stempf "`target'"
local target = "`parent'/output/temp_data"
global temp_data "`target'"


* switch to data directory:
cd $output
* Check


set scheme stcolor, permanently

***************************************
* 6. Determinants
***************************************

* --------------------------
**# Regressions log(abs) stacked + "cross-section"
* ----------------------

use $data/extended_stacked, clear

gen forecast1000 = forecast*1000
gen forecast1000rounded = round(forecast1000)
gen model = (forecast1000-forecast1000rounded!=0) if forecast!=.

/*
egen idcvh = group(idci Var Hor)
sort idcvh datem
drop if idcvh==.
drop if datem==.
xtset idcvh datem
*/

	
* institution characteristics

* FE
local FE idi#datem#Var#Hor datem#country_num#Var#Hor
* clustering
local se cluster idi datem country_num

reghdfe labs_FE_a1 Foreign, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_mult", replace  ///
	addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign if Multinational==0, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_mult", append  ///
	addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_2, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign if Multinational==1, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_mult", append  ///
	addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_3, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 ForeignHQ if Multinational==1, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_mult", append  ///
	addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_4, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 ForeignHQ LocalSub if Multinational==1, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_mult", append  ///
	addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_5, asterisk(10 5 1) parentheses(stderr) format(%7.2f) order(Foreign ForeignHQ LocalSub))
lincom ForeignHQ + LocalSub

* country characteristics


* clustering
local se cluster idi datem country_num
reghdfe labs_FE_a1 Foreign GDP future month Emerging WDI_inst lgdp_ppp_o lgdp_ppp_d, noabsorb vce(`se')

reghdfe labs_FE_a1 Foreign GDP future month, absorb(country_num#year idi#year) vce(`se')
regsave using "$temp_data/reg_labs_cs_FE", replace addlabel(FE0, "\checkmark", FE1, "", FE2, "", FE3, "", FE4, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

local se cluster idi datem country_num
local FE idi#Var#Hor country_num#Var#Hor

reghdfe labs_FE_a1 Foreign rec vix, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_FE", append addlabel(FE0, "", FE1, "\checkmark", FE2, "", FE3, "", FE4, "") table(col_2, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

local se cluster idi datem country_num
local FE idi#datem#Var#Hor 

reghdfe labs_FE_a1 Foreign Emerging WDI_inst, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_FE", append addlabel(FE0, "", FE1, "", FE2, "", FE3, "\checkmark", FE4, "") table(col_3, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign Emerging WDI_inst lgdp_ppp_o, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_FE", append addlabel(FE0, "", FE1, "", FE2, "", FE3, "\checkmark", FE4, "") table(col_4, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

local se cluster idi datem country_num
local FE idi#Var#Hor#datem datem#country_num#Var#Hor

reghdfe labs_FE_a1 Foreign c.Foreign#c.GDP c.Foreign#c.future c.Foreign#c.month, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_FE", append addlabel(FE0, "", FE1, "", FE2, "", FE3, "\checkmark", FE4, "\checkmark") table(col_5, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign c.Foreign#c.rec c.Foreign#c.vix, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_FE", append addlabel(FE0, "", FE1, "", FE2, "", FE3, "\checkmark", FE4, "\checkmark") table(col_6, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign c.Foreign#c.WDI_inst c.Foreign#c.lgdp_ppp_o c.Foreign#c.Emerging, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_FE", append addlabel(FE0, "", FE1, "", FE2, "", FE3, "\checkmark", FE4, "\checkmark") table(col_7, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign c.Foreign#c.GDP c.Foreign#c.future c.Foreign#c.month c.Foreign#c.WDI_inst c.Foreign#c.lgdp_ppp_o c.Foreign#c.Emerging c.Foreign#c.rec c.Foreign#c.vix, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_FE", append addlabel(FE0, "", FE1, "", FE2, "", FE3, "\checkmark", FE4, "\checkmark") table(col_8, asterisk(10 5 1) parentheses(stderr) format(%7.2f) order(Foreign GDP future month vix rec Emerging WDI_institutions lgdp_ppp_o  c.Foreign#c.GDP c.Foreign#c.future c.Foreign#c.month c.Foreign#c.vix c.Foreign#c.rec c.Foreign#c.Emerging c.Foreign#c.WDI_institutions c.Foreign#c.lgdp_ppp_o))

* predicted values
local se cluster idi datem country_num
local FE idi#Var#Hor country_num#Var#Hor
reghdfe labs_FE_a1 Foreign rec vix, absorb(`FE') vce(`se')
gen predicted = _b[_cons]+_b[rec]*rec+_b[vix]*vix
drop predicted
local se cluster idi datem country_num
local FE idi#datem#Var#Hor 
reghdfe labs_FE_a1 Foreign Emerging WDI_inst lgdp_ppp_o, absorb(`FE') vce(`se')
gen predicted = _b[_cons]+_b[Emerging]*Emerging+_b[WDI_inst]*WDI_inst+_b[lgdp_ppp_o]*lgdp_ppp_o

* Country and time heterogeneity

local se cluster idi datem country_num
local FE idi#Var#Hor#datem country_num#Var#Hor#datem
reghdfe labs_FE_a1 c.Foreign#i.year, nocons absorb(`FE') vce(`se')
coefplot, ylab(, labs(medlarge)) ci(90) xline(0) omitted baselevels
graph export "$figures//heterogeneity_by_year.pdf", as(pdf) replace

local se cluster idi datem country_num
local FE idi#Var#Hor#datem country_num#Var#Hor#datem
reghdfe labs_FE_a1 c.Foreign#i.month, nocons absorb(`FE') vce(`se')
coefplot, ylab(, labs(medlarge)) ci(90) xline(0) omitted baselevels
graph export "$figures//heterogeneity_by_month.pdf", as(pdf) replace

bys idci month var hor: egen NN = count(labs_FE_a1)

local se cluster idi datem country_num
local FE country_num#Var#Hor#datem idi#Var#Hor#datem
reghdfe labs_FE_a1 c.Foreign#i.country_num#c.Emerging c.Foreign#i.country_num, nocons absorb(`FE') vce(`se')
estimates store Advanced
reghdfe labs_FE_a1 c.Foreign#i.country_num#c.Advanced c.Foreign#i.country_num, nocons absorb(`FE') vce(`se')
estimates store Emerging
coefplot Emerging Advanced, keep(*country_num#c.Foreign)  xline(0) sort plotlabels("Emerging" "Advanced") ylab(, nolabel) ci(90) baselevels
graph export "$figures//heterogeneity_by_cty.pdf", as(pdf) replace

local se cluster idi datem country_num
local FE country_num#Var#Hor#datem idi#Var#Hor#datem
reghdfe labs_FE_a1 c.Foreign#i.idi#c.Multinational c.Foreign#i.idi, nocons absorb(`FE') vce(`se')
estimates store National
reghdfe labs_FE_a1 c.Foreign#i.idi#c.National c.Foreign#i.idi, nocons absorb(`FE') vce(`se')
estimates store Multinational
coefplot Multinational National, keep(*idi#c.Foreign)  xline(0) sort plotlabels("Multinational" "National") ylab(, nolabel) ci(90) baselevels
graph export "$figures//heterogeneity_by_for.pdf", as(pdf) replace

*reghdfe labs_FE_a1, absorb(idi#datem#Var#Hor country_num, savefe) // saves with '__hdfe' prefix

* role of size: not robust
local se cluster idi datem country_num
local FE idi#Var#Hor#datem datem#country_num#Var#Hor
reghdfe labs_FE_a1 c.Foreign#c.small c.Foreign#c.large, absorb(`FE') vce(`se')
coefplot, drop(_cons)	

* variable by variable

local se cluster idi datem country_num
local FE idi#Var#Hor#datem datem#country_num#Var#Hor

reghdfe labs_FE_a1 Foreign c.Foreign#c.GDP , absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_ind_FE", replace addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign c.Foreign#c.future , absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_ind_FE", append addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_2, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign c.Foreign#c.month , absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_ind_FE", append addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_3, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign c.Foreign#c.vix, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_ind_FE", append addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_4, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign c.Foreign#c.rec, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_ind_FE", append addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_5, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign c.Foreign#c.Emerging, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_ind_FE", append addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_6, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign c.Foreign#c.WDI_institutions, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_ind_FE", append addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_7, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign c.Foreign#c.lgdp_ppp_o, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_cs_ind_FE", append addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_8, asterisk(10 5 1) parentheses(stderr) format(%7.2f) order(Foreign c.Foreign#c.GDP c.Foreign#c.future c.Foreign#c.month c.Foreign#c.vix c.Foreign#c.rec c.Foreign#c.Emerging c.Foreign#c.WDI_institutions c.Foreign#c.lgdp_ppp_o))


reghdfe labs_FE_a1 Foreign c.Foreign#c.WDI_inst c.Foreign#c.lgdp_ppp_o c.Foreign#c.Emerging c.Foreign#c.l_sdreturn c.Foreign#c.crisis c.Foreign#c.vix c.Foreign#c.t, absorb(`FE') vce(`se')


* gravity variables


gen forest=.
gen forlb = .
gen forub = .
gen forest1=.
gen forlb1 = .
gen forub1 = .
gen n = .

drop n
local FE idi#Var#Hor#datem datem#country_num#Var#Hor
local se cluster datem id4
reghdfe labs_FE_a1 c.Foreign##c.tariff, absorb(`FE') vce(`se')
forval i=0/8 {
	lincom Foreign+2*`i'*c.Foreign#c.tariff, l(90)
	replace forlb = r(lb) if _n==1+`i'
	replace forub = r(ub) if _n==1+`i'
	replace forest = r(estimate) if _n==1+`i'
}
reghdfe labs_FE_a1 c.Foreign##c.WDI_inst c.Foreign##c.tariff, absorb(`FE') vce(`se')
forval i=0/8 {
	lincom Foreign+2*`i'*c.Foreign#c.tariff, l(90)
	replace forlb1 = r(lb) if _n==1+`i'
	replace forub1 = r(ub) if _n==1+`i'
	replace forest1 = r(estimate) if _n==1+`i'
}
gen n=(_n-1)*2 if _n<9
label var n "Tariffs"
twoway (line forlb n,color(blue) lpattern(dash)) (line forlb1 n,color(red) lpattern(dash)) (line forest n, color(blue)) (line forest1 n, color(red)) (line forub n,color(blue) lpattern(dash)) (line forub1 n,color(red) lpattern(dash)), legend(label(3 "Baseline") label(4 "Controlling for institutions") label(1 "") label(2 "") label(5 "") label(6 "") pos(6) cols(2) size(18pt)) xtitle("Tariff", size(18pt))
graph export "$figures//interaction_by_tariff.pdf", as(pdf) replace

drop n
local FE idi#Var#Hor#datem datem#country_num#Var#Hor
local se cluster datem id4
reghdfe labs_FE_a1 Foreign c.Foreign#c.ka_o if Finance==1, absorb(`FE') vce(`se')
forval i=0/10 {
	lincom Foreign+.2*`i'*c.Foreign#c.ka_o, l(90)
	replace forlb = r(lb) if _n==1+`i'
	replace forub = r(ub) if _n==1+`i'
	replace forest = r(estimate) if _n==1+`i'
}
reghdfe labs_FE_a1 Foreign c.Foreign##c.WDI_inst c.Foreign#c.ka_o if Finance==1, absorb(`FE') vce(`se')
forval i=0/10 {
	lincom Foreign+.2*`i'*c.Foreign#c.ka_o, l(90)
	replace forlb1 = r(lb) if _n==1+`i'
	replace forub1 = r(ub) if _n==1+`i'
	replace forest1 = r(estimate) if _n==1+`i'
}
gen n=(_n-1)*.2 if _n<11
label var n "Capital controls"
twoway (line forlb n,color(blue) lpattern(dash)) (line forlb1 n,color(red) lpattern(dash)) (line forest n, color(blue)) (line forest1 n, color(red)) (line forub n,color(blue) lpattern(dash)) (line forub1 n,color(red) lpattern(dash)), legend(label(3 "Baseline") label(4 "Controlling for institutions") label(1 "") label(2 "") label(5 "") label(6 "") pos(6) cols(2) size(18pt)) xtitle("Capital controls", size(18pt))
graph export "$figures//interaction_by_ka.pdf", as(pdf) replace


****

gen ka_o_dummy = (ka_o<=.1) if ka_o!=.

replace trade_exports = (tradeflow_comtrade_d)/(gdp_d)
replace trade_exports = (absorbtion)/(gdp_d) if country==Headquarter

replace distw_trade_exports = (distw_tradeflow_comtrade_d)/(distw_gdp_d)
replace distw_trade_exports = (distw_absorbtion)/(distw_gdp_d) if country==closest_ctry_distw


*standardize variables
foreach var in distw_distw distw_cultural_distance distw_lingdist_dominant distw_time_overlap distw_r2 distw_trade_exports lingdist_dominant trade_exports trade {
	qui sum `var'
	replace `var' = `var'/r(sd)
}

local FE idi#Var#Hor#datem Var#Hor#datem#country_num
local se cluster datem country_num idi
reghdfe labs_FE_a1 Foreign c.Foreign#c.ka_o_dummy if Finance==1, absorb(`FE') vce(`se')
lincom Foreign + c.Foreign#c.ka_o_dummy

local FE country_num#Var#Hor#datem idi#Var#Hor#datem
local se cluster datem country_num idi

reghdfe labs_FE_a1 Foreign, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_gravity", replace addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%6.0g))
reghdfe labs_FE_a1 Foreign distw_distw, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_2, asterisk(10 5 1) parentheses(stderr) format(%6.0g))
reghdfe labs_FE_a1 Foreign distw_cultural_distance, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_3, asterisk(10 5 1) parentheses(stderr) format(%6.0g))
reghdfe labs_FE_a1 Foreign distw_lingdist_dominant, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_4, asterisk(10 5 1) parentheses(stderr) format(%6.0g))
reghdfe labs_FE_a1 Foreign distw_r2, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_5, asterisk(10 5 1) parentheses(stderr) format(%6.0g))
reghdfe labs_FE_a1 Foreign distw_migration, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_12, asterisk(10 5 1) parentheses(stderr) format(%6.0g))

local FE idi#Var#Hor#datem Var#Hor#datem#country_num
local se cluster country_num idi datem
reghdfe labs_FE_a1 Foreign distw_lingdist_dominant trade_exports, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_6, asterisk(10 5 1) parentheses(stderr) format(%6.0g) )
reghdfe labs_FE_a1 Foreign if Finance==1, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_7, asterisk(10 5 1) parentheses(stderr) format(%6.0g) )
reghdfe labs_FE_a1 Foreign c.Foreign#c.ka_o_dummy if Finance==1, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_8, asterisk(10 5 1) parentheses(stderr) format(%6.0g) )
reghdfe labs_FE_a1 Foreign c.Foreign#c.ka_o_dummy c.Foreign#c.WDI_institutions if Finance==1, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_9, asterisk(10 5 1) parentheses(stderr) format(%6.0g) )

local FE country_num#Var#Hor#datem idi#Var#Hor#datem
local se cluster datem country_num idi
reghdfe labs_FE_a1 Foreign distw_lingdist_dominant lingdist_dominant, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_10, asterisk(10 5 1) parentheses(stderr) format(%6.0g) )
reghdfe labs_FE_a1 Foreign distw_trade_exports trade_exports, absorb(`FE') vce(`se')
regsave using "$temp_data/reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_11, asterisk(10 5 1) parentheses(stderr) format(%6.0g) order(Foreign distw_distw distw_cultural_distance distw_lingdist_dominant distw_time_overlap distw_r2 distw_migration_2000 distw_trade_exports lingdist_dominant trade_exports trade c.Foreign#c.ka_o_dummy c.Foreign#c.WDI_institutions))


/*
local FE idi#Var#Hor#datem datem#country_num#Var#Hor
local se cluster datem country_num idi
ivreghdfe labs_FE_a1 Foreign (trade_exports = gatt rta_type1 rta_type2 rta_type4 rta_type5 rta_type6) distw_distw distw_cultural_distance distw_lingdist_dominant distw_beta, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_10, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
ivreghdfe labs_FE_a1 Foreign (trade_exports = gatt rta_type1 rta_type2 rta_type4 rta_type5 rta_type6) distw_distw distw_cultural_distance distw_lingdist_dominant distw_beta if Finance==1, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_11, asterisk(10 5 1) parentheses(stderr) format(%7.2f) order(Foreign distw_distw distw_cultural_distance distw_lingdist_dominant distw_time_overlap distw_beta distw_trade_exports lingdist_dominant trade_exports trade))
*/

/*
reghdfe labs_FE_a1 Foreign, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", replace addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign distw_distw distw_cultural_distance distw_lingdist_dominant, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_2, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign distw_beta, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_3, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign distw_distw distw_cultural_distance distw_lingdist_dominant  distw_beta, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_4, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign c.Foreign#c.tariff, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_5, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign if Finance==1, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_6, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign c.Foreign#c.ka_o if Finance==1, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_7, asterisk(10 5 1) parentheses(stderr) format(%7.2f) order(Foreign distw_distw distw_cultural_distance distw_lingdist_dominant distw_time_overlap distw_beta c.Foreign#c.tariff c.Foreign#c.ka_o))
reghdfe labs_FE_a1 Foreign c.Foreign#c.ka_o c.Foreign#c.WDI_inst if Finance==1, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_8, asterisk(10 5 1) parentheses(stderr) format(%7.2f) order(Foreign distw_distw distw_cultural_distance distw_lingdist_dominant distw_time_overlap distw_beta c.Foreign#c.tariff c.Foreign#c.ka_o c.Foreign#c.WDI_inst))
*/

/*
reghdfe labs_FE_a1 Foreign, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", replace addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign distw_distw distw_cultural_distance distw_lingdist_dominant, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_4, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign distw_time_overlap, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_3, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign distw_corr_wdi_res, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_2, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
local se cluster datem id4 id3
reghdfe labs_FE_a1 Foreign trade_exports, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_5, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
reghdfe labs_FE_a1 Foreign distw_lingdist_dominant distw_time_overlap distw_corr_wdi_res trade_exports, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "") table(col_6, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
ivreghdfe labs_FE_a1 (trade_exports = gatt rta_type1 rta_type2 rta_type4 rta_type5 rta_type6) Foreign distw_lingdist_dominant distw_time_overlap distw_corr_wdi_res, absorb(`FE') vce(`se')
regsave using "reg_labs_gravity", append addlabel(FE1, "\checkmark", FE2, "\checkmark", FE3, "\checkmark") table(col_7, asterisk(10 5 1) parentheses(stderr) format(%7.2f) order(Foreign distw_distw distw_cultural_distance distw_lingdist_dominant distw_time_overlap distw_corr_wdi_res trade_exports))
*/


/*
local FE idi#datem#Var#Hor country_num#datem#Var#Hor 
local se cluster datem id4 id3
reghdfe labs_FE_a1 c.Foreign##c.distw_time_overlap, absorb(`FE') vce(`se')
reghdfe labs_FE_a1 c.Foreign##c.distw_lingdist_dominant, absorb(`FE') vce(`se')
reghdfe labs_FE_a1 c.Foreign##c.distw_corr_wdi_res, absorb(`FE') vce(`se')
reghdfe labs_FE_a1 c.Foreign##c.trade_exports, absorb(`FE') vce(`se')
reghdfe labs_FE_a1 c.Foreign##c.(distw_time_overlap distw_corr_wdi_res distw_lingdist_dominant trade_exports), absorb(`FE') vce(`se')

reghdfe labs_FE_a1 distw_time_overlap if Foreign==1, absorb(`FE') vce(`se')
reghdfe labs_FE_a1 distw_lingdist_dominant if Foreign==1, absorb(`FE') vce(`se')
reghdfe labs_FE_a1 distw_corr_wdi_res if Foreign==1, absorb(`FE') vce(`se')
reghdfe labs_FE_a1 distw_time_overlap distw_corr_wdi_res distw_lingdist_dominant if Foreign==1, absorb(`FE') vce(`se')
*/



******************************


* Put results in tables

* Multinational
use "$temp_data/reg_labs_mult", clear

* clean the data
drop if var == "restr" | var == "_id" | strpos(var,"_cons")>0

replace var = "$ R^2 $" if var == "r2"

replace var = "Foreign" if var == "Foreign_coef"
replace var = "" if var == "Foreign_stderr"
replace var = "Foreign HQ" if var == "ForeignHQ_coef"
replace var = "" if var == "ForeignHQ_stderr"
replace var = "Local Subsidiary" if var == "LocalSub_coef"
replace var = "" if var == "LocalSub_stderr"

replace var = "Country $ \times $ Date $ \times $ Var. $ \times $ Hor. FE" if var == "FE1"
replace var = "For. $ \times $ Date $ \times $ Var. $ \times $ Hor. FE " if var == "FE2"

label var var "Coefficient"
label var col_1 ""
label var col_2 "Non-Mult."
label var col_3 "Mult."
label var col_4 "Mult."
label var col_5 "Mult."


texsave var col_*  using "$tables/error_reg_labs_mult.tex", ///
	title(Multinational and Non-Multinational Forecasters) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C C) location(H) replace label(tab:error_reg_labs_mult) headerlines("&\multicolumn{5}{c}{$\ln(|Error_{ijt,t}^m|)$}\tabularnewline\cline{2-6} &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}") footnote("\begin{minipage}{1\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:}   The table shows the regression of the log absolute forecast error of current and future CPI and GDP on regressors on different sub-samples. All standard errors are clustered at the country, forecaster and date levels. \end{tabnote} \end{minipage}  ")



* country and institution characteristics
use "$temp_data/reg_labs_cs_FE", clear

* clean the data
drop if var == "restr" | var == "_id" | strpos(var,"_cons")>0

replace var = "$ R^2 $" if var == "r2"

replace var = "Foreign" if var == "Foreign_coef"
replace var = "" if var == "Foreign_stderr"
replace var = "GDP" if var == "GDP_coef"
replace var = "" if var == "GDP_stderr"
replace var = "Future" if var == "future_coef"
replace var = "" if var == "future_stderr"
replace var = "Emerging" if var == "Emerging_coef"
replace var = "" if var == "Emerging_stderr"
replace var = "Month-of-year" if var == "month_coef"
replace var = "" if var == "month_stderr"
replace var = "ln(GDP)" if var == "lgdp_ppp_o_coef"
replace var = "" if var == "lgdp_ppp_o_stderr"
replace var = "Institutions" if var == "WDI_institutions_coef"
replace var = "" if var == "WDI_institutions_stderr"
replace var = "Recession" if var == "rec_coef"
replace var = "" if var == "rec_stderr"
replace var = "VIX" if var == "vix_coef"
replace var = "" if var == "vix_stderr"
replace var = "Emerging" if var == "Emerging_coef"
replace var = "" if var == "Emerging_stderr"

replace var = "Foreign $\times$ GDP" if var == "c.Foreign#c.GDP_coef"
replace var = "" if var == "c.Foreign#c.GDP_stderr"
replace var = "Foreign $\times$ Future" if var == "c.Foreign#c.future_coef"
replace var = "" if var == "c.Foreign#c.future_stderr"
replace var = "Foreign $\times$ Month-of-year" if var == "c.Foreign#c.month_coef"
replace var = "" if var == "c.Foreign#c.month_stderr"
replace var = "Foreign $\times$ ln(GDP)" if var == "c.Foreign#c.lgdp_ppp_o_coef"
replace var = "" if var == "c.Foreign#c.lgdp_ppp_o_stderr"
replace var = "Foreign $\times$ Institutions" if var == "c.Foreign#c.WDI_institutions_coef"
replace var = "" if var == "c.Foreign#c.WDI_institutions_stderr"
replace var = "Foreign $\times$ Recession" if var == "c.Foreign#c.rec_coef"
replace var = "" if var == "c.Foreign#c.rec_stderr"
replace var = "Foreign $\times$ VIX" if var == "c.Foreign#c.vix_coef"
replace var = "" if var == "c.Foreign#c.vix_stderr"
replace var = "Foreign $\times$ Emerging" if var == "c.Foreign#c.Emerging_coef"
replace var = "" if var == "c.Foreign#c.Emerging_stderr"

expand 2 if var == "FE0", gen(dup)
expand 2 if var == "FE1", gen(dup2)

replace var = "Cty. $ \times $ Year FE" if var == "FE0" & dup==0
replace var = "For. $ \times $ Year FE" if var == "FE0" & dup==1
replace var = "Cty $ \times $ Var. $ \times $ Hor. FE" if var == "FE1" & dup2==0
replace var = "For. $ \times $ Var. $ \times $ Hor. FE" if var == "FE1" & dup2==1
drop if var =="FE2"
replace var = "For. $ \times $ Date $ \times $ Var. $ \times $ Hor. FE" if var == "FE3"
replace var = "Cty $ \times $ Date $ \times $ Var. $ \times $ Hor. FE " if var == "FE4"

gen n = _n
replace n = n+1 if n>37
replace n = 38 if n==42
replace n = n+1 if n>39
replace n = 40 if n==44

sort n
drop n dup dup2
order var col_1 col_2 col_3 col_4 col_5 col_6 col_7 col_8

label var var "Coefficient"
label var col_1 ""
label var col_2 ""
label var col_3 ""
label var col_4 ""
label var col_5 ""
label var col_6 ""
label var col_7 ""
label var col_8 ""

texsave var col_1-col_8  using "$tables/error_reg_labs_cs.tex", ///
	title(Variable, Horizon, Time and Country Dependence) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(scriptsize)  align(l C C C C C C C C) location(H) replace label(tab:error_reg_labs_cs) headerlines("&\multicolumn{8}{c}{$\ln(|Error_{ijt,t}^m|)$}\tabularnewline\cline{2-9} &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)}&{(8)}") footnote("\begin{minipage}{1\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:}   The table shows the regression of the log absolute forecast error of current and future CPI and GDP on regressors with different fixed-effects specifications. All standard errors are clustered at the country, forecaster and date levels. \end{tabnote} \end{minipage}  ")


* country and institution characteristics, variable by variable (appendix)
use "$temp_data/reg_labs_cs_ind_FE", clear

* clean the data
drop if var == "restr" | var == "_id" | strpos(var,"_cons")>0

replace var = "$ R^2 $" if var == "r2"

replace var = "Foreign" if var == "Foreign_coef"
replace var = "" if var == "Foreign_stderr"
replace var = "Foreign $\times$ GDP" if var == "c.Foreign#c.GDP_coef"
replace var = "" if var == "c.Foreign#c.GDP_stderr"
replace var = "Foreign $\times$ Future" if var == "c.Foreign#c.future_coef"
replace var = "" if var == "c.Foreign#c.future_stderr"
replace var = "Foreign $\times$ Month-of-year" if var == "c.Foreign#c.month_coef"
replace var = "" if var == "c.Foreign#c.month_stderr"
replace var = "Foreign $\times$ ln(GDP)" if var == "c.Foreign#c.lgdp_ppp_o_coef"
replace var = "" if var == "c.Foreign#c.lgdp_ppp_o_stderr"
replace var = "Foreign $\times$ Institutions" if var == "c.Foreign#c.WDI_institutions_coef"
replace var = "" if var == "c.Foreign#c.WDI_institutions_stderr"
replace var = "Foreign $\times$ Recession" if var == "c.Foreign#c.rec_coef"
replace var = "" if var == "c.Foreign#c.rec_stderr"
replace var = "Foreign $\times$ VIX" if var == "c.Foreign#c.vix_coef"
replace var = "" if var == "c.Foreign#c.vix_stderr"
replace var = "Foreign $\times$ Emerging" if var == "c.Foreign#c.Emerging_coef"
replace var = "" if var == "c.Foreign#c.Emerging_stderr"


replace var = "Cty $ \times $ Date $ \times $ Var. $ \times $ Hor. FE" if var == "FE1"
replace var = "For. $ \times $ Date $ \times $ Var. $ \times $ Hor. FE " if var == "FE2"


label var var "Coefficient"
label var col_1 ""
label var col_2 ""
label var col_3 ""
label var col_4 ""
label var col_5 ""
label var col_6 ""
label var col_7 ""
label var col_8 ""


texsave var col_*  using "$tables/error_reg_labs_cs_ind.tex", ///
	title(Variable, Horizon, Time and Country Dependence - Separate Regressions) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C C C C C) location(H) replace label(tab:error_reg_labs_cs_ind) headerlines("&\multicolumn{8}{c}{$\ln(|Error_{ijt,t}^m|)$}\tabularnewline\cline{2-9} &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)}&{(8)}") footnote(		"\begin{minipage}{1\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:} The table shows the regression of the log absolute forecast error of current and future CPI and GDP on different regressors. All standard errors are clustered at the country, forecaster and date levels. \end{tabnote} \end{minipage}  ")


* Gravity
use "$temp_data/reg_labs_gravity", clear

* clean the data
drop if var == "restr" | var == "_id" | strpos(var,"_cons")>0

replace var = "$ R^2 $" if var == "r2"

replace var = "Foreign" if var == "Foreign_coef"
replace var = "" if var == "Foreign_stderr"

replace var = "Time overlap" if var == "distw_time_overlap_coef"
replace var = "" if var == "distw_time_overlap_stderr"
replace var = "BC correlation" if var == "distw_corr_wdi_res_coef"
replace var = "" if var == "distw_corr_wdi_res_stderr"
replace var = "Physical dist." if var == "distw_distw_coef"
replace var = "" if var == "distw_distw_stderr"
replace var = "Cultural dist." if var == "distw_cultural_distance_coef"
replace var = "" if var == "distw_cultural_distance_stderr"
replace var = "Linguistic dist." if var == "distw_lingdist_dominant_coef"
replace var = "" if var == "distw_lingdist_dominant_stderr"
replace var = "BC comovement" if var == "distw_r2_coef"
replace var = "" if var == "distw_r2_stderr"
replace var = "Linguistic dist." if var == "lingdist_dominant_coef"
replace var = "" if var == "lingdist_dominant_stderr"
replace var = "Trade" if var == "trade_exports_coef"
replace var = "" if var == "trade_exports_stderr"
replace var = "Trade" if var == "distw_trade_exports_coef"
replace var = "" if var == "distw_trade_exports_stderr"
replace var = "Migration" if var == "distw_migration_2000_coef"
replace var = "" if var == "distw_migration_2000_stderr"

replace var = "Foreign $\times$ Tariffs" if var == "c.Foreign#c.tariff_coef"
replace var = "" if var == "c.Foreign#c.tariff_stderr"
replace var = "Foreign $\times$ Low Cap. Controls" if var == "c.Foreign#c.ka_o_dummy_coef"
replace var = "" if var == "c.Foreign#c.ka_o_dummy_stderr"
replace var = "Foreign $\times$ Institutions" if var == "c.Foreign#c.WDI_institutions_coef"
replace var = "" if var == "c.Foreign#c.WDI_institutions_stderr"

replace var = "Cty $ \times $ Date $ \times $ Var. $ \times $ Hor. FE" if var == "FE1"
replace var = "For. $ \times $ Date $ \times $ Var. $ \times $ Hor. FE " if var == "FE2"
drop if var == "FE3"

label var var "Coefficient"
label var col_1 ""
label var col_2 ""
label var col_3 ""
label var col_4 ""
label var col_5 ""
label var col_6 ""
label var col_7 "Finance"
label var col_8 "Finance"
label var col_9 "Finance"
label var col_10 ""
label var col_11 ""
label var col_12 ""

gen col_13 = .
gen col_14 = .

order var col_1-col_6 col_12 col_13 col_7-col_9 col_14 col_10-col_11

gen n = _n
set obs `=_N+4'
replace n = 2.1 if _n==27
replace n = 2.2 if _n==28
replace n = 14.1 if _n==29
replace n = 14.2 if _n==30
replace var = " \textbf{\emph{W.r.t. closest subs.:}} " if _n == 27
replace var = " \textbf{\emph{W.r.t. headquarters:}} " if _n == 29
drop if _n == 28 | _n == 30
sort n

texsave var col_*  using "$tables/error_reg_labs_gravity.tex", ///
	title(The Geography of Information) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C C C C m{0.005\textwidth} C C C m{0.005\textwidth} C C) location(H) replace label(tab:error_reg_labs_gravity) headerlines("&\multicolumn{14}{c}{$\ln(|Error_{ijt,t}^m|)$}\tabularnewline\cline{2-15} \tabularnewline  \cline{2-8} \cline{10-12} \cline{14-15}\tabularnewline  &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)}&&{(8)}&{(9)}&{(10)}&&{(11)}&{(12)}") footnote(		"\begin{minipage}{1\linewidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:}   The table shows the regression of the log absolute forecast error on regressors accounting for the geography of information. All standard errors are clustered at the country, forecaster and date levels. \end{tabnote} \end{minipage}  ")

/*
texsave var col_*  using "$tables/error_reg_labs_gravity.tex", ///
	title(The Geography of Information) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(footnotesize)  align(l C C C C m{0.005\textwidth} C C C C) location(H) replace label(tab:error_reg_labs_gravity) headerlines("&\multicolumn{9}{c}{$\ln(|Error_{ijt,t}^m|)$}\tabularnewline\cline{2-10} \tabularnewline &\multicolumn{4}{c}{Barriers}&&\multicolumn{4}{c}{Incentives} \tabularnewline \cline{2-5} \cline{7-10}\tabularnewline  &{(1)}&{(2)}&{(3)}&{(4)}&&{(5)}&{(6)}&{(7)}&{(8)}") footnote(		"\begin{minipage}{1\linewidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:}   The table shows the regression of the log absolute forecast error of current and future CPI and GDP on regressors accounting for the geography of information. All standard errors are clustered at the country-closest subsidiary country pair and date levels. \end{tabnote} \end{minipage}  ")
*/

***********************
**** cross-section ****
***********************

**** FE regressions ****

use $temp_data/mg_FE_reg_cty_month, clear
gen var = "gdp"
gen b_FR = b_FR_gdp
gen N_FR = N_FR_gdp
gen sd_FR = sd_FR_gdp

append using $temp_data/mg_FE_reg_cty_month
replace var = "cpi" if var == ""
replace b_FR = b_FR_cpi if var == "cpi"
replace N_FR = N_FR_cpi if var == "cpi"
replace sd_FR = sd_FR_cpi if var == "cpi"

sort country_num
merge m:1 country_num using $stempf/cty_cs, nogen
gen l_sd_gdp = log(sd_gdp)
gen l_sd_cpi = log(sd_cpi)
gen l_rmse_gdp = log(rmse_gdp)
gen l_rmse_cpi = log(rmse_cpi)

gen l_sd = l_sd_gdp if var=="gdp"
replace l_sd = l_sd_cpi if var=="cpi"
gen l_rmse = l_rmse_gdp if var=="gdp"
replace l_rmse = l_rmse_cpi if var=="cpi"

gen GDP = (var=="gdp")
replace GDP =. if var!="gdp" & var!="cpi"

gen CPI = 1-GDP

encode var, gen(Var)

gen weight = 1/sd_FR_gdp if var == "gdp"
replace weight = 1/sd_FR_cpi if var == "cpi"


* clustering
local se cluster country_num
* fixed effects
local FE country_num#Var month#Var


reghdfe b_FR Foreign month GDP [aweight=weight], noabsorb vce(`se')
regsave using "$temp_data/FE_reg_mg", replace  ///
	addlabel(FE1, "", FE2, "") table(col_1, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

local FE Var#month
reghdfe b_FR Foreign WDI Emerging lgdp_ppp_o [aweight=weight], absorb(`FE') vce(`se')
regsave using "$temp_data/FE_reg_mg", append  ///
	addlabel(FE1, "", FE2, "\checkmark") table(col_2, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	
	reghdfe b_FR Foreign c.Foreign#c.month c.Foreign#c.GDP [aweight=weight], absorb(`FE') vce(`se')
regsave using "$temp_data/FE_reg_mg", append  ///
	addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_3, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

local FE country_num#Var month#Var
reghdfe b_FR Foreign c.Foreign#c.WDI c.Foreign#c.Emerging c.Foreign#c.lgdp_ppp_o [aweight=weight], absorb(`FE') vce(`se')
regsave using "$temp_data/FE_reg_mg", append  ///
	addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_4, asterisk(10 5 1) parentheses(stderr) format(%7.2f))
	
local FE country_num#Var month#Var
reghdfe b_FR Foreign c.Foreign#c.GDP c.Foreign#c.month c.Foreign#c.WDI c.Foreign#c.Emerging c.Foreign#c.lgdp_ppp_o [aweight=weight], absorb(`FE') vce(`se')
regsave using "$temp_data/FE_reg_mg", append  ///
	addlabel(FE1, "\checkmark", FE2, "\checkmark") table(col_5, asterisk(10 5 1) parentheses(stderr) format(%7.2f) order(Foreign GDP month WDI_institutions Emerging lgdp_ppp_o c.Foreign#c.GDP  c.Foreign#c.month c.Foreign#c.WDI_institutions  c.Foreign#c.Emerging  c.Foreign#c.lgdp_ppp_o))
	
**** disagreement *****

use $temp_data/disag_mg_cty_month, clear
gen var = "gdp"
gen b_FR = b_FR_gdp
gen N_FR = N_FR_gdp
gen sd_FR = sd_FR_gdp

append using $temp_data/disag_mg_cty_month
replace var = "cpi" if var == ""
replace b_FR = b_FR_cpi if var == "cpi"
replace N_FR = N_FR_cpi if var == "cpi"
replace sd_FR = sd_FR_cpi if var == "cpi"

sort country_num
merge m:1 country_num using $stempf/cty_cs, nogen
gen l_sd_gdp = log(sd_gdp)
gen l_sd_cpi = log(sd_cpi)
gen l_rmse_gdp = log(rmse_gdp)
gen l_rmse_cpi = log(rmse_cpi)

gen l_sd = l_sd_gdp if var=="gdp"
replace l_sd = l_sd_cpi if var=="cpi"
gen l_rmse = l_rmse_gdp if var=="gdp"
replace l_rmse = l_rmse_cpi if var=="cpi"

gen GDP = (var=="gdp")
replace GDP =. if var!="gdp" & var!="cpi"

gen CPI = 1-GDP

gen weight = 1/sd_FR_gdp if var == "gdp"
replace weight = 1/sd_FR_cpi if var == "cpi"

encode var, gen(Var)

* clustering
local se cluster country_num

reghdfe b_FR month GDP [aweight=weight], absorb(country_num) vce(`se')
regsave using "$temp_data/FE_reg_mg", append  ///
	addlabel(FE1, "", FE2, "") table(col_6, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

local FE country_num#Var
reghdfe b_FR month [aweight=weight], absorb(`FE') vce(`se')
regsave using "$temp_data/FE_reg_mg", append  ///
	addlabel(FE1, "\checkmark", FE2, "") table(col_7, asterisk(10 5 1) parentheses(stderr) format(%7.2f))

local FE Var#month
reghdfe b_FR WDI Emerging lgdp_ppp_o [aweight=weight], absorb(`FE') vce(`se')
regsave using "$temp_data/FE_reg_mg", append  ///
	addlabel(FE1, "", FE2, "\checkmark") table(col_8, asterisk(10 5 1) parentheses(stderr) format(%7.2f) order(Foreign GDP month WDI_institutions Emerging lgdp_ppp_o c.Foreign#c.GDP  c.Foreign#c.month c.Foreign#c.WDI_institutions  c.Foreign#c.Emerging  c.Foreign#c.lgdp_ppp_o))


	
* country and institution characteristics
use "$temp_data/FE_reg_mg", clear

* clean the data
drop if var == "restr" | var == "_id" | strpos(var,"_cons")>0

replace var = "$ R^2 $" if var == "r2"


replace var = "Foreign" if var == "Foreign_coef"
replace var = "" if var == "Foreign_stderr"

replace var = "GDP" if var == "GDP_coef"
replace var = "" if var == "GDP_stderr"
replace var = "Emerging" if var == "Emerging_coef"
replace var = "" if var == "Emerging_stderr"
replace var = "Month of year" if var == "month_coef"
replace var = "" if var == "month_stderr"
replace var = "ln(GDP)" if var == "lgdp_ppp_o_coef"
replace var = "" if var == "lgdp_ppp_o_stderr"
replace var = "Institutions" if var == "WDI_institutions_coef"
replace var = "" if var == "WDI_institutions_stderr"

replace var = "Foreign $\times$ GDP" if var == "c.Foreign#c.GDP_coef"
replace var = "" if var == "c.Foreign#c.GDP_stderr"
replace var = "Foreign $\times$ future" if var == "c.Foreign#c.future_coef"
replace var = "" if var == "c.Foreign#c.future_stderr"
replace var = "Foreign $\times$ Emerging" if var == "c.Foreign#c.Emerging_coef"
replace var = "" if var == "c.Foreign#c.Emerging_stderr"
replace var = "Foreign $\times$ Month of year" if var == "c.Foreign#c.month_coef"
replace var = "" if var == "c.Foreign#c.month_stderr"
replace var = "Foreign $\times$ ln(GDP)" if var == "c.Foreign#c.lgdp_ppp_o_coef"
replace var = "" if var == "c.Foreign#c.lgdp_ppp_o_stderr"
replace var = "Foreign $\times$ Institutions" if var == "c.Foreign#c.WDI_institutions_coef"
replace var = "" if var == "c.Foreign#c.WDI_institutions_stderr"
replace var = "Foreign $\times$ Emerging" if var == "c.Foreign#c.Emerging_coef"
replace var = "" if var == "c.Foreign#c.Emerging_stderr"

replace var = "Country $ \times $ Variable FE" if var == "FE1"
replace var = "Month-of-year $ \times $ Variable FE" if var == "FE2"


label var var "Coefficient"
label var col_1 ""
label var col_2 ""
label var col_3 ""
label var col_4 ""
label var col_5 ""
label var col_6 ""
label var col_7 ""
label var col_8 ""
gen col_9=.
label var col_9 ""

texsave var col_1-col_5 col_9 col_6-col_8 using "$tables/FE_reg_mg.tex", ///
	title(Variable, Horizon, and Country Dependence - $\beta$ coefficients) varlabels nofix hlines(0) headersep(0pt) ///
frag  size(scriptsize)  align(l C C C C C m{0.01\textwidth} C C C) location(H) replace label(tab:FE_reg_mg) headerlines("&\multicolumn{5}{c}{$\beta^{FE}$}&&\multicolumn{3}{c}{$\beta^{Dis}$}\tabularnewline\cline{2-6} \cline{8-10} &{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&&{(6)}&{(7)}&{(8)}") footnote(		"\begin{minipage}{1\textwidth} \vspace{-10pt} \begin{tabnote} \textit{Notes:}   The table shows the regression of $\beta^{FE}$ and $\beta^{Dis}$ on regressors with different fixed-effects specifications. All standard errors are clustered on the country level. \end{tabnote} \end{minipage}  ")




