library(shiny)
library(tibble)
library(ggplot2)
library(dplyr)
library(ggforce)
library(deldir)

col2hex <- gplots::col2hex
colorValues <- colors()
colorNames <- glue::glue("{colorValues} <span style='background-color:{col2hex(colorValues)}'>{rep('&nbsp;', 15) %>% stringr::str_c(collapse = '')}</span>")
colors <- setNames(colorValues, colorNames)
js_render_string <- I("
  {
    item: function(item, escape) { return '<div>' + item.label + '</div>'; },
    option: function(item, escape) { return '<div>' + item.label + '</div>'; }
  }")

# Define UI for application that draws a histogram
ui <- fluidPage(
  shinyFeedback::useShinyFeedback(),
  theme = bslib::bs_theme(bootswatch = "litera"),
  # Application title
  titlePanel("Voronoi Drawings"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      tabsetPanel(
        tabPanel(
          title = 'drawing',
          h3('Colour Settings'),
          selectizeInput(
            "color",
            "Colour",
            selected = 'grey80',
            choices = colors,
            options = list(render = js_render_string)
          ),
          selectizeInput(
            "mode",
            "Mode",
            selected = 'Colouring',
            choices = c('Colouring', 'Adding')
          ),
          selectizeInput(
            "line_color",
            "Line Colour",
            selected = 'black',
            choices = colors,
            options = list(render = js_render_string)
          ),
          h3('Simulate cells'),
          numericInput(
            'n_cells',
            'Number of new cells',
            value = NA,
            min = 2,
            max = 1000,
            step = 1
          ),
          checkboxInput(
            'random_colors',
            'Fill with random colors?',
            value = F
          ),
          actionButton(
            'simulate_btn',
            'Simulate!'
          )
          
          
        ),
        tabPanel(
          title = 'Export',
          h3('Download data'),
          splitLayout(
            downloadButton('download_tsv', label = '.tsv'), 
            downloadButton('download_csv', label = '.csv (,)'),
            downloadButton('download_csv2', label = '.csv (;)'),
            cellWidths = rep('33%', 3),
            cellArgs = list(style = "margin: 2% 0 0 2%;")
          ),
          h3('Download picture'),
          selectizeInput(
            "file_format",
            "File Format",
            selected = 'png',
            choices = c('png', 'jpeg'),
          ),
          selectizeInput(
            "size",
            'Size (in cm)',
            selected = '8x8',
            choices = glue::glue('{8:20}x{8:20}')
          ),
          downloadButton('download_pic', 'Download picture')
          
        )
      )
      
      
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("canvas", click = 'canvas_click', width = '500px', height = '500px'),
    )
  )
)

change_colors_by_dist <- function(coordinates, clicked_x, clicked_y, new_color) {
  coordinates %>% 
    mutate(
      dist = (x - clicked_x)^2 + (y - clicked_y)^2,
      nearest_point = (dist == min(dist)),
      color = if_else(nearest_point, new_color, color)
    ) %>% 
    select(x, y, color)
}

download_backend <- function(format, data) {
  downloadHandler(
    filename = function() {glue::glue("voronoi_data.{stringr::str_sub(format, 1, 3)}")},
    content = function(file) {
      vroom::vroom_write(
        x = if (format == 'csv2') {
          data %>% 
            mutate(across(
              .cols = c('x', 'y'), 
              .fns = ~scales::comma(.,accuracy = 0.00001, decimal.mark = ',', big.mark = '')
            ))
        } else {data} , 
        file,
        delim = case_when(
          format == 'tsv' ~ '\t',
          format == 'csv' ~ ',',
          format == 'csv2' ~ ';'
        )
      )
    }
  )
}

# Define server logic required to draw a histogram
server <- function(input, output) {

  coordinates <- reactiveVal(
    tibble(x = runif(10), y = runif(10), color = 'grey80')
  )
  
  observeEvent(input$canvas_click, {
    if (input$mode == 'Adding') {
      coordinates(
        coordinates() %>% 
          bind_rows(
            tibble(
              x = input$canvas_click$x,  
              y = input$canvas_click$y,
              color = input$color
            )
          ) %>% 
          unique()
      )
    } else {
      coordinates(
        coordinates() %>% 
          change_colors_by_dist(
            input$canvas_click$x,
            input$canvas_click$y,
            input$color
          )
      )
    }
    
  })
  
  plot <- reactive({
    coordinates() %>% 
      ggplot(aes(x, y, group = 1, fill = color)) +
      geom_point() +
      geom_voronoi_tile(bound = c(0, 1, 0, 1)) +
      geom_voronoi_segment(bound = c(0, 1, 0, 1), color = input$line_color) +
      coord_equal(xlim = c(0, 1), ylim = c(0, 1), expand = F) +
      theme_void() +
      scale_fill_identity()
  })
  
  output$canvas <- renderPlot({plot()})
  
  
  observeEvent(input$simulate_btn, {
    # Check if value has been provided
    shinyFeedback::feedbackWarning(
      "n_cells", 
      is.na(input$n_cells), 
      "Please provide integer between 2 and 1000"
    )
    req(input$n_cells)
    
    # Check if provided value is valid
    integer_in_range <- between(input$n_cells, 2, 1000) & (input$n_cells %% 1 == 0)
    shinyFeedback::feedbackWarning(
      "n_cells", 
      !integer_in_range, 
      "Please select integer between 2 and 1000"
    )
    req(integer_in_range)
    
    # Set new coordinates
    coordinates(
      tibble(
        x = runif(input$n_cells), 
        y = runif(input$n_cells), 
        color = if (input$random_colors) {
          sample(colorValues, input$n_cells, replace = T)
        } else {
          input$color
        }
      )
    )
    
    # Some positive feedback
    shinyFeedback::feedbackSuccess(
      'n_cells',
      T,
      text = 'Simulation successful!'
    )
  })
  
  output$download_tsv <- download_backend('tsv', coordinates())
  output$download_csv <- download_backend('csv', coordinates())
  output$download_csv2 <- download_backend('csv2', coordinates())
  
  picture_size <- reactive({
    stringr::str_split(input$size, 'x') %>% 
      purrr::pluck(1, 1) %>% 
      as.numeric()
  })
  
  output$download_pic <- downloadHandler(
    filename = function() {glue::glue("voronoi_picture.{input$file_format}")},
    content = function(file) {
      ggsave(file, plot(), width = picture_size(), height = picture_size(), units = 'cm')
    }
  )
  
}

# Run the application 
shinyApp(ui = ui, server = server)
