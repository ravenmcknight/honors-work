## goal: fit bym and bym2 models 

## packages/setup -------------------------------

packages <- c('rstan', 'shinystan', 'spdep', 'tigris', 'sf', 'data.table')

miss_pkgs <- packages[!packages %in% installed.packages()[,1]]

if(length(miss_pkgs) > 0){
  install.packages(miss_pkgs, dep = TRUE)
}

invisible(lapply(packages, library, character.only = TRUE))

rm(miss_pkgs, packages)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

## data -----------------------------------------

counties <- c("Anoka", "Carver", "Dakota", "Hennepin", "Ramsey", "Scott", "Washington")
bgs <- block_groups("MN", counties, 2016)

mod_dat <- readRDS('/Users/mcknigri/Documents/honors/honors-work/data/ag-modeling-data.RDS')
setDT(mod_dat)

neighborhood <- poly2nb(bgs)
source("nb_data_funs.R") 

nbs <- nb2graph(neighborhood)
N <- nbs$N
node1 <- nbs$node1
node2 <- nbs$node2
N_edges <- nbs$N_edges
mod_dat <- mod_dat[!avg_activity_per_capita == Inf]
y = mod_dat$avg_activity_per_capita

bym_dat <- list(N = N, 
                node1 = node1,
                node2 = node2,
                N_edges = N_edges,
                y = y)


## fit ------------------------------------------
bym <- stan_model("stan/bym.stan")
bym_fit <- sampling(bym, data = bym_dat, chains = 4, save_warmup = FALSE)

launch_shinystan(bym_fit)
print(bym_fit)

pairs(bym_fit)
