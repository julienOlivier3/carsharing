library(rvest)
library(RSelenium)

bcs_landing <- 'https://carsharing.de/cs-standorte'

bcs <- read_html(bcs_landing)

bcs

gemeinde1 <- "71134  AIDLINGEN"
gemeinde2 <- "71229  LEONBERG"

# Initialize Selenium server ----------------------------------------------
remDr <- rsDriver(
  port = sample(x = 1:1000, size = 1),
  browser = "firefox",
  verbose = FALSE, 
  chromever = "88.0.4324.27"
)

# Navigate to landing page
remDr$client$navigate(bcs_landing)

# Find search field
search_field <- remDr$client$findElement(using = "xpath", value = "//*[@id='edit-street-address']")

# Paste district name into search field
search_field$sendKeysToElement(list(gemeinde2, key="enter"))


temp <- remDr$client$findElement(using = "xpath", value = "/html/body/div[2]/div/div/div[2]/div[3]")
temp$click()
car_list$
car_list$click()
car_list$sendKeysToElement(list(key="enter"))
