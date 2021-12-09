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
                  value = 30),
      # Added Button here
      actionButton("draw_button", "Reevaluate!", width = "100%")
    ),
    
    mainPanel(
      plotOutput("distPlot")
    )
  )
)

server <- function(input, output) {
  
  #  Create reactive variable through event
  plot <- eventReactive(
    input$draw_button, {
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)
        hist(x, breaks = bins, col = 'darkgray', border = 'white')
      }
  )
  
  output$distPlot <- renderPlot({plot()})
  
}


shinyApp(ui = ui, server = server)
