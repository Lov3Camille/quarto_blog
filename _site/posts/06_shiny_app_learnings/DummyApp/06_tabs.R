library(shiny)
library(tidyverse)


## Helper functions - could technically be moved to separate file
create_UI <- function(unique_part) {
  sidebarLayout(
    sidebarPanel(
      sliderInput(paste("bins", unique_part, sep = "_"),
                  "Number of bins:",
                  min = 1,
                  max = 50,
                  value = 30),
      actionButton(paste("draw_button", unique_part, sep = "_"), "Reevaluate!", width = "100%"),
      actionButton(paste("change_view", unique_part, sep = "_"), "Change view", width = "100%")
    ),
    
    mainPanel(
      textOutput(paste("demonstration_text", unique_part, sep = "_")), # Counter text added
      textOutput(paste("countEvaluations", unique_part, sep = "_")),
      plotOutput(paste("distPlot", unique_part, sep = "_"))
    )
  )
}

render_my_plot <- function(panel, counter, input, output) {
  tmp <- counter() # save current value of counter
  counter(tmp + 1) # update counter
  
  # Create identifier names
  bins_name <- paste("bins", panel, sep = "_")
  distplot_name <- paste("distPlot", panel, sep = "_")
  demonstration_text <- paste("demonstration_text", panel, sep = "_")
  
  # Render plot
  output[[distplot_name]] <- renderPlot({
    x    <- faithful[, 2]
    bins <- seq(min(x), max(x), length.out = isolate(pluck(input, bins_name)) + 1)
    hist(x, breaks = bins, col = 'darkgray', border = 'white')
  })
  
  # Render counter text
  output[[demonstration_text]] <- renderText(paste(
    "You have clicked the draw button",
    counter(),
    "times. Congrats!"
  ))
}

####### End helper functions

ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "superhero"),
  titlePanel("Old Faithful Geyser Data"),
  tabsetPanel(
    id = "my_tabs",
    selected = "panel1",
    type = "hidden",
    tabPanel("panel1", create_UI("panel1")),
    tabPanel("panel2", create_UI("panel2"))
  )
  
)

server <- function(input, output) {
  # Counter initialization
  counter <- reactiveVal(value = 0)
  counter2 <- reactiveVal(value = 0)
  
  # Plot Rendering
  observeEvent(
    input$draw_button_panel1, {
      render_my_plot("panel1", counter, input, output)
    }
  )
  observeEvent(
    input$draw_button_panel2, {
      render_my_plot("panel2", counter2, input, output)
    }
  )
  
  # Panel Switching
  observeEvent(
    input$change_view_panel1, 
    updateTabsetPanel(inputId = "my_tabs", selected = "panel2")
  )
  observeEvent(
    input$change_view_panel2, 
    updateTabsetPanel(inputId = "my_tabs", selected = "panel1")
  )
}


shinyApp(ui = ui, server = server)
