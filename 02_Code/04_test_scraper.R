if (!require("pacman")) install.packages("pacman")
pacman::p_load(pbapply, future, furrr, devtools)

# Install development version Till's parsel package which allows parallelization  
# to run multiple RSelenium browsers simultaneously
# devtools::install_github("till-tietz/parsel")
library(parsel)

source("02_Code/01.1_start_selenium.R", verbose = FALSE)
source("02_Code/01.3_outer_crawler.R", verbose = FALSE)


# Define sample districts for which to scrape carsharing locations if available
districts <- c(
  "Bamberg",    # the most beautiful city in Germany
  "Tübingen",   # my home town - nice, too
  "Mannheim",   # well, another city in Germany
  "Heidelberg", # its nice neighbor
  "Bad Tölz",   # Bavaria!
  "Balingen",   # no carsharing available, unfortunately
  #"dfagdafg",   # what happens here?
  "München",
  "Frankfurt"
  )

# Scrape locations for a single district
crawl_singleregion(district = districts[1])

# Scrape locations for all districts with progress bar
plan(sequential)
system.time({
  carsharing_locations <- pblapply(districts, function(district) mem_crawl_singleregion(district)) %>% bind_rows()  
})

# Look at results
carsharing_locations

# Scrape locations for all districts in parallel using parsel::parscrape which
# runs multiple RSelenium browsers simultaneously
plan(multisession)
system.time({
  carsharing_locations <- parsel::parscrape(
    scrape_fun = parallel_crawl_singleregion,
    scrape_input = districts,
    cores = 3,
    packages = c("RSelenium", "tidyverse", "rvest", "janitor", "rlist", "memoise", "here"),
    browser = "firefox",
    scrape_tries = 1)
})

# Look at results
carsharing_locations$scraped_results %>% bind_rows()
