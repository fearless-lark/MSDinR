library(purrr)
library(ggplot2)
library(magrittr)
library(data.table)
library(microbenchmark)


# functions ---------------------------------------------------------------

# 1. Factorial_loop: a version that computes the factorial of an integer using 
# looping (such as a for loop)
fctrl_lp <- function(x) {
    
    if (x < 0 || (x %% 1) > 0) {
        stop("x must be a positive integer")
    }
    
    if (x == 0) {
        return(1)
    } else {
        fctrl <- 1
        for (i in seq_len(x)) {
            fctrl <- i * fctrl
        }
    }
    return(fctrl)
}


# 2. Factorial_reduce: a version that computes the factorial using the reduce() 
# function in the purrr package. Alternatively, you can use the Reduce() 
# function in the base package.
fctrl_rdc <- function(x) {
    
    if (x < 0 || (x %% 1) > 0) {
        stop("x must be a positive integer")
    }
    
    if (x == 0) {
        return(1)
    } else {
        fctrl <- purrr::reduce(seq_len(x), prod)
    }
    return(fctrl)
}


# 3. Factorial_func: a version that uses recursion to compute the factorial.
fctrl_rcrsn <- function(x) {
    
    if (x < 0 || (x %% 1) > 0) {
        stop("x must be a positive integer")
    }
    
    if (x == 0) {
        return(1)
    } else {
        fctrl <- x * fctrl_rcrsn(x - 1) 
    }
    return(fctrl)
}


# 4. Factorial_mem: a version that uses memoization to compute the factorial.
fctrl_tbl <- c(1, rep(NA, 50))

fctrl_rcrsn_mem <- function(x) {
    
    if (x < 0 || (x %% 1) > 0) {
        stop("x must be a positive integer")
    }
    
    if (x == 0) {
        return(1)
    } else {
        
        if(!is.na(fctrl_tbl[x])){
            fctrl_tbl[x]
        } else {
            fctrl_tbl[x - 1] <<- fctrl_rcrsn_mem(x - 1)
            fctrl_tbl[x - 1] * x
        }
        
    }
}



# comparison --------------------------------------------------------------
# function that extracs microbenchmark data
get_microbenchmark_data <- function(v, fun, fun_name, repeats = 100) {
    
    tb <- map(v, function(x){microbenchmark(fun(x), times = repeats)$time})
    df <- as.data.frame(tb)
    
    df %<>% 
        sapply(., median) %>% 
        melt(value.name = "time")
    setDT(df)
    
    df[, num := v]
    df[, method := fun_name]
    
    return(df)
    
}

# perform calculations
vec <- 1:20
fctrl_data_1 <- get_microbenchmark_data(v = vec, fun = fctrl_lp, fun_name = "fctrl_lp")
fctrl_data_2 <- get_microbenchmark_data(v = vec, fun = fctrl_rdc, fun_name = "fctrl_rdc")
fctrl_data_3 <- get_microbenchmark_data(v = vec, fun = fctrl_rcrsn, fun_name = "fctrl_rcrsn")
fctrl_data_4 <- get_microbenchmark_data(v = vec, fun = fctrl_rcrsn_mem, fun_name = "fctrl_rcrsn_mem")

# merging data from different functions
fctrl_data <- rbindlist(list(fctrl_data_1, 
                             fctrl_data_2, 
                             fctrl_data_3, 
                             fctrl_data_4))

# points plot
fctrl_data %>% 
    ggplot(aes(x = num, y = time, color = method)) +
    geom_point() +
    facet_wrap(.~method)

# automatical comparison
vec <- 1:20
comparison <- microbenchmark(map(vec, fctrl_lp),
                             map(vec, fctrl_rdc),
                             map(vec, fctrl_rcrsn),
                             map(vec, fctrl_rcrsn_mem),
                             times = 100)
comparison

vec <- 1:50
comparison <- microbenchmark(map(vec, fctrl_lp),
                             map(vec, fctrl_rdc),
                             map(vec, fctrl_rcrsn),
                             map(vec, fctrl_rcrsn_mem),
                             times = 100)
comparison

# automatical plot
autoplot(comparison)
