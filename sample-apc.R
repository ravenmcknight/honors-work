## Goal: sample 490 billion rows of apc data to get more workable size
# stratify by PICK_START_DATE, service_id, date_key, line_id, line_direction, trip_number, StopID
# this should make sure that every type of trip at every location is represented
# take 10% sample

## packages -----------------------------------------------

# these lines make sure any user has all the necessary packages!
packages <- c('data.table', 'splitstackshape')

miss_pkgs <- packages[!packages %in% installed.packages()[,1]]

if(length(miss_pkgs) > 0){
  install.packages(miss_pkgs)
}

invisible(lapply(packages, library, character.only = TRUE))

rm(miss_pkgs, packages)


## data ---------------------------------------------------
apcboth <- readRDS('data/apc-interpolated.RDS')
setDT(apcboth)

## sample -------------------------------------------------

# using the splitstackshape package
apc_sample <- stratified(apcboth, group = c('date_key', 'service_id', 'line_id', 'line_direction', 'site_id'), size = 0.1)

saveRDS(apc_sample, 'data/apc-sample.RDS')
