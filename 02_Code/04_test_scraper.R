if (!require("pacman")) install.packages("pacman")
pacman::p_load(pbapply)



source("02_Code/01.1_start_selenium.R", verbose = FALSE)
source("02_Code/01.3_outer_crawler.R", verbose = FALSE)

# Define sample districts for which to scrape carsharing locations if available
districts <- c(
  "Bamberg",  # the most beautiful city in Germany
  "Tübingen", # my home town - nice, too
  "Mannheim", # well, another city in Germany
  "Bad Tölz"  # Bavaria!
  )

# Scrape locations for a single district
crawl_singleregion(district = districts[1])

# Scrape locations for all districts
system.time({
  carsharing_locations <- pblapply(districts, function(district) mem_crawl_singleregion(district)) %>% bind_rows()  
})

# Look at results
carsharing_locations
