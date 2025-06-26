
global gravity "C:\Users\kbenhima\Dropbox\Research\Current_projects\Imperfect_information\FNS project\4Foreign vs local expectations\Data\Gravity Data\"
global data "C:\Users\kbenhima\Dropbox\Research\Current_projects\Imperfect_information\FNS project\4Foreign vs local expectations\Data\data_output\"
global path "C:\Users\kbenhima\Dropbox\Research\Current_projects\Imperfect_information\FNS project\4Foreign vs local expectations\Data\stata\"
global navid "C:\Users\kbenhima\Dropbox\Research\Current_projects\Imperfect_information\FNS project\4Foreign vs local expectations\Navid's File\"

use "$navid/Company Trees/data_final_newVintage_2_toMergeGravity.dta", clear
gen subsidiaryCountry0 = Headquarters
save "$navid/Company Trees/data_final_newVintage_2_toMergeGravity_.dta", replace

use "C:\Users\Kbenhima\Dropbox\Research\Current_projects\Imperfect_information\FNS project\4Foreign vs local expectations\Navid's File\Company Trees\data_final_newVintage_3.dta", clear

keep country country_num institution id year date dateq datem month subsidiary* Headquarters

*********************************************************************************
* MERGE GRAVITY DATABASE

merge m:1 year country Headquarters using "$gravity/gravity_to_merge.dta"
drop if _merge == 2

* a few observations are not matched because missing headquarter (around 3000). the other 3000 observations are observations after 2019
*br if _merge == 1 & Headquarters != ""

drop _merge

order country country_num institution id date datem month

keep subsidiaryCountry* year country country_num date datem dateq month institution id Headquarters dist*

gen subsidiaryCountry0 = Headquarters

save "$path/temp_gravity.dta", replace

forval x = 0(1)121{
	
	*preserve
	
	* we match data from the gravity base to the subsidiaries in consensus economics data base.
	* for this, we define the headquarter in the gravity database to dynamically be equal to the
	* name of subsidiarycountryX . Then, we match the distance measures for this country 
	
	*local x = 2
	use "$gravity/gravity_to_merge.dta", clear
	
	keep year country Headquarters dist distw distcap distwces dist_source
	
	rename dist ABdist`x' 
	rename distw CDdistw`x' 
	rename distcap DEdistcap`x' 
	rename distwces FGdistwces`x' 
	rename dist_source HIdist_source`x'
	
	rename Headquarters subsidiaryCountry`x'
	
	save "$gravity/gravity_temp.dta", replace
	
	use "$navid/Company Trees/data_final_newVintage_2_toMergeGravity_.dta", clear
		
	merge m:1 year country subsidiaryCountry`x' using "$gravity/gravity_temp.dta"
	drop if _merge == 2
	drop _merge

	save "$navid/Company Trees/data_final_newVintage_2_toMergeGravity_.dta", replace
	
	disp("`x'")
	
}


*capture erase "$gravity/gravity_temp.dta"

save "$gravity/gravity_temp3.dta", replace

use "$path/temp_gravity.dta", clear

merge 1:1 country institution datem dateq Headquarters using "$gravity/gravity_temp3.dta"
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




/*
*cap drop countryToMatch_dist


* for those institutions, where the headquarter is closer than the minimum of the subsidiary, put headquarter as country to match:
*g countryToMatch_dist = Headquarters if distHQ <= min_dist_subs | distHQ == .

* for those institutions with zero subsidiaries, put headquarter as country to match
*replace countryToMatch_dist = Headquarters if sub_counter == 0

*replace countryToMatch_dist = subsidiaryCountry1 if ABdist1 == min_dist_subs & countryToMatch_dist == ""




cap drop countryToMatch_dist
g countryToMatch_dist = ""


replace countryToMatch_dist = Headquarters if distHQ <= min_dist_subs | distHQ == .

forval x = 1(1)121{
	
	replace countryToMatch_dist = subsidiaryCountry`x' if  ABdist`x' == min_dist_subs & countryToMatch_dist == ""
		
}


*/

/*

use "$gravity/gravity_temp.dta", clear

* now, we have to identify , for each distance variable, which is the subsidiary that is closest to the country of forecasts
egen min_dist = rowmin( dist1 - dist121)
egen min_distw = rowmin( distw1 - distw121)
egen min_distcap = rowmin( distcap1 - distcap121)
egen min_distwces = rowmin( distwces1 - distwces121)
egen min_dist_source = rowmin( dist_source1 - dist_source121)
*/



* dummy to identify the subsidiary (or headquarter):
foreach var in ABdist CDdistw DEdistcap FGdistwces HIdist_source {

cap drop countryToMatch_`var'

cap drop flag_`var'

g countryToMatch_`var' = ""

g flag_`var' = .

forval x = 0(1)121{
	
	* replace the minimum distance subsidiary variable with the respective country if the distance matches 
	replace countryToMatch_`var' = subsidiaryCountry`x' if  round(`var'`x',8) == round(min_`var'_subs,8) & countryToMatch_`var' == ""
	* replace it by the headquarter if the headquarter country is actually the closest country
	*replace countryToMatch_`var' = Headquarters if  min_`var' == `var'HQ 
	
	*replace flag_`var' = 1 if   min_`var' == `var'`x' & min_subsidiary_`var' != ""
	
}
	
}


keep country country_num institution id date datem dateq countryToMatch_ABdist countryToMatch_CDdistw countryToMatch_DEdistcap countryToMatch_FGdistwces 

rename countryToMatch_ABdist closest_ctry_dist
rename countryToMatch_CDdistw closest_ctry_distw
rename countryToMatch_DEdistcap closest_ctry_distcap
rename countryToMatch_FGdistwces closest_ctry_distwces

sort country id datem 

save "$gravity/gravity_temp2.dta", replace
