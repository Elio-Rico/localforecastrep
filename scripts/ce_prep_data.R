
devtools::load_all(".")
library("tidyverse")
library("haven")
library("cli")


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


# load gdp data:
gdp_data <- ce_prep_gdp(path = path_ce(),
                 lscountries = list_of_countries,
                 fy = first.year,
                 ly = last.year,
                 months = list.of.months
                 )


saveRDS(gdp_data, file = "inst/data/produced/ce/gdp_data.rds")


# prep and finalise data:
gdp_stata_final <- ce_prep_macro_data(ce_data = gdp_data)

# write gdp data
ce_write_data(data_input = gdp_stata_final,
              indicator = "gdp")




# ---------------------
# Inflation
# ---------------------

cpi_data <- ce_prep_cpi(path = path_ce(),
                        lscountries = list_of_countries,
                        fy = first.year,
                        ly = last.year,
                        months = list.of.months
)



saveRDS(cpi_data, file = "inst/data/produced/ce/cpi_data.rds")


# prep and finalise data:
cpi_stata_final <- ce_prep_macro_data(ce_data = cpi_data)

# write gdp data
ce_write_data(data_input = cpi_stata_final,
              indicator = "cpi")

# ---------------------
# end of code
# ---------------------

