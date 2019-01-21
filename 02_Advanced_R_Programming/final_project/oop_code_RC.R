pollution <- read.csv("data/MIE.csv" , header = TRUE)
summary(pollution)
dim(pollution)
head(pollution)

LongitudinalData <- setRefClass("LongitudinalData",
                                fields = list(id = "numeric",
                                              visit_num = "numeric",
                                              room_name = "character",
                                              value = "numeric",
                                              timepoint = "numeric"),
                                
                                methods = list(
                                    make_LD = function(df){
                                        ld_df <- df %>% nest(-id)
                                        structure(ld_df, class = c("LonditudinalData"))
                                    },
                                    print = function(x){
                                        paste("Longitudinal dataset with", length(x$id), "subject")
                                        invisible(x)
                                    },
                                    subject = function(ld_df, id) {
                                        index <- which(ld_df[["id"]] == id)
                                        if(length(index) == 0)
                                            return(NULL)
                                        structure(list(id = id, data = ld_df[["data"]][[index]]), class = "subject")
                                    }
                                ))

subject <- setRefClass("subject",
                       contains = "LongitudinalData",
                       fields = list(id = "numeric",
                                     visit_num = "numeric",
                                     room = "character",
                                     ld_df = "data.frame"),
                       methods = list(
                           print = function(x) {
                               cat("Subject ID:",x[["id"]])
                               invisible(x)
                           },
                           summary = function(object) {
                               output <- object[["data"]] %>%
                                   group_by(visit, room) %>%
                                   summarise(value = mean(value)) %>%
                                   spread(room,value) %>%
                                   as.data.frame
                               structure(list(id = object[["id"]],
                                              output = output), class = "Summary")
                           },
                           visit = function(subject, vistit_num){
                               if(!visit_num %in% 0:2)
                                   stop("Must choose a number 0, 1, 2")
                               data <- subject[["data"]] %>%
                                   filter(visit == visit_num) %>%
                                   select(-visit)
                               structure(list(id = subject[["id"]],
                                              visit_num = visit_num,
                                              data = data), class = "Visit")
                           }
                       ))

visit <- setRefClass("visit",
                     fields = list(room_name = "character",
                                   visit_num = "numeric",
                                   subject = "numeric"),
                     methods = list(
                         visit = function(visit, room_name){
                             if(!room_name %in% visit[["data"]][["room"]])
                                 stop("Must provide a valid room name")
                             data <- visit[["data"]] %>%
                                 filter(room == room_name) %>%
                                 select(-room)
                             structure(list(id = visit[["id"]],
                                            visit_num = visit[["visit_num"]],
                                            room = room_name,
                                            data = data), class = "room")
                         }
                     ))
room <- setRefClass("room",
                    fields = list(room_name = "character", visit = "numeric"),
                    methods = list(
                        print = function(x){
                            cat("ID:", x[["id"]], "\n")
                            cat("Visit:", x[["visit_num"]], "\n")
                            cat("Room:", x[["room"]])
                            invisible(x)
                        },
                        summary = function(object) {
                            output <- summary(object[["data"]][["value"]])
                            structure(list(id = object[["id"]],
                                           output = output), class = "Summary")
                        }
                    ))

Summary <- setRefClass("summary",
                       methods = list(
                           print = function(x){
                               cat("ID:", x[[1]], "\n")
                               print(x[[2]])
                               invisible(x)
                           }
                       ))
