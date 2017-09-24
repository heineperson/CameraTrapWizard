
library(shiny)
#devtools::install_github("flovv/RoogleVision")
library(RoogleVision)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  # Render a table of meta data for the uploaded file/files
  output$files <- renderTable(input$files)
  
  
  # Copy Uploaded file to www directory
  observeEvent(input$submitButton, {
    #inFile <- input$myFile
    inFile <- input$files
    if (is.null(inFile))
      return()
    file.copy(inFile$datapath, file.path("./www", inFile$name) )
    })
  
  # make the input files list reactive
  files <- reactive({
    files <- input$files
    files$datapath <- gsub("\\\\", "/", files$datapath)
    files
  })
  
  NewImages <- reactive({
    setdiff(list.files("./www", full.names = TRUE), CurrentImages)
  })


  output$images <- renderUI({
    if(is.null(input$files)) return(NULL)
    image_output_list <- 
      lapply(1:nrow(files()),
             function(i)
             {
               imagename = paste0("image", i)
               imageOutput(imagename)
             })
    
    do.call(tagList, image_output_list)
  })
  
  
  
  # Render uplaoded images
  observeEvent(input$submitButton,{
    if(is.null(input$files)) return(NULL)
    for (i in 1:nrow(files()))
    {
      print(i)
      local({
        my_i <- i
        imagename = paste0("image", my_i)
        print(imagename)
        output[[imagename]] <- 
          renderImage({
            list(src = files()$datapath[my_i],
                 alt = "Image failed to render",
                 width="400")
          }, deleteFile = FALSE)
      })
    }
  }
  )
  
  #Spit out training data output
   observeEvent(input$submitButton,{
    if(is.null(input$files)) return(NULL)

    # Applying threshold for animal certainty
     if(input$AnimalFilter=="Yes"){
        All_Results <- All_Results[AnimalScore>input$FilterThreshold | AnimalInd==1]
       }else{
      All_Results <- All_Results}
     
    # Applying Google output to all of the new images
    # GoogleResultsList <- lapply(paste0("./www/",files()$name), grabGoogleID)
    # #GoogleResultsList <- lapply(NewImages(), grabGoogleID)
    # # Binding the results together
    # GoogleResults <- rbindlist(GoogleResultsList, fill=TRUE)
    output$GoogleTable <- renderTable({All_Results[Source=="google" & File%in%files()$name,.(description,score,Specificity,SelectionMetric)]})
    output$AWSTable <- renderTable({All_Results[Source=="amazon" & File%in%files()$name,.(description,score,Specificity,SelectionMetric)]})
    output$CLARTable <- renderTable({All_Results[Source=="clarifAI" & File%in%files()$name,.(description,score,Specificity,SelectionMetric)]})
    output$IBMTable <- renderTable({All_Results[Source=="IBM" & File%in%files()$name,.(description,score,Specificity,SelectionMetric)]})
    TrainingResults <- trainingdata[PhotoName%in%files()$name,.(`Specific Name`=ScientificNameMajor,
                                                                  `Common Name` = CommonNameMajor,  
                                                                  `General Group` = SimplestName)]
    # Composite Output
    output$TopFive <- renderUI({
             if (is.null(input$submitButton)) return(NULL)
            fluidRow(
              h1("Composite Results"),
              renderTable({All_Results[File%in%files()$name,.(Source,description,SelectionMetric)][order(-SelectionMetric) ][1:5]}))
              })

    # Rendering the output
    output$BigTables <- renderUI({
       if (is.null(input$submitButton)) return(NULL)
         fluidRow(
           column(6,h2("Google Cloud Vision"),tableOutput('GoogleTable')),
           column(6,h2("Amazon Rekognition"),tableOutput('AWSTable')),
          column(6,h2("IBM"),tableOutput('IBMTable')),
           column(6,h2("clarifAI"),tableOutput('CLARTable')))

           })
    
    # Output the training results for all the images selected
    output$TrainingResults <- renderUI({
             if (is.null(input$submitButton)) return(NULL)
            fluidRow(
              h1("Training Data"),
              renderTable(TrainingResults[]))
              })
    
  }
  )
  
  
  
  
})
