if (!require("pacman")) install.packages("pacman")
pacman::p_load(pbapply, future, furrr, devtools, dplyr)

# Install development version Till's parsel package which allows parallelization  
# to run multiple RSelenium browsers simultaneously
# devtools::install_github("till-tietz/parsel")
library(parsel)

source("02_Code/01.3_outer_crawler.R", verbose = FALSE)
source("02_Code/02_get_districts.R", verbose = FALSE)

# Get districts already scraped
districts_done <- read_delim(file = "01_Data\\03_Carsharing\\scraping_sample.txt", delim="\t")
districts_done <- unique(districts_done$district)

system.time({
  carsharing_locations <- parsel::parscrape(
    scrape_fun = mem_crawl_singleregion,
    scrape_input = districts$district_clean[!(districts$district_clean %in% districts_done)],
    #ports = 1:8,
    cores = parallel::detectCores()-1,
    packages = c("RSelenium", "tidyverse", "rvest", "janitor", "rlist", "memoise", "here"),
    browser = "firefox",
    scrape_tries = 1)
})

# Look at results
carsharing_locations$scraped_results %>% bind_rows()



system.time({
  source("02_Code/01.1_start_selenium.R", verbose = FALSE)
  carsharing_locations <- pblapply(districts$district_clean[!(districts$district_clean %in% districts_done)], function(district) mem_crawl_singleregion(district)) %>% bind_rows()  
  
})

# Look at results
carsharing_locations


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
  write_delim(file = "01_Data//03_Carsharing//scraping_sample.txt", 
              delim = '\t', 
              append=TRUE)
