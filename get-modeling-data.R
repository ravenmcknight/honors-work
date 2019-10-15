## Goal: fix my terrible practices which have lead to totally irreproducible data! woo!


packages <- c('data.table', 'tigris', 'ggplot2')

miss_pkgs <- packages[!packages %in% installed.packages()[,1]]

if(length(miss_pkgs) > 0){
  install.packages(miss_pkgs)
}

invisible(lapply(packages, library, character.only = TRUE))

rm(miss_pkgs, packages)

options(tigris_class = 'sf')


## Get 2017 average daily activity --------------

apc <- readRDS('/Users/raven/Documents/honors/honors-work/data/mt-data/apc-bg-ag-sum.RDS')
setDT(apc)

# restrict to 2017
apc <- apc[date_key %like% 2017]
apc <- apc[, .(avg_activity = mean(ag_board + ag_alight)), by = GEOID]

# add basic acs
acs <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/basic_acs.RDS')
setDT(acs)
acs <- acs[year == 3]
apc <- apc[acs, on = 'GEOID']

apc[, avg_act_per_capita := mean(avg_activity/estimate_tot_pop), by = 'GEOID']

educ <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/education.RDS')
house_veh <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/housing-and-vehicles.RDS')
language <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/language.RDS')
nativity <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/nativity.RDS')
employment <- readRDS('/Users/raven/Documents/honors/honors-work/data/covariates/wac/wac-2017.RDS')
setDT(educ)
setDT(house_veh)
setDT(language)
setDT(nativity)
setDT(employment)

mod_dat <- apc[educ[year == 3, c('perc_hs', 'perc_bach', 'GEOID')], on = 'GEOID']
mod_dat <- mod_dat[house_veh[year == 3, c('GEOID', 'perc_rent', 'perc_owner_occ', 'perc_no_veh')], on = 'GEOID']
mod_dat <- mod_dat[language[year == 3, c('GEOID', 'perc_english_only')], on = 'GEOID']

setnames(nativity, 'GEOID', 'tract_GEOID')
mod_dat[, tract_GEOID := substr(GEOID, 1, 11)]

mod_dat <- mod_dat[nativity[year == 3, c('tract_GEOID', 'perc_native', 'perc_foreign')], on = 'tract_GEOID']
mod_dat <- mod_dat[employment[, c('GEOID', 'total_jobs_here')], on = 'GEOID']

counties <- c("Anoka", "Carver", "Dakota", "Hennepin", "Ramsey", "Scott", "Washington")
bgs <- block_groups("MN", counties, 2016)

mod_dat <- left_join(bgs, mod_dat, on = 'GEOID')
setDT(mod_dat)

mod_dat[, sqkm := ALAND/1000000]
mod_dat[, emp_density := total_jobs_here/sqkm]
mod_dat[, log_avg_act := log(avg_act_per_capita)]
mod_dat[, c('STATEFP', 'COUNTYFP', 'TRACTCE', 'BLKGRPCE', 'NAMELSAD', 'MTFCC', 'FUNCSTAT', 
            'ALAND', 'AWATER', 'INTPTLAT', 'INTPTLON', 'NAME', 'geometry') := NULL]

saveRDS(mod_dat, 'data/ag-2017-mod-dat.RDS')
