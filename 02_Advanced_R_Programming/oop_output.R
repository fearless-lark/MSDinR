library(purrr)
library(ggplot2)
library(magrittr)
library(data.table)
library(microbenchmark)
# source("oop_code.R")


# id: the subject identification number
# visit: the visit number which can be 0, 1, or 2
# room: the room in which the monitor was placed
# value: the level of pollution in micrograms per cubic meter
# timepoint: the time point of the monitor value for a given visit/room

# make_LD: a function that converts a data frame into a “LongitudinalData” object
# subject: a generic function for extracting subject-specific information
# visit: a generic function for extracting visit-specific information
# room: a generic function for extracting room-specific information

data <- fread("data/MIE.csv")


# Reference Classes (RC) --------------------------------------------------
# LongitudinalData <- setRefClass("LongitudinalData",
#                                 fields = list(id = "numeric",
#                                               value = "numeric",
#                                               visit = "numeric",
#                                               room = "character",
#                                               timepoint = "numeric"),
#                                 methods = list(
#                                     subject = function(id) {
#                                         x[id == id]
#                                     }
#                                 ))
# make_LD <- function(df) {
#     LongitudinalData$new(id = df$id, 
#                          room = df$room, 
#                          visit = df$visit, 
#                          value = df$value, 
#                          timepoint = df$timepoint)
# }



# S4 ----------------------------------------------------------------------
LongitudinalData <- setClass("LongitudinalData",
                             slots = list(id = "integer",
                                          visit = "integer",
                                          room = "character",
                                          value = "numeric",
                                          timepoint = "numeric"))
make_LD <- function(df) {
    new("LongitudinalData",
        id = df$id, 
        visit = df$visit, 
        room = df$room, 
        value = df$value, 
        timepoint = df$timepoint
    )
}


x <- make_LD(data)
print(class(x))
print(x)


# subject -----------------------------------------------------------------
setGeneric("subject", function(x, ...){
    standardGeneric("subject")
})
setMethod("subject",
          c(x = "LongitudinalData"),
          function(x, num) {
              if (num %in% x@id) {
                  new("LongitudinalData",
                      id = x@id[x@id == num],
                      visit = x@visit[x@id == num],
                      room = x@room[x@id == num],
                      value = x@value[x@id == num],
                      timepoint = x@timepoint[x@id == num]
                  )
              } else {
                  NULL
              }
          })



# print -------------------------------------------------------------------
setGeneric("print")
setMethod("print",
          c(x = "LongitudinalData"),
          function(x) {
              paste("Subject ID:", unique(x@id))
          })


# summary -----------------------------------------------------------------
# setGeneric("summary")
setMethod("summary",
          c(x = "LongitudinalData"),
          function(x, num) {
              if (num %in% x@id) {
                  new("LongitudinalData",
                      id = x@id[x@id == num],
                      visit = x@visit[x@id == num],
                      room = x@room[x@id == num],
                      value = x@value[x@id == num],
                      timepoint = x@timepoint[x@id == num]
                  )
              } else {
                  NULL
              }
          })




# subject.LongitudinalData <- function(df, id) {
#     df[id == id]
# }

subject(x, 14)




## Subject 10 doesn't exist
out <- subject(x, 10)
print(out)
# x$subject(10)

out <- subject(x, 14)
print(out)

out <- subject(x, 54) %>% summary
print(out)

out <- subject(x, 14) %>% summary
print(out)

out <- subject(x, 44) %>% visit(0) %>% room("bedroom")
print(out)

## Show a summary of the pollutant values
out <- subject(x, 44) %>% visit(0) %>% room("bedroom") %>% summary
print(out)

out <- subject(x, 44) %>% visit(1) %>% room("living room") %>% summary
print(out)