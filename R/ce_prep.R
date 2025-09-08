get_country_group <- function(country) {

  eastern.countries <- c("Bulgaria","Croatia","Czech Republic","Estonia","Hungary","Poland","Russia",
                         "Turkey","Latvia",
                         "Lithuania","Romania","Slovakia","Slovenia")

  latinamerica.countries <- c("Argentina","Brazil","Chile","Mexico","Venezuela","Colombia","Peru")

  asiapacific.countries <- c("Australia","China","India","Indonesia","Malaysia","New Zealand",
                             "Philippines",
                             "South Korea","Thailand")

  g7.countries <- c("USA","Japan","Germany","France","UK","Italy","Canada","Netherlands","Norway",
                    "Spain","Sweden",
                    "Switzerland","Austria","Belgium","Denmark","Egypt","Finland","Greece",
                    "Ireland","Israel",
                    "Nigeria","Portugal","Saudi Arabia","South Africa")


  if (country %in% eastern.countries) return(c("Eastern-Europe", "EE"))
  if (country %in% latinamerica.countries) return(c("Latin-America", "LA"))
  if (country %in% asiapacific.countries) return(c("Asia-Pacific", "AP"))
  if (country %in% g7.countries) return(c("G7-Europe", "CF"))
  warning("Country group not found: ", country)
  return(NULL)
}

build_file_path <- function(path, folder, prefix, month, year) {
  file.path(path, folder, paste0(prefix, month, year, ".xlsx"))
}

read_forecast_data <- function(file, country) {
  out <- try(readxl::read_excel(file, sheet = country, col_names = TRUE), silent = TRUE)
  if (inherits(out, "try-error")) return(NULL)
  out
}

get_gdp_column <- function(data, country) {
  gdp_variants <- switch(
    country,
    "USA" = c("Gross Domestic Product", "Gross National Product"),
    "Japan" = c("Gross Domestic Product", "Gross National Product"),
    "Germany" = c("Gross Domestic Product", "Gross National Product"),
    "South Korea" = c("Gross Domestic Product", "Gross National Product"),
    "Norway" = c("Gross Domestic Product (Mainland)", "Gross Domestic Product"),
    c("Gross Domestic Product")
  )
  for (gdp_name in gdp_variants) {
    idx <- which(paste(data[2,], data[3,]) == gdp_name)
    if (length(idx) > 0) return(idx)
  }
  return(NULL)
}



ce_read_gdp <- function(path, lscountries, fy, ly, months) {

  cli::cli_alert_info("Loading GDP data...")

    df.gdp.sum <- df.gdp <- data.frame()

    for (country in lscountries) {
      for (year in fy:ly) {
        for (month in months) {

          print(country)
          print(year)
          print(month)

          grp <- get_country_group(country)
          if (is.null(grp)) next
          file <- build_file_path(path, grp[1], grp[2], month, year)
          if (!file.exists(file)) next
          data <- read_forecast_data(file, country)
          if (is.null(data)) next

          # GDP column
          col_gdp <- get_gdp_column(data, country)
          if (is.null(col_gdp)) next

          # Survey date
          exact.date.survey <- extract_date(data)
          # Forecast years
          y1y2 <- extract_forecast_years(data, country, year, month, col_gdp)
          if (is.null(y1y2)) next

          # Extract data
          parsed <- parse_forecasts(data, col_gdp, y1y2[[1]], y1y2[[2]], exact.date.survey, country)
          df.gdp.sum <- rbind(df.gdp.sum, parsed$summary)
          df.gdp     <- rbind(df.gdp, parsed$individual)
        }
      }
    }

    df.gdp$Value <- as.numeric(df.gdp$Value)
    df.gdp.sum$Value <- as.numeric(df.gdp.sum$Value)

    # Clean
    # remove rows where no institution and value is present:
    df.gdp <- dplyr::anti_join(df.gdp, dplyr::filter(df.gdp, is.na(Value) & is.na(Institution)),
                               by = c("Institution", "Date", "Value"))

    # remove rows in case there is a row of number of forecasts in the final datafrmae:
    df.gdp <- dplyr::anti_join(df.gdp, dplyr::filter(df.gdp, Institution == "Number of Forecasts"),
                               by = c("Institution", "Date", "Value"))

    return(list(summary = df.gdp.sum, individual = df.gdp))

}



extract_forecast_years <- function(data, country, year, month, col_idx) {
  get_year_string <- function(cell, prefix = "") {
    cell <- gsub("FY", prefix, as.character(cell))
    parsed <- as.Date(cell, format = "%Y")
    format(parsed, "%Y")
  }

  tryCatch({

    if (country == "India") {
      fy_prefix <- if (year < 1999) "19" else if (year == 1999 && month %in% c("jan", "feb", "mar")) "19" else "20"

      year1 <- get_year_string(data[5, col_idx], prefix = fy_prefix)
      year2 <- get_year_string(data[5, col_idx + 1], prefix = fy_prefix)

      # correct for weird placeholder values
      if (year1 == "2099") year1 <- "1999"
      if (year2 == "2099") year2 <- "1999"

    } else {
      year1 <- format(as.Date(as.character(data[5, col_idx]), format = "%Y"), "%Y")
      year2 <- format(as.Date(as.character(data[5, col_idx + 1]), format = "%Y"), "%Y")
    }

    return(list(year1, year2))

  }, error = function(e) {
    warning("Could not parse forecast years for ", country)
    return(NULL)
  })
}



extract_date <- function(data) {
  raw_value <- data[[1]][3]

  # Try Excel serial number (numeric origin)
  if (suppressWarnings(!is.na(as.numeric(raw_value)))) {
    return(as.Date(as.numeric(raw_value), origin = "1899-12-30"))
  }

  # Try parsing text date
  parsed <- suppressWarnings(lubridate::mdy(raw_value))
  if (!is.na(parsed)) {
    return(parsed)
  }

  warning("Unable to parse survey date: ", raw_value)
  return(NA)
}



parse_forecasts <- function(data, col_idx, year1, year2, date, country) {
  # Summary and individual forecasts for year 1
  summary1 <- data[c(7, 9:12), c(1, col_idx)]
  summary1[[2]] <- as.numeric(summary1[[2]])
  individ1 <- data[25:nrow(data), c(1, col_idx)]
  individ1[[2]] <- as.numeric(individ1[[2]])

  summary1$Year <- year1
  individ1$Year <- year1

  # Summary and individual forecasts for year 2
  summary2 <- data[c(7, 9:12), c(1, col_idx + 1)]
  summary2[[2]] <- as.numeric(summary2[[2]])
  individ2 <- data[25:nrow(data), c(1, col_idx + 1)]
  individ2[[2]] <- as.numeric(individ2[[2]])

  summary2$Year <- year2
  individ2$Year <- year2

  # Standardize column names
  names(summary1) <- names(summary2) <- c("Measure", "Value", "Year")
  names(individ1) <- names(individ2) <- c("Institution", "Value", "Year")

  # Combine year 1 and year 2
  summary_all <- dplyr::bind_rows(summary1, summary2)
  individ_all <- dplyr::bind_rows(individ1, individ2)

  # Add metadata
  summary_all$Country <- individ_all$Country <- country
  summary_all$Date <- individ_all$Date <- date
  individ_all$current <- as.integer(individ_all$Year == year1)
  summary_all$current <- as.integer(summary_all$Year == year1)

  return(list(summary = summary_all, individual = individ_all))
}



standardize_institution_names <- function(df, replacements) {
  dfclean <- df

  for (rule in replacements) {
    if (is.character(rule)) next  # skip if somehow passed as just a character vector

    old_name <- rule$old
    new_name <- rule$new
    country <- rule$country

    if (is.null(country)) {
      # Global replacement
      dfclean <- dfclean %>%
        mutate(Institution = if_else(Institution == old_name, new_name, Institution))
    } else {
      # Country-specific replacement
      dfclean <- dfclean %>%
        mutate(Institution = if_else(Institution == old_name & Country == country, new_name, Institution))
    }
  }

  return(dfclean)
}




prepare_institution_info <- function(df,
                                     country_name,
                                     local_list = character(0),
                                     multinational_list = character(0),
                                     foreign_list = character(0),
                                     source_notes = list(),
                                     headquarters_map = list()) {

  # Create unique list of institutions for the country
  unique_inst <- df %>%
    filter(Country == country_name) %>%
    arrange(Institution) %>%
    distinct(Institution) %>%
    mutate(
      local = 1,
      source = "",
      headquarter = "",
      Country = country_name
    )

  # Add source notes (as a named list)
  for (inst in names(source_notes)) {
    unique_inst <- unique_inst %>%
      mutate(source = replace(source, Institution == inst, source_notes[[inst]]))
  }

  # Set headquarters from headquarters_map (as named list)
  for (inst in names(headquarters_map)) {
    unique_inst <- unique_inst %>%
      mutate(headquarter = replace(headquarter, Institution == inst, headquarters_map[[inst]]))
  }

  # Set USA (or any country) as default headquarter where local == 1
  unique_inst <- unique_inst %>%
    mutate(headquarter = replace(headquarter, local == 1 & headquarter == "", country_name))

  # Update local to 0 for foreign institutions
  unique_inst <- unique_inst %>%
    mutate(local = ifelse(Institution %in% foreign_list, 0, local))

  # Add local.2 classification
  unique_inst <- unique_inst %>%
    mutate(local.2 = case_when(
      Institution %in% local_list ~ 1,
      Institution %in% multinational_list ~ 2,
      Institution %in% foreign_list ~ 3,
      TRUE ~ NA_real_
    ))

  return(unique_inst)
}



