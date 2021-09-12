if (!require("pacman")) install.packages("pacman")
pacman::p_load(pbapply, future, furrr, devtools)

# Install development version Till's parsel package which allows parallelization  
# to run multiple RSelenium browsers simultaneously
# devtools::install_github("till-tietz/parsel")
library(parsel)

source("02_Code/01.3_outer_crawler.R", verbose = FALSE)
source("02_Code/02_get_districts.R", verbose = FALSE)



system.time({
  carsharing_locations <- parsel::parscrape(
    scrape_fun = parallel_crawl_singleregion,
    scrape_input = districts$district_clean,
    #ports = 1:8,
    cores = parallel::detectCores(),
    packages = c("RSelenium", "tidyverse", "rvest", "janitor", "rlist", "memoise", "here"),
    browser = "firefox",
    scrape_tries = 1)
  parsel::close_rselenium()
})

system.time({
  source("02_Code/01.1_start_selenium.R", verbose = FALSE)
  source("02_Code/01.3_outer_crawler.R", verbose = FALSE)
  carsharing_locations <- pblapply(districts$district_clean[1:662], function(district) parallel_crawl_singleregion(district)) %>% bind_rows()  
  
})

# Look at results
carsharing_locations$scraped_results %>% bind_rows()


# Do some minor data cleaning before saving
carsharing_locations %>% rename(c("location" = "standort", 
                                  "provider" = "anbieter", 
                                  "distance_from_center" = "entfernung", 
                                  "location_id" = "standord_id", 
                                  "provider_id" = "anbieter_id")) %>%           # Rename German column names to English equivalents
  select(district, district_autocomplete, provider, provider_id, location,      # Reorder columns
         location_id, distance_from_center, scale_info) %>%                     
  mutate(provider_id = str_remove(provider_id, "/anbieter/")) %>%               # Remove unnecessary characters from provider_id
  mutate(location_id = str_remove(location_id, "/standort/")) %>%               # Remove unnecessary characters from location_id
  mutate(distance_from_center =                                                 # Turn information how far shared cars are located from city center from string into double (in meters)
           as.numeric(str_replace(
             str_remove(distance_from_center, " km"),
             ",", "."))*1000) %>% 
  write_delim(path = "01_Data//03_Carsharing//scraping_sample.txt", 
              delim = '\t', 
              append=TRUE)
