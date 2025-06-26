
devtools::load_all(".")
library("tidyverse")


list_of_countries <- c("Austria","Argentina", "Brazil","Belgium","Bulgaria","Canada","Chile","China",
                       "Colombia","Croatia","Czech Republic","Denmark",
                       "Estonia","France","Finland","Germany","Greece", "Hungary",
                       "India","Indonesia","Italy","Ireland","Israel","Japan","Latvia","Lithuania",
                       "Malaysia",
                       "Mexico","Netherlands","New Zealand","Nigeria","Norway","Peru",
                       "Philippines","Poland","Portugal","Romania",
                       "Russia", "Saudi Arabia","South Africa","South Korea","Spain","Sweden","Slovakia","Slovenia",
                       "Switzerland",
                       "Thailand","Turkey",
                       "Ukraine","UK","USA","Venezuela")

first.year <- 1989
last.year  <- 2021

list.of.months <- c("jan","feb","mar","apr","may","jun",
                    "jul","aug","sep","oct","nov","dec")



# ---------------------
# GDP
# ---------------------

# prepare gdp data:
gdp_data <- ce_prep_gdp(path = path_ce(),
                 lscountries = list_of_countries,
                 fy = first.year,
                 ly = last.year,
                 months = list.of.months
                 )


saveRDS(gdp_data, file = "inst/data/produced/gdp_data.rds")


# some initial cleaning
gdp_data_c1 <- standardize_institution_names(gdp_data$individual,   # Define all alternative names mapping to standardized names
                                             replacements = c(
                                               "American Int'l Group" = "American International Group",
                                               "American Intl Group" = "American International Group",
                                               "Amoco" = "Amoco Corporation",
                                               "Amoco Corp" = "Amoco Corporation",
                                               "BMO Financial Markets" = "BMO Capital Markets",
                                               "Brown Brothers" = "Brown Brothers Harriman",
                                               "Chase" = "Chase Manhatten Bank",
                                               "Chase Manhatten" = "Chase Manhatten Bank",
                                               "Chemical Bank" = "Chemical Banking",
                                               "Core States" = "CoreStates Financial Corporation",
                                               "CoreStates Fin Corp" = "CoreStates Financial Corporation",
                                               "CoreStates" = "CoreStates Financial Corporation",
                                               "CRT Govt Securities" = "CRT Govt. Securities",
                                               "CS First Boston" = "Credit Suisse First Boston",
                                               "FannieMae" = "Fannie Mae",
                                               "Ford Motor" = "Ford Motor Company",
                                               "Ford Motor Corp" = "Ford Motor Company",
                                               "Georgia State Uni." = "Georgia State University",
                                               "IHS Global Insight" = "IHS Markit",
                                               "IHS Economics" = "IHS Markit",
                                               "J P Morgan" = "JP Morgan",
                                               "Moody's Economy.com" = "Moody's Analytics",
                                               "Mortgage Bankers" = "Mortgage Bankers Association",
                                               "Mortgage Bankers Assoc" = "Mortgage Bankers Association",
                                               "Mortgage Bankers Assoc." = "Mortgage Bankers Association",
                                               "Nat Assn Manufacturers" = "Nat Assn of Manufacturers",
                                               "Nat Assn of Homebuilders" = "Nat Assn of Home Builders",
                                               "Nat. Ass. of Homebuilders" = "Nat Assn of Home Builders",
                                               "Natl Assoc of Home Builders" = "Nat Assn of Home Builders",
                                               "PNC Financial Services" = "PNC Bank",
                                               "Prudential Insurance" = "Prudential Financial",
                                               "Regional Financial Ass." = "Regional Financial Associates Inc",
                                               "Regional Financial Assocs" = "Regional Financial Associates Inc",
                                               "Sears Roebuck" = "Sears Roebuck & Co",
                                               "Smith Barney" = "Smith Barney Shearson",
                                               "Standard & Poors" = "Standard & Poor's",
                                               "U.S. Trust" = "United States Trust",
                                               "Wells Fargo Bank" = "Wells Fargo",
                                               "WEFA Group" = "Wharton Econometric Forecasting Associates",
                                               "The WEFA Group" = "Wharton Econometric Forecasting Associates",
                                               "Economy.com" = "Moody's Analytics",
                                               "Global Insight" = "IHS Markit")
                                             )


