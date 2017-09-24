# Bring in libraries
library(data.table)
library(RoogleVision) 
library(googleAuthR)
library(LSAfun)


load("~/CameraTrapWizard/EN_100k_lsa.rda")
load("~/CameraTrapWizard/TASA.rda")

AWS <- fread("AWSImageResults.csv")
AWS <- AWS[, .(description=V3,score=V2/100,File)]
GCV <- fread("GoogleImageResults.csv")
GCV <- GCV[, .(description,score,File)]
CLAR <- fread("ClarifaiImageResults.csv")
IBM <- fread("IBM_Watson_results.csv")
AWS[, Source := "amazon"]
GCV[, Source := "google"]
CLAR[, Source := "clarifAI"]
IBM[, Source := "IBM"]
IBM[,type_hierarchy:=NULL]
setnames(IBM,c("Filename","class"),c("File","description"))

# Mammal names
mammals <- fread("mammal_species_list.csv")
mammals[,MammalBland:=tolower(MammalBland)]
mammals[,`Common Name`:=tolower(iconv(mammals$`Common Name`,"WINDOWS-1252","UTF-8"))]

All_Results <- rbindlist(list(AWS,GCV,CLAR,IBM), fill=TRUE)
All_Results[,description:=tolower(description)]
  
UniqueWorkds <- All_Results[, .N, keyby=.(description2=description)]
UniqueWorkds[, description := stringr::str_replace_all(description2, "[[:punct:]]", "")]
UniqueWorkds[, paste0("Word",1:5) := tstrsplit(description, "\\s+")]
UniqueWorkds[, Score1 := sapply(Word1, function(x) Cosine("animal",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word2), Score2 := sapply(Word2, function(x) Cosine("animal",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word3), Score3 := sapply(Word3, function(x) Cosine("animal",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word4), Score4 := sapply(Word4, function(x) Cosine("animal",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word5), Score5 := sapply(Word5, function(x) Cosine("animal",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[, AnimalScore := sapply(1:.N, function(x) max(c(Score1[x],Score2[x],Score3[x],Score4[x],Score5[x]),na.rm=TRUE))]
UniqueWorkds[AnimalScore==-Inf, AnimalScore := 0.0]

UniqueWorkds[, Score1 := sapply(Word1, function(x) Cosine("bird",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word2), Score2 := sapply(Word2, function(x) Cosine("bird",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word3), Score3 := sapply(Word3, function(x) Cosine("bird",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word4), Score4 := sapply(Word4, function(x) Cosine("bird",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word5), Score5 := sapply(Word5, function(x) Cosine("bird",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[, BirdScore := sapply(1:.N, function(x) max(c(Score1[x],Score2[x],Score3[x],Score4[x],Score5[x]),na.rm=TRUE))]
UniqueWorkds[BirdScore==-Inf, BirdScore := 0.0]

UniqueWorkds[, Score1 := sapply(Word1, function(x) Cosine("dog",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word2), Score2 := sapply(Word2, function(x) Cosine("dog",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word3), Score3 := sapply(Word3, function(x) Cosine("dog",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word4), Score4 := sapply(Word4, function(x) Cosine("dog",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[!is.na(Word5), Score5 := sapply(Word5, function(x) Cosine("dog",x,tvectors=EN_100k_lsa,breakdown=TRUE))]
UniqueWorkds[, DogScore := sapply(1:.N, function(x) max(c(Score1[x],Score2[x],Score3[x],Score4[x],Score5[x]),na.rm=TRUE))]
UniqueWorkds[DogScore==-Inf, DogScore := 0.0]
UniqueWorkds[, (paste0("Score",1:5)) := NULL]
UniqueWorkds[, TotalScore := sapply(1:.N, function(x) max(c(AnimalScore[x],BirdScore[x],DogScore[x]),na.rm=TRUE))]
setorder(UniqueWorkds, -TotalScore)
#View(UniqueWorkds[])

All_Results[UniqueWorkds, AnimalScore := i.TotalScore, on=.(description=description2)]
All_Results[description%in%unique(mammals$MammalBland) | description=="zebra" , AnimalInd := 1]

# Defining specificty for this group
SpecWords <- All_Results[, .N, keyby=.(description3=description)]
SpecWords[, description := stringr::str_replace_all(description3, "[[:punct:]]", "")]
SpecWords[, paste0("Word",1:5) := tstrsplit(description, "\\s+")]
SpecWords[, Score1 := sapply(Word1, function(x) asym("animal",x,tvectors=EN_100k_lsa,method="cosweeds",breakdown=TRUE))]
SpecWords[!is.na(Word2), Score2 := sapply(Word2, function(x) asym("animal",x,tvectors=EN_100k_lsa,method="cosweeds",breakdown=TRUE))]
SpecWords[!is.na(Word3), Score3 := sapply(Word3, function(x) asym("animal",x,tvectors=EN_100k_lsa,method="cosweeds",breakdown=TRUE))]
SpecWords[!is.na(Word4), Score4 := sapply(Word4, function(x) asym("animal",x,tvectors=EN_100k_lsa,method="cosweeds",breakdown=TRUE))]
SpecWords[!is.na(Word5), Score5 := sapply(Word5, function(x) asym("animal",x,tvectors=EN_100k_lsa,method="cosweeds",breakdown=TRUE))]
SpecWords[, Specificity := sapply(1:.N, function(x) max(c(Score1[x],Score2[x],Score3[x],Score4[x],Score5[x]),na.rm=TRUE))]
SpecWords[Specificity==-Inf, Specificity := 0.5]
SpecWords[description%in%c("animal","terrestrial animal"), Specificity := 0]
SpecWords[description=="mammal", Specificity := 0]
SpecWords[, (paste0("Score",1:5)) := NULL]

All_Results[SpecWords, Specificity := i.Specificity, on=.(description=description3)]


## Making a final metric of speceificity + certainty of engine score + 0.2 points if it's on animal on teh bland list and + 0.5 points if it's mammal on the mammal list
All_Results[,Count:=.N,by=c("description")]
All_Results[,Metric:=Specificity*.5+score*1.5+.3/sqrt(Count)+AnimalScore/4]

setnames(All_Results,"Metric","SelectionMetric")

write.csv(All_Results,"All_Results.csv")
