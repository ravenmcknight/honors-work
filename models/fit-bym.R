## goal: fit bym and bym2 models 

## packages/setup -------------------------------

packages <- c('rstan', 'shinystan', 'spdep', 'tigris', 'sf')

miss_pkgs <- packages[!packages %in% installed.packages()[,1]]

if(length(miss_pkgs) > 0){
  install.packages(miss_pkgs)
}

invisible(lapply(packages, library, character.only = TRUE))

rm(miss_pkgs, packages)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

## data -----------------------------------------

counties <- c("Anoka", "Carver", "Dakota", "Hennepin", "Ramsey", "Scott", "Washington")
bgs <- block_groups("MN", counties, 2016)


neighborhood <- poly2nb(bgs)
source("nb_data_funs.R");
nbs <- nb2graph(neighborhood)
