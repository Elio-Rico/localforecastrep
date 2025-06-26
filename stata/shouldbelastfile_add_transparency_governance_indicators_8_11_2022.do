********************************************************************************
*
*				ADD GOVERNANCE AND WORLD DEVELOPMENT INDICATORS
*
********************************************************************************

/*

The file uses wbopendata to download several world bank indicators

*/

* PRELIMINARIES
******************




clear all
set more off

/*
use "C:\Users\Kbenhima\Dropbox\Research\Current_projects\Imperfect_information\FNS project\4Foreign vs local expectations\Navid's File\Company Trees\data_final_newVintage_2.dta", clear
cd "C:\Users\Kbenhima\Dropbox\Research\Current_projects\Imperfect_information\FNS project\4Foreign vs local expectations\EmpiricalResults\Kenza"

global fol "C:\Users\Kbenhima\Dropbox\Research\Current_projects\Imperfect_information\FNS project\4Foreign vs local expectations\EmpiricalResults\Kenza\LocalProjections\"
global latex "C:\Users\Kbenhima\Dropbox\Research\Current_projects\Imperfect_information\FNS project\4Foreign vs local expectations\Writing\Paper\Sections\"
global tables "C:\Users\Kbenhima\Dropbox\Research\Current_projects\Imperfect_information\FNS project\4Foreign vs local expectations\Writing\Paper\Tables\"
global figures "C:\Users\Kbenhima\Dropbox\Research\Current_projects\Imperfect_information\FNS project\4Foreign vs local expectations\Writing\Paper\Figures\"
*/



* prepare governance indicators:


wbopendata , indicator(IQ.SCI.MTHD;IQ.SCI.PRDC;IQ.SCI.SRCE;IQ.SCI.OVRL;IQ.SPI.OVRL;IQ.SPI.PIL1;IQ.SPI.PIL2;IQ.SPI.PIL3;IQ.SPI.PIL4;IQ.SPI.PIL5;IQ.CPA.HRES.XQ;IQ.CPA.BREG.XQ;IQ.CPA.DEBT.XQ;IQ.CPA.ECON.XQ;IQ.CPA.REVN.XQ;IQ.CPA.PRES.XQ;IQ.CPA.FINS.XQ;IQ.CPA.FISP.XQ;IQ.CPA.GNDR.XQ;IQ.CPA.MACR.XQ;IQ.CPA.SOCI.XQ;IQ.CPA.ENVR.XQ;IQ.CPA.PROP.XQ;IQ.CPA.PUBS.XQ;IQ.CPA.FINQ.XQ;IQ.CPA.PADM.XQ;IQ.CPA.PROT.XQ;IQ.CPA.STRC.XQ;IQ.CPA.TRAD.XQ;IQ.CPA.TRAN.XQ;CC.EST;GE.EST;PV.EST;RQ.EST;RL.EST;VA.EST) clear long ///
country(ARG;AUT;BEL;BRA;BGR;CAN;CHL;CHN;COL;HRV;CZE;DNK;EST;FIN;FRA;DEU;GRC;HUN;IND;IDN;IRL;ISR;ITA;JPN;LVA;LTU;MYS;MEX;NLD;NZL;NGA;NOR;PER;PHL;POL;PRT;ROU;RUS;SAU;SVK;SVN;ZAF;ESP;SWE;CHE;THA;TUR;GBR;USA;VEN;KOR)



* need to do some name changes:
replace countryname = "South Korea" if countryname == "Korea, Rep"
replace countryname = "Venezuela" if countryname == "Venezuela, RB"
replace countryname = "Russia" if countryname == "Russian Federation"
replace countryname = "Slovakia" if countryname == "Slovak Republic"



drop region regionname adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename

rename countryname country

save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_output/world_bank_data_yearly.dta", replace


* merge with original dataset:

use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_2.dta", clear


merge m:1 year country using "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_output/world_bank_data_yearly.dta"


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




save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", replace



* add data about VIX
***********************

use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Markets Risk Measure/VIX_History.dta", clear

keep close date_m 

collapse (mean) vix = close (sd) sd_vix = close, by(date_m)

rename date_m datem

save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Markets Risk Measure/VIX_History_merge.dta", replace


use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", clear


merge m:1 datem using "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Markets Risk Measure/VIX_History_merge.dta"
drop if _merge == 2
drop _merge

save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", replace


* transparancey 
***********************


