library(baseballr)
library(dplyr)

dat_2015 <- fg_batter_leaders(stats="bat",
                              type="8",
                              startseason = "2015",
                              endseason = "2015",
                              qual = "200",
                              ind = "1",
                              pageitems="10000")
dat_2015<-dat_2015 %>%
  mutate(Clutch_calc=(WPA/pLI)-WPA_LI)
pick_col<-function(df,patterns){
  nms<-names(df)
  hit <- nms[Reduce(`|`, lapply(patterns, function(p) grepl(p, nms, ignore.case = TRUE)))]
  if (length(hit) == 0) stop("Could not find column matching: ", paste(patterns, collapse = ", "))
  hit[[1]]}

wpa_col<-pick_col(dat_2015,c("^WPA$","WPA\\."))
pli_col<-pick_col(dat_2015,c("^pLI$","pli"))
wpaLI_col<-pick_col(dat_2015,c("WPA.?/LI","WPA_LI","WPA\\.LI","WPAperLI"))
dat_2015_clutch <- dat_2015 %>%
  mutate(
    Clutch_calc=(.data[[wpa_col]] / .data[[pli_col]]) - .data[[wpaLI_col]])

dat_2015_clutch %>% select(PlayerName,team_name,PA, all_of(c(wpa_col,pli_col,wpaLI_col)),Clutch_calc) %>% head(10)
summary(dat_2015_clutch$Clutch_calc)

library(baseballr)
library(dplyr)
library(purrr)

seasons<-2015:2024

clutch_all<-map_dfr(seasons, function(y) {
   message("Pulling season:",y)
  df <- fg_batter_leaders(stats="bat",
                          type="8",
                          startseason=as.character(y),
                          endseason=as.character(y),
                          qual="200",
                          ind="1",
                          pageitems="10000")
df %>%mutate(Season=y,Clutch_calc = (WPA / pLI) - WPA_LI)})
table(clutch_all$Season)
summary(clutch_all$Clutch_calc)

library(ggplot2)
ytY<-clutch_all %>% select(PlayerName,Season,Clutch_calc,PA) %>%
  arrange(PlayerName,Season) %>%
  group_by(PlayerName) %>%
  mutate(Clutch_next=lead(Clutch_calc)) %>%
  ungroup() %>%
  filter(!is.na(Clutch_next),PA>=200)
cor(ytY$Clutch_calc, ytY$Clutch_next)

ggplot(ytY,aes(Clutch_calc,Clutch_next)) +
  geom_point(alpha = 0.35) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Clutch Performance Year-to-Year",
    subtitle = "2015–2024, FanGraphs-style Clutch (replicated)",
    x="Clutch (Season t)",
    y= "Clutch (Season t+1)") +theme_minimal()
