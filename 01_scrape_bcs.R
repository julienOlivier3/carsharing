# Setup -------------------------------------------------------------------
rm(list = ls())
library(tidyverse)
library(rvest)
library(RSelenium)
library(janitor)
library(rlist)

source("02_get_districts.R", verbose = FALSE)


# Define scraping functions -----------------------------------------------

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

scrape_bcs <- function(district, district_autocomplete=""){
  
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
  
  # Paste district name into search field and execute
  search_field$sendKeysToElement(list(district, key="enter"))
  
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
  
  # Get number of tables with carsharing locations
  carsharing_exits <- length(carsharing_info)
  
  # If there are no carsharing offers in the district return an empty df
  if (carsharing_exits==0){
    carsharing_tab <- tibble("standort"=NA, "anbieter"=NA, "entfernung"=NA, "standord_id"=NA, "anbieter_id"=NA)
  }
  
  # If there are carsharing offerings in the district, they are either listed
  # (a) in one table (only few offerings available) or
  # (b) listed across several tables (many offerings)
  else{

    # If many carsharing offers exist, they are listed in several tables which need to which all need to be called separately
    several_tabs <- parsed_html %>% html_nodes("[title='Zur letzten Seite']")
    # If only one table exists, scrape the table
    if (length(several_tabs)==0){
      carsharing_tab <- scrape_singletab(carsharing_info[[1]])
    }
      
    # If several tables exist, we need some additional handling
    else{
      
      #warning("Several tables exist")
      # Find the "last page/table" button and execute it
      lastpage_field <- remDr$client$findElement(using = "xpath", value = "//li[@class='pager__item pager__item--last']")
      lastpage_field$clickElement()
      
      # Find the "current page/table" button get the number of tables information 
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
        # Parse updated html code
        parsed_html <- read_html(remDr$client$getPageSource()[[1]])
        
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

# Test
#scrape_bcs(district = "Tübingen")


# Initialize Selenium server ----------------------------------------------
remDr <- rsDriver(
  port = sample(x = 1:1000, size = 1),
  browser = "firefox",
  verbose = FALSE, 
  chromever = "88.0.4324.27"
)

# Define landing page
bcs_landing <- 'https://carsharing.de/cs-standorte'

# Navigate to landing page
remDr$client$navigate(bcs_landing)

# Wait until page has been loaded
currentURL <- NULL
while(is.null(currentURL)){
  Sys.sleep(3) # sleep for a second before letting the while loop continue iterating
  currentURL <- tryCatch({str_detect(remDr$client$getCurrentUrl()[[1]], bcs_landing)},
                         error = function(e){NULL})
  # while loop runs until site has been loaded
}


# Loop over districts -----------------------------------------------------

# Instantiate empty objects
carsharing_locations <- tibble(district = character(),
                               standort = character(), 
                               anbieter = character(), 
                               entfernung = character(), 
                               standord_id = character(), 
                               anbieter_id = character(),
                               district_autocomplete = character(), 
                               scale_info = character())
error_districts = c()
district_autocomplete <- ""


# Loop
for (district in districts$district_clean[1:100]){
  
  tryCatch(
    
    ########################################################################
    # Try part: define the expression(s) you want to "try"                 #
    ########################################################################
    
    {
      # Just to highlight: 
      # If you want to use more than one R expression in the "try part" 
      # then you'll have to use curly brackets. 
      # Otherwise, just write the single expression you want to try and 
      temp <- scrape_bcs(district, district_autocomplete)
      district_autocomplete <- unique(temp$district_autocomplete)
      carsharing_locations <- carsharing_locations %>% 
        add_row(temp)
      
    },
    
    ########################################################################
    # Condition handler part: define how you want conditions to be handled #
    ########################################################################
    
    # Handler when a warning occurs:
    #warning = function(cond) {
    #  message(paste("The following district caused a warning:", district))
    #  message("Here's the original warning message:")
    #  message(paste(cond, '\n'))
      
      # Choose a return value when such a type of condition occurs
    #  temp <- scrape_bcs(district, district_autocomplete)
    #  district_autocomplete <- unique(temp$district_autocomplete)
    #  carsharing_locations <- carsharing_locations %>% 
    #    add_row(temp)
      
    #},
    
    # Handler when an error occurs:
    error = function(cond) {
      message(paste("The following district caused an error:", district))
      message("Here's the original error message:")
      message(paste(cond, '\n'))
      
      # Choose a return value when such a type of condition occurs
      error_districts <<- c(error_districts, district)
      
    },
    
    ########################################################################
    # Final part: define what should happen AFTER                          #
    # everything has been tried and/or handled                             #
    ########################################################################
    
    finally = {
      message(paste("Processed district:", district))
      #message("Some message at the end\n")
    }
    
  )
  
  
}
