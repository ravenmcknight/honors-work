# Goal: get census variables of interest, 2015-2017

## packages -----------------------------------------------

packages <- c('data.table', 'tigris', 'tidycensus', 'purrr')

miss_pkgs <- packages[!packages %in% installed.packages()[,1]]

if(length(miss_pkgs) > 0){
  install.packages(miss_pkgs)
}

invisible(lapply(packages, library, character.only = TRUE))

rm(miss_pkgs, packages)

options(tigris_class = 'sf')


## acs variables ------------------------------------------

# look at acs 5yr estimates for 2015
v15 <- load_variables(2016, "acs5", cache = TRUE)
setDT(v15)
View(v15)

# start by pulling some basics for a first model
# this document will likely be updated often as I go
counties <- c('Anoka', 'Carver', 'Dakota', 'Hennepin', 'Ramsey', 'Scott', 'Washington')

# 2018 acs not out yet
years <- list(2015, 2016, 2017)

basics <- map_dfr(
  years,
  ~ get_acs(
    geography = "block group",
    variables = c(tot_pop = "B00001_001",
                  tot_no_veh = "B08201_002",
                  median_age = "B01002_001",
                  median_hh_income = "B19013_001",
                  speak_only_english = "B16001_002",
                  white_alone = "B02001_002"),
    state = "MN",
    county = counties,
    year = .x,
    survey = "acs5"
  ),
  .id = "year"
)

saveRDS(basics, 'data/covariates/basic_acs.RDS')

## employment data ----------------------------------------

# i'll use the employment data i cleaned here:
# https://github.com/ravenmcknight/LODES-analysis/blob/master/get-ts-data.R
# add year restrictions here

od_jobs <- readRDS('/Users/raven/Documents/projects/LODES-analysis/data/od_jobs.RDS')
setDT(od_jobs)
od_jobs <- od_jobs[year %in% years]
saveRDS(od_jobs, 'data/covariates/od_jobs.RDS')

tot_jobs <- readRDS('/Users/raven/Documents/projects/LODES-analysis/data/tot_jobs.RDS')
setDT(tot_jobs)
tot_jobs <- tot_jobs[year %in% years]
saveRDS(tot_jobs, 'data/covariates/tot_jobs.RDS')
