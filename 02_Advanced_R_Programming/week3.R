# Debugging and Profiling -------------------------------------------------

# Debugging ---------------------------------------------------------------
# traceback()
check_n_value <- function(n) {
    if(n > 0) {
        stop("n should be <= 0")
    }
}
error_if_n_is_greater_than_zero <- function(n){
    check_n_value(n)
    n
}
error_if_n_is_greater_than_zero(5)
traceback()


# browser()
check_n_value <- function(n) {
    if(n > 0) {
        browser()  ## Error occurs around here
        stop("n should be <= 0")
    }
}
error_if_n_is_greater_than_zero(5)


# trace()
# 1
trace("check_n_value")
error_if_n_is_greater_than_zero(5)

# 2
as.list(body(check_n_value))
as.list(body(check_n_value)[[2]])
trace("check_n_value", browser, at = list(c(2, 3)))
body(check_n_value)

# 3
trace("check_n_value", quote({
    if(n == 5) {
        message("invoking the browser")
        browser()
    }
}), at = 2)
body(check_n_value)

# 4
trace("glm", browser, at = 4, where = asNamespace("stats"))
body(stats::glm)[1:5]


# debug()
# debug(f) ~= trace(f, browser)
debug(lm)
debugonce()

# recover()
options(error = recover)
error_if_n_is_greater_than_zero(5)


# Profiling ---------------------------------------------------------------
# microbenchmark
library(ggplot2)
library(microbenchmark)
tmp <- microbenchmark(a <- rnorm(1000), 
                      b <- mean(rnorm(1000)))
autoplot(tmp)

# profvis
library(profvis)
datafr <- dlnm::chicagoNMMAPS
threshold <- 27

profvis({
    highest_temp <- c()
    record_temp <- c()
    for(i in 1:nrow(datafr)){
        highest_temp <- max(highest_temp, datafr$temp[i])
        record_temp[i] <- datafr$temp[i] >= threshold & 
            datafr$temp[i] >= highest_temp
    }
    datafr <- cbind(datafr, record_temp)
})
# Non-standard evaluation -------------------------------------------------


