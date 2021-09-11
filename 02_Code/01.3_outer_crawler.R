# Setup -------------------------------------------------------------------
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, rvest, RSelenium, janitor, rlist, memoise, here)

# Load scrape_singletab() function
source("02_Code/01.2_inner_scraper.R", verbose = FALSE)


# Define crawler ----------------------------------------------------------
# Outer crawler
## Function which which does all the clicking and execution of web elements (using Selenium) to show the car sharing locations of a desired region
crawl_singleregion <- function(district, district_autocomplete=""){
  
  # Find search field on the landing page in order to insert the district where carsharing offers shall be searched for
  search_field <- NULL
  while(is.null(search_field)){
    Sys.sleep(1) # sleep for a second before letting the while loop continue iterating
    search_field <- tryCatch({remDr$client$findElement(using = "xpath", value = "//input[@id='edit-street-address']")},
                             error = function(e){NULL})
    # while loop runs until search field for entering district is available
  }
  
  # Clear search field 
  search_field$clearElement()
  Sys.sleep(1) # sleep for a second
  
  # Paste district name into search field and execute
  search_field$sendKeysToElement(list(district, key="enter"))
  Sys.sleep(1) # sleep for a second
  
  # Wait until page has been re-loaded
  currentValue <- NULL
  while(is.null(currentValue)){
    Sys.sleep(1) # sleep for a second before letting the while loop continue iterating
    search_field <- tryCatch({remDr$client$findElement(using = "xpath", value = "//input[@id='edit-street-address']")},
                             error = function(e){NULL})
    tempValue <- tryCatch({search_field$getElementAttribute("value")[[1]]},
                          error = function(e){NULL})
    currentValue <- tryCatch({tempValue==district_autocomplete},
                             error = function(e){NULL})
    if (currentValue){ currentValue <- NULL }
    # while loop runs until current auto complete district (currentValue) name differs from previous auto complete district (district_autocomplete)
  }
  
  # Refresh html code so hidden tables with carsharing locations in the given district gets updated
  remDr$client$refresh()
  Sys.sleep(1) # sleep for a second
  
  # Parse updated html code
  parsed_html <- read_html(remDr$client$getPageSource()[[1]])
  
  # Get table(s) with carsharing offerings
  carsharing_info <- parsed_html %>% 
    html_nodes('table') 
  
  # If there are no carsharing offerings in the district return an empty df
  if (length(carsharing_info)==0){
    carsharing_tab <- tibble("standort"=NA, "anbieter"=NA, "entfernung"=NA, "standord_id"=NA, "anbieter_id"=NA)
  }
  
  # If there are carsharing offerings in the district, they are either listed
  # (a) in one table (only <= 10 available) or
  # (b) listed across several tables (many offerings, > 10)
  else{
    
    # If many carsharing offers exist, they are listed in several tables which all need to be activated separately by clicking through the table slider
    several_tabs <- parsed_html %>% html_nodes("[title='Zur letzten Seite']")
    # If only one table exists, scrape the table
    if (length(several_tabs)==0){
      carsharing_tab <- scrape_singletab(carsharing_info[[1]])
    }
    
    # If several tables exist, we need some additional handling
    else{
      
      # Activate the table interface so the table slider becomes clickable
      activate_field <- remDr$client$findElement(using = "css selector", value = ".show-result-list")
      activate_field$clickElement()
      Sys.sleep(1) # sleep for a second
      
      # Find the "last page/table" button and click it
      lastpage_field <- remDr$client$findElement(using = "xpath", value = "//li[@class='pager__item pager__item--last']")
      lastpage_field$clickElement()
      Sys.sleep(1) # sleep for a second
      
      # Find the "current page/table" button to get the overall number of tables 
      currentpage_field <- remDr$client$findElement(using = "xpath", value = "//li[@class='pager__item pager__item--current']")
      n_tabs <- as.numeric(currentpage_field$getElementAttribute("innerHTML")[[1]])
      
      # Initialize empty df
      carsharing_tab <- tibble(standort = character(), 
                               anbieter = character(), 
                               entfernung = character(), 
                               standord_id = character(), 
                               anbieter_id = character())
      
      # Then scrape the tables from the last to the first one
      for (tab in n_tabs:1){
        
        # Click on previous table 
        if (tab<n_tabs){ 
          previouspage_field <- remDr$client$findElement(using = "xpath", value = "//li[@class='pager__item pager__item--previous']")
          previouspage_field$clickElement()
          Sys.sleep(1) # sleep for a second
        }
        
        # Parse updated html code
        parsed_html <- read_html(remDr$client$getPageSource()[[1]])
        Sys.sleep(1) # sleep for a second
        
        # Get table(s) with carsharing offerings
        carsharing_info <- parsed_html %>% 
          html_nodes('table') 
        
        # Scrape the table
        temp <- scrape_singletab(carsharing_info[[1]])
        
        carsharing_tab <- carsharing_tab %>% 
          add_row(temp)
        
      }
      
    }
    
  }
  
  # Get additional metadata:
  # Scale information from the map
  scale_info <- parsed_html %>% 
    html_node("[class='ol-scale-line-inner']") %>% 
    html_text()
  
  # Autocompleted district
  search_field <- NULL
  while(is.null(search_field)){
    Sys.sleep(1) # sleep for a second before letting the while loop continue iterating
    search_field <- tryCatch({remDr$client$findElement(using = "xpath", value = "//input[@id='edit-street-address']")},
                             error = function(e){NULL})
    # while loop runs until search field for entering district is available
  }
  district_autocomplete <- search_field$getElementAttribute("value")[[1]]
  
  carsharing_tab <- carsharing_tab %>% 
    add_column(district) %>% 
    add_column(district_autocomplete) %>% 
    add_column(scale_info) %>% 
    select(district, everything())
  
  return(carsharing_tab)
  
  
}

# Enable caching
## Cache directory path
cache_dir = here("01_Data/.rcache")

## Create this directory if it doesn't yet exist
if (!dir.exists(cache_dir)) dir.create(cache_dir)

mem_crawl_singleregion <- function(x) {
  # Create cached version of crawl_singleregion
  cached_crawl_singleregion <- memoise(crawl_singleregion, cache = cache_filesystem(cache_dir))
  
    ## 1. Load cached data if already generated
    if (has_cache(cached_crawl_singleregion)(x)) {
      cat("Loading cached data for district =", x, "\n")
      my_data =  cached_crawl_singleregion(x)
      return(my_data)
    }
    
    ## 2. Generate new data if cache not available
    cat("Generating data from scratch for district =", x, "...")
    my_data = cached_crawl_singleregion(x)
    cat("ok\n")
    
    return(my_data)
}
