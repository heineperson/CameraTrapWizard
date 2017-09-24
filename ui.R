library(shiny)
library(shinythemes)
library(jsonlite) 
# Define UI for application that draws a histogram
shinyUI(fluidPage(
  theme = shinytheme("united"),
  
  # Application Theme
  
  
  # Application title
  titlePanel("Wandering Eye: Prowling the Web for Camera Trap IDs"),
  navbarPage("    ",
             tabPanel("Home",
                    fluidRow( column(6, h1("Welcome to Wandering Eye!"),
                      h3("A one stop shop for your camera trap image recognition needs"),
                      p("This service layer is a web service designed to allow the conservation community to accurately and quickly document species 
                        by evaluating which service (or combination of services) best fits the need of the conservation application.")
                      , h2("How does it work?"),
                      p("We access and compile image recognition output from four computer vision APIs:"),
                      tags$ol(
                        tags$li("Google Cloud Vision"), 
                        tags$li("IBM Watson"), 
                        tags$li("Amazon Rekognition"),
                        tags$li("ClarifAI")),
                      p("From the aggregated output we create a composite output that produces the best five results across 
                        platforms based on our metric that balances the confidence versus specifcity of camera trap IDs."),
                      h2("What challenges did we face?"),
                      tags$ol(
                        tags$li("Removing non-animal ID terms"), 
                        tags$li("API limits and fees"), 
                        tags$li("Creating a Training Dataset")),
                      h2("Who could use this?"),
                       p("Anyone who doesn't have time to upload the same photos into four separate web sites. 
                         We could make this service into an API for the SMART Partnership who wrote this problem statement")),
                    
                      
                      column(4, img(src='Ogeoffroyi 3717-27.JPG', align = "right",width="400px"),
                        img(src='Cchinga B-Rancho Chico 3715-14.JPG', align = "right",width="400px")))
                      
                     
                        
                      ),
             tabPanel("Picture Upload",
                      
  sidebarLayout(
    
    # Sidebar with a slider input
    sidebarPanel( 
      fluidRow( 
        fileInput(inputId = 'files', 
                  label = 'Select an Image',
                  multiple = TRUE,
                  accept=c('image/png', 'image/jpeg'),
                  width='400px'),
        radioButtons("AnimalFilter", "Filter Non Animal Words", choices = c("Yes","No"), selected = "Yes",
  inline = FALSE, width = NULL, choiceNames = NULL, choiceValues = NULL),

       sliderInput("FilterThreshold", "Non-animal exclusion Filter",
                  min = 0, max = 1,
                  value = 0.7),
        actionButton("submitButton", "Run CameraTrap Wizard")
        )     
        ),
    
    # Show a plot of the generated distribution
    mainPanel(
      #tableOutput('files'),
      fluidRow(
        column(6,uiOutput('images')),   
        column(6,uiOutput('TrainingResults'),uiOutput('TopFive'))),hr(),
      fluidRow(uiOutput('BigTables'))
      
      )
  )
             )
  )
)
)
