## Goal: get modeling data for final spatiotemporal model

packages <- c('data.table', 'tigris', 'ggplot2', 'dplyr', 'rgdal', 'sf')

miss_pkgs <- packages[!packages %in% installed.packages()[,1]]

if(length(miss_pkgs) > 0){
  install.packages(miss_pkgs)
}

invisible(lapply(packages, library, character.only = TRUE))

rm(miss_pkgs, packages)

options(tigris_class = 'sf')

# Read "raw" data, from "gap-fill.R" script
apc <- readRDS('data/mt-data/apc-interpolated.RDS')
setDT(apc)

apc <- apc[!date_key %like% 2017]
apc[, site_id := as.character(site_id)]

# read stop to block group from "aggregate-apc.R" script
stop_to_bg <- readRDS('data/mt-data/stop-to-bg.RDS')
stop_to_bg <- unique(stop_to_bg)
apc <- stop_to_bg[apc, on = 'site_id']

# exclude rail stations
stops2 <- fread('data/csv_trans_stop_boardings_alightings/TransitStopsBoardingsAndAlightings2018.csv') # year doesn't really matter
stops2 <- stops2[Route == "Blue Line" | Route == "North Star" | Route == "Green Line"]

apc <- apc[!site_id %in% stops2$Site_id]
# double check Green & Blue line are out
apc <- apc[line_id != 902 & line_id != 901]

# exclude things outside of 7 county
apc <- apc[!is.na(GEOID)]

apc_ag <- apc[, .(daily_boards = sum(board, na.rm = T), daily_alights = sum(alight, na.rm = T), num_interpolated = sum(interpolated), 
                  num_routes = length(unique(line_id)), daily_stops = .N), keyby = .(date_key, GEOID)]

saveRDS(apc_ag, 'data/mt-data/daily_aggregation_1118.RDS')
apc_ag <- readRDS('data/mt-data/daily_aggregation_1118.RDS')

# more modeling specific things
library(lubridate)
apc_ag[, wday := wday(ymd(date_key))]
#apc_ag <- apc_ag[wday != 6 & wday != 7] # won't want this for temporal
apc_ag[, daily_activity := daily_boards + daily_alights, keyby = .(date_key, GEOID)]
apc_ag[, total_daily_activity := sum(daily_activity, na.rm =T), keyby = .(date_key)]


saveRDS(apc_ag, 'data/spattemp_mod_dat_1130.RDS')