wbopendata , indicator(IQ.CPA.TRAN.XQ) clear long ///
country(ARG;AUT;BEL;BRA;BGR;CAN;CHL;CHN;COL;HRV;CZE;DNK;EST;FIN;FRA;DEU;GRC;HUN;IND;IDN;IRL;ISR;ITA;JPN;LVA;LTU;MYS;MEX;NLD;NZL;NGA;NOR;PER;PHL;POL;PRT;ROU;RUS;SAU;SVK;SVN;ZAF;ESP;SWE;CHE;THA;TUR;GBR;USA;VEN;KOR)



* need to do some name changes:
replace countryname = "South Korea" if countryname == "Korea, Rep"
replace countryname = "Venezuela" if countryname == "Venezuela, RB"
replace countryname = "Russia" if countryname == "Russian Federation"
replace countryname = "Slovakia" if countryname == "Slovak Republic"



drop region regionname adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename

rename countryname country

label var iq_cpa_tran_xq "CPIA transparency, accountability, and corruption in the public sector rating (1=low to 6=high)"

save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_output/world_bank_data_yearly_transparency.dta", replace


* merge with original dataset:

use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", clear


merge m:1 year country using "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_output/world_bank_data_yearly_transparency.dta"
drop if _merge == 2
drop _merge

save  "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", replace



* add two more measures from world bank:


wbopendata , indicator(IC.BUS.DISC.XQ;IQ.CPA.BREG.XQ) clear long ///
country(ARG;AUT;BEL;BRA;BGR;CAN;CHL;CHN;COL;HRV;CZE;DNK;EST;FIN;FRA;DEU;GRC;HUN;IND;IDN;IRL;ISR;ITA;JPN;LVA;LTU;MYS;MEX;NLD;NZL;NGA;NOR;PER;PHL;POL;PRT;ROU;RUS;SAU;SVK;SVN;ZAF;ESP;SWE;CHE;THA;TUR;GBR;USA;VEN;KOR)



* need to do some name changes:
replace countryname = "South Korea" if countryname == "Korea, Rep"
replace countryname = "Venezuela" if countryname == "Venezuela, RB"
replace countryname = "Russia" if countryname == "Russian Federation"
replace countryname = "Slovakia" if countryname == "Slovak Republic"



drop region regionname adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename

rename countryname country

label var ic_bus_disc_xq "Business extent of disclosure index (0 = less disclosure to 10 = more disclosure)"
label var iq_cpa_breg_xq "CPIA business regulatory environment rating (1= low to 6 = high)"


save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_output/world_bank_data_yearly_transparency2.dta", replace


use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", clear


merge m:1 year country using "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_output/world_bank_data_yearly_transparency2.dta"
drop if _merge == 2
drop _merge

save  "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", replace


* ADD STOCK MARKET DATA
******************************
******************************
******************************



* stock market indices - data from navid

use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Markets Risk Measure/Market indices/Per country/1. Final_indices.dta", clear


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


save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Markets Risk Measure/Market indices/Per country/indexlong.dta", replace





* merge
use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", clear

cap drop country_merge
g country_merge = lower(country)
replace country_merge = subinstr(country_merge, " ","",.)

merge m:1 datem country_merge using "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Markets Risk Measure/Market indices/Per country/indexlong.dta"

drop if _merge == 2

drop _merge

save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", replace



* MSCI DATA - data from margaret

local sheets "argentina	australia	austria	belgium	brazil	bulgaria	canada	chile	china	colombia	croatia	czechrepublic	denmark	estonia	finland	france	germany	greece	hungary	india	indonesia	ireland	israel	italy	japan	koreasouth	latvia	lithuania	malaysia	mexico	netherlands	newzealand	nigeria	norway	peru	philippines	poland	portugal	romania	russianfederation	saudiarabia	slovakia	slovenia	southafrica	spain	sweden	switzerland	thailand	turkey	unitedkingdom	unitedstates"



