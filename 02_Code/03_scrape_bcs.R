source("02_Code/01.1_start_selenium.R", verbose = FALSE)
source("02_Code/01.3_outer_crawler.R", verbose = FALSE)
source("02_Code/02_get_districts.R", verbose = FALSE)


## Instantiate empty objects ...
# ... for scraping results
carsharing_locations <- tibble(district = character(),
                               standort = character(), 
                               anbieter = character(), 
                               entfernung = character(), 
                               standord_id = character(), 
                               anbieter_id = character(),
                               district_autocomplete = character(), 
                               scale_info = character())

# ... for districts where crawler run into an error
error_districts = c()

# ... for a helper object required for the subsequent loop
district_autocomplete <- ""

# Iterator object for showing crawling progress 
id <- 0

# Create vector of districts
districts <- districts$district_clean
n_districts <- length(districts)

# Loop including error handling (errors may happen because of stale elements)
#-----------------------------------------------------------------------------
for (district in districts){
  
  # Add simple progress information
  id = id + 1
  if(id%%100==0)
    cat("Scraping progress:", round(id/n_districts, digits = 3)*100, "%")
  
  
  tryCatch(
    
    ########################################################################
    # Try part: define the expression(s) you want to "try"                 #
    ########################################################################
    
    {
      # Just to highlight: 
      # If you want to use more than one R expression in the "try part" 
      # then you'll have to use curly brackets. 
      # Otherwise, just write the single expression you want to try and 
      temp <- crawl_singleregion(district, district_autocomplete)
      district_autocomplete <- unique(temp$district_autocomplete)
      carsharing_locations <- carsharing_locations %>% 
        add_row(temp)
      
    },
    
    ########################################################################
    # Condition handler part: define how you want conditions to be handled #
    ########################################################################
    
    # Handler when an error occurs:
    error = function(cond) {
      message(paste("The following district caused an error:", district))
      message("Here's the original error message:")
      message(paste(cond, '\n'))
      
      # Add districts for which scraping has not been successful to list
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
  write_delim(file = "01_Data//03_Carsharing_Locations//scraping_sample.txt", 
              delim = '\t')