## Goal: use opentripplanner to calculate 10 minute walking distance from each bus stop

packages <- c('data.table', 'rgdal', 'sf', 'tidyverse', 'lwgeom')

miss_pkgs <- packages[!packages %in% installed.packages()[,1]]

if(length(miss_pkgs) > 0){
  install.packages(miss_pkgs, dep = TRUE)
}

invisible(lapply(packages, library, character.only = TRUE))

rm(miss_pkgs, packages)

# install.packages('otptools', type = 'source', 
#                 repos = 'http://mtapshiny1p/MT/SIDev/R')

library(otptools)


## get stops --------------------------

url <- 'ftp://ftp.gisdata.mn.gov/pub/gdrs/data/pub/us_mn_state_metc/trans_transit_stops/shp_trans_transit_stops.zip'
loc <- file.path(tempdir(), 'stops.zip')
download.file(url, loc)
unzip(loc, exdir = file.path(tempdir(), 'stops'), overwrite = TRUE)
file.remove(loc)
stops <- readOGR(file.path(tempdir(), 'stops'), layer = 'TransitStops', stringsAsFactors = FALSE)
stops <- st_as_sf(stops)
stops <- st_transform(stops, 4326)

# mark rail stops
stops <- stops %>%
  filter(busstop_yn == "Y")

# somehow need to isolate light rail stops
# using csv from: https://gisdata.mn.gov/dataset/us-mn-state-metc-trans-stop-boardings-alightings
stops2 <- fread('data/csv_trans_stop_boardings_alightings/TransitStopsBoardingsAndAlightings2018.csv') # year doesn't really matter
stops2 <- stops2[Route == "Red Line" | Route == "Blue Line" | Route == "North Star" | Route == "Green Line"]

setDT(stops)
stops[, rail := 0]
stops[site_id %in% stops2$Site_id, rail := 1]
stops <- stops[rail == 0]
stops <- st_as_sf(stops)

## run otp ----------------------------

otpstop <- stops[, c("geometry", "site_id")]
otpstop <- otpstop %>%
  mutate(lon = unlist(map(otpstop$geometry,1)),
         lat = unlist(map(otpstop$geometry,2)))

otpstop$geometry <- NULL
setDT(otpstop)
setnames(otpstop, "site_id", "id")


# ugly function to save bit by bit (kept getting stuck otherwise)
secs <- list(1:1000, 1001:2000, 2001:3000, 3001:4000, 4001:5000, 5001:6000,
          6001:7000, 7001:8000, 8001:9000, 9001:10000, 10001:11000, 11001:12000,
          12001:13000, 13001:14000, 14001:15016)
for(i in 1:15){
  isos <- queryIsochrone(location = otpstop[secs[[i]]], 
                         otp_params = otp_params(cutoffSec = c(600), mode = "WALK"),
                         host = "localhost", port = 8080)
  saveRDS(isos, paste0('data/isochrones/isos', i, '.RDS'))
}


# calculate area of sfc obejct --------


