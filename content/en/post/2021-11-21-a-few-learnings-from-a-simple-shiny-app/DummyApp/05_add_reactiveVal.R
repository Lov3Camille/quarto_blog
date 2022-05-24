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
      actionButton("draw_button", "Reevaluate!", width = "100%")
    ),
    
    mainPanel(
      textOutput("demonstration_text"), # Counter text added
      textOutput("countEvaluations"),
      plotOutput("distPlot")
    )
  )
)

server <- function(input, output) {
  # Initialize counter here
  counter <- reactiveVal(value = 0)
  
  observeEvent(
    input$draw_button, {
      tmp <- counter() # save current value of counter
      counter(tmp + 1) # update counter
      
      output$distPlot <- renderPlot({
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = isolate(input$bins) + 1)
        hist(x, breaks = bins, col = 'darkgray', border = 'white')
      })
      
      # Render counter text
      output$demonstration_text <- renderText(paste(
        "You have clicked the draw button",
        counter(),
        "times. Congrats!"
      ))
    }
  )

}


shinyApp(ui = ui, server = server)
