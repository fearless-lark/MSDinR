library(magrittr)
library(data.table)

data <- fread("data/MIE.csv")


# S4 classes --------------------------------------------------------------
LongitudinalData <- setClass("LongitudinalData",
                             slots = list(id = "integer",
                                          visit = "integer",
                                          room = "character",
                                          value = "numeric",
                                          timepoint = "numeric"))
LongitudinalDataSummary <- setClass("LongitudinalDataSummary",
                                    contains = "LongitudinalData")
subject <- setClass("subject",
                    contains = "LongitudinalData")
subject_room <- setClass("subject_room",
                         contains = "LongitudinalData")
subject_room_summary <- setClass("subject_room_summary",
                                 contains = "subject_room")


# make_LD -----------------------------------------------------------------
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
                  new("subject",
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


# visit -------------------------------------------------------------------
setGeneric("visit", function(x, ...){
    standardGeneric("visit")
})
setMethod("visit",
          c(x = "LongitudinalData"),
          function(x, v_num) {
              if (v_num %in% x@visit) {
                  new("LongitudinalData",
                      id = x@id[x@visit == v_num],
                      visit = x@visit[x@visit == v_num],
                      room = x@room[x@visit == v_num],
                      value = x@value[x@visit == v_num],
                      timepoint = x@timepoint[x@visit == v_num]
                  )
              } else {
                  NULL
              }
          })


# room --------------------------------------------------------------------
setGeneric("room", function(x, ...){
    standardGeneric("room")
})
setMethod("room",
          c(x = "LongitudinalData"),
          function(x, room_name) {
              if (room_name %in% x@room) {
                  new("subject_room",
                      id = x@id[x@room == room_name],
                      visit = x@visit[x@room == room_name],
                      room = x@room[x@room == room_name],
                      value = x@value[x@room == room_name],
                      timepoint = x@timepoint[x@room == room_name]
                  )
              } else {
                  NULL
              }
          })


# summary -----------------------------------------------------------------
# isGeneric("summary")
setGeneric("summary")

setMethod("summary",
          signature(object = "LongitudinalData"),
          function(object) {
              dt <- data.table(id = object@id,
                               visit = object@visit,
                               room = object@room,
                               value = object@value)
              dt %<>% .[, .(value = mean(value)),
                        by = list(id, visit, room)]
              new("LongitudinalDataSummary",
                  id = dt$id,
                  visit = dt$visit,
                  room = dt$room,
                  value = dt$value
              )
          })

setMethod("summary",
          signature(object = "subject_room"),
          function(object) {
              dt <- data.table(id = object@id,
                               visit = object@visit,
                               room = object@room,
                               value = object@value)
              new("subject_room_summary",
                  id = dt$id,
                  visit = dt$visit,
                  room = dt$room,
                  value = dt$value
              )
          })

# prints ------------------------------------------------------------------
setGeneric("print")

setMethod("print",
          signature(x = "LongitudinalData"),
          function(x) {
              paste("Longitudinal dataset with", uniqueN(x@id), "subjects")
          })


setMethod("print",
          c(x = "LongitudinalDataSummary"),
          function(x) {
              dt <- data.table(id = x@id,
                               visit = x@visit,
                               room = x@room,
                               value = x@value)
              
              dt %<>% 
                  dcast.data.table(formula = id + visit ~ room,
                                   value.var = "value")
              
              print(paste("ID:", unique(x@id)))
              print(dt[, -c("id")])
          })


setMethod("print",
          signature(x = "subject"),
          function(x) {
              paste("Subject ID:", unique(x@id))
          })


setMethod("print",
          c(x = "subject_room"),
          function(x) {
              out <- paste(paste("ID:", unique(x@id)),
                           paste("Visit:", unique(x@visit)),
                           paste("Room:", unique(x@room)),
                           sep = "\n")
              cat(out, sep = '\n')
          })


setMethod("print",
          c(x = "subject_room_summary"),
          function(x) {
              print(paste("ID:", unique(x@id)))
              print(summary(x@value))
          })
