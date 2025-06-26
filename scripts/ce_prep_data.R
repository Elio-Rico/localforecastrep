
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
gdp_data_c1 <- standardize_institution_names(gdp_data$individual)


# USA info:  - later on, we might source that out into stata file.
gdp_data_c2 <- prepare_institution_info(
  df = gdp_data_c1,
  country_name = "USA",
  local_list = c(
    "Bethlehem Steel","Chrysler","CRT Govt. Securities","Daimler Chrysler","Dynamic Econ Strategy",
    "Fannie Mae","First Chicago","First Fidelity","First Trust Advisors","First Union Corp",
    "Ford Motor Company","General Motors","Georgia State University","Griggs & Santow",
    "Inforum - Univ of Maryland","Kemper Financial","Marine Midland","Mortgage Bankers Association",
    "Nat Assn of Home Builders","Provident Bank","RDQ Economics","Regional Financial Associates Inc",
    "Robert Fry Economics","Shawmut Bank","Shawmut National","The University of Michigan",
    "Univ of Michigan - RSQE","Nat Assn of Manufacturers"
  ),
  multinational_list = c(
    "Action Economics","Amoco Corporation","Bank America Corp","Bank of America - Merrill",
    "Bank of Boston","Bank One Corp","Bankers Trust","Barclays","Barclays Capital","BBVA",
    "BBVA Compass","Bear Stearns","BMO Capital Markets","BP Amoco","Brown Brothers Harriman",
    "Chase Manhattan","Chase Manhatten Bank","Chase Manhattan Bank","Chemical Banking",
    "Continental Bank","CoreStates Financial Corporation","Credit Suisse","Credit Suisse First Boston",
    "DRI-WEFA","Dun & Bradstreet","DuPont","Eaton Corporation","Econ Intelligence Unit",
    "FedEx Corporation","First Boston","Goldman Sachs","HSBC","IHS Markit","JP Morgan",
    "Lehman Brothers","Macroeconomic Advisers","Manufacturers Hanover","Mass Financial Services",
    "Mellon Bank","Merrill Lynch","Metropolitan Life","Moody's Analytics","Morgan Guaranty",
    "Morgan Stanley","NationsBank","Nomura","Northern Trust","Oxford Economics","Paine Webber",
    "PNC Bank","Prudential Financial","Roubini Global Econ","Royal Bank of Canada",
    "Shearson Lehman","Smith Barney Shearson","Standard & Poor's","Swiss Re","The Conference Board",
    "UBS","United States Trust","US Chamber of Commerce","Wachovia Corp","Wells Capital",
    "Wells Capital Mgmt","Wells Fargo","Wharton Econometric Forecasting Associates","Citigroup",
    "American International Group","Sears Roebuck & Co","CIBC Capital Markets","CIBC World Markets",
    "BBVA Bancomer"
  ),
  foreign_list = c(),
  source_notes = list(
    "BBVA Compass" = "Headquarter in the US. In June 2019, BBVA unified its brand worldwide and BBVA Compass is renamed BBVA USA.",
    "Barclays" = "Headquarter in the UK",
    "BMO Capital Markets" = "Headquarter in Canada",
    "CIBC Capital Markets" = "Headquarter in Canada",
    "CIBC World Markets" = "Headquarter in Canada",
    "Credit Suisse" = 'Headquarter in Switzerland. However, note that we consider "Credit Suisse First Boston" to be local with its headquarter in the United States.',
    "CRT Govt. Securities" = "Credit Risk Transfer (CRT) securities are general obligations of the US Federal National Mortgage Association. Hence, local to United States.",
    "DRI-WEFA" = "May 7, 2001: Global Insight announced it would acquire DRI and WEFA from their respective parent companies to form its first subsidiary, DRI-WEFA Inc.",
    "DuPont" = "Is an American company. Prior to the spinoffs it was the world's largest chemical company in terms of sales.",
    "Eaton Corporation" = "Headquarter in Ireland",
    "Econ Intelligence Unit" = "The Economist Intelligence Unit. Headquarter in the UK",
    "IHS Markit" = "Headquarter in the UK",
    "HSBC" = "Headquarter in the UK",
    "Nomura" = "A Japanese financial holding company and a principal member of the Nomura Group",
    "Oxford Economics" = "Headquarter in the UK",
    "Roubini Global Econ" = "Headquarter in the UK",
    "Royal Bank of Canada" = "Headquarter in Canada",
    "Swiss Re" = "Headquarter in Switzerland",
    "UBS" = "Headquarter in Switzerland"
  ),
  headquarters_map = list(
    "Barclays" = "GBR",
    "Barclays Capital" = "GBR",
    "Econ Intelligence Unit" = "GBR",
    "HSBC" = "GBR",
    "IHS Markit" = "GBR",
    "Oxford Economics" = "GBR",
    "Roubini Global Econ" = "GBR",
    "BMO Capital Markets" = "CAN",
    "CIBC Capital Markets" = "CAN",
    "CIBC World Markets" = "CAN",
    "Royal Bank of Canada" = "CAN",
    "Credit Suisse" = "CHE",
    "UBS" = "CHE",
    "Swiss Re" = "CHE",
    "Eaton Corporation" = "IRL",
    "Nomura" = "JPN"
  )
)



