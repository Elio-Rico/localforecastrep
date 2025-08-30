

# Read the .dta file
dr <- haven::read_dta("/Users/ebollige/Dropbox/1_1_replication_forecasters/localforecastrep/inst/data/produced/ce/df_gdp_stata.dta")

# View the first rows
old <- haven::read_dta("/Users/ebollige/Dropbox/1_1_replication_forecasters/localforecastrep/inst/data/raw/ce/Codes/data_output/df_gdp_stata.dta") |>
  dplyr::rename(value = gdprpc) |>
  dplyr::select(country, date, institution, year_forecast, value, current, local, local_2, source, headquarter)

head(dr)
head(old)

# a few tests:
without_local_src_hq_dr <- dr |>
  select(-c(local, local_2, source, headquarter))

without_local_src_hq_old <- old |>
  select(-c(local, local_2, source, headquarter))

diff <- anti_join(without_local_src_hq_dr, without_local_src_hq_old)



aunew <- without_local_src_hq_dr |> filter(institution == "OXFORD-LBS" & year_forecast == 2006 & country == "Austria" &
                                             date == "2006-03-13")
auold <- without_local_src_hq_old |> filter(institution == "OXFORD-LBS" & year_forecast == 2006 & country == "Austria" &
                                              date == "2006-03-13")

anti_join(aunew, auold)


sapply(names(aunew), function(col) identical(aunew[[col]], auold[[col]]))

aunew$value - auold$value


# a few tests:
# Round numeric columns before joins/comparisons
round_df <- function(df, digits = 6) {
  df %>% mutate(across(where(is.numeric), ~ round(.x, digits)))
}

aunew_rounded <- round_df(without_local_src_hq_dr)
auold_rounded <- round_df(without_local_src_hq_old)

diff_to_check <- anti_join(aunew_rounded, auold_rounded)


aunew <- without_local_src_hq_dr |> filter(institution == "Citigroup" & year_forecast == 2017 & country == "Slovakia" &
                                             date == "2016-03-14")
auold <- without_local_src_hq_old |> filter(institution == "Citigroup" & year_forecast == 2017 & country == "Slovakia" &
                                              date == "2016-03-14")

aunew <- without_local_src_hq_dr |> filter(institution == "Oxford Economics" & year_forecast == 2019 & country == "India" &
                                             date == "2019-06-10")
auold <- without_local_src_hq_old |> filter(institution == "Oxford Economics" & year_forecast == 2019 & country == "India" &
                                              date == "2019-06-10")

# we see that the only difference is due to UKRAINE (when we discard rounding differences). should be ok therefore :)
