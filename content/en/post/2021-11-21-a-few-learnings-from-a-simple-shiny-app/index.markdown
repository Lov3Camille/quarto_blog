---
title: "6 simple Shiny things I have learned from creating a somewhat small app"
author: ''
date: '2021-12-09'
slug: []
categories: []
tags: []
description: "I recently built a small Shiny app where I had to search for how to do a lot of things. Here are 6 things I learned doing that. Maybe a Shiny beginner will find something useful in here."
hideToc: no
enableToc: yes
enableTocContent: no
tocFolding: no
tocPosition: inner
tocLevels:
  - h2
  - h3
  - h4
series: ~
image: ~
libraries:
  - mathjax
---



A couple of weeks back, I wanted to explain to my student what I mean when I talk about the "variance of the sample variance". In my head, this term sounds quite confusing and contains the word "variance" at least one too many times. But as I was not sure whether my subsequent explanation really came through, I decided to let my students explore the notion on their own through [a Shiny app](https://rappa.shinyapps.io/estimator-variance/).

Honestly, I thought this would be quite simple to code because I have already learned the basics of Shiny when I wanted to show my students what exciting web developmental things R can do. Back then, I summarized the basics in one chapter of [my YARDS lecture notes](https://yards.albert-rapp.de/shiny-applications.html).

However, even though the idea of my app was simple, I soon came to realize that I would need to learn a couple more Shiny-related things to get the job done. And, as is usual with coding, I did this mostly by strolling through the web in order to find code solutions for my particular problems. Most of the time, I consulted Hadley Wickham's [Mastering Shiny](https://mastering-shiny.org/) but still I ended up searching for a lot of random other stuff on the web. 

Consequently, I decided that it might be nice to collect what I have learned in one place. So, here is a compilation of loosely connected troubles I solved during my Shiny learning process. May this summary serve someone well.

## Use a theme for simple customization
Let's start with something super easy.
If you wish to customize the appearance of you app, you can set the `theme` argument of `fluidPage()` to either a CSS-file that contains the necessary configuration (this is the hard way) or use a theme from `bslib::bs_theme()`.
The latter approach comes with a lot of named preimplemented themes and is easily implemented by `bootswatch = "name"`.
In my app, I have simply added `theme = bslib::bs_theme(bootswatch = "superhero")`.
For other themes, have a look at [RStudio's Shiny themes page](https://rstudio.github.io/shinythemes/).

Check out this super simple example that I have adapted from the default "new Shiny app" output (you will actually have to copy and run this in an R script on your own).


```r
library(shiny)
library(tidyverse)

ui <- fluidPage(
  # Theme added here
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
    bins <- seq(min(x), max(x), length.out = input$bins + 1)
    hist(x, breaks = bins, col = 'darkgray', border = 'white')
  })
}

shinyApp(ui = ui, server = server)
```

During the course of this text, we will extend this small example bit by bit. But, I want to avoid copy-and-pasting code each time we change something. Thus, for the remaining examples I will only describe the changes to the previous version instead of pasting the whole code. Nevertheless, I will provide links after each example so that each script can be downloaded at will. The current example can be found [here](https://albert-rapp.de/post/2021-11-21-a-few-learnings-from-a-simple-shiny-app/DummyApp/01_add_theme.R).

## Isolate slider from reactivity

As is currently intended, our app's histogram changes whenever the slider is moved.
Sometimes, though, this is not what we wish to do.
Instead, we may want to delay the rendering of the plot until a button is clicked.

This can be achieved through a simple `isolate()` command which, well, isolates whatever is in between the function's parentheses from changes on the UI. 
Here, let us put `input$bins` into the `isolate()` function and check what happens when we move the slider (full code [here](https://albert-rapp.de/post/2021-11-21-a-few-learnings-from-a-simple-shiny-app/DummyApp/02_add_isolate.R)), i.e. we changed

```r
bins <- seq(min(x), max(x), length.out = isolate(input$bins) + 1)
```
Excellent! Nothing happens when we move the slider. Dumb and useless but excellent anyway.

Observe that we could have also put the whole `renderPlot()` function call into `isolate()`.
This app would work in the sense that we created valid code but then the reactivity of the slider is still active.
The `isolate()` documentation hints at this with "...if you assign a variable inside the isolate(), its value will be visible outside of the `isolate()`". 

## Create and observe Buttons
Let us bring back some reactivity to our app by adding a button that reevaluates our histogram when clicked.
First, we will add a button to the UI.
Second, we will implement what needs to happen on the server side of things when the button is clicked.

The first step is pretty simple.
All we have to do is add `actionButton()` to the UI.
Same as `sliderInput()` we have to specify a `inputId` and `label` for the button.
Here, we could add

```r
actionButton("draw_button", "Reevaluate!", width = "100%")
```

Then, on the server side we will have to catch each click on the button.
Once a click is registered, the plot is supposed to be rendered again.
We do this with `observeEvent()` which expects an event expression and a handler expression.
In our case, the former is simply the id of our button, i.e. `input$draw_button`, and the latter is what code is to be executed when the event is observed.
Therefore, we move our code for rendering the plot into this part of `observeEvent()`.
Thus, in our server function we now have

```r
observeEvent(
  input$draw_button, {
    output$distPlot <- renderPlot({
      x    <- faithful[, 2]
      bins <- seq(min(x), max(x), length.out = isolate(input$bins) + 1)
      hist(x, breaks = bins, col = 'darkgray', border = 'white')
    })
  }
)
```

Notice that we have wrapped our code into `{}`.
Strictly speaking, this is not necessary because we only "do one thing" but, of course, we can easily imagine that we want to tie multiple calculations to a button click.
In this case, we will need to wrap all commands into `{}`.
In any case, our code now does what we expect it to do and on each click a new histogram is rendered using the current value of the slider input. This new app's complete code can be found [here](https://albert-rapp.de/post/2021-11-21-a-few-learnings-from-a-simple-shiny-app/DummyApp/03_add_button.R).

## Use eventReactive() as an alternative for updating values 

Honestly, this part I learned just 5 minutes ago while I was writing the last section of this blog post.
When I looked into the documentation of `observeEvent()`, I noticed that there is also a function `eventReactive()` which may be better suited for our current use case as it allows us to avoid manually isolating `input$bins`.

This new function works similar to `observeEvent()` but it creates a reactive variable instead. This, we can use for rendering.
Check this out

```r
plot <- eventReactive(
  input$draw_button, {
    x    <- faithful[, 2]
    bins <- seq(min(x), max(x), length.out = input$bins + 1)
    hist(x, breaks = bins, col = 'darkgray', border = 'white')
  }
)

output$distPlot <- renderPlot({plot()})
```

Notice how we do not use `isolate()` anymore and use the `plot` variable like a reactive in `renderPlot()`, i.e. we have to "call" its value with `()`.

However, be aware that `eventReactive()` creates a reactive variable such that you cannot change, say, multiple plots at once.
Nevertheless, `eventReactive()` can be a great way to tie a plot to an event.
So, I guess it dependes on your use case and personal preference if you want to use `eventReactive()` rather than `observeEvent()`. Anyway, this version's code can be copied from [here](https://albert-rapp.de/post/2021-11-21-a-few-learnings-from-a-simple-shiny-app/DummyApp/04_eventReactive_instead.R).

## Use reactiveVal() to manually change values on click
Another neat function is `reactiveVal()` which helps you to construct for instance counters that increase on the click of a button. 
We can initialize a reactive value by writing 

```r
counter <- reactiveVal(value = 0)
```
within the server function. This way, our counter is set to zero and we can update it and set it to, say, one by calling `counter(value = 1)`.
The current value of the counter can be accessed through `counter()`.

Clearly, we can tie the updating of a reactive value to an event that we observe through `observeEvent()`.
For instance, we count how often the draw button in our small app is clicked by changing our previous `observeEvent(input$draw_button, ...)`.
Here, we would change this particular line of code to

```r
observeEvent(
  input$draw_button, {
    tmp <- counter()
    counter(tmp + 1)
    
    output$distPlot <- renderPlot({
      x    <- faithful[, 2]
      bins <- seq(min(x), max(x), length.out = isolate(input$bins) + 1)
      hist(x, breaks = bins, col = 'darkgray', border = 'white')
    })
  }
)
```

Finally, we can show this information on our UI for demonstration purposes by adding a `textOutput("demonstration_text")` to our UI and setting

```r
output$demonstration_text <- renderText(paste(
  "You have clicked the draw button",
  counter(),
  "times. Congrats!"
))
```

The complete app can be found [here](https://albert-rapp.de/post/2021-11-21-a-few-learnings-from-a-simple-shiny-app/DummyApp/05_add_reactiveVal.R).

## Use tabsetPanel and unique plot names

Often, you do not want to display all information at once.  [In my particular case](https://rappa.shinyapps.io/estimator-variance/), I wanted to show only one out of two plots based on the user's chosen estimator (sample mean or sample variance). A great way to achieve that is to use `tabsetPanel()` in the UI.

Ordinarily, you can create a UI this way by setting


```r
mainPanel(
  tabsetPanel(
    tabPanel("Plot", plotOutput("plot")),
    tabPanel("Summary", verbatimTextOutput("summary")),
    tabPanel("Table", tableOutput("table"))
  )
)
```

This was an example taken straight out of the documentation of `tabsetPanel()`. What you will get if you start an app containing a UI like this is a panel with three tabs (each one corresponding to a plot, text or table output) and the user can click on the tabs to switch between the views. This isn't that surprising. 

However, if we also add an `id` to this and set `type` to `hidden`, like so

```r
mainPanel(
  tabsetPanel(
    id = "my_tabs",
    type = "hidden",
    tabPanel("Plot", plotOutput("plot")),
    tabPanel("Summary", verbatimTextOutput("summary")),
    tabPanel("Table", tableOutput("table"))
  )
)
```
then, by default, the user does not have the options to change between views by clicking on tabs. Now, the view will need to change based on other interactions of the user with the UI. This change will then need to be customized within the server function. This is where the `id` argument comes into play because it allows ourselves to address the tabs via `updateTabsetPanel()`.

Here, let us take our previous example and display the same information on a different panel, i.e. at the end we will have two panels with exactly the same information in each tab. I know. This is not particularly exciting or meaningful but it serves our current purpose well.

Naively, we might implement our user-interface like so

```r
mainPanel(
  tabsetPanel(
    id = "my_tabs",
    type = "hidden",
    tabPanel("panel1", {
      # UI commands from before here
    }),
    tabPanel("panel2", {
      # UI commands from before here
    }),
  )
)
```

However, we will have to be careful! If we simply copy-and-paste our UI from before, then we won't have unique identifiers to address e.g. the draw button or the plot output. Since this is a serious NO-NO (all caps for dramatic effect) and the app won't work properly, let us instead write a function that draws the UI for us but creates it with different identifiers like this

```r
create_UI <- function(unique_part) {
  sidebarLayout(
    sidebarPanel(
      # unique label here by adding unique_part to bins
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
```

Also, notice that I have created another button called "Change view" within the UI. Further, this button's name is so mind-baffling that I won't even try to elaborate what it will do.
Finally, using `create_UI`, we can set up the UI like so


```r
mainPanel(
  tabsetPanel(
    id = "my_tabs",
    selected = "panel1",
    type = "hidden",
    tabPanel("panel1", create_UI("panel1")),
    tabPanel("panel2", create_UI("panel2")),
  )
)
```

and address everything within the UI in a unique manner. Of course, such a functional approach only works well if the two panels look sufficiently similar such that it makes sense to design them through a single function. In my particular app that deals with the variance of estimators, this was the case because the tabs for the sample mean and sample variance were quite similar in their structure.

Now that we have covered how the UI needs to be set up, let me show you how to change the view from one panel to the next. Shockingly, let us link this to a click on the "change view" button(s) like so

```r
observeEvent(
  input$change_view_panel1, 
  updateTabsetPanel(inputId = "my_tabs", selected = "panel2")
)
observeEvent(
  input$change_view_panel2, 
  updateTabsetPanel(inputId = "my_tabs", selected = "panel1")
)
```

Also, note that the previous code

```r
observeEvent(
  input$draw_button, {
    tmp <- counter()
    counter(tmp + 1)
    
    output$distPlot <- renderPlot({
      x    <- faithful[, 2]
      bins <- seq(min(x), max(x), length.out = isolate(input$bins) + 1)
      hist(x, breaks = bins, col = 'darkgray', border = 'white')
    })
  }
)
```

won't work anymore because the old identifiers like `draw_button` etc. need to be updated to `draw_button_panel1` or `draw_button_panel2`. 
Clearly, this could potentially require some code duplication to implement the server-side logic for both tabs.
But since we feel particularly clever today[^today_smart], let us write another function that avoids a lot of code duplication.

[^today_smart]: And with that I really mean today. When I built my Shiny app, I actually used code duplication. But in hindsight, I feel somewhat embarrassed to leave it as it is for this blog post. Thus, I figured out how to make it work with a function.


```r
render_my_plot <- function(panel, counter, input, output) {
  tmp <- counter() # save current value of counter
  counter(tmp + 1) # update counter
  
  # Create identifier names
  bins_name <- paste("bins", panel, sep = "_")
  distplot_name <- paste("distPlot", panel, sep = "_")
  demonstration_text <- paste("demonstration_text", panel, sep = "_")
  
  # Render Plot
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
```

Notice a few things here:
- Our function needs to know the objects `counter`, `input` and `output` to work. 
- Also we need to switch to double-bracket notation for assigning new variables like `distPlot_panel1` to `output`. Obviously, we couldn't use `$` for assignment anymore but single-bracket notation like `output[var_name]` is for some reason forbidden in Shiny. At least, that's what an error message will kindly tell you when you dare to use only one bracket.

So, all in all our server-side logic looks like this now

```r
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
```



The complete app that we have just build can be found [here](https://albert-rapp.de/post/2021-11-21-a-few-learnings-from-a-simple-shiny-app/DummyApp/06_tabs.R).

## Closing

Alright, I hope this helps you to build your own small Shiny app. [In my particular case](https://rappa.shinyapps.io/estimator-variance/), I had to use another cool function from the `shinyjs` package to update the text on the UI such that it appears in red for a second (in order for the user to notice what changes). 
And because I have the feeling that `shinyjs` has way more in store for us, I will end this already quite long blog post here and save that (exciting) story for another time. Hope you will be there when I talk about `shinyjs`.
