library(shiny)
library(tidyverse)

ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "superhero"),
  
  titlePanel("Old Faithful Geyser Data"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("bins",
                  "Number of bins:",
                  min = 1,
                  max = 50,
                  value = 30)
    ),
    
    mainPanel(
      plotOutput("distPlot")
    )
  )
)

server <- function(input, output) {
  
  
    output$distPlot <- renderPlot({
      x    <- faithful[, 2]
      # input$bins isolated here
      bins <- seq(min(x), max(x), length.out = isolate(input$bins) + 1)
      hist(x, breaks = bins, col = 'darkgray', border = 'white')
    })
}


shinyApp(ui = ui, server = server)
