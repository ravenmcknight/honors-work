## Goal: get 2017 covariate data

packages <- c('data.table', 'tigris', 'ggplot2', 'dplyr', 'rgdal', 'sf')

miss_pkgs <- packages[!packages %in% installed.packages()[,1]]

if(length(miss_pkgs) > 0){
  install.packages(miss_pkgs)
}

invisible(lapply(packages, library, character.only = TRUE))

rm(miss_pkgs, packages)

options(tigris_class = 'sf')

# add basic acs
acs <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/basic_acs.RDS')
setDT(acs)
acs <- acs[year == 3]

educ <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/education.RDS')
house_veh <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/housing-and-vehicles.RDS')
language <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/language.RDS')
nativity <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/nativity.RDS')
wac <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/wac/all-wac.RDS')
rac <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/rac/all-rac.RDS')
acs_emp <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/acs-emp.RDS')
walk <- readRDS('/Users/raven/Documents/honors/honors-work/data/isochrones/bg_isos_1122.RDS')
setDT(educ)
setDT(house_veh)
setDT(language)
setDT(nativity)
setDT(wac)
setDT(rac)
setDT(acs_emp)

acs[, year := NULL]
acs[, NAME := NULL]

mod_dat <- acs[educ[year == 3, c('perc_hs', 'perc_bach', 'GEOID')], on = 'GEOID', all = TRUE]
mod_dat <- mod_dat[house_veh[year == 3, c('GEOID', 'perc_rent', 'perc_owner_occ', 'perc_no_veh')], on = 'GEOID', all = TRUE]
mod_dat <- mod_dat[language[year == 3, c('GEOID', 'perc_english_only')], on = 'GEOID', all = TRUE]

setnames(nativity, 'GEOID', 'tract_GEOID')
mod_dat[, tract_GEOID := substr(GEOID, 1, 11)]

mod_dat <- mod_dat[nativity[year == 3, c('tract_GEOID', 'perc_native', 'perc_foreign')], on = 'tract_GEOID', all = TRUE]

wac <- wac[year == 2017]
wac <- wac[, c("w_total_jobs_here", "GEOID", "w_perc_jobs_white", "w_perc_jobs_men", "w_perc_jobs_no_college", 
               "w_perc_jobs_less40", "w_perc_jobs_age_less30")]

rac <- rac[year == 2017]
rac <- rac[, c("GEOID", "tot_jobs", "perc_jobs_white", "perc_jobs_men", "perc_jobs_no_college", 
               "perc_jobs_less40", "perc_jobs_age_less30")]

mod_dat <- mod_dat[wac, on = 'GEOID', all = TRUE]
mod_dat <- mod_dat[rac, on = 'GEOID', all = TRUE]
acs_emp <- acs_emp[year == "3", c("GEOID", "perc_transit_comm")]
setnames(acs_emp, "GEOID", "tract_GEOID")
mod_dat <- mod_dat[acs_emp, on = 'tract_GEOID', all = TRUE]

mod_dat <- mod_dat[walk[, c('GEOID', 'walkability')], on = 'GEOID', all = TRUE]
mod_dat[, walkability := as.numeric(walkability)]

counties <- c("Anoka", "Carver", "Dakota", "Hennepin", "Ramsey", "Scott", "Washington")
bgs <- block_groups("MN", counties, 2016)

mod_dat <- left_join(bgs, mod_dat, on = 'GEOID')
setDT(mod_dat)

mod_dat[, sqkm := ALAND/1000000]
mod_dat[, emp_density := w_total_jobs_here/sqkm]
mod_dat[, pop_density := estimate_tot_pop/sqkm]
mod_dat[, c('STATEFP', 'COUNTYFP', 'TRACTCE', 'BLKGRPCE', 'NAMELSAD', 'MTFCC', 'FUNCSTAT', 
            'ALAND', 'AWATER', 'INTPTLAT', 'INTPTLON', 'geometry') := NULL]

# save un-standardized
saveRDS(mod_dat, 'data/ag-2017-dat.RDS')

## standardize ------------------------

# alicia: log, then standardize
small_dat <- mod_dat[, c("GEOID", "estimate_median_hh_income", "perc_only_white", "walkability",
                         "perc_hs", "perc_bach", "perc_rent", "perc_no_veh", "perc_english_only", "perc_foreign",
                         "emp_density", "tot_jobs", "perc_jobs_white", "perc_jobs_men", "perc_jobs_no_college", 
                         "perc_jobs_less40", "perc_jobs_age_less30", "w_total_jobs_here", "w_perc_jobs_white", 
                         "w_perc_jobs_men", "w_perc_jobs_no_college", "w_perc_jobs_less40", "w_perc_jobs_age_less30", 
                         "sqkm", "estimate_tot_pop", "estimate_median_age", "perc_transit_comm", "pop_density")]
setDT(small_dat)

# for modeling
small_dat[small_dat == 0] <- 0.01

# log
logged_dat <- lapply(small_dat[, -c('GEOID')], log)
logged_dat$GEOID <- small_dat$GEOID
setDT(logged_dat)

# scale
scaled_dat <- lapply(logged_dat[, -c('GEOID')], scale)
scaled_dat$GEOID <- logged_dat$GEOID
scaled_dat <- as.data.table(scaled_dat)

saveRDS(scaled_dat, 'data/ag_2017_scaled_mod.RDS')
