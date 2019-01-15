library(swirl)

library(readr)
library(dplyr)

## Download data from RStudio (if we haven't already)
if(!file.exists("data/2016-07-20.csv.gz")) {
    download.file("http://cran-logs.rstudio.com/2016/2016-07-20.csv.gz", 
                  "data/2016-07-20.csv.gz")
}
# cran <- read_csv("data/2016-07-20.csv.gz", col_types = "ccicccccci")
# cran %>% filter(package == "filehash") %>% nrow


check_pkg_deps <- function() {
    if(!require(readr)) {
        message("installing the 'readr' package")
        install.packages("readr")
    }
    if(!require(dplyr))
        stop("the 'dplyr' package needs to be installed first")
}

check_for_logfile <- function(date) {
    year <- substr(date, 1, 4)
    src <- sprintf("http://cran-logs.rstudio.com/%s/%s.csv.gz",
                   year, date)
    dest <- file.path("data", basename(src))
    if(!file.exists(dest)) {
        val <- download.file(src, dest, quiet = TRUE)
        if(!val)
            stop("unable to download file ", src)
    }
    dest
}

## 'pkgname' can now be a character vector of names
num_download <- function(pkgname, date = "2016-07-20") {
    check_pkg_deps()
    
    ## Check arguments
    if(!is.character(pkgname))
        stop("'pkgname' should be character")
    if(!is.character(date))
        stop("'date' should be character")
    if(length(date) != 1)
        stop("'date' should be length 1")
    
    dest <- check_for_logfile(date)
    cran <- read_csv(dest, col_types = "ccicccccci", 
                     progress = FALSE)
    cran %>% filter(package %in% pkgname) %>% 
        group_by(package) %>%
        summarize(n = n())
}

num_download(c("Rcpp", "filehash", "weathermetrics"))
