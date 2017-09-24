# Bring in libraries
library(data.table)
library(RoogleVision) 
library(googleAuthR)
library(LSAfun)
load("EN_100k_lsa.rda")

# Read in data
trainingdata <- fread("SamplePhotoTrainingData20170924.csv") 
trainingdata[, SimplestName := tolower(SimplestName)]
trainingdata[, CommonNameMajor := tolower(CommonNameMajor)]

# Read in Cloud Results
All_Results <- fread("All_Results.csv")
All_Results[trainingdata, SimplestName := i.SimplestName, on=.(File=PhotoName)]
All_Results[trainingdata, CommonNameMajor := i.CommonNameMajor, on=.(File=PhotoName)]
All_Results[trainingdata, TimeofDay := i.TimeofDay, on=.(File=PhotoName)]
All_Results[trainingdata, Amount := `i.Amount (Entire/Partial/Mixed)`, on=.(File=PhotoName)]
All_Results[trainingdata, Vegetation := i.Vegetation, on=.(File=PhotoName)]
All_Results[trainingdata, NumOfAnimals := `i.Number of Animals`, on=.(File=PhotoName)]

# Explore
All_Results[, .N, keyby=.(SimplestName)]
All_Results[description==SimplestName]

# Unique words
UniqueWorkds <- All_Results[, .N, keyby=.(description2=description,SimplestName)]
UniqueWorkds[, description := stringr::str_replace_all(description2, "[[:punct:]]", "")]
UniqueWorkds[, paste0("Word",1:5) := tstrsplit(description, "\\s+")]
UniqueWorkds[, Score1 := sapply(1:.N, function(x) Cosine(SimplestName[x],Word1[x],tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word2), Score2 := sapply(1:.N, function(x) Cosine(SimplestName[x],Word2[x],tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word3), Score3 := sapply(1:.N, function(x) Cosine(SimplestName[x],Word3[x],tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word4), Score4 := sapply(1:.N, function(x) Cosine(SimplestName[x],Word4[x],tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word5), Score5 := sapply(1:.N, function(x) Cosine(SimplestName[x],Word5[x],tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[, Score := sapply(1:.N, function(x) max(c(Score1[x],Score2[x],Score3[x],Score4[x],Score5[x]),na.rm=TRUE))]
All_Results[UniqueWorkds, SimplestNameScore := i.Score, on=.(description=description2,SimplestName)]

# Unique words
UniqueWorkds <- All_Results[, .N, keyby=.(description2=description,CommonNameMajor)]
UniqueWorkds[, description := stringr::str_replace_all(description2, "[[:punct:]]", "")]
UniqueWorkds[, paste0("Word",1:5) := tstrsplit(description, "\\s+")]
UniqueWorkds[, Score1 := sapply(1:.N, function(x) Cosine(CommonNameMajor[x],Word1[x],tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word2), Score2 := sapply(1:.N, function(x) Cosine(CommonNameMajor[x],Word2[x],tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word3), Score3 := sapply(1:.N, function(x) Cosine(CommonNameMajor[x],Word3[x],tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word4), Score4 := sapply(1:.N, function(x) Cosine(CommonNameMajor[x],Word4[x],tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word5), Score5 := sapply(1:.N, function(x) Cosine(CommonNameMajor[x],Word5[x],tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[, Score := sapply(1:.N, function(x) max(c(Score1[x],Score2[x],Score3[x],Score4[x],Score5[x]),na.rm=TRUE))]
All_Results[UniqueWorkds, CommonNameScore := i.Score, on=.(description=description2,CommonNameMajor)]

# Merge back on score
Final <- All_Results[, .SD[SimplestNameScore==max(SimplestNameScore)][1], keyby=.(File,Source)]
Final[, .N, keyby=.(Source,description==SimplestName)]
Final <- All_Results[, .SD[CommonNameScore==max(CommonNameScore)][1], keyby=.(File,Source)]
Final[, .N, keyby=.(Source,description==CommonNameMajor)]

# Predict
All_Results[SimplestNameScore==-Inf, SimplestNameScore := 0]
All_Results[CommonNameScore==-Inf, CommonNameScore := 0]

library(randomForest)
All_Results[, ScoreRank := frank(score), keyby=.(File,Source)]
x <- All_Results[, .(Source,AnimalScore,Specificity,Amount,Vegetation,NumOfAnimals,TimeofDay,ScoreRank)]
x <- model.matrix(~.-1.,x)
ySimple <- All_Results$SimplestNameScore
yCommon <- All_Results$CommonNameScore
rfSimplest <- randomForest(x, ySimple)
rfCommon <- randomForest(x, yCommon)
All_Results[, SimplestRF := rfSimplest$predicted]
All_Results[, CommonRF := rfCommon$predicted]
SimplestResults <- All_Results[, .SD[SimplestRF==max(SimplestRF)][1L], keyby=.(File)]
SimplestResults[, .N, keyby=.(Source)]
SimplestResults[, .N, keyby=.(description==SimplestName)]
SimplestResults[description==SimplestName, .N, keyby=.(Source)]
SimplestResults[, Correct := sapply(1:.N, function(x) length(intersect(
  unlist(strsplit(description[x]," ")),SimplestName[x])))]
SimplestResults[, .N, keyby=.(Correct)]
SimplestResults[, .N, keyby=.(Amount,Correct)]
SimplestResults[, .N, keyby=.(TimeofDay,Correct)]
SimplestResults[, .N, keyby=.(NumOfAnimals,Correct)]
SimplestResults[Correct>0, .N, keyby=.(Source)]

View(SimplestResults[, .(File,Source, description, SimplestName)])

CommonResults <- All_Results[, .SD[CommonRF==max(CommonRF)][1L], keyby=.(File)]
CommonResults[, .N, keyby=.(Source)]
CommonResults[, Correct := sapply(1:.N, function(x) length(intersect(
  unlist(strsplit(description[x]," ")),CommonNameMajor[x])))]
CommonResults[, .N, keyby=.(Amount,Correct)]
CommonResults[Correct>0, .N, keyby=.(Source)]

View(CommonResults[, .(File,Source, description, CommonNameMajor)])
fwrite(All_Results, "All_Results201709241000.csv")

SimplestResults <- All_Results[, .SD[SimplestRF==max(SimplestRF)][1L], keyby=.(File,Source)]
SimplestResults[, Correct := sapply(1:.N, function(x) length(intersect(
  unlist(strsplit(description[x]," ")),SimplestName[x])))]
SimplestResults[, .N, keyby=.(Correct)]
SimplestResults[Correct>0, .N, keyby=.(Source)]

CommonResults <- All_Results[, .SD[CommonRF==max(CommonRF)][1L], keyby=.(File,Source)]
CommonResults[, Correct := sapply(1:.N, function(x) length(intersect(
  unlist(strsplit(description[x]," ")),CommonNameMajor[x])))]
CommonResults[, .N, keyby=.(Correct)]
CommonResults[Correct>0, .N, keyby=.(Source)]

# All_Results[, rank:=rank(-SelectionMetric),by=c("File")]
# All_Results[rank<=5,.(List= toString(description)),by=c("File")]