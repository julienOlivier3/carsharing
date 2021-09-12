if (!require("pacman")) install.packages("pacman")
pacman::p_load(pbapply, future, furrr, devtools)

# Define sample districts for which to scrape carsharing locations if available
districts <- c(
  "Bamberg",    # the most beautiful city in Germany
  "Tübingen",   # my home town - nice, too
  "Mannheim",   # well, another city in Germany
  "Heidelberg", # the beautiful neighboring city
  "Bad Tölz",   # Bavaria!
  "Balingen",   # no carsharing available, unfortunately
  "München",    # ...
  "Frankfurt",  # ...
  "Koblenz",    # ...
  "Köln",       # ...
  "Bisingen",   # ...
  "Dachau",     # ...
  "Überlingen", # ...
  "Radolfzell", # ...
  "Weinheim",   # ...
  "Rostock",    # ...
  "Rügen"       # ...
)


# Caching sequential ------------------------------------------------------
source("02_Code/01.3_outer_crawler.R", verbose = FALSE)

# Scrape locations sequentially for all districts with progress bar
system.time({
  source("02_Code/01.1_start_selenium.R", verbose = FALSE)
  carsharing_locations1 <- pblapply(districts, function(district) mem_crawl_singleregion(district)) %>% bind_rows() 
})

# Close Rselenium
remDr$close()
rD$server$stop()

# Look at results
carsharing_locations


# Caching in parallel -----------------------------------------------------


# Install development version Till's parsel package which allows parallelization  
# to run multiple RSelenium browsers simultaneously
# devtools::install_github("till-tietz/parsel")
library(parsel)

# Scrape locations for all districts in parallel using parsel::parscrape() which
# runs multiple RSelenium browsers simultaneously
system.time({
  carsharing_locations2 <- parsel::parscrape(
    scrape_fun = mem_crawl_singleregion,
    scrape_input = districts,
    cores = parallel::detectCores()-1,
    packages = c("RSelenium", "tidyverse", "rvest", "janitor", "rlist", "memoise", "here"),
    browser = "firefox",
    scrape_tries = 1)
})

# Look at results
carsharing_locations2 <- carsharing_locations2$scraped_results %>% bind_rows()
carsharing_locations2
