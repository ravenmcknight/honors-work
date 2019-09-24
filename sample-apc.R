## Goal: sample 490 billion rows of apc data to get more workable size
# stratify by PICK_START_DATE, service_id, date_key, line_id, line_direction, StopID
# this should make sure that every type of trip at every location is represented
# take 10% sample

## packages -----------------------------------------------

# these lines make sure any user has all the necessary packages!
packages <- c('data.table', 'splitstackshape', 'ggplot2', 'rgdal', 'sf', 'dplyr')

miss_pkgs <- packages[!packages %in% installed.packages()[,1]]

if(length(miss_pkgs) > 0){
  install.packages(miss_pkgs)
}

invisible(lapply(packages, library, character.only = TRUE))

rm(miss_pkgs, packages)


## data ---------------------------------------------------
apcboth <- readRDS('data/mt-data/apc-interpolated.RDS')
setDT(apcboth)

## sample -------------------------------------------------

# using the splitstackshape package
apc_sample <- stratified(apcboth, group = c('date_key', 'service_id', 'line_id', 'line_direction', 'site_id'), size = 0.1)

saveRDS(apc_sample, 'data/apc-sample.RDS')



## test sample --------------------------------------------
apc_sample <- readRDS('data/mt-data/apc-sample.RDS')
setDT(apc_sample)
summary(apcboth$board)
summary(apc_sample$board)
# if modeling at stop level, will need to consider the number of 0s

# make sure we didn't lose any locations:
length(unique(apcboth$site_id))
length(unique(apc_sample$site_id))
# uh oh... missing 3740

missing_stops <- apcboth[!site_id %in% apc_sample$site_id]$site_id
missing_stops <- unique(missing_stops)
missing_stops <- data.frame(missing_stops)
missing_stops$missing_stops <- as.character(missing_stops$missing_stops) # messy

url <- 'ftp://ftp.gisdata.mn.gov/pub/gdrs/data/pub/us_mn_state_metc/trans_transit_stops/shp_trans_transit_stops.zip'
loc <- file.path(tempdir(), 'stops.zip')
download.file(url, loc)
unzip(loc, exdir = file.path(tempdir(), 'stops'), overwrite = TRUE)
file.remove(loc)
stops <- readOGR(file.path(tempdir(), 'stops'), layer = 'TransitStops', stringsAsFactors = FALSE)
stops <- st_as_sf(stops)
stops <- st_transform(stops, 4326)

missing_stops <- left_join(missing_stops, stops, by = c("missing_stops" = "site_id"))
# check to see where these are, if they're active, etc
