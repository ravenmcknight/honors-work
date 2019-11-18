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

apc_ag <- apc[, .(daily_boards = sum(board), daily_alights = sum(alight), num_interpolated = sum(interpolated), 
                  num_routes = length(unique(line_id)), daily_stops = .N), keyby = .(date_key, site_id)]
saveRDS(apc_ag, 'data/mt-data/daily_aggregation_1118.RDS')

# oops, exclude 2018 for now
apc_ag <- apc_ag[!date_key %like% 2018]


# now, aggregate to block groups

# read stop to block group from "aggregate-apc.R" script
stop_to_bg <- readRDS('data/mt-data/stop-to-bg.RDS')
stop_to_bg <- unique(stop_to_bg)

apc_ag[, site_id := as.character(site_id)]
apc_ag <- stop_to_bg[apc_ag, on = 'site_id']

# mark rail stops
