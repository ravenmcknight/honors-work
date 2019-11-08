## Goal: aggregate daily APC to block groups 


## data & packages ----------------------------------------

packages <- c('data.table', 'tigris', 'sf', 'rgdal', 'dplyr')

miss_pkgs <- packages[!packages %in% installed.packages()[,1]]

if(length(miss_pkgs) > 0){
  install.packages(miss_pkgs)
}

invisible(lapply(packages, library, character.only = TRUE))

rm(miss_pkgs, packages)

# apc
apc <- readRDS('data/mt-data/apc-aggregate.RDS')
setDT(apc)

# stops
url <- 'ftp://ftp.gisdata.mn.gov/pub/gdrs/data/pub/us_mn_state_metc/trans_transit_stops/shp_trans_transit_stops.zip'
loc <- file.path(tempdir(), 'stops.zip')
download.file(url, loc)
unzip(loc, exdir = file.path(tempdir(), 'stops'), overwrite = TRUE)
file.remove(loc)
stops <- readOGR(file.path(tempdir(), 'stops'), layer = 'TransitStops', stringsAsFactors = FALSE)
stops <- st_as_sf(stops)
stops <- st_transform(stops, 4326)

# block groups
options(tigris_class = 'sf')
counties <- c('Anoka', 'Carver', 'Dakota', 'Hennepin', 'Ramsey', 'Scott', 'Washington')
bgs <- block_groups('MN', counties, year = 2016)
bgs <- st_transform(bgs, 4326)

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
stops <- st_as_sf(stops)

## aggregation without buffering --------------------------

# join stop locations to apc

apc[, site_id := as.character(site_id)]
apc_loc <- left_join(stops, apc) # dplyr joins are usually easier with sf objects
rm(apc) # just for space

# intersect stops and block groups
apc_bg <- st_join(apc_loc, bgs, st_intersects)
setDT(apc_bg)

# count bus stops
bc <- apc_bg[rail == 0, .(count_bus_stops = length(unique(site_id))), by = 'GEOID']
rc <- apc_bg[rail == 1, .(count_rail_stops = length(unique(site_id))), by = 'GEOID']

# save stops to block groups
names(apc_bg)
stop_to_bg <- apc_bg[, c('site_id', 'GEOID')]
saveRDS(stop_to_bg, 'data/stop-to-bg.RDS')

# save verion with no buffering
apc_bg_sum <- apc_bg[, .(ag_board = sum(daily_boards, na.rm = T), ag_alight = sum(daily_alights, na.rm = T), 
                         ag_trips = sum(num_trips, na.rm = T), ag_interp = sum(num_interpolated, na.rm = T)),
                     by = c('GEOID', 'date_key', 'line_id', 'line_direction', 'service_id')]
apc_bg_sum <- bc[apc_bg_sum, on = 'GEOID']
apc_bg_sum <- rc[apc_bg_sum, on = 'GEOID']
saveRDS(apc_bg_sum, 'data/mt-data/apc-bg-sum.RDS')

#apc_bg_sum <- readRDS('data/mt-data/apc-bg-sum.RDS') 

# save most aggregated version
apc_bg_ag_sum <- apc_bg_sum[, .(ag_board = sum(ag_board, na.rm = T), ag_alight = sum(ag_alight, na.rm = T), 
                                ag_trips = sum(ag_trips, na.rm = T), ag_interp = sum(ag_interp, na.rm = T),
                                count_bus_stops = count_bus_stops, count_rail_stops = count_rail_stops),
                        by = c('GEOID', 'date_key')]
saveRDS(apc_bg_ag_sum, 'data/mt-data/apc-bg-ag-sum.RDS')

## with buffering -----------------------------------------

# start with a small subset 
stops <- stops %>% filter(county == 'Anoka')
stops <- st_transform(stops, 32615) # can't buffer lat/long
stop_buff <- st_buffer(stops, 10) # 10m buffer should handle opposite side of street
stop_buff <- st_transform(stop_buff, 4326)

apc_loc_buff <- left_join(stop_buff, apc)
rm(apc)

stop_buff_bg <- st_join(stop_buff, bgs, st_intersects)
setDT(stop_buff_bg)

apc_bg_buff <- left_join(apc_loc_buff, stop_buff_bg, by = 'site_id')
setDT(apc_bg_buff)

# just export super aggregated version
apc_bg_ag_buff_sum <- apc_bg_buff[, .(ag_board = sum(daily_boards, na.rm = T), ag_alight = sum(daily_alights, na.rm = T), ag_trips = sum(num_trips, na.rm = T), ag_interp = sum(num_interpolated, na.rm = T)),
                               by = c('date_key', 'GEOID')]
saveRDS(apc_bg_ag_buff_sum, 'data/mt-data/apc-bg-ag-buff-sum.RDS')