# USA info:  - later on, we might source that out into stata file.
gdp_data_c2 <- ce_prep_usa(gdp_data_c1)


# further cleaning :
gdp_data_c3 <- standardize_institution_names(gdp_data_c2,
                                             replacements = c(
                                            "Caisse de depot" = "Caisse de Depot",
                                            "Caisse de Depots" = "Caisse de Depot",
                                            "Centre for Spatial Econ" = "Centre for Spatial Economics",
                                            "Centre for Spatial Econ." = "Centre for Spatial Economics",
                                            "DRI - Canada" = "DRI Canada",
                                            "DRI  Canada" = "DRI Canada",
                                            "Du Pont" = "DuPont Canada",
                                            "Merrill Lynch - Canada" = "Merrill Lynch Canada",
                                            "RBC Dominion Securities" = "RBC - Dominion Securities",
                                            "RBC Dominion" = "RBC - Dominion Securities",
                                            "Toronto Dominion" = "Toronto Dominion Bank",
                                            "Conference Board" = "Conf Board of Canada",
                                            "Royal Trust" = "Royal Trust (Canada)")
                                          )

# CANADA info:  - later on, we might source that out into stata file.
gdp_data_c4 <- ce_prep_canada(gdp_data_c3)

# further cleaning :
gdp_data_c5 <- standardize_institution_names(gdp_data_c4, replacements = c(
  "KOF Swiss Econ Inst" = "KOF/ETH",
  "KOF Swiss Econ. Inst." = "KOF/ETH",
  "KOF/ETH Zentrum" = "KOF/ETH",
  "Zurcher Kantonalbank" = "Zürcher Kantonalbank",
  "IHS Global Insight" = "IHS Markit",
  "IHS Economics" = "IHS Markit",
  "Global Insight" = "IHS Markit",
  "Oxford - BAK" = "Oxford - BAK Basel"
)
)


# SWITZERLAND:
gdp_data_c6 <- ce_prep_switzerland(gdp_data_c5)

# further cleaning :
gdp_data_c7 <- standardize_institution_names(gdp_data_c6, replacements = c(
    "KOF Swiss Econ Inst" = "KOF/ETH",
    "KOF Swiss Econ. Inst." = "KOF/ETH",
    "KOF/ETH Zentrum" = "KOF/ETH",
    "Zurcher Kantonalbank" = "Zürcher Kantonalbank",
    "IHS Global Insight" = "IHS Markit",
    "IHS Economics" = "IHS Markit",
    "Global Insight" = "IHS Markit",
    "Oxford - BAK" = "Oxford - BAK Basel",
    "Erik Penser FK" = "Erik Penser Bank",
    "Hagglof - SBC Warburg" = "Hagglof - SG Warburg",
    "Hagstromer & Qviberg" = "Hagströmer & Qviberg",
    "SBAB" = "SBAB Bank",
    "Volvo Group Finance" = "Volvo",
    "HQ Bank" = "Hagströmer & Qviberg Bank",
    "Hagströmer & Qviberg" = "Hagströmer & Qviberg Bank",
    "Matteus FK" = "Matteus Fondkommission",
    "Matteus Bank" = "Matteus Fondkommission",
    "Ohman" = "Öhman Mutual Funds and Asset Management",
    "Öhman" = "Öhman Mutual Funds and Asset Management",
    "Aragon" = "Aragon Fondkommission",
    "Finanskonsult" = "Ficope Finanskonsult",
    "ITEM Club" = "EY Item Club",
    "SE Banken" = "Skandinaviska Enskilda Banken"
  )
)

# SWEDEN
gdp_data_c8 <- ce_prep_sweden(gdp_data_c7)


