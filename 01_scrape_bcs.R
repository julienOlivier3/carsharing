library(rvest)

bcs_landing <- 'https://carsharing.de/cs-standorte'

bcs <- read_html(bcs_landing)

bcs
