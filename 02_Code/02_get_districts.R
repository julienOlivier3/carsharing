if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, readxl, janitor, ggmap, pdftools)

# Read district names as provided by Federal Motor Transport Authority
districts <- readxl::read_excel("01_Data\\02_Bestand\\fz3_2021.xlsx", sheet = "FZ 3.1", range = "D9:D11215") %>% 
  clean_names()

# Clean district names
districts <- districts %>% 
  mutate(district_clean = str_remove(plz_gemeinde, pattern = "\\,.*")) %>%  # drop some unwanted information in the district names
  filter(str_detect(district_clean, pattern = "\\d{5}")) %>% # drop entries not related to districts (basically subtotal infos)
  select(district_clean)

# Create separate column for name of district and zip code respectively 
districts <- districts %>% 
  mutate(zip_code = str_extract(district_clean, pattern = "\\d{5}")) %>% 
  mutate(district_name = str_remove(district_clean, pattern = "\\d{5}  ")) 

# Get geodata using google maps API
# geocodings might be relevant for an alternative (API-like) scraping attempt where 
# URL of bcs allows the insertion of geocodes
# e.g.: https://carsharing.de/cs-standorte-ol3-v7?field_geofield_distance%5Bdistance%5D=10&update_lat=49.88&update_lon=10.89

# usethis::edit_r_environ() 
# register_google(key = Sys.getenv("GOOGLE_MAPS_API_KEY"))
#districts <- districts %>% 
#  mutate_geocode(district_clean, output = "more")

#districts %>% 
#   write_delim(file = "01_Data/05_Geodata/german_districts_geodata.txt", 
#             delim = '\t', 
#             append=FALSE)
