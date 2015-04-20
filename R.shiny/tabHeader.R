header <- dashboardHeader(title = 'ALICE',
                          #disable = TRUE,
                          dropdownMenu(type = "messages",
                                       messageItem(
                                         from = "Training data",
                                         message = "Unsupervised IL for 10x10 j.rndn is ready.",
                                         icon = icon("life-ring"),
                                         time = "2014-04-13"
                                       )
                          ),
                          dropdownMenu(type = "notifications",
                                       notificationItem(
                                         text = "Imitation learning based on DAGGER",
                                         icon("truck"),
                                         status = "success"
                                       ),
                                       notificationItem(
                                         text = "Implement fixed imitation learning",
                                         icon = icon("exclamation-triangle"),
                                         status = "warning"
                                       ),
                                       notificationItem(
                                         text = "Look into 'global' features",
                                         icon("globe"),
                                         status = "warning"
                                       )
                          ),
                          dropdownMenu(type = "tasks", badgeStatus = "success",
                                       taskItem(value = 75, color = "green",
                                                "Imitation learning"
                                       ),
                                       taskItem(value = 50, color = "aqua",
                                                "Features"
                                       ),
                                       taskItem(value = 80, color = "red",
                                                "Overall project"
                                       )
                          )
)
