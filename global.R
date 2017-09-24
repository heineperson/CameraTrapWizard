# Bring in libraries
library(data.table)
library(RoogleVision) 
library(googleAuthR)
library(LSAfun)


# Read in data
trainingdata <- fread("Sample Photo Training Data - Sheet1.csv") 
trainingdata[,SimplestName:=tolower(SimplestName)]
trainingdata[,CommonNameMajor:=tolower(CommonNameMajor)]

All_Results <- fread("All_Results.csv")

All_Results[,rank:=rank(-SelectionMetric),by=c("File")]
All_Results[rank<=5,.(List= toString(description)),by=c("File")]

