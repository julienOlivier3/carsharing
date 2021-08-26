source("02_Code/01_scraping_setup.R", verbose = FALSE)

districts <- c(
  "Bamberg", # the most beautiful city in Germany
  "Tübingen",# my home town - nice, too
  "Mannheim" # weird city in Germany
  )

scrape_bcs(district = districts[1])

lapply(districts, function(district) scrape_bcs(district))