# further cleaning :
gdp_data_c9 <- standardize_institution_names(gdp_data_c8, replacements = c(
  "Bank of Tokyo" = "Bank of Tokyo-Mitsubishi UFJ",
  "Bank of Tokyo - London" = "Bank of Tokyo-Mitsubishi UFJ",
  "Bank of Tokyo Mitsubishi" = "Bank of Tokyo-Mitsubishi UFJ",
  "Barclays" = "Barclays Capital Group",
  "Barclays Capital" = "Barclays Capital Group",
  "Citigroup Japan" = "Citigroup Global Mkts Japan",
  "BDai-ichi Kangyo Bank" = "Dai-Ichi Kangyo Bank",
  "Dai-Ichi Kangyo Rsrch Inst" = "Dai-Ichi Kangyo Bank",
  "Dai-Ichi Kangyo Rsrch Institute" = "Dai-Ichi Kangyo Bank",
  "Dai-Ichi Life Research" = "Dai-Ichi Kangyo Bank",
  "Dai-ichi Kangyo Bank" = "Dai-Ichi Kangyo Bank",
  "Daiwa Institute of Research" = "Daiwa Securities Research",
  "Daiwa Institute of Rsrch" = "Daiwa Securities Research",
  "Daiwa Securities Rsrch" = "Daiwa Securities Research",
  "Deutsche Securities" = "Deutsche Bank (Asia)",
  "Deutsche Bank  (Asia)" = "Deutsche Bank (Asia)",
  "Dresdner Kleinwort Asia" = "Dresdner Kleinwort (Asia)",
  "Dresdner Kleinwort Benson" = "Dresdner Kleinwort (Asia)",
  "Jap Ctr for Econ Rsrch" = "Japan Ctr for Econ Research",
  "Japan Ctr Economic Rsrch" = "Japan Ctr for Econ Research",
  "Kokumin Keizai Research Inst" = "Kokumin Keizai Research Inst.",
  "Mitsubishi Research" = "Mitsubishi Research Institute",
  "Mitsubishi Research Inst" = "Mitsubishi Research Institute",
  "Mitsubishi Research Institute" = "Mitsubishi Research Institute",
  "Mitsubishi Rsrch" = "Mitsubishi Research Institute",
  "Nikko Citigroup" = "Nikko Salomon Smith Barney",
  "Nippon Steel Rsch Inst Corp" = "Nippon Steel Research Institute",
  "Nippon Steel & Sumikin Res Inst" = "Nippon Steel Research Institute",
  "Nippon Steel & Sumikin Rsrch" = "Nippon Steel Research Institute",
  "Nomura Rsrch Center" = "Nomura Research Institute",
  "Nomura Securities" = "Nomura Research Institute",
  "S G Warburg - Japan" = "SG Warburg - Japan",
  "S G Warburg - Tokyo" = "SG Warburg - Japan",
  "SG Warburg - Japan" = "SG Warburg - Japan",
  "SBC Warburg - Japan" = "SG Warburg - Japan",
  "Salomon Smith Barney" = "Salomon Smith Barney Asia (Citigroup)",
  "Salomon Smith Barney Asia" = "Salomon Smith Barney Asia (Citigroup)",
  "Salomon Brothers Asia" = "Salomon Brothers Asia Ltd.",
  "Sumitomo Bank" = "Sumitomo Life Research Institute",
  "Sumitomo Life Rsrch Institute" = "Sumitomo Life Research Institute",
  "Sanwa Research Institute" = "Sanwa Research Institute Corp.",
  "Schroder Securities" = "Schroders - Japan",
  "Schroders" = "Schroders - Japan",
  "UBS - Phillips & Drew" = "UBS Phillips & Drew (Securities) Tokyo",
  "UBS - Phillips & Drew - Tokyo" = "UBS Phillips & Drew (Securities) Tokyo",
  "UBS  Phillips & Drew - Tokyo" = "UBS Phillips & Drew (Securities) Tokyo",
  "UBS  Securities- Tokyo" = "UBS Phillips & Drew (Securities) Tokyo",
  "UBS  Securities - Tokyo" = "UBS Phillips & Drew (Securities) Tokyo",
  "UBS Securities - Japan" = "UBS Phillips & Drew (Securities) Tokyo",
  "UBS Phillips & Drew" = "UBS Phillips & Drew (Securities) Tokyo",
  "Yamaichi Rsrch Institute" = "Yamaichi Research Institute",
  "Smith Barney - Japan" = "Smith Barney (Shearson) Tokyo",
  "Smith Barney - Tokyo" = "Smith Barney (Shearson) Tokyo",
  "Smith Barney Shearson - Tokyo" = "Smith Barney (Shearson) Tokyo",
  "Smith Barney Shersn - Tokyo" = "Smith Barney (Shearson) Tokyo",
  "Jardine Fleming" = "Jardine Fleming - Tokyo",
  "Long Term Credit Bank" = "Long Term Credit Bank Japan",
  "LTCB" = "Long Term Credit Bank Japan",
  "NCB Research Institute" = "Nippon Credit Bank",
  "Nikko Rsrch Center" = "Nikko Research Center"
)
)

