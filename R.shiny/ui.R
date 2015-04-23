source('tabHeader.R')

sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Data set", icon = icon("dashboard"),
             selectInput("dimension", "Dimension:",
                         levels(dataset.OPT$Dimension),multiple=F),
             selectInput("problems", "Problem distributions:",multiple=T,
                         levels(dataset.OPT$Problem),
                         selected='j.rnd'),
             selectInput("problem", "Main problem distribution:",
                         levels(dataset.OPT$Problem),
                         selected='j.rnd')
             ),
    menuItem("General", icon = icon("home"),
             menuSubItem("Gantt charts", tabName = "gantt", icon = icon("car")),
             menuSubItem("SDR", tabName = "sdr", icon = icon("car")),
             menuSubItem("BDR", tabName = "bdr", icon = icon("car")),
             menuSubItem("Difficulty", tabName = "sdrDifficulty", icon = icon("car"))
             ),
    menuItem("Preference models", icon = icon("plane"),
             menuSubItem("LIBLINEAR settings", tabName = "prefSettings", icon = icon("car")),
             menuSubItem("Feature reduction", tabName = "prefExhaustive", icon = icon("car")),
             menuSubItem("Imitation learning", tabName = "prefImitationLearning", icon = icon("university"))
    ),
    menuItem("Optimality", tabName = "opt", icon = icon("bold")),
    menuItem("Features", tabName = "feat", icon = icon("binoculars"),
             badgeLabel = "new", badgeColor = "green"),
    menuItem("DataTable", tabName = "table", icon = icon("table")),
    menuItem("Save", icon = icon("save"),
             selectInput("save", "Save as", choices = ifelse(!is.na(file.info(subdir)$isdir),
                                                             c("none"="none","full page"="full","half page"="half"),'NA'))),
    menuItem("Source code", icon = icon("github"),
             href = "https://github.com/tungufoss/alice/"),
    menuItem("About", tabName="about", icon = icon("github-alt"))
  )
)
body <- dashboardBody(
  tabItems(
    tabItem(tabName = "sdr", uiOutput("tabSDR")),
    tabItem(tabName = "bdr", uiOutput("tabBDR")),
    tabItem(tabName = "sdrDifficulty", uiOutput("tabDifficulty")),
    tabItem(tabName = "gantt", uiOutput("tabGantt")),
    tabItem(tabName = "opt", uiOutput("tabOpt")),
    tabItem(tabName = "feat", uiOutput("tabFEAT")),
    tabItem(tabName = "table", uiOutput("tabTable")),
    tabItem(tabName = "prefSettings", uiOutput("tabPref.settings")),
    tabItem(tabName = "prefExhaustive", uiOutput("tabPref.exhaustive")),
    tabItem(tabName = "prefImitationLearning", uiOutput("tabPref.imitationLearning")),
    tabItem(tabName = "about", uiOutput("tabAbout"))
  )
)
ui <- dashboardPage(header, sidebar, body)
