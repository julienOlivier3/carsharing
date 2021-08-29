if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse)


carsharing_locaions <- read_delim(file = "01_Data/03_Carsharing_Locations/scraping_sample.txt", delim = '\t')

length(unique(carsharing_locaions$provider))
length(unique(carsharing_locaions$provider_id))

carsharing_districts <- carsharing_locaions %>% 
  filter(!is.na(provider)) %>% 
  distinct(district, provider)

carsharing_providers <- carsharing_districts %>%
  distinct(provider)

carsharing_providers %>% 
  mutate(id = row.names(.)) %>% 
  select(id, provider) %>% 
  write_delim("01_Data/03_Carsharing/carsharing_providers.txt", delim = "\t")
