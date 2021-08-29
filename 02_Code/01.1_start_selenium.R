# Setup -------------------------------------------------------------------
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, rvest, RSelenium, janitor, rlist)


# Initialize Selenium server ----------------------------------------------
remDr <- rsDriver(
  port = sample(x = 1:1000, size = 1),
  browser = "chrome",
  verbose = FALSE, 
  chromever = "92.0.4515.107"
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


  

         