foreach sheet of local sheets {
	
	
	import excel "/Users/ebollige/Dropbox/3_PhD/Projects/EPFR_consensus/MSCIdat/equity_indices_clean.xlsx", sheet(`sheet')  clear
	
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
	
	save "/Users/ebollige/Dropbox/3_PhD/Projects/EPFR_consensus/EPFRdat/bin/`sheet'_msci_temp.dta", replace
	
	
}




use "/Users/ebollige/Dropbox/3_PhD/Projects/EPFR_consensus/EPFRdat/bin/argentina_msci_temp.dta", clear

local sheets "australia	austria	belgium	brazil	bulgaria	canada	chile	china	colombia	croatia	czechrepublic	denmark	estonia	finland	france	germany	greece	hungary	india	indonesia	ireland	israel	italy	japan	koreasouth	latvia	lithuania	malaysia	mexico	netherlands	newzealand	nigeria	norway	peru	philippines	poland	portugal	romania	russianfederation	saudiarabia	slovakia	slovenia	southafrica	spain	sweden	switzerland	thailand	turkey	unitedkingdom	unitedstates"


foreach sheet of local sheets {
	
	disp("`sheet'")
	
	append using "/Users/ebollige/Dropbox/3_PhD/Projects/EPFR_consensus/EPFRdat/bin/`sheet'_msci_temp.dta"

}


*use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Markets Risk Measure/Market indices/msci_temp_all.dta", clear

cap drop country_merge
g country_merge = country

drop country
save  "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Markets Risk Measure/Market indices/msci_temp_all.dta", replace




use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", clear

cap drop country_merge
g country_merge = lower(country)
replace country_merge = subinstr(country_merge, " ","",.)

merge m:1 datem country_merge using "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Markets Risk Measure/Market indices/msci_temp_all.dta"

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



save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", replace






/*
use "/Users/ebollige/Dropbox/3_PhD/Projects/EPFR_consensus/EPFRdat/EPFR_CONSENSUS_LONG_MONTHLY.dta", clear


merge m:1 country datem using "/Users/ebollige/Dropbox/3_PhD/Projects/EPFR_consensus/EPFRdat/bin/msci_temp_all.dta"


drop if _merge == 2
drop _merge


save "/Users/ebollige/Dropbox/3_PhD/Projects/EPFR_consensus/EPFRdat/EPFR_CONSENSUS_LONG_MONTHLY.dta", replace









/*


* add data about FDI:
**********************

* perpare data

import excel "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_input/DEJ2019-FDIdatabase.xlsx", clear firstrow

rename Economy_ISO countrycode
rename Year year
drop Economy Investment_from

save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_input/DEJ2019-FDIdatabase.dta", replace



* get common countryocde country variables - we just want the actual countrynames for matching:
use  "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", clear
keep countrycode country
collapse (last) countrycode , by(country)

save  "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/country_iso.dta", replace

rename countrycode Investment_from_ISO
rename country Headquarters
save  "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/country_iso2.dta", replace


use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_input/DEJ2019-FDIdatabase.dta", clear

merge m:1 countrycode using "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/country_iso.dta"
drop _merge

merge m:1 Investment_from_ISO using "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/country_iso2.dta"
drop _merge

drop if country == ""

label var Inward_FDI  "Inward_FDI (investment from country is headquarter)"
label var Inward_FDI_SPEs "Inward_FDI_SPEs (investment from country is headquarter)"
label var Inward_FDI_NonSPEs "Inward_FDI_NonSPEs (investment from country is headquarter)"
label var Inward_FDI_NonSPEs_UIE "Inward_FDI_NonSPEs_UIE (investment from country is headquarter)"
label var Inward_FDI_confidential "Inward_FDI_confidential (investment from country is headquarter)"
label var Inward_FDI_source "Inward_FDI_source (investment from country is headquarter)"
label var SPE_adjustment "SPE_adjustment (investment from country is headquarter)"
label var UIE_adjustment "UIE_adjustment (investment from country is headquarter)"

drop countrycode

drop if Headquarters == ""

save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_input/DEJ2019-FDIdatabase.dta", replace


* now, ready for merge
use  "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", clear

drop if  country_num == . &   institution == "" & id == .

merge m:1 year country Headquarters using "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_input/DEJ2019-FDIdatabase.dta"
drop if _merge == 2


drop _merge

save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", replace



*use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_input/DEJ2019-FDIdatabase.dta", clear

* add data about FPI:
**********************
use  "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/country_iso2.dta", clear
rename Investment_from_ISO Investor

save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/country_iso3.dta", replace

use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_input/Restated_Bilateral_External_Portfolios.dta", clear

rename Year year

* same here, we need similar countrynames for matching. Headquarters is equal to the investor, country is equal to issuer
rename Issuer countrycode

merge m:1 countrycode using "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/country_iso.dta"
drop _merge


merge m:1 Investor using "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/country_iso3.dta"
drop if _merge == 2

drop if Headquarters == ""
drop if country == ""

drop _merge


* we have several asset classes, hence, we have another "long" dimension. We need to cerate specific variables for each catogry of asset class:
levelsof Asset_Class_Code, local(levels) 


foreach l of local levels {
	
	
	preserve
	
	drop if Asset_Class_Code != "`l'"
	
	
	if Asset_Class_Code == "B"{
		rename Position_Residency B_Position_Residency
		rename Restatement_TH_Only B_Restatement_TH_Only
		rename Restatement_Full  B_Restatement_Full
		rename Restatement_Ex_Domestic B_Restatement_Ex_Domestic 
		rename Restatement_Sales B_Restatement_Sales
		rename Restatement_Sales_Ex_Domestic  B_Restatement_Sales_Ex_Dom
		rename Estimated_Common_Equity  B_Estimated_Common_Equity
		rename Methodology B_Methodology
	}
	
			
	if Asset_Class_Code == "BC"{
		rename Position_Residency BC_Position_Residency
		rename Restatement_TH_Only BC_Restatement_TH_Only
		rename Restatement_Full  BC_Restatement_Full
		rename Restatement_Ex_Domestic BC_Restatement_Ex_Domestic 
		rename Restatement_Sales BC_Restatement_Sales
		rename Restatement_Sales_Ex_Domestic  BC_Restatement_Sales_Ex_Dom
		rename Estimated_Common_Equity  BC_Estimated_Common_Equity
		rename Methodology BC_Methodology
	}
	
	
	
			
	if Asset_Class_Code == "BG"{
		rename Position_Residency BG_Position_Residency
		rename Restatement_TH_Only BG_Restatement_TH_Only
		rename Restatement_Full  BG_Restatement_Full
		rename Restatement_Ex_Domestic BG_Restatement_Ex_Domestic 
		rename Restatement_Sales BG_Restatement_Sales
		rename Restatement_Sales_Ex_Domestic  BG_Restatement_Sales_Ex_Dom
		rename Estimated_Common_Equity  BG_Estimated_Common_Equity
		rename Methodology BG_Methodology
	}
	
	
			
	if Asset_Class_Code == "BSF"{
		rename Position_Residency BSF_Position_Residency
		rename Restatement_TH_Only BSF_Restatement_TH_Only
		rename Restatement_Full  BSF_Restatement_Full
		rename Restatement_Ex_Domestic BSF_Restatement_Ex_Domestic 
		rename Restatement_Sales BSF_Restatement_Sales
		rename Restatement_Sales_Ex_Domestic  BSF_Restatement_Sales_Ex_Dom
		rename Estimated_Common_Equity  BSF_Estimated_Common_Equity
		rename Methodology BSF_Methodology
	}
	
	
			if Asset_Class_Code == "E"{
		rename Position_Residency E_Position_Residency
		rename Restatement_TH_Only E_Restatement_TH_Only
		rename Restatement_Full  E_Restatement_Full
		rename Restatement_Ex_Domestic E_Restatement_Ex_Domestic 
		rename Restatement_Sales E_Restatement_Sales
		rename Restatement_Sales_Ex_Domestic  E_Restatement_Sales_Ex_Dom
		rename Estimated_Common_Equity  E_Estimated_Common_Equity
		rename Methodology E_Methodology
	}

			if Asset_Class_Code == "EF"{
		rename Position_Residency EF_Position_Residency
		rename Restatement_TH_Only EF_Restatement_TH_Only
		rename Restatement_Full  EF_Restatement_Full
		rename Restatement_Ex_Domestic EF_Restatement_Ex_Domestic 
		rename Restatement_Sales EF_Restatement_Sales
		rename Restatement_Sales_Ex_Domestic  EF_Restatement_Sales_Ex_Dom
		rename Estimated_Common_Equity  EF_Estimated_Common_Equity
		rename Methodology EF_Methodology
	}
	
	
	drop Asset_Class
	drop Asset_Class_Code
	drop Investor_Name
	drop Investor
	drop Issuer_Name
	
	
	save "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_input/Restated_Bilateral_External_Portfolios_`l'.dta", replace
	
	
	
	restore
	
}













/*

use  "/Users/ebollige/Dropbox/4Foreign vs local expectations/Navid's File/Company Trees/data_final_newVintage_3.dta", clear


use "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_input/Restated_Bilateral_External_Portfolios_B.dta", clear
 
 duplicates report year country Headquarters
 
 
 
foreach data in "B" "BC""BG"  "BSF" "E" "EF" {
	
		
	merge m:1 year country Headquarters using "/Users/ebollige/Dropbox/4Foreign vs local expectations/Data/data_input/Restated_Bilateral_External_Portfolios_`data'.dta"
	drop _merge

	
	
}


