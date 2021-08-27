source("02_Code/01.1_start_selenium.R", verbose = FALSE)
source("02_Code/01.3_outer_crawler.R", verbose = FALSE)

districts <- c(
  "Bamberg",  # the most beautiful city in Germany
  "Tübingen", # my home town - nice, too
  "Mannheim"  # well, another city in Germany
  )

crawl_singleregion(district = districts[1])

purrr::walk(districts, function(district) crawl_singleregion(district) %>% print(n=3))