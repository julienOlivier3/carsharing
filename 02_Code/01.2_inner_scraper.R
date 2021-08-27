# Setup -------------------------------------------------------------------
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, rvest, RSelenium, janitor, rlist)


# Define scraper ----------------------------------------------------------
## Inner scraper
# Function which extracts html table of car sharing locations given a region name
scrape_singletab <- function(html_table){
  # Extract main table information
  carsharing_tab <- html_table %>% 
    html_table() %>% 
    clean_names()
  
  # Extract additional meta information (unique location and company IDs)
  # included in tables <a> tags as "href"
  carsharing_meta <- html_table %>% 
    html_nodes("a") %>% 
    html_attr("href") %>% 
    as_tibble()
  
  location_meta <- carsharing_meta %>% 
    filter(str_detect(value, "standort")) %>% 
    rename(c("standord_id" = "value"))
  
  company_meta <- carsharing_meta %>% 
    filter(str_detect(value, "anbieter")) %>% 
    rename(c("anbieter_id" = "value"))
  
  # Append the meta information to the main table
  carsharing_tab <- carsharing_tab %>% 
    add_column(location_meta) %>% 
    add_column(company_meta) 
  
  return(carsharing_tab)
  
}

