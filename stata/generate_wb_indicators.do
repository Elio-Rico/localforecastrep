* generate world-bank indicators:


* this is the code that was used to generate the world bank indicators. note
* that some of the indicators are now only available in the archive. This code
* is just here for transparency reasons. We provide the resulting data set
* in the folder inst/produced/worldbank.


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
save "$worldbankf/world_bank_data_yearly.dta", replace

* transparancey indicators

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

save "$worldbankf/world_bank_data_yearly_transparency.dta", replace


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


save "$worldbankf/world_bank_data_yearly_transparency2.dta", replace
