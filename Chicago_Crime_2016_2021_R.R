#load tidyverse library
library(tidyverse)
library(patchwork) # To display 2 charts together
library(plyr)

#read data from SQL query
Chicago_Crime <- read.csv("Chicago_Crime_2016_2022.csv") 
#display first 6 rows
(Chicago_Crime) 
#view datatypes and other metadata
glimpse(Chicago_Crime)

#read data from Chicago police dept budget file
CPD_budget <- read.csv("CPD_budget_2016_2021.csv",fileEncoding="UTF-8-BOM") 
head(CPD_budget) 
glimpse(CPD_budget)

arrest_numbers <- Chicago_Crime %>% 
  #filter out non criminal activity
  filter(primary_type != "NON-CRIMINAL" & primary_type != "NON - CRIMINAL" & primary_type != "NON-CRIMINAL (SUBJECT SPECIFIED)") %>%
  #Keep crimes where arrests have been made
  filter(arrest == "true")%>% 
  #make a table of arrests per year
  ddply(.(year), nrow)
  #change name of new column to n_arrests
names(arrest_numbers)[names(arrest_numbers) == 'V1'] <- "n_arrests" 

crime_numbers <- Chicago_Crime %>% 
  #filter out non criminal activity 
  filter(primary_type != "NON-CRIMINAL" & primary_type != "NON - CRIMINAL" & primary_type != "NON-CRIMINAL (SUBJECT SPECIFIED)") %>%
  #make a table of crimes per year
  ddply(.(year), nrow) 
  #change name of new column to n_crime
names(crime_numbers)[names(crime_numbers) == 'V1'] <- "n_crimes" 

#inner join the tables of crime numbers and arrest numbers
chicago_arrest_statistics <- merge(x=crime_numbers,y=arrest_numbers,by="year")%>%
  #add a column for arrest rates in %
  mutate(arrest_rate = (n_arrests/n_crimes)*100) 

chicago_arrests_vs_funding <- merge(chicago_arrest_statistics,CPD_budget,by="year")

ggplot(data = chicago_arrest_statistics) +
  geom_line(mapping = aes(x = year, y = n_arrests, color = "N_arrests")) + 
  geom_line(mapping = aes(x = year, y = n_crimes, color = "N_crimes")) +
  labs(title="Number of Arrests and Crimes 2016-2022 ",x ="Year", y = "Quantity", color = "LEGEND")
 
p1 <- ggplot(chicago_arrests_vs_funding, aes(x=year, y=n_crimes)) +
  geom_line(color="#69b3a2", size=2) +
  labs(title="Number of Crimes 2016-2022",x ="Year", y = "Number of Crimes")

p2 <- ggplot(chicago_arrests_vs_funding, aes(x=year, y=CPD_budget)) +
  geom_line(color="grey",size=2) +
  labs(title="Chicago PD Funding 2016-2022",x ="Year", y = "Chicago PD Funding")

p1 + p2 

#correlation between number of crimes and CPD Budget
cor(chicago_arrests_vs_funding$n_crimes, chicago_arrests_vs_funding$CPD_budget)

#correlation between arrest rate and CPD Budget
cor(chicago_arrests_vs_funding$arrest_rate , chicago_arrests_vs_funding$CPD_budget)

#remove crimes with 100% arrest rate
arrest_numbers_no_bias <- Chicago_Crime %>% 
  filter(primary_type != "CONCEALED CARRY LICENSE VIOLATION" & primary_type != "GAMBLING" & primary_type != "INTERFERENCE WITH PUBLIC OFFICER") %>%
  filter(primary_type != "LIQUOR LAW VIOLATION" & primary_type != "NARCOTICS" & primary_type != "OTHER NARCOTIC VIOLATION") %>%
  #filter out non criminal activity
  filter(primary_type != "NON-CRIMINAL" & primary_type != "NON - CRIMINAL" & primary_type != "NON-CRIMINAL (SUBJECT SPECIFIED)") %>%
  #Keep crimes where arrests have been made
  filter(arrest == "true")%>% 
  #make a table of arrests per year
  ddply(.(year), nrow)
  #change name of new column to n_arrests
  names(arrest_numbers_no_bias)[names(arrest_numbers_no_bias) == 'V1'] <- "n_arrests_no_bias"

#remove crimes with 100% arrest rate
crime_numbers_no_bias <- Chicago_Crime %>% 
  filter(primary_type != "CONCEALED CARRY LICENSE VIOLATION" & primary_type != "GAMBLING" & primary_type != "INTERFERENCE WITH PUBLIC OFFICER") %>%
  filter(primary_type != "LIQUOR LAW VIOLATION" & primary_type != "NARCOTICS" & primary_type != "OTHER NARCOTIC VIOLATION") %>%
  #filter out non criminal activity
  filter(primary_type != "NON-CRIMINAL" & primary_type != "NON - CRIMINAL" & primary_type != "NON-CRIMINAL (SUBJECT SPECIFIED)") %>%
  #make a table of arrests per year
  ddply(.(year), nrow)
#change name of new column to n_arrests
names(crime_numbers_no_bias)[names(crime_numbers_no_bias) == 'V1'] <- "n_crimes_no_bias"

#inner join the tables of crime numbers and arrest numbers
chicago_arrest_statistics_no_bias <- merge(x=crime_numbers_no_bias,y=arrest_numbers_no_bias,by="year")%>%
  #add a column for arrest rates in %
  mutate(arrest_rate_unbiased = (n_arrests_no_bias/n_crimes_no_bias)*100) 

chicago_arrests_vs_funding_no_bias <- merge(chicago_arrest_statistics_no_bias,CPD_budget,by="year")

#correlation between arrest rate and CPD Budget
cor(chicago_arrests_vs_funding_no_bias$arrest_rate_unbiased, chicago_arrests_vs_funding_no_bias$CPD_budget)