# JAPAN
gdp_data_c10 <- ce_prep_japan(gdp_data_c9)


# further cleaning
gdp_data_c11 <- standardize_institution_names(gdp_data_c10, replacements = c(
  "Banamex-Citi" = "Banamex",
  "Banamex" = "Banamex",
  "Bancomer" = "BBVA Bancomer",
  "Bancomer Centro" = "BBVA Bancomer",
  "BBVA" = "BBVA Bancomer",  # make sure to filter by country if needed
  "BofAML" = "Bank of America Merrill Lynch",
  "BPI" = "Banco BPI",
  "CEESP" = "Commission on Environmental, Economic and Social Policy (CEESP)",
  "Center Klein F'casting" = "Center Klein Forecasting",
  "CKF-Forecasting" = "Center Klein Forecasting",
  "Deutsche Bank Rsrch" = "Deutschebank Research",
  "ESANE" = "ESANE Consultores SC",
  "ESANE Consultores" = "ESANE Consultores SC",
  "Grupo Bursatil" = "Grupo Bursatil Mexicano",
  "Grupo Financ Inverlat" = "Grupo Financiero Inverlat",
  "Heath & Associates" = "Heath and Associates",
  "Heath y Associates" = "Heath and Associates",
  "JP Morgan Chase Mex" = "JP Morgan Mexico",
  "RGE" = "RGE Monitor",
  "Scotia Inverlat" = "Scotiabank Inverlat",
  "American Chamber Mex" = "American Chamber Of Commerce Of México A.C.",
  "CAPEM" = "Grupo CAPEM",
  "Casa de Bolsa Inverlat" = "Grupo Financiero Scotiabank",
  "Scotiabank" = "Grupo Financiero Scotiabank",
  "Scotiabank Inverlat" = "Grupo Financiero Scotiabank",
  "Grupo Financiero Inverlat" = "Grupo Financiero Scotiabank",
  "Consultores Econ" = "Consultores Economicos",
  "EIU" = "Econ Intelligence Unit",
  "Interacciones" = "Banco Interacciones, SA",
  "Heath and Associates" = "Jonathan Heath & Assoc",
  "Prognosis" = "Prognosis Economia Finanzas e Inversiones, S.C.",
  "RGE Monitor" = "Roubini Global Econ"
)
)

# MEXICO:
gdp_data_c12 <- ce_prep_mexico(gdp_data_c11)

# further cleaning :
gdp_data_c13 <- standardize_institution_names(gdp_data_c12, replacements = c(
  "BBV" = "BBV Latinvest",
  "BBV Securities" = "BBV Latinvest",
  "Credit Lyonnais -  Arg" = "Credit Lyonnais Argentina",
  "Credit Lyonnais Arg" = "Credit Lyonnais Argentina",
  "Jorge Avila y Asociades" = "Jorge Avila y Asociados",
  "M A Broda y Asociades" = "M A Broda & Asociados",
  "M A Broda y Asociados" = "M A Broda & Asociados",
  "MVA Macroeconomia" = "MVAS Macroeconomia",
  "ACM" = "ACM Research",
  "Delphos" = "Delphos Investment",
  "Econometrica" = "Econométrica S.A. - Novedades",
  "EXANTE" = "Exante Consultora",
  "Exante" = "Exante Consultora",
  "FIEL" = "Fundación de Investigaciones Económicas Latinoamericanas (FIEL)",
  "FASEL" = "Fundación para el Análisis Socioeconómico de Latinoamérica (FASEL)",
  "Fundacion Mediterranea" = "IERAL Fundacion Mediterranea",
  "IERAL Fund" = "IERAL Fundacion Mediterranea",
  "IERAL Fund Mediterranea" = "IERAL Fundacion Mediterranea",
  "LCG Consultora" = "LCG. Consultora Labour Capital & Growth",
  "M A Broda & Asociados" = "Macro Fundamentals - Estudio Broda y Asociados",
  "Macroeconomica" = "MVAS Macroeconomia",
  "Orlando Ferreres" = "Orlando Ferreres & Asoc",
  "Puente" = "Puente Hnos",
  "West Merchant Bank" = "West Merchant Bank Ltd"
)
)


# ARGENTINA
gdp_data_c14 <- ce_prep_argentina(gdp_data_c13)

