library(shiny)
library(dplyr)

ui <- fluidPage(
  shinyFeedback::useShinyFeedback(),
  h3('A Day with Mr. Garvey'),
  textInput(
    'name',
    'What\'s your name?',
  )
)

names <- c('Jay Quellin','Jacqueline', 'Balakay', 'Blake', 'Dee-nice', 'Denise',
           'Ay-Ay-Ron', 'Aaron')
return_msg <- function(name) {
  case_when(
    name == 'Balakay' ~ 'My name is Blake.',
    name == 'Blake' ~ 'Do you wanna go to war, Balakay? You better check yourself!',
    name == 'Jay Quellin' ~ 'Do you mean Jacqueline?',
    name == 'Jacqueline' ~ 'So that\'s how it\'s going to be. I got my eye on you Jay Quellin!',
    name == 'Dee-nice' ~ 'Do you mean Denise?',
    name == 'Denise' ~ 'You say your name right!',
    name == 'Ay-Ay-Ron' ~ 'It is pronounced Aaron.',
    name == 'Aaron' ~ 'You done messed up Ay-Ay-Ron!'
  )
}

server <- function(input, output, session) {
  name_input <- reactive(input$name) %>% debounce(250)
  observeEvent(name_input(), {
    shinyFeedback::hideFeedback('name')
    
    shinyFeedback::feedbackDanger(
      'name',
      show = (name_input() %in% names),
      text = return_msg(name_input())
    )
    
    req(name_input(), !(name_input() %in% names))
    shinyFeedback::feedbackSuccess(
      'name',
      show = !(name_input() %in% names),
      text = 'Thank you!'
    )
  })
}

shinyApp(ui, server)