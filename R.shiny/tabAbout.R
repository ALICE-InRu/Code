output$tabAbout <- renderUI({
  dashboardBody(
    fluidRow(h2('ALICE: Adaptive Learning Intelligent Composite rulEs')),
    fluidRow(
      column(6,
             includeMarkdown("about.md")
      ),
      column(3,
             img(class="img-polaroid",
                 src=paste0("http://upload.wikimedia.org/",
                            "wikipedia/commons/b/ba/",
                            "Alice_par_John_Tenniel_30.png"), height=500),
             tags$small(
               "Source: original illustration (1865) by",
               a(href="http://en.wikipedia.org/wiki/John_Tenniel",
                 "John Tenniel"),
               "(1820-1914), of the novel Alice's Adventures in Wonderland by",
               a(href="http://en.wikipedia.org/wiki/Lewis_Carroll",
                 "Lewis Carroll")
             )
      )
    ),
    fluidRow(h6(HTML(paste0(
      #'<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a><br />',
      '<span xmlns:dct="http://purl.org/dc/terms/" property="dct:title">ALICE</span> by <span xmlns:cc="http://creativecommons.org/ns#" property="cc:attributionName">Helga Ingimundardottir</span> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.<br />')), align = "center"))
  )
})