# further cleaning :
gdp_data_c3 <- standardize_institution_names_2(gdp_data_c2)

# CANADA info:  - later on, we might source that out into stata file.
gdp_data_c4 <- prepare_institution_info(
  df = gdp_data_c3,
  country_name = "Canada",
  local_list = c(
    "Bank of Montreal", "Burns Fry", "Centre for Spatial Economics", "Conf Board of Canada",
    "DRI Canada", "Economap", "EDC Economics", "Informetrica", "Institute of Policy Analysis",
    "Levesque Beaubien", "Loewen Ondaatje", "National Bank Financial",
    "National Bank of Canada", "Nesbitt Burns", "Nesbitt Thomson", "Richardson Greenshields",
    "Stokes Econ Consulting", "University of Toronto", "WEFA Canada"
  ),
  multinational_list = c(
    "Bank of America - Merrill", "BMO Capital Markets", "Bank of Nova Scotia", "Bunting Warburg",
    "Caisse de Depot", "Canadian Imperial Bank", "Capital Economics", "CIBC",
    "CIBC Capital Markets", "CIBC Markets", "CIBC Wood Gundy", "CIBC World Markets",
    "Citigroup", "Desjardins", "DuPont Canada", "HSBC", "IHS Markit", "JP Morgan",
    "JP Morgan Canada", "McLean McCarthy", "Merrill Lynch Canada", "Moody's Analytics",
    "RBC - Dominion Securities", "Royal Bank of Canada", "Royal Trust (Canada)",
    "Scotia Economics", "Scotia McLeod", "Sun Life", "Toronto Dominion Bank",
    "UBS", "Wood Gundy", "BMO Nesbitt Burns"
  ),
  foreign_list =  c(
    "Bank of America - Merrill",
    "Capital Economics",
    "Citigroup",
    "JP Morgan",
    "Moody's Analytics",
    "Econ Intelligence Unit",
    "HSBC",
    "IHS Markit",
    "Inst Fiscal Studies",
    "Oxford Economics",
    "UBS"
  ),
  source_notes = list(
    "Bunting Warburg" = "The company was formerly known as UBS Bunting Warburg Dillon Read and Bunting Warburg Inc. The company is headquartered in Toronto, Canada.",
    "Caisse de Depot" = "Caisse de dépôt et placement du Québec, not to be confused with Caisse des dépôts et consignations.",
    "Capital Economics" = "Headquarter in the UK",
    "Economap" = "Economap Inc.,  Toronto, Ontario",
    "Inst Fiscal Studies" = "Institute for Fiscal Studies, UK headquarter",
    "Institute of Policy Analysis" = "likely to be from the university of toronto: https://edirc.repec.org/data/ipautca.html",
    "McLean McCarthy" = "The Canadian securities house McLean McCarthy Ltd. – founded in 1972 – was acquired by Deutsche Bank (Canada)",
    "National Bank Financial" = "National Bank Financial is a wholly-owned subsidiary of National Bank and is the result of the merger between Lévesque Beaubien Geoffrion and First Marathon Inc. in September 1999",
    "Scotia Economics" = "Very likely, this is the Research Union of Bank of Nova Scotia -> Canada"
  ),
  headquarters_map = list(
    # USA institutions
    "Bank of America - Merrill" = "USA",
    "Citigroup" = "USA",
    "JP Morgan" = "USA",
    "Moody's Analytics" = "USA",
    # UK institutions
    "Capital Economics" = "GBR",
    "Econ Intelligence Unit" = "GBR",
    "HSBC" = "GBR",
    "IHS Markit" = "GBR",
    "Inst Fiscal Studies" = "GBR",
    "Oxford Economics" = "GBR",
    # Switzerland
    "UBS" = "CHE"
  )
)









