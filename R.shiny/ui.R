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
             menuSubItem("SDR", tabName = "sdr", icon = icon("chain")),
             menuSubItem("Gantt charts", tabName = "gantt", icon = icon("clock-o")),
             menuSubItem("BDR", tabName = "bdr", icon = icon("code-fork")),
             menuSubItem("Difficulty", tabName = "sdrDifficulty", icon = icon("trophy"))
             ),
    menuItem("Preference models", icon = icon("gears"),
             menuSubItem("LIBLINEAR settings", tabName = "prefSettings", icon = icon("gear")),
             menuSubItem("Trajectories & ranks", tabName = "prefTrajectories", icon = icon("search")),
             menuSubItem("Stepwise bias", tabName = "prefStepwiseBias", icon = icon("clock-o")),
             menuSubItem("Feature reduction", tabName = "prefExhaustive", icon = icon("angle-double-down")),
             menuSubItem("Imitation learning", tabName = "prefImitationLearning", icon = icon("copy"))
    ),
    menuItem("Optimality", icon = icon("bold"),
             menuSubItem("Uniqueness", tabName = "optUniqueness", icon = icon("star")),
             menuSubItem("SDR", tabName = "optSDR", icon = icon("star-half-empty")),
             menuSubItem("Best and worst case scenario", tabName = "optBW", icon = icon("star-o"))
             ),
    menuItem("Features", tabName = "feat", icon = icon("binoculars")),
    menuItem("CMA-ES", tabName = "cmaes", icon = icon("globe")),
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
    tabItem(tabName = "optUniqueness", uiOutput("tabOpt.uniqueness")),
    tabItem(tabName = "optSDR", uiOutput("tabOpt.SDR")),
    tabItem(tabName = "optBW", uiOutput("tabOpt.bw")),
    tabItem(tabName = "feat", uiOutput("tabFEAT")),
    tabItem(tabName = "cmaes", uiOutput("tabCMAES")),
    tabItem(tabName = "table", uiOutput("tabTable")),
    tabItem(tabName = "prefSettings", uiOutput("tabPref.settings")),
    tabItem(tabName = "prefTrajectories", uiOutput("tabPref.trajectories")),
    tabItem(tabName = "prefStepwiseBias", uiOutput("tabPref.stepwiseBias")),
    tabItem(tabName = "prefExhaustive", uiOutput("tabPref.exhaustive")),
    tabItem(tabName = "prefImitationLearning", uiOutput("tabPref.imitationLearning")),
    tabItem(tabName = "about", uiOutput("tabAbout"))
  )
)
ui <- dashboardPage(header, sidebar, body)