ce_prep_usa <- function(data){


  data_out <- prepare_institution_info(
    df = data,
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


  data_out <- data_out %>%
    mutate(local = if_else(headquarter != "USA", 0, local))

  return(data_out)

}


ce_prep_canada <- function(data){

  data_out <- prepare_institution_info(
    df = data,
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

  return(data_out)
}


ce_prep_switzerland <- function(data){


  data_out <- prepare_institution_info(
    df = data,
    country_name = "Switzerland",
    local_list = c(
      "BAK Basel", "ETH Zentrum", "Institut Crea", "KOF/ETH", "Luzerner Kantonalbank",
      "St. Gallen ZZ", "Swiss Life", "Swiss Life Asset Mgrs", "Wellershoff & Partners",
      "WPuls", "Zürcher Kantonalbank", "Bantleon Bank"
    ),
    multinational_list = c(
      "Allianz", "Bank Julius Baer", "Bank Vontobel", "Citigroup", "Credit Suisse",
      "Fitch Ratings", "Goldman Sachs", "HSBC", "IHS Markit", "ING Financial Markets",
      "JP Morgan", "Moody's Analytics", "Morgan Stanley", "Nomura",
      "Oxford - BAK Basel", "Pictet & Cie", "UBS", "UBS Switzerland"
    ),
    foreign_list =  c(
      "Bank of America - Merrill", "Citigroup", "JP Morgan", "Moody's Analytics",
      "Fitch Ratings", "Goldman Sachs", "Morgan Stanley",
      "Capital Economics", "Econ Intelligence Unit", "HSBC", "IHS Markit",
      "Inst Fiscal Studies", "Oxford Economics", "ING Financial Markets", "Nomura"
    ),
    source_notes = list(
      "Capital Economics" = "HQ in London, UK",
      "Oxford - BAK Basel" = "Collaboration between Oxford Economics and BAK Basel. For this reason, we will label this as local. However, note that there are also single entries for Oxford Economics and BAK for some time. If they were not mentioned together, Oxford Economics was labelled foreign and BAK local"
    ),
    headquarters_map = list(
      # USA institutions
      "Bank of America - Merrill" = "USA",
      "Citigroup" = "USA",
      "JP Morgan" = "USA",
      "Moody's Analytics" = "USA",
      "Fitch Ratings" = "USA",
      "Goldman Sachs" = "USA",
      "Morgan Stanley" = "USA",
      # UK institutions
      "Capital Economics" = "GBR",
      "Econ Intelligence Unit" = "GBR",
      "HSBC" = "GBR",
      "IHS Markit" = "GBR",
      "Inst Fiscal Studies" = "GBR",
      "Oxford Economics" = "GBR",
      # Swiss
      "UBS" = "CHE",
      # Netherlands
      "ING Financial Markets" = "NLD",
      # Japan
      "Nomura" = "JPN"
    )
  )

  return(data_out)

}


ce_prep_sweden <- function(data){

  data_out <- prepare_institution_info(
    df = data,
    country_name = "Sweden",
    local_list = c(
      "Aragon Fondkommission", "Confed of Swed Enterprise", "Erik Penser Bank", "Ficope Finanskonsult",
      "Industrieforbundet", "Matteus Fondkommission", "National Institute - NIER",
      "Öhman Mutual Funds and Asset Management", "SA Makro", "SBAB Bank", "Volvo",
      "Hagströmer & Qviberg Bank"
    ),
    multinational_list = c(
      "Alfred Berg", "Bank of America Merrill", "BNP Paribas", "Citigroup", "EY Item Club",
      "Goldman Sachs", "Hagglof - SG Warburg", "HSBC", "ING Financial Markets", "JP Morgan",
      "MeritaNordbanken", "Merrill Lynch", "Moody's Analytics", "Morgan Stanley", "Nordbanken",
      "Nordea", "Nordea Nordbanken", "NYKredit", "SBC Warburg", "Skandiabanken",
      "Skandinaviska Enskilda Banken", "Svenska Handelsbanken", "Swedbank", "UBS",
      "UBS Limited", "UBS Warburg", "Warburg Dillon Read"
    ),
    foreign_list =  c(
      "Capital Economics", "Econ Intelligence Unit", "Euromonitor Intl", "Industrial Bank of Japan",
      "Mizuho Financial Group", "Oxford Economics", "UniCredit", "IHS Markit"
    ),
    source_notes = list(
      "Capital Economics" = "HQ in London, UK",
      "Hagglof - SG Warburg" = "The British investment bank S G Warburg acquires Gota's fund commissioning business Hägglöf & Ponsbach. Hence, we label the headquarter as Sweden due to Hägglöf & Ponsbach. However, SG Warburg itself is from the UK.",
      "Industrieforbundet" = "Industrieforbundet, the federation of Swedish industries",
      "National Institute - NIER" = "The National Institute of Economic Research (NIER) is a government agency operating under the Ministry of Finance. We perform analyses and forecasts of the Swedish and international economy as a basis for economic policy in Sweden, and conduct related research.",
      "UBS Warburg" = "Foreign: S. G. Warburg & Co. war eine Investmentbank mit Sitz in London. Starting on 9 June 2003, all UBS business groups, including UBS Paine Webber and UBS Warburg, were rebranded under the UBS moniker following company's start of operations as a unified global entity. Hence, we set UBS Warburg to foreign.",
      "SBC Warburg" = "Als der SBV 1995 die 1934 gegründete Investmentbank S.G. Warburg Plc. in London übernahm, änderte er deren Namen in „SBC Warburg - A Division of Swiss Bank Corporation“ und integrierte diese als Unternehmensbereich Investment Banking in das Unternehmen. Hence, foreign",
      "UBS Limited" = "Is a credit institution in Great Britain. Hence, foreign, headquarter in UK.",
      "Warburg Dillon Read " = "Warburg Dillon Read war kurzzeitig der Markenname des Unternehmensbereichs Investment Banking des damaligen Schweizerischen Bankvereins (SBV) und der späteren UBS...",
      "Alfred Berg" = "Local: In addition to Alfred Berg’s own extensive range of investment solutions, we are the sole distributor of BNP Paribas Asset Management’s investment products and services in Norway and Sweden.",
      "EY Item Club" = "The EY ITEM Club is a leading UK economic forecasting group. HQ in UK",
      "MeritaNordbanken" = "This is Swedish-Finnish. Hence local.",
      "SA Makro" = "Could not find any source for this. Presumably, this is just SBAB Bank Macro division. Hence local. But not sure."
    ),
    headquarters_map = list(
      # USA
      "Bank of America - Merrill" = "USA",
      "Bank of America Merrill" = "USA",
      "Citigroup" = "USA",
      "JP Morgan" = "USA",
      "Moody's Analytics" = "USA",
      "Fitch Ratings" = "USA",
      "Goldman Sachs" = "USA",
      "Morgan Stanley" = "USA",
      "Merrill Lynch" = "USA",
      # UK
      "Capital Economics" = "GBR",
      "Econ Intelligence Unit" = "GBR",
      "HSBC" = "GBR",
      "IHS Markit" = "GBR",
      "Inst Fiscal Studies" = "GBR",
      "Oxford Economics" = "GBR",
      "Euromonitor Intl" = "GBR",
      "EY Item Club" = "GBR",
      "SBC Warburg" = "GBR",
      "UBS Limited" = "GBR",
      # Switzerland
      "UBS" = "CHE",
      "UBS Warburg" = "CHE",
      "Warburg Dillon Read" = "CHE",
      # Netherlands
      "ING Financial Markets" = "NLD",
      # Japan
      "Nomura" = "JPN",
      "Industrial Bank of Japan" = "JPN",
      "Mizuho Financial Group" = "JPN",
      # France
      "BNP Paribas" = "FRA",
      # Norway
      "Nordbanken" = "NOR",
      # Denmark
      "NYKredit" = "DNK",
      # Italy
      "UniCredit" = "ITA"
    )
  )

  return(data_out)


}



ce_prep_japan <- function(data){

  data_out <- prepare_institution_info(
    df = data,
    country_name = "Japan",
    local_list = c(
      "Fuji Research Institute",
      "ITOCHU Institute",
      "Japan Tech Info Services Corp",
      "Kokumin Keizai Research Inst.",
      "Mitsubishi UFJ Research",
      "Nikko Research Center",
      "Nippon Steel Research Institute",
      "NLI Research Institute",
      "Sakura Institute of Research",
      "Sanwa Research Institute Corp.",
      "Shinsei Bank",
      "Toyota Motor Corporation",
      "Japan Ctr for Econ Research",
      "Mizuho Research Institute"
    ),
    multinational_list = c(
      "Bank of Tokyo-Mitsubishi UFJ",
      "Barclays Capital Group",
      "Baring Securities - Japan",
      "BZW - Japan",
      "Citigroup Global Mkts Japan",
      "Credit Suisse",
      "Credit Suisse First Boston",
      "CS First Boston",
      "Daiwa Securities Research",
      "Deutsche Bank (Asia)",
      "Dresdner Kleinwort (Asia)",
      "Euromonitor Intl",
      "Global Insight",
      "Goldman Sachs",
      "Hitachi Research Institute",
      "HSBC",
      "IHS Economics",
      "IHS Global Insight",
      "IHS Markit",
      "Industrial Bank of Japan",
      "Jardine Fleming - Tokyo",
      "Jardine Fleming Securities",
      "JP Morgan",
      "JP Morgan - Japan",
      "Kleinwort Benson - Tokyo",
      "Lehman Brothers",
      "Long Term Credit Bank Japan",
      "LTCB Warburg - Japan",
      "Merrill Lynch - Japan",
      "Mitsubishi Bank",
      "Mitsubishi Research Institute",
      "Mitsubushi Bank",  # Likely a typo of Mitsubishi Bank
      "Mizuho Research Institute",
      "Mizuho Securities",
      "Moody's Analytics",
      "Morgan Stanley",
      "MUFG Bank",
      "Nikko Salomon Smith Barney",
      "Nippon Credit Bank",
      "Nomura Research Institute",
      "Salomon Brothers Asia Ltd.",
      "Salomon Smith Barney Asia (Citigroup)",
      "Schroders - Japan",
      "SG Warburg - Japan",
      "Smith Barney (Shearson) Tokyo",
      "Societe Generale",
      "Sumitomo Life Research Institute",
      "Tokai Bank",
      "UBS",
      "UBS Phillips & Drew (Securities) Tokyo",
      "UBS Warburg",
      "UFJ Institute",
      "Warburg Dillon Read - Japan",
      "Yamaichi Research Institute",
      "Dai-Ichi Kangyo Bank",
      "IBJ Securities"
    ),
    foreign_list =  c(
      "Capital Economics",
      "Econ Intelligence Unit",
      "Oxford Economics"
    ),
    source_notes = list(
      "Jardine Fleming Securities" = "Jardine Fleming Securities has headquarter in China.",
      "JP Morgan" = "Only about 4 entries are not from JP Morgan Japan. I guess this is a typo; hence all JP Morgan for Japan are marked as local.",
      "Nikko Salomon Smith Barney" = "Joint venture of Nikko (Japanese) and Smith Barney (Morgan Stanley, USA). We label it as local due to Nikko's Japanese origin.",
      "Sanwa Research Institute Corp." = "Separately, MUFG has its own think tank, Mitsubishi UFJ Research and Consulting (MURC), a conglomerate including Sanwa Research Institute. Hence, local.",
      "Mitsubishi UFJ Research" = "Mitsubishi UFJ Research, Bank of Tokyo-Mitsubishi UFJ, and Mitsubishi Research Institute are different institutions but all with HQ in Japan.",
      "Mizuho Securities" = "Mizuho Securities and Mizuho Research Institute are different entities."
    ),
    headquarters_map = c(
      # United States
      "Bank of America - Merrill" = "USA",
      "Citigroup" = "USA",
      "Moody's Analytics" = "USA",
      "Fitch Ratings" = "USA",
      "Goldman Sachs" = "USA",
      "Morgan Stanley" = "USA",
      "Bank of America Merrill" = "USA",
      "Merrill Lynch" = "USA",
      "Credit Suisse First Boston" = "USA",
      "Lehman Brothers" = "USA",

      # United Kingdom
      "Capital Economics" = "GBR",
      "Econ Intelligence Unit" = "GBR",
      "HSBC" = "GBR",
      "IHS Markit" = "GBR",
      "Inst Fiscal Studies" = "GBR",
      "Oxford Economics" = "GBR",
      "Euromonitor Intl" = "GBR",
      "EY Item Club" = "GBR",
      "SBC Warburg" = "GBR",
      "UBS Limited" = "GBR",
      "Barclays Capital Group" = "GBR",

      # Switzerland
      "UBS" = "CHE",
      "UBS Warburg" = "CHE",
      "Warburg Dillon Read" = "CHE",
      "Credit Suisse" = "CHE",

      # Netherlands
      "ING Financial Markets" = "NLD",

      # Japan
      "Nomura" = "JPN",
      "Industrial Bank of Japan" = "JPN",
      "Mizuho Financial Group" = "JPN",

      # France
      "BNP Paribas" = "FRA",
      "Societe Generale" = "FRA",

      # Norway
      "Nordbanken" = "NOR",

      # Denmark
      "NYKredit" = "DNK",

      # Italy
      "UniCredit" = "ITA",

      # China
      "Jardine Fleming Securities" = "CHN"
    )
  )

  return(data_out)

}







ce_prep_mexico <- function(data){

  data_out <- prepare_institution_info(
    df = data,
    country_name = "Mexico",
    local_list = c(
      "Actinver Casa de Bolsa", "American Chamber Of Commerce Of México A.C.", "Analitica Consultores",
      "Asesoria Estrategica", "Banamex", "Banorte", "BBVA Bancomer", "CAIE-ITAM", "Comermex", "Consultores Economicos",
      "Ecanal", "Economia Aplicada", "ESANE Consultores SC", "GBM/Atlantico", "GEA", "Grupo Bursametrica",
      "Grupo Bursatil Mexicano", "Grupo CAPEM", "Invex Grupo Financiero", "Jonathan Heath & Assoc", "Latin Source",
      "Macro Asesoria Econ", "Prognosis Economia Finanzas e Inversiones, S.C.", "Banco Ve por Más", "Vector Casa de Bolsa",
      "CIEMEX-WEFA", "Ve Por Mas"
    ),
    multinational_list = c(
      "Banco BPI", "Banco Interacciones, SA", "Bank of America", "Bank of America Merrill Lynch",
      "Bankers Trust", "Barclays", "Barclays Capital", "BofA - Merrill Lynch", "Bulltick", "Chase Manhattan",
      "Citigroup", "Commission on Environmental, Economic and Social Policy (CEESP)", "Credit Suisse",
      "CS First Boston", "Deutschebank Research", "First Boston", "Fitch Ratings", "General Motors",
      "Global Insight", "Grupo Financiero Scotiabank", "HSBC", "HSBC Mexico", "IHS Economics", "IHS Global Insight",
      "ING", "ING Bank", "ING Barings", "J P Morgan", "JP Morgan", "JP Morgan Chase", "JP Morgan Mexico",
      "Lehman Brothers", "Merrill Lynch", "Monex", "Moody's Analytics", "Morgan Guaranty", "Morgan Stanley",
      "Multivalores", "Salomon Brothers", "Santander Investment", "Santander Mexico", "Santander Serfin Mexico",
      "Standard Chartered", "UBS", "UBS Securities", "UBS Warburg", "Credit Suisse First Boston", "Dresdner Kleinwort",
      "IHS Markit", "Swiss Re", "BBVA"
    ),
    foreign_list =  c(
      "Action Economics", "AGPV", "Capital Economics", "Center Klein Forecasting", "Dresdner Kleinwort Ben.",
      "Econ Intelligence Unit", "Euromonitor Intl", "IDEAglobal", "Kleinwort Benson Secs", "Oxford Economics",
      "Roubini Global Econ", "Warburg Dillon Read", "XP Securities"
    ),
    source_notes = list(
      "AGPV" = "Azpurua, Garcia-Palacios & Velazquez, from Venezuela!",
      "Grupo Financiero Scotiabank" = "I assumed that Scotiabank was actually the Grupo Financiero Scotiabank to which also several subsidiaries such as Scotiabank Mexico, Scotia Casa de Bolsa, Scotia Fondos and Scotia Afore belong to. Since this Grupo Financiero has its headquarter in Mexico, I declared it as local.",
      "Center Klein Forecasting" = "I guess it is the Center of ARNE CHRISTIAN KLEIN, from the WWU Münster.",
      "Comermex" = "Multibanco Comermex (bought by Inverlat and became Comermex Inverlat) Scotiabank Inverlat. Since Inverlat is local, Comermex is also local.",
      "Commission on Environmental, Economic and Social Policy (CEESP)" = "Regional Office for Mexico, Central America and the Caribbean San Jose, Costa Rica",
      "Jonathan Heath & Assoc" = "https://jonathanheath.net/ from Mexico",
      "Santander Investment" = "Looking at all Santanders that made forecasts for Mexico, it must almost surely be Santander Mexico, and hence local.",
      "UBS Securities" = "UBS Securities Co., Ltd. ist eine chinesische Investmentbank und Maklerfirma. Es ist seit 2018 eine Tochtergesellschaft der multinationalen Finanzgruppe UBS."
    ),
    headquarters_map = c(
      # Local Mexico
      "local" = "MEX",

      # Institutions mapped individually
      "Bank of America" = "USA",
      "Bank of America Merrill Lynch" = "USA",
      "Bank of America Merrill" = "USA",
      "Bankers Trust" = "USA",
      "Action Economics" = "USA",
      "BofA - Merrill Lynch" = "USA",
      "Bulltick" = "USA",
      "Chase Manhattan" = "USA",
      "Citigroup" = "USA",
      "First Boston" = "USA",
      "Fitch Ratings" = "USA",
      "General Motors" = "USA",
      "JP Morgan" = "USA",
      "JP Morgan Chase" = "USA",
      "Lehman Brothers" = "USA",
      "Merrill Lynch" = "USA",
      "Moody's Analytics" = "USA",
      "Morgan Guaranty" = "USA",
      "Morgan Stanley" = "USA",
      "Salomon Brothers" = "USA",

      "Capital Economics" = "GBR",
      "Barclays Capital" = "GBR",
      "Barclays Capital Group" = "GBR",
      "Barclays" = "GBR",
      "Econ Intelligence Unit" = "GBR",
      "Euromonitor Intl" = "GBR",
      "HSBC" = "GBR",
      "IDEAglobal" = "GBR",
      "IHS Markit" = "GBR",
      "Kleinwort Benson Secs" = "GBR",
      "Oxford Economics" = "GBR",
      "Roubini Global Econ" = "GBR",
      "Standard Chartered" = "GBR",
      "XP Securities" = "GBR",
      "IHS Economics" = "GBR",
      "IHS Global Insight" = "GBR",

      "ING Financial Markets" = "NLD",
      "ING" = "NLD",
      "ING Bank" = "NLD",
      "ING Barings" = "NLD",

      "Monex" = "LIE",

      "UBS" = "CHE",
      "UBS Warburg" = "CHE",
      "Warburg Dillon Read" = "CHE",
      "Credit Suisse" = "CHE",

      "AGPV" = "VEN",
      "Banco BPI" = "POR",

      "Center Klein Forecasting" = "GER",
      "Deutschebank Research" = "GER",
      "Dresdner Kleinwort" = "GER",
      "Dresdner Kleinwort Ben." = "GER",

      "Commission on Environmental, Economic and Social Policy (CEESP)" = "CRI",

      "UBS Securities" = "CHN"
    )
  )

  return(data_out)

}


ce_prep_argentina <- function(data){

  data_out <- prepare_institution_info(
    df = data,
    country_name = "Argentina",
    local_list = c(
      "Abeceb.com",
      "ALPHA",
      "Asesores Economicos",
      "Banco Credicoop",
      "Banco Galicia",
      "Banco Tornquist",
      "Delphos Investment",
      "Eco Go",
      "Eco Go/Estudio Bein",
      "Ecolatina",
      "Econométrica S.A. - Novedades",
      "Econviews",
      "Elypsis",
      "Espert & Asociados",
      "Estudio Bein & Asoc",
      "Estudio Espert",
      "Exante Consultora",
      "Fundación de Investigaciones Económicas Latinoamericanas (FIEL)",
      "Fundación para el Análisis Socioeconómico de Latinoamérica (FASEL)",
      "IERAL Fundacion Mediterranea",
      "Jose Luis Espert & Asoc",
      "LCG. Consultora Labour Capital & Growth",
      "M & S Consultores",
      "Macro Fundamentals - Estudio Broda y Asociados",
      "Macroview",
      "MVAS Macroeconomia",
      "Orlando Ferreres & Asoc",
      "Overdata",
      "PROECO",
      "Puente Hnos",
      "Fundacion Capital"
    ),
    multinational_list = c(
      "Bank of America",
      "Bank of America Merrill Lynch",
      "Bankers Trust",
      "Barclays Capital",
      "BBVA Argentina",
      "BBVA Banco Frances",
      "BBVA Bancomer",
      "BBVA Securities",
      "Bear Stearns",
      "BofA - Merrill Lynch",
      "Bulltick",
      "Chartered West LB",
      "Citigroup",
      "Credit Lyonnais Argentina",
      "Credit Suisse",
      "Credit Suisse First Boston",
      "CSM Worldwide",
      "Deutschebank Research",
      "Dresdner Kleinwort",
      "Dresdner Kleinwort Ben.",
      "First Boston",
      "General Motors",
      "Goldman Sachs",
      "HSBC",
      "ING Barings",
      "ING Financial Markets",
      "Itau BBA",
      "JP Morgan",
      "JP Morgan Chase",
      "Kleinwort Benson Secs",
      "Lehman Brothers",
      "Merrill Lynch",
      "Morgan Guaranty",
      "Morgan Stanley",
      "Salomon Brothers",
      "Salomon Smith Barney Asia (Citigroup)",
      "Santander Investment",
      "Scotiabank Quilmes",
      "SSB Citigroup",
      "UBS Warburg",
      "Warburg Dillon Read",
      "West Merchant Bank Ltd",
      "XP Securities",
      "BBVA"
    ),
    foreign_list =  c(
      "ACM Research",
      "BBV Latinvest",
      "Capital Economics",
      "Corp Group",
      "Datarisk",
      "Econ Intelligence Unit",
      "Euromonitor Intl",
      "IDEAglobal",
      "IHS Markit",
      "Jorge Avila y Asociados",
      "Moody's Analytics",
      "Oxford Economics"
    ),
    source_notes = list(
      "BBVA Banco Frances" = "Changed name to BBVA Argentina",
      "ALPHA" = "No information found - hence local",
      "Asesores Economicos" = "http://www.cyt-asesores.com.ar/contacto.php"
    ),
    headquarters_map = c(
      "Bank of America" = "USA",
      "Bank of America Merrill Lynch" = "USA",
      "BBVA Securities" = "USA",
      "ACM Research" = "USA",
      "Bear Stearns" = "USA",
      "Credit Suisse First Boston" = "USA",
      "CSM Worldwide" = "USA",
      "Goldman Sachs" = "USA",
      "SSB Citigroup" = "USA",
      "Bank of America Merrill" = "USA",
      "Bankers Trust" = "USA",
      "Action Economics" = "USA",
      "BofA - Merrill Lynch" = "USA",
      "Bulltick" = "USA",
      "Chase Manhattan" = "USA",
      "Citigroup" = "USA",
      "First Boston" = "USA",
      "Fitch Ratings" = "USA",
      "General Motors" = "USA",
      "JP Morgan" = "USA",
      "JP Morgan Chase" = "USA",
      "Lehman Brothers" = "USA",
      "Merrill Lynch" = "USA",
      "Moody's Analytics" = "USA",
      "Morgan Guaranty" = "USA",
      "Morgan Stanley" = "USA",
      "Salomon Brothers" = "USA",

      "Capital Economics" = "GBR",
      "Barclays Capital" = "GBR",
      "Chartered West LB" = "GBR",
      "West Merchant Bank Ltd" = "GBR",
      "BBV Latinvest" = "GBR",
      "Barclays Capital Group" = "GBR",
      "Barclays" = "GBR",
      "Econ Intelligence Unit" = "GBR",
      "Euromonitor Intl" = "GBR",
      "HSBC" = "GBR",
      "IDEAglobal" = "GBR",
      "IHS Markit" = "GBR",
      "Kleinwort Benson Secs" = "GBR",
      "Oxford Economics" = "GBR",
      "Roubini Global Econ" = "GBR",
      "Standard Chartered" = "GBR",
      "XP Securities" = "GBR",

      "Corp Group" = "CHL",

      "Datarisk" = "BRA",
      "Itau BBA" = "BRA",

      "Jorge Avila y Asociados" = "PAN",

      "Salomon Smith Barney Asia (Citigroup)" = "USA",

      "BBVA Bancomer" = "MEX",

      "ING Financial Markets" = "NLD",
      "ING" = "NLD",
      "ING Bank" = "NLD",
      "ING Barings" = "NLD",

      "Monex" = "LIE",

      "UBS" = "CHE",
      "UBS Warburg" = "CHE",
      "Warburg Dillon Read" = "CHE",
      "Credit Suisse" = "CHE",

      "AGPV" = "VEN",

      "Banco BPI" = "POR",

      "Center Klein Forecasting" = "GER",
      "Deutschebank Research" = "GER",
      "Dresdner Kleinwort" = "GER",
      "Dresdner Kleinwort Ben." = "GER",

      "Commission on Environmental, Economic and Social Policy (CEESP)" = "CRI",

      "UBS Securities" = "CHN"
    )
  )

  return(data_out)

}





ce_prep_brazil <- function(data){

  data_out <- prepare_institution_info(
    df = data,
    country_name = "Brazil",
    local_list = c(
      "4e Consultoria","Arazul Capital","Banco BBM","Banco BV","Banco Crefisul SA","Banco da Bahia Invest",
      "Banco Fator","Banco Itamarati","Banco Votorantim","Banespa","Bco Estado (Banespa)","Datalynk",
      "E J Reis","Fritsch, Franco e Asociades","Fundacao G Vargas","GO Associados",
      "IPEA - Instituto de Pesquisa Econômica Aplicada","LCA Consultores","M B Associados","M B Associadosn",
      "Macrometrica","MCM Consultores","Parallaxis Economics","Pezco Economics","Reis e Moreira",
      "Rosenberg Consultoria","SILCON/C.R. Contador","Tendencias","Trend Analise Economica",
      "UFRJ Universidade Federal do Rio de Janeiro"
    ),
    multinational_list = c(
      "Banco Bradesco","Banco Safra","Bank of America - Brazil","Bank of America Merrill Lynch","Bankers Trust",
      "Barclays","Barclays Capital","BBVA Bancomer","BBVA Brasil","BBVA Securities","BCP Securities",
      "BNP Paribas","BofA - Merrill Lynch","Citibank Brazil","Citigroup","Credit Suisse First Boston",
      "CSFB Garantia","Deutsche Bank","Dresdner Kleinwort","Dresdner Kleinwort Ben.","Eaton",
      "Eaton Corporation","Euler Hermes","Euromonitor Intl","First Boston","Fitch Ratings","General Motors",
      "GlobalData","Goldman Sachs","HSBC","HSBC Brazil","IHS Markit","ING","ING Bank","ING Barings",
      "Itau BBA","Itau Corretora","Itau Unibanco","J P Morgan","JP Morgan","JP Morgan Chase",
      "JP Morgan Chase Brazil","Kleinwort Benson Secs","Lehman Brothers","Lloyds Bank - Sao Paulo",
      "Lloyds TSB Brazil","Lombard Street Research","Merrill Lynch","Moody's Analytics",
      "Morgan Guaranty","Morgan Stanley","Rabobank","Royal Bank of Scotland","Salomon Brothers",
      "Santander Brazil","Santander Investment","SBC Warburg","Standard Chartered",
      "Standard Chartered Bank","Timetric","UBS Securities","BBVA"
    ),
    foreign_list =  c(
      "C Contador & Asocs","Capital Economics","Econ Intelligence Unit","Grupo Bursatil Mexicano","GW Consultants",
      "IDEAglobal","Oxford Economics","RGE Monitor", "RGE","Roubini Global Econ"
    ),
    source_notes = list(
      "BCP Securities" = "Has a localisation in Sao Paola, hence not sure if local or foreign. Hence, I will put it as local.",
      "CSFB Garantia" = "Former Banco Garantia which was taken over by Credit Suisse (First Boston). Banco Garantia is from Brazil which is why we put the dummy equal to local here.",
      "Datalynk" = "Possibly Datalynx actually, which is Brazilian",
      "GW Consultants" = "GW Consultants is located in Keerbergen, FLEMISH BRABANT, Belgium and is part of the Consulting Services Industry."
    ),
    headquarters_map = c(
      # USA
      "Bank of America" = "USA", "Bank of America Merrill Lynch" = "USA", "Bankers Trust" = "USA",
      "BBVA Securities" = "USA", "BofA - Merrill Lynch" = "USA", "Citigroup" = "USA",
      "Credit Suisse First Boston" = "USA", "Lehman Brothers" = "USA", "First Boston" = "USA",
      "Merrill Lynch" = "USA", "Moody's Analytics" = "USA", "Fitch Ratings" = "USA",
      "General Motors" = "USA", "Goldman Sachs" = "USA", "JP Morgan" = "USA",
      "JP Morgan Chase" = "USA", "Morgan Guaranty" = "USA", "Morgan Stanley" = "USA",
      "Salomon Brothers" = "USA",

      # GBR
      "Barclays Capital" = "GBR", "Barclays" = "GBR", "Capital Economics" = "GBR",
      "Econ Intelligence Unit" = "GBR", "Euromonitor Intl" = "GBR", "GlobalData" = "GBR",
      "HSBC" = "GBR", "IDEAglobal" = "GBR", "IHS Markit" = "GBR",
      "Kleinwort Benson Secs" = "GBR", "Lombard Street Research" = "GBR", "Oxford Economics" = "GBR",
      "Roubini Global Econ" = "GBR", "Royal Bank of Scotland" = "GBR", "SBC Warburg" = "GBR",
      "Standard Chartered" = "GBR", "Standard Chartered Bank" = "GBR", "Timetric" = "GBR",
      "XP Securities" = "GBR",

      # Other countries
      "BBVA Bancomer" = "MEX",
      "Grupo Bursatil Mexicano" = "MEX",
      "BNP Paribas" = "FRA",
      "Euler Hermes" = "FRA",
      "C Contador & Asocs" = "PER",
      "Deutsche Bank" = "GER", "Dresdner Kleinwort" = "GER", "Dresdner Kleinwort Ben." = "GER",
      "Eaton" = "IRL", "Eaton Corporation" = "IRL",
      "GW Consultants" = "BEL",
      "ING Financial Markets" = "NLD", "ING" = "NLD", "ING Bank" = "NLD", "ING Barings" = "NLD",
      "UBS Securities" = "CHN"
    )
  )

  return(data_out)

}






ce_prep_china <- function(data){

  data_out <- prepare_institution_info(
    df = data,
    country_name = "China",
    local_list = c(
      "Bank of China", "Bank of China (H.K.)", "Bank of China (HK)", "Crosby Securities",
      "Hang Seng Bank", "Hongkong Bank Research", "Sun Hung Kai Research"
    ),
    multinational_list = c(
      "ABN Amro", "Allianz", "Asia Equity", "Bank of America", "Bank of East Asia", "Bankers Trust",
      "Barclays", "Barclays Capital", "Baring Securities", "BBVA", "BNP Paribas", "BNP Paribas Peregrine",
      "BNP Prime Peregrine", "BofA - Merrill Lynch", "Chase JF", "Chase Manhattan", "China Int'l Capital Corp",
      "Citigroup", "Credit Suisse", "Credit Suisse First Boston", "CS First Boston", "Daiwa Capital Markets",
      "Daiwa Research Inst", "DBS Bank", "Deutsche Bank", "Deutsche Morgan Grenfell", "Dresdner Kleinwort",
      "Econ Intelligence Unit", "Euromonitor Intl", "Experian", "Global Insight", "Goldman Sachs Asia",
      "Hongkong Bank Research", "HSBC", "HSBC Economics", "HSBC James Capel Asia", "HSBC Research",
      "IHS Economics", "IHS Global Insight", "IHS Markit", "ING", "ING Barings", "James Capel Asia",
      "JP Morgan (Hong Kong)", "JP Morgan Chase", "JP Morgan Hong Kong", "Lehman Brothers",
      "Lehman Brothers Asia", "Merrill Lynch", "MF Global", "Moody's Analytics", "Morgan Grenfell Asia",
      "Morgan Stanley Asia", "NatWest Markets", "Nomura International (HK)", "Nomura", "Nomura Research Inst",
      "Peregrine", "Salomon Smith Barney", "Salomon Smith Barney Asia (Citigroup)", "Schroder Securities",
      "Schroders", "SG Securities", "SG Warburg Securities", "Smith New Court", "Societe Generale",
      "Standard Chartered", "SocGen-Crosby", "South China Securities", "Timetric", "UBS", "UBS Securities",
      "UBS Warburg", "UOB Kay Hian", "W.I.Carr", "BBVA Bancomer", "GlobalData", "Jardine Fleming - Tokyo",
      "Schroders - Japan"
    ),
    foreign_list =  c(
      "Capital Economics", "FAZ InfoDienste", "FAZ Institut", "FERI", "G.K. Goh Securities",
      "Mizuho Research Institute", "Oxford Economics", "Oxford Economics USA", "Sakura Inst of Research"
    ),
    source_notes = list(
      "Baring Securities" = "Not exactly sure if local or foreign. Baring Securuties had several overseas operating subsidiaries, including two in Singapore: Barings Securities (Singapore) Pte Ltd. (BSS), which principally engaged in securities trading, and Barings Futures (Singapore) Pte Ltd. (BFS), which BSL formed to allow Barings to trade on SIMEX. Since not sure, we set it to local.",
      "BNP Paribas Peregrine" = "Peregrine (including Peregrine Investments Holdings Limited and Peregrine Infrastructure Investments Limited) was an investment company based in Hong Kong. It was liquidated following the downturn of the Indonesian economy during the Asian financial crisis, and was acquired by BNP Paribas. Hence local.",
      "Chase JF" = "Chase JF Ltd. provides investment banking and financial services in the Asia-Pacific region."
    ),
    headquarters_map = c(
      "Bank of America" = "USA", "Bank of America Merrill Lynch" = "USA", "Bankers Trust" = "USA", "BofA - Merrill Lynch" = "USA",
      "JP Morgan Chase" = "USA", "Chase Manhattan" = "USA", "Citigroup" = "USA", "Credit Suisse First Boston" = "USA",
      "Lehman Brothers" = "USA", "Merrill Lynch" = "USA", "MF Global" = "USA", "Moody's Analytics" = "USA",
      "Oxford Economics USA" = "USA", "Salomon Smith Barney Asia (Citigroup)" = "USA",

      "Barclays Capital" = "GBR", "Barclays" = "GBR", "Deutsche Morgan Grenfell" = "GBR", "Capital Economics" = "GBR",
      "Daiwa Capital Markets" = "GBR", "Econ Intelligence Unit" = "GBR", "Euromonitor Intl" = "GBR", "GlobalData" = "GBR",
      "HSBC" = "GBR", "HSBC Economics" = "GBR", "HSBC Research" = "GBR", "IHS Markit" = "GBR", "NatWest Markets" = "GBR",
      "Oxford Economics" = "GBR", "Smith New Court" = "GBR", "Standard Chartered" = "GBR", "Timetric" = "GBR",

      "ING Financial Markets" = "NLD", "ING" = "NLD", "ING Bank" = "NLD", "ING Barings" = "NLD", "ABN Amro" = "NLD",

      "Deutsche Bank" = "GER", "Dresdner Kleinwort" = "GER", "Dresdner Kleinwort Ben." = "GER", "Allianz" = "GER",
      "FAZ InfoDienste" = "GER", "FAZ Institut" = "GER", "FERI" = "GER",

      "BBVA Bancomer" = "MEX", "BNP Paribas" = "FRA", "SG Securities" = "FRA", "Societe Generale" = "FRA",

      "UBS" = "CHE", "UBS Warburg" = "CHE", "Warburg Dillon Read" = "CHE", "Credit Suisse" = "CHE", "SG Warburg Securities" = "CHE",

      "Daiwa Research Inst" = "JPN", "Jardine Fleming - Tokyo" = "JPN", "Mizuho Research Institute" = "JPN", "Nomura" = "JPN",
      "Nomura Research Inst" = "JPN", "Sakura Inst of Research" = "JPN", "Schroders - Japan" = "JPN",

      "DBS Bank" = "MYS", "G.K. Goh Securities" = "MYS", "UOB Kay Hian" = "MYS",

      "Eaton" = "IRL", "Eaton Corporation" = "IRL", "Experian" = "IRL",

      "UBS Securities" = "CHN"
    )
  )

  return(data_out)

}



ce_prep_india <- function(data){

  data_out <- prepare_institution_info(
    df = data,
    country_name = "India",
    local_list = c(
      "CDE-DSE", "CDE-DSE Research", "CMIE", "Confed of Indian Industry", "CRISIL", "DSP Financial Consult",
      "Hindustan Lever", "IEG - DSE Research", "India Ratings & Research", "Kotak Securities",
      "National Council of Applied Economic Research - India", "Oxus Research",
      "Tata Services (DES)", "UTI Securities"
    ),
    multinational_list = c(
      "ABN Amro", "ABN Amro India", "American Express Bank", "ANZ Bank", "ANZ Grindlays Bank",
      "ANZ Investment Bank", "Bank of Tokyo", "Bank of Tokyo-Mitsubishi", "Bank of Tokyo-Mitsubishi UFJ",
      "Bank of Tokyo Mitsubishi", "Barclays", "Barclays Capital", "Bk of Tokyo-Mitsubishi UFJ",
      "BNP Paribas", "BofA - Merrill Lynch", "Chase JF", "Chase Manhattan Bank", "Chase Manhattan Rsrch",
      "Citigroup", "Credit Suisse", "Credit Suisse First Boston", "DBS Bank", "Deloitte India", "Deutsche Bank",
      "Deutsche Morgan Grenfell", "DRI-WEFA", "DSP Merrill Lynch", "Experian", "Experian Business Strat",
      "Experian Business Strategies", "General Motors", "Global Insight", "GlobalData", "Goldman Sachs",
      "Goldman Sachs Asia", "W.I.Carr", "HSBC", "HSBC Batlivala & Karani", "HSBC Securities",
      "ICICI Bank", "ICICI Securities", "IHS Economics", "IHS Global Insight", "IHS Markit",
      "ING", "ING Barings", "Jardine Fleming India", "JP Morgan", "JP Morgan Chase",
      "Lehman Brothers", "Lehman Brothers Asia", "Merrill Lynch", "Morgan Stanley",
      "Morgan Stanley (Bombay)", "Morgan Stanley Asia", "MUFG Bank", "NatWest Markets", "Nomura",
      "Peregrine", "Rabobank", "Salomon Smith Barney Asia (Citigroup)", "SG Securities",
      "Soc-Gen Crosby", "SocGen-Crosby", "Societe Generale", "Standard Chartered",
      "Timetric", "UBS", "UBS Securities", "UBS Warburg", "Tata Services (DES)",
      "BBVA Bancomer", "Wharton Econometric Forecasting Associates"
    ),
    foreign_list =  c(
      "BBVA", "Crosby Securities", "Dresdner Bank", "Econ Intelligence Unit", "FERI",
      "Moody's Economy.com", "Moody's Analytics", "Oxford Economics", "WEFA Group"
    ),
    source_notes = list(
      "DRI-WEFA" = "DRI merged with WEFA to form Global Insight",
      "DSP Financial Consult" = "Both DSP financial consult and merrill lynch are located in mumbai",
      "DSP Merrill Lynch" = "Both DSP financial consult and merrill lynch are located in mumbai",
      "HSBC Securities" = "is located in the US contrary to the HSBC."
    ),
    headquarters_map = c(
      # USA
      "Bank of America" = "USA", "Bank of America Merrill Lynch" = "USA", "American Express Bank" = "USA",
      "BofA - Merrill Lynch" = "USA", "Chase Manhattan Bank" = "USA", "Chase Manhattan Rsrch" = "USA",
      "Citigroup" = "USA", "Credit Suisse First Boston" = "USA", "DRI-WEFA" = "USA",
      "Econ Intelligence Unit" = "USA", "General Motors" = "USA", "Goldman Sachs" = "USA",
      "HSBC Securities" = "USA", "JP Morgan Chase" = "USA", "JP Morgan" = "USA", "Lehman Brothers" = "USA",
      "Merrill Lynch" = "USA", "Moody's Analytics" = "USA", "Morgan Stanley" = "USA",
      "Salomon Smith Barney Asia (Citigroup)" = "USA", "Wharton Econometric Forecasting Associates" = "USA",

      # GBR
      "Barclays Capital" = "GBR", "Barclays" = "GBR", "ANZ Bank" = "GBR", "ANZ Grindlays Bank" = "GBR",
      "Deutsche Morgan Grenfell" = "GBR", "GlobalData" = "GBR", "HSBC" = "GBR", "IHS Markit" = "GBR",
      "NatWest Markets" = "GBR", "Oxford Economics" = "GBR", "Standard Chartered" = "GBR",
      "Timetric" = "GBR", "HSBC Economics" = "GBR", "HSBC Research" = "GBR", "Smith New Court" = "GBR",

      # NLD
      "ING Financial Markets" = "NLD", "ING" = "NLD", "ING Bank" = "NLD", "ING Barings" = "NLD", "ABN Amro" = "NLD",

      # AUS
      "ANZ Investment Bank" = "AUS",

      # JPN
      "Bank of Tokyo-Mitsubishi" = "JPN", "Mitsubishi UFJ Research" = "JPN", "Mitsubishi Research Institute" = "JPN",
      "Bank of Tokyo-Mitsubishi UFJ" = "JPN", "Bk of Tokyo-Mitsubishi UFJ" = "JPN", "MUFG Bank" = "JPN",
      "Daiwa Research Inst" = "JPN", "Jardine Fleming - Tokyo" = "JPN", "Mizuho Research Institute" = "JPN",
      "Nomura" = "JPN", "Nomura Research Inst" = "JPN", "Sakura Inst of Research" = "JPN",
      "Schroders - Japan" = "JPN",

      # MEX
      "BBVA Bancomer" = "MEX",

      # FRA
      "BNP Paribas" = "FRA", "SG Securities" = "FRA", "Societe Generale" = "FRA",

      # CHE
      "UBS" = "CHE", "UBS Warburg" = "CHE", "Warburg Dillon Read" = "CHE", "Credit Suisse" = "CHE",
      "SG Warburg Securities" = "CHE",

      # CHN
      "Crosby Securities" = "CHN", "SocGen-Crosby" = "CHN", "Soc-Gen Crosby" = "CHN",

      # MYS
      "DBS Bank" = "MYS", "G.K. Goh Securities" = "MYS", "UOB Kay Hian" = "MYS",

      # GER
      "Deutsche Bank" = "GER", "Dresdner Kleinwort" = "GER", "Dresdner Kleinwort Ben." = "GER",
      "Dresdner Bank" = "GER", "Allianz" = "GER", "FAZ InfoDienste" = "GER", "FAZ Institut" = "GER",
      "FERI" = "GER", "ICICI Bank" = "GER", "ICICI Securities" = "GER",

      # IRL
      "Eaton" = "IRL", "Eaton Corporation" = "IRL", "Experian" = "IRL",
      "Experian Business Strat" = "IRL", "Experian Business Strategies" = "IRL",

      # CHN (again)
      "UBS Securities" = "CHN"
    )
  )

  return(data_out)

}






ce_read_cpi <- function(path, lscountries, fy, ly, months) {

  cli::cli_alert_info("Loading CPI data...")

  df.cpi.sum <- df.cpi <- data.frame()

  for (country in lscountries) {
    for (year in fy:ly) {
      for (month in months) {

        print(country)
        print(year)
        print(month)
        print("cpi data")

        grp <- get_country_group(country)
        if (is.null(grp)) next
        file <- build_file_path(path, grp[1], grp[2], month, year)
        if (!file.exists(file)) next
        data <- read_forecast_data(file, country)
        if (is.null(data)) next

        # GDP column
        col_cpi <- get_cpi_column(data, country)
        if (is.null(col_cpi)) next

        # Survey date
        exact.date.survey <- extract_date(data)
        # Forecast years
        y1y2 <- extract_forecast_years(data, country, year, month, col_cpi)
        if (is.null(y1y2)) next

        # Extract data
        parsed <- parse_forecasts(data, col_cpi, y1y2[[1]], y1y2[[2]], exact.date.survey, country)
        df.cpi.sum <- rbind(df.cpi.sum, parsed$summary)
        df.cpi     <- rbind(df.cpi, parsed$individual)
      }
    }
  }

  df.cpi$Value <- as.numeric(df.cpi$Value)
  df.cpi.sum$Value <- as.numeric(df.cpi.sum$Value)

  # Clean
  # remove rows where no institution and value is present:
  df.cpi <- dplyr::anti_join(df.cpi, dplyr::filter(df.cpi, is.na(Value) & is.na(Institution)),
                             by = c("Institution", "Date", "Value"))

  # remove rows in case there is a row of number of forecasts in the final datafrmae:
  df.cpi <- dplyr::anti_join(df.cpi, dplyr::filter(df.cpi, Institution == "Number of Forecasts"),
                             by = c("Institution", "Date", "Value"))

  return(list(summary = df.cpi.sum, individual = df.cpi))

}

get_cpi_column <- function(data, country) {
  cpi_variants <- switch(
    country,
    "UK" = c("Retail Prices (Headline Rate)", "Retail Prices (RPIX)"),
    "Germany" = c("Consumer Prices", "Harmonised Index of Consumer Prices"),
    c("Consumer Prices")
  )

  for (cpi_name in cpi_variants) {
    idx <- which(paste(data[2,], data[3,]) == cpi_name)
    if (length(idx) > 0) return(idx)
  }

  return(NULL)
}


















ce_prep_macro_data <- function(ce_data){

  cli::cli_alert_info("Cleaning and preparing data...")


  # some initial cleaning
  macro_data_c1 <- standardize_institution_names(
    ce_data$individual,
    replacements = list(
      list(old = "American Int'l Group", new = "American International Group"),
      list(old = "American Intl Group", new = "American International Group"),
      list(old = "Amoco", new = "Amoco Corporation"),
      list(old = "Amoco Corp", new = "Amoco Corporation"),
      list(old = "BMO Financial Markets", new = "BMO Capital Markets"),
      list(old = "Brown Brothers", new = "Brown Brothers Harriman"),
      list(old = "Chase", new = "Chase Manhatten Bank"),
      list(old = "Chase Manhatten", new = "Chase Manhatten Bank"),
      list(old = "Chemical Bank", new = "Chemical Banking"),
      list(old = "Core States", new = "CoreStates Financial Corporation"),
      list(old = "CoreStates Fin Corp", new = "CoreStates Financial Corporation"),
      list(old = "CoreStates", new = "CoreStates Financial Corporation"),
      list(old = "CRT Govt Securities", new = "CRT Govt. Securities"),
      list(old = "CS First Boston", new = "Credit Suisse First Boston"),
      list(old = "FannieMae", new = "Fannie Mae"),
      list(old = "Ford Motor", new = "Ford Motor Company"),
      list(old = "Ford Motor Corp", new = "Ford Motor Company"),
      list(old = "Georgia State Uni.", new = "Georgia State University"),
      list(old = "IHS Global Insight", new = "IHS Markit"),
      list(old = "IHS Economics", new = "IHS Markit"),
      list(old = "J P Morgan", new = "JP Morgan"),
      list(old = "Moody's Economy.com", new = "Moody's Analytics"),
      list(old = "Mortgage Bankers", new = "Mortgage Bankers Association"),
      list(old = "Mortgage Bankers Assoc", new = "Mortgage Bankers Association"),
      list(old = "Mortgage Bankers Assoc.", new = "Mortgage Bankers Association"),
      list(old = "Nat Assn Manufacturers", new = "Nat Assn of Manufacturers"),
      list(old = "Nat Assn of Homebuilders", new = "Nat Assn of Home Builders"),
      list(old = "Nat. Ass. of Homebuilders", new = "Nat Assn of Home Builders"),
      list(old = "Natl Assoc of Home Builders", new = "Nat Assn of Home Builders"),
      list(old = "PNC Financial Services", new = "PNC Bank"),
      list(old = "Prudential Insurance", new = "Prudential Financial"),
      list(old = "Regional Financial Ass.", new = "Regional Financial Associates Inc"),
      list(old = "Regional Financial Assocs", new = "Regional Financial Associates Inc"),
      list(old = "Sears Roebuck", new = "Sears Roebuck & Co"),
      list(old = "Smith Barney", new = "Smith Barney Shearson"),
      list(old = "Standard & Poors", new = "Standard & Poor's"),
      list(old = "U.S. Trust", new = "United States Trust"),
      list(old = "Wells Fargo Bank", new = "Wells Fargo"),
      list(old = "WEFA Group", new = "Wharton Econometric Forecasting Associates"),
      list(old = "The WEFA Group", new = "Wharton Econometric Forecasting Associates"),
      list(old = "Economy.com", new = "Moody's Analytics"),
      list(old = "Global Insight", new = "IHS Markit")
    )
  )


  # USA info:  - later on, we might source that out into stata file.
  inst_usa <- ce_prep_usa(macro_data_c1)


  # further cleaning :
  macro_data_c2 <- standardize_institution_names(
    macro_data_c1,
    replacements = list(
      list(old = "Caisse de depot", new = "Caisse de Depot"),
      list(old = "Caisse de Depots", new = "Caisse de Depot"),
      list(old = "Centre for Spatial Econ", new = "Centre for Spatial Economics"),
      list(old = "Centre for Spatial Econ.", new = "Centre for Spatial Economics"),
      list(old = "DRI - Canada", new = "DRI Canada"),
      list(old = "DRI  Canada", new = "DRI Canada"),
      list(old = "Du Pont", new = "DuPont Canada"),
      list(old = "Merrill Lynch - Canada", new = "Merrill Lynch Canada"),
      list(old = "RBC Dominion Securities", new = "RBC - Dominion Securities"),
      list(old = "RBC Dominion", new = "RBC - Dominion Securities"),
      list(old = "Toronto Dominion", new = "Toronto Dominion Bank"),
      list(old = "Conference Board", new = "Conf Board of Canada"),
      list(old = "Royal Trust", new = "Royal Trust (Canada)")
    )
  )

  # CANADA info:  - later on, we might source that out into stata file.
  inst_canada <- ce_prep_canada(macro_data_c2)

  # further cleaning :
  macro_data_c3 <- standardize_institution_names(
    macro_data_c2,
    replacements = list(
      list(old = "KOF Swiss Econ Inst", new = "KOF/ETH"),
      list(old = "KOF Swiss Econ. Inst.", new = "KOF/ETH"),
      list(old = "KOF/ETH Zentrum", new = "KOF/ETH"),
      list(old = "Zurcher Kantonalbank", new = "Zürcher Kantonalbank"),
      list(old = "IHS Global Insight", new = "IHS Markit"),
      list(old = "IHS Economics", new = "IHS Markit"),
      list(old = "Global Insight", new = "IHS Markit"),
      list(old = "Oxford - BAK", new = "Oxford - BAK Basel")
    )
  )



  # SWITZERLAND:
  inst_switzerland <- ce_prep_switzerland(macro_data_c3)

  # further cleaning :
  macro_data_c4 <- standardize_institution_names(
    macro_data_c3,
    replacements = list(
      list(old = "KOF Swiss Econ Inst", new = "KOF/ETH"),
      list(old = "KOF Swiss Econ. Inst.", new = "KOF/ETH"),
      list(old = "KOF/ETH Zentrum", new = "KOF/ETH"),
      list(old = "Zurcher Kantonalbank", new = "Zürcher Kantonalbank"),
      list(old = "IHS Global Insight", new = "IHS Markit"),
      list(old = "IHS Economics", new = "IHS Markit"),
      list(old = "Global Insight", new = "IHS Markit"),
      list(old = "Oxford - BAK", new = "Oxford - BAK Basel"),
      list(old = "Erik Penser FK", new = "Erik Penser Bank"),
      list(old = "Hagglof - SBC Warburg", new = "Hagglof - SG Warburg"),
      list(old = "Hagstromer & Qviberg", new = "Hagströmer & Qviberg"),
      list(old = "SBAB", new = "SBAB Bank"),
      list(old = "Volvo Group Finance", new = "Volvo"),
      list(old = "HQ Bank", new = "Hagströmer & Qviberg Bank"),
      list(old = "Hagströmer & Qviberg", new = "Hagströmer & Qviberg Bank"),
      list(old = "Matteus FK", new = "Matteus Fondkommission"),
      list(old = "Matteus Bank", new = "Matteus Fondkommission"),
      list(old = "Ohman", new = "Öhman Mutual Funds and Asset Management"),
      list(old = "Öhman", new = "Öhman Mutual Funds and Asset Management"),
      list(old = "Aragon", new = "Aragon Fondkommission"),
      list(old = "Finanskonsult", new = "Ficope Finanskonsult"),
      list(old = "ITEM Club", new = "EY Item Club"),
      list(old = "SE Banken", new = "Skandinaviska Enskilda Banken")
    )
  )


  # SWEDEN
  inst_sweden <- ce_prep_sweden(macro_data_c4)


  # further cleaning :
  macro_data_c5 <- standardize_institution_names(
    macro_data_c4,
    replacements = list(
      list(old = "Bank of Tokyo", new = "Bank of Tokyo-Mitsubishi UFJ"),
      list(old = "Bank of Tokyo - London", new = "Bank of Tokyo-Mitsubishi UFJ"),
      list(old = "Bank of Tokyo Mitsubishi", new = "Bank of Tokyo-Mitsubishi UFJ"),
      list(old = "Barclays", new = "Barclays Capital Group", country = "Japan"),
      list(old = "Barclays Capital", new = "Barclays Capital Group", country = "Japan"),
      list(old = "Citigroup Japan", new = "Citigroup Global Mkts Japan"),
      list(old = "BDai-ichi Kangyo Bank", new = "Dai-Ichi Kangyo Bank"),
      list(old = "Dai-Ichi Kangyo Rsrch Inst", new = "Dai-Ichi Kangyo Bank"),
      list(old = "Dai-Ichi Kangyo Rsrch Institute", new = "Dai-Ichi Kangyo Bank"),
      list(old = "Dai-Ichi Life Research", new = "Dai-Ichi Kangyo Bank"),
      list(old = "Dai-ichi Kangyo Bank", new = "Dai-Ichi Kangyo Bank"),
      list(old = "Daiwa Institute of Research", new = "Daiwa Securities Research"),
      list(old = "Daiwa Institute of Rsrch", new = "Daiwa Securities Research"),
      list(old = "Daiwa Securities Rsrch", new = "Daiwa Securities Research"),
      list(old = "Deutsche Securities", new = "Deutsche Bank (Asia)"),
      list(old = "Deutsche Bank  (Asia)", new = "Deutsche Bank (Asia)"),
      list(old = "Dresdner Kleinwort Asia", new = "Dresdner Kleinwort (Asia)"),
      list(old = "Dresdner Kleinwort Benson", new = "Dresdner Kleinwort (Asia)"),
      list(old = "Jap Ctr for Econ Rsrch", new = "Japan Ctr for Econ Research"),
      list(old = "Japan Ctr Economic Rsrch", new = "Japan Ctr for Econ Research"),
      list(old = "Kokumin Keizai Research Inst", new = "Kokumin Keizai Research Inst."),
      list(old = "Mitsubishi Research", new = "Mitsubishi Research Institute"),
      list(old = "Mitsubishi Research Inst", new = "Mitsubishi Research Institute"),
      list(old = "Mitsubishi Research Institute", new = "Mitsubishi Research Institute"),
      list(old = "Mitsubishi Rsrch", new = "Mitsubishi Research Institute"),
      list(old = "Nikko Citigroup", new = "Nikko Salomon Smith Barney"),
      list(old = "Nippon Steel Rsch Inst Corp", new = "Nippon Steel Research Institute"),
      list(old = "Nippon Steel & Sumikin Res Inst", new = "Nippon Steel Research Institute"),
      list(old = "Nippon Steel & Sumikin Rsrch", new = "Nippon Steel Research Institute"),
      list(old = "Nomura Rsrch Center", new = "Nomura Research Institute"),
      list(old = "Nomura Securities", new = "Nomura Research Institute"),
      list(old = "S G Warburg - Japan", new = "SG Warburg - Japan"),
      list(old = "S G Warburg - Tokyo", new = "SG Warburg - Japan"),
      list(old = "SG Warburg - Japan", new = "SG Warburg - Japan"),
      list(old = "SBC Warburg - Japan", new = "SG Warburg - Japan"),
      list(old = "Salomon Smith Barney", new = "Salomon Smith Barney Asia (Citigroup)"),
      list(old = "Salomon Smith Barney Asia", new = "Salomon Smith Barney Asia (Citigroup)"),
      list(old = "Salomon Brothers Asia", new = "Salomon Brothers Asia Ltd."),
      list(old = "Sumitomo Bank", new = "Sumitomo Life Research Institute"),
      list(old = "Sumitomo Life Rsrch Institute", new = "Sumitomo Life Research Institute"),
      list(old = "Sanwa Research Institute", new = "Sanwa Research Institute Corp."),
      list(old = "Schroder Securities", new = "Schroders - Japan"),
      list(old = "Schroders", new = "Schroders - Japan"),
      list(old = "UBS - Phillips & Drew", new = "UBS Phillips & Drew (Securities) Tokyo"),
      list(old = "UBS - Phillips & Drew - Tokyo", new = "UBS Phillips & Drew (Securities) Tokyo"),
      list(old = "UBS  Phillips & Drew - Tokyo", new = "UBS Phillips & Drew (Securities) Tokyo"),
      list(old = "UBS  Securities- Tokyo", new = "UBS Phillips & Drew (Securities) Tokyo"),
      list(old = "UBS  Securities - Tokyo", new = "UBS Phillips & Drew (Securities) Tokyo"),
      list(old = "UBS Securities - Japan", new = "UBS Phillips & Drew (Securities) Tokyo"),
      list(old = "UBS Phillips & Drew", new = "UBS Phillips & Drew (Securities) Tokyo"),
      list(old = "Yamaichi Rsrch Institute", new = "Yamaichi Research Institute"),
      list(old = "Smith Barney - Japan", new = "Smith Barney (Shearson) Tokyo"),
      list(old = "Smith Barney - Tokyo", new = "Smith Barney (Shearson) Tokyo"),
      list(old = "Smith Barney Shearson - Tokyo", new = "Smith Barney (Shearson) Tokyo"),
      list(old = "Smith Barney Shersn - Tokyo", new = "Smith Barney (Shearson) Tokyo"),
      list(old = "Jardine Fleming", new = "Jardine Fleming - Tokyo"),
      list(old = "Long Term Credit Bank", new = "Long Term Credit Bank Japan"),
      list(old = "LTCB", new = "Long Term Credit Bank Japan"),
      list(old = "NCB Research Institute", new = "Nippon Credit Bank"),
      list(old = "Nikko Rsrch Center", new = "Nikko Research Center")
    )
  )

  # JAPAN
  inst_japan <- ce_prep_japan(macro_data_c5)


  # further cleaning
  macro_data_c6 <- standardize_institution_names(
    macro_data_c5,
    replacements = list(
      list(old = "Banamex-Citi", new = "Banamex"),
      list(old = "Banamex", new = "Banamex"),
      list(old = "Bancomer", new = "BBVA Bancomer"),
      list(old = "Bancomer Centro", new = "BBVA Bancomer"),
      list(old = "BBVA", new = "BBVA Bancomer", country = "Mexico"),
      list(old = "BofAML", new = "Bank of America Merrill Lynch"),
      list(old = "BPI", new = "Banco BPI"),
      list(old = "CEESP", new = "Commission on Environmental, Economic and Social Policy (CEESP)"),
      list(old = "Center Klein F'casting", new = "Center Klein Forecasting"),
      list(old = "CKF-Forecasting", new = "Center Klein Forecasting"),
      list(old = "Deutsche Bank Rsrch", new = "Deutschebank Research"),
      list(old = "ESANE", new = "ESANE Consultores SC"),
      list(old = "ESANE Consultores", new = "ESANE Consultores SC"),
      list(old = "Grupo Bursatil", new = "Grupo Bursatil Mexicano"),
      list(old = "Grupo Financ Inverlat", new = "Grupo Financiero Inverlat"),
      list(old = "Heath & Associates", new = "Heath and Associates"),
      list(old = "Heath y Associates", new = "Heath and Associates"),
      list(old = "JP Morgan Chase Mex", new = "JP Morgan Mexico"),
      list(old = "RGE", new = "RGE Monitor"),
      list(old = "Scotia Inverlat", new = "Scotiabank Inverlat"),
      list(old = "American Chamber Mex", new = "American Chamber Of Commerce Of México A.C."),
      list(old = "CAPEM", new = "Grupo CAPEM"),
      list(old = "Casa de Bolsa Inverlat", new = "Grupo Financiero Scotiabank"),
      list(old = "Scotiabank", new = "Grupo Financiero Scotiabank"),
      list(old = "Scotiabank Inverlat", new = "Grupo Financiero Scotiabank"),
      list(old = "Grupo Financiero Inverlat", new = "Grupo Financiero Scotiabank"),
      list(old = "Consultores Econ", new = "Consultores Economicos"),
      list(old = "EIU", new = "Econ Intelligence Unit"),
      list(old = "Interacciones", new = "Banco Interacciones, SA"),
      list(old = "Heath and Associates", new = "Jonathan Heath & Assoc"),
      list(old = "Prognosis", new = "Prognosis Economia Finanzas e Inversiones, S.C."),
      list(old = "RGE Monitor", new = "Roubini Global Econ")
    )
  )


  # MEXICO:
  inst_mexico <- ce_prep_mexico(macro_data_c6)

  # further cleaning :
  macro_data_c7 <- standardize_institution_names(
    macro_data_c6,
    replacements = list(
      list(old = "BBV", new = "BBV Latinvest"),
      list(old = "BBV Securities", new = "BBV Latinvest"),
      list(old = "Credit Lyonnais -  Arg", new = "Credit Lyonnais Argentina"),
      list(old = "Credit Lyonnais Arg", new = "Credit Lyonnais Argentina"),
      list(old = "Jorge Avila y Asociades", new = "Jorge Avila y Asociados"),
      list(old = "M A Broda y Asociades", new = "M A Broda & Asociados"),
      list(old = "M A Broda y Asociados", new = "M A Broda & Asociados"),
      list(old = "MVA Macroeconomia", new = "MVAS Macroeconomia"),
      list(old = "ACM", new = "ACM Research"),
      list(old = "Delphos", new = "Delphos Investment"),
      list(old = "Econometrica", new = "Econométrica S.A. - Novedades"),
      list(old = "EXANTE", new = "Exante Consultora"),
      list(old = "Exante", new = "Exante Consultora"),
      list(old = "FIEL", new = "Fundación de Investigaciones Económicas Latinoamericanas (FIEL)"),
      list(old = "FASEL", new = "Fundación para el Análisis Socioeconómico de Latinoamérica (FASEL)"),
      list(old = "Fundacion Mediterranea", new = "IERAL Fundacion Mediterranea"),
      list(old = "IERAL Fund", new = "IERAL Fundacion Mediterranea"),
      list(old = "IERAL Fund Mediterranea", new = "IERAL Fundacion Mediterranea"),
      list(old = "LCG Consultora", new = "LCG. Consultora Labour Capital & Growth"),
      list(old = "M A Broda & Asociados", new = "Macro Fundamentals - Estudio Broda y Asociados"),
      list(old = "Macroeconomica", new = "MVAS Macroeconomia"),
      list(old = "Orlando Ferreres", new = "Orlando Ferreres & Asoc"),
      list(old = "Puente", new = "Puente Hnos"),
      list(old = "West Merchant Bank", new = "West Merchant Bank Ltd")
    )
  )

  macro_data_c7 <- standardize_institution_names(
    macro_data_c7,
    replacements = list(
      list(old = "M A Broda & Asociados", new = "Macro Fundamentals - Estudio Broda y Asociados")
    )
  )

  # ARGENTINA
  inst_argentina <- ce_prep_argentina(macro_data_c7)


  # further cleaning:
  macro_data_c8 <- standardize_institution_names(
    macro_data_c7,
    replacements = list(
      list(old = "Banco da Bahia", new = "Banco da Bahia Invest"),
      list(old = "C Contador e Asocs", new = "C Contador & Asocs"),
      list(old = "Grupo Bursatil Mex", new = "Grupo Bursatil Mexicano"),
      list(old = "J.P. Morgan", new = "JP Morgan"),
      list(old = "M B Asociados", new = "M B Associadosn"),
      list(old = "MB Associados", new = "M B Associadosn"),
      list(old = "IPEA", new = "IPEA - Instituto de Pesquisa Econômica Aplicada"),
      list(old = "Rosenberg", new = "Rosenberg Consultoria"),
      list(old = "UFRJ", new = "UFRJ Universidade Federal do Rio de Janeiro"),
      list(old = "Univ. Federal do RJ", new = "UFRJ Universidade Federal do Rio de Janeiro"),
      list(old = "Unibanco", new = "Itau Unibanco")
    )
  )



  # BRAZIL
  inst_brazil <- ce_prep_brazil(macro_data_c8)


  # further cleaning:
  macro_data_c9 <- standardize_institution_names(
    macro_data_c8,
    replacements = list(
      list(old = "Credit Suisse First Bstn", new = "Credit Suisse First Boston"),
      list(old = "G.K. Goh", new = "G.K. Goh Securities"),
      list(old = "GK Goh Securities", new = "G.K. Goh Securities"),
      list(old = "Mizuho Research Inst", new = "Mizuho Research Institute"),
      list(old = "Oxford Econ Forecast", new = "Oxford Economics"),
      list(old = "Oxford Econ Forecasting", new = "Oxford Economics"),
      list(old = "SSB/Citibank", new = "Salomon Smith Barney Asia (Citigroup)"),
      list(old = "SSB Citibank", new = "Salomon Smith Barney Asia (Citigroup)"),
      list(old = "Standard Chartered Bank", new = "Standard Chartered"),
      list(old = "UOB Kayhian", new = "UOB Kay Hian"),
      list(old = "UOB KayHian", new = "UOB Kay Hian"),
      list(old = "WI Carr", new = "W.I.Carr")
    )
  )


  # CHINA:
  inst_china <- ce_prep_china(macro_data_c9)

  # further cleaning:
  macro_data_c10 <- standardize_institution_names(
    macro_data_c9,
    replacements = list(
      list(old = "CMB Research", new = "Chase Manhattan Rsrch"),
      list(old = "Natl Cncil Apl Eco Rsrch", new = "National Council of Applied Economic Research - India"),
      list(old = "W.I.Carr", new = "W.I.Carr")  # redundant but kept as is
    )
  )


  # INDIA:
  inst_india <- ce_prep_india(macro_data_c10)



  # list of institutions:
  list_inst <- list(inst_usa, inst_canada, inst_switzerland, inst_sweden,
                    inst_japan, inst_mexico, inst_argentina, inst_brazil,
                    inst_china, inst_india)



  ce_stata <- ce_prep_data_stata(data = list(data_individual = macro_data_c10,
                                             data_sum = ce_data$summary),
                                 institution_info = list_inst
  )


  return(ce_stata)


}





ce_prep_data_stata <- function(data, institution_info){

  ind <- data$data_individual
  sum <- data$data_sum


  all_inst <- bind_rows(institution_info)

  ind <- ind %>%
    dplyr::full_join(all_inst,by=c("Institution","Country"))

  ind_f <- ind |>
    mutate(Country = replace(Country, Country == "USA", "United States"),
           Country = replace(Country, Country == "UK", "United Kingdom")) |>
    select(Country, Date, Institution, Year, Value, current, local, local.2, source, headquarter) |>
    rename_with(tolower) |>
    mutate(local = as.factor(local),
           local.2 = as.factor(local.2),
           current = as.factor(current)
    ) |>
    rename(year_forecast = year) |>
    mutate(headquarter = replace(headquarter, headquarter == "Argentina", "ARG"),
           headquarter = replace(headquarter, headquarter == "Japan", "JPN"),
           headquarter = replace(headquarter, headquarter == "China", "CHN"),
           headquarter = replace(headquarter, headquarter == "Sweden", "SWE"),
           headquarter = replace(headquarter, headquarter == "Switzerland", "CHE"),
           headquarter = replace(headquarter, headquarter == "Mexico", "MEX"),
           headquarter = replace(headquarter, headquarter == "Canada", "CAN"),
           headquarter = replace(headquarter, headquarter == "India", "IND"),
           headquarter = replace(headquarter, headquarter == "Brazil", "BRA")
           ) |>
    filter(!is.na(date))

  sum_f <- sum |>
    mutate(Country = replace(Country, Country == "USA", "United States")) |>
    select(Country, Date, Measure, Year, Value, current) |>
    rename_with(tolower) |>
    rename(year_forecast = year) |>
    filter(!is.na(date))


  return(list(df_stata = ind_f,
              df_stata_sum = sum_f)
  )


}



ce_write_data <- function(data_input, indicator = "gdp") {
  cli::cli_alert_info("Writing {toupper(indicator)} data...")

  # Remove columns from main data
  clean_data <- data_input[["df_stata"]] |>
     dplyr::rename(local_2 = local.2)

  clean_summary <- data_input[["df_stata_sum"]]

  # Prepare for Stata and RDS
  stata <- list()
  stata[[paste0("df_", indicator, "_stata")]] <- clean_data
  stata[[paste0("df_", indicator, "_stata_sum")]] <- clean_summary

  # Write files to disk
  success <- c(
    safe_write(haven::write_dta(clean_data, path = glue::glue("inst/data/produced/ce/df_{indicator}_stata.dta")), paste("Stata", toupper(indicator), "data")),
    safe_write(haven::write_dta(clean_summary, path = glue::glue("inst/data/produced/ce/df_{indicator}_stata_sum.dta")), paste("Stata", toupper(indicator), "summary")),
    safe_write(saveRDS(clean_data, file = glue::glue("inst/data/produced/ce/df_{indicator}_stata.rds")), paste("RDS", toupper(indicator), "data")),
    safe_write(saveRDS(clean_summary, file = glue::glue("inst/data/produced/ce/df_{indicator}_stata_sum.rds")), paste("RDS", toupper(indicator), "summary"))
  )

  if (all(success)) {
    cli::cli_alert_success("All {toupper(indicator)} data written successfully.")
  } else {
    cli::cli_alert_warning("Some files failed to write for {toupper(indicator)}.")
  }
}


# Safe writing helper
safe_write <- function(expr, file_label) {
  tryCatch({
    expr
    cli::cli_alert_success("{file_label} written successfully.")
    TRUE
  }, error = function(e) {
    cli::cli_alert_danger("Failed to write {file_label}: {e$message}")
    FALSE
  })
}
