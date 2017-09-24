# Bring in libraries
library(data.table)
library(RoogleVision) 
library(googleAuthR)
library(LSAfun)


# Read in data
trainingdata <- fread("Sample Photo Training Data - Sheet1.csv") 
trainingdata[,SimplestName:=tolower(SimplestName)]
trainingdata[,CommonNameMajor:=tolower(CommonNameMajor)]

All_Results <- fread("All_Results201709241000.csv")

# All_Results[, SimplestRFRank := frank(SimplestRF), keyby=.(File)]
# All_Results[, CommoneRFRank := frank(CommonRF), keyby=.(File)]
# 
# All_Results[,SelectionMetric:=0.5*SimplestRFRank+0.5*CommoneRFRank]
# 
# SummaryResultsCommon <- All_Results[, .SD[CommonRF==max(CommonRF)], key=.(File)]
# SummaryResultsCommon[, .N, keyby=.(Source,description==CommonNameMajor)]
# 
# SummaryResultsSimple <- All_Results[, .SD[SimplestRF==max(SimplestRF)], key=.(File)]
# SummaryResultsSimple[, .N, keyby=.(Source,description==SimplestName)]
# SummaryResultsSimple[, .N, keyby=.(Amount,description==SimplestName)]

