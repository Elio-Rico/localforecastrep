get_country_group <- function(country) {

  eastern.countries <- c("Bulgaria","Croatia","Czech Republic","Estonia","Hungary","Poland","Russia","Turkey","Latvia",
                         "Lithuania","Romania","Slovakia","Slovenia","Ukraine")

  latinamerica.countries <- c("Argentina","Brazil","Chile","Mexico","Venezuela","Colombia","Peru")

  asiapacific.countries <- c("Australia","China","India","Indonesia","Japan","Malaysia","New Zealand","Philippines",
                             "South Korea","Thailand")

  g7.countries <- c("USA","Japan","Germany","France","UK","Italy","Canada","Netherlands","Norway","Spain","Sweden",
                    "Switzerland","Austria","Belgium","Denmark","Egypt","Finland","Greece","Ireland","Israel",
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



ce_prep_gdp <- function(path, lscountries, fy, ly, months) {

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




standardize_institution_names <- function(df) {
  # Define all alternative names mapping to standardized names
  replacements <- c(
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
    "Global Insight" = "IHS Markit"
  )

  dfclean <- df %>%
    mutate(Institution = recode(Institution, !!!replacements))

  return(dfclean)
}





prepare_institution_info <- function(df,
                                     country_name,
                                     local_list,
                                     multinational_list,
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





standardize_institution_names_2 <- function(df) {
  # Define all alternative names mapping to standardized names
  replacements <- c(
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
    "Royal Trust" = "Royal Trust (Canada)"
  )

  dfclean <- df %>%
    mutate(Institution = recode(Institution, !!!replacements))

  return(dfclean)
}
