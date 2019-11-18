library(readr)
library(sf)
library(tigris)
library(data.table)
library(otptools)

# first, download population-weighted centroids
url <- "https://www2.census.gov/geo/docs/reference/cenpop2010/blkgrp/CenPop2010_Mean_BG27.txt"
loc <- file.path("/Users/raven/Documents/honors/honors-work/data/isochrones", 'centrs.csv')
download.file(url, loc)

centrs <- read_csv('data/isochrones/centrs.csv')
setDT(centrs)

counties <- c("Anoka", "Carver", "Dakota", "Hennepin", "Ramsey", "Scott", "Washington")
bgs <- block_groups("MN", counties, 2016)

centrs <- centrs[COUNTYFP %in% bgs$COUNTYFP]
centrs[, bgid := paste0(STATEFP, COUNTYFP, TRACTCE, BLKGRPCE)]

centrs_loc <- centrs[, c("bgid", "LATITUDE", "LONGITUDE")]
setnames(centrs_loc, c("bgid", "LATITUDE", "LONGITUDE"), c("id", "lat", "lon"))

# then, use opentripplanner to get 10min walk isos
isos <- queryIsochrone(location = centrs_loc,
                       otp_params = otp_params(cutoffSec = c(600), mode = "WALK"),
                       host = "localhost", port = 8080)

saveRDS(isos, "data/isochrones/centroid_isos.RDS")
                     