library(rvest)
library(RSelenium)

district <- "71134  AIDLINGEN"
district <- "71229  LEONBERG"

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

# Find search field on the landing page in order to insert the district where carsharing offers shall be searched for
search_field <- remDr$client$findElement(using = "xpath", value = "//*[@id='edit-street-address']")

# Paste district name into search field and execute
search_field$sendKeysToElement(list(district, key="enter"))

# Refresh html code so hidden tables with carsharing locations in the given district gets updated
remDr$client$refresh()

# Parse updated html code
parsed_html <- read_html(remDr$client$getPageSource()[[1]])

# Get table with carsharing offerings
parsed_html %>% 
  html_nodes('table') %>% 
  html_table()


