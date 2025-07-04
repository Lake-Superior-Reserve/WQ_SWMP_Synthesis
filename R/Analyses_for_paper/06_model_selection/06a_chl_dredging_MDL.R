library(tidyverse)
library(doParallel)
library(tictoc)
library(vegan)
# library(lme4)   # switched to this from glmmTMB due to timing
library(glmmTMB)  # back to this because it allows SEs for predictions and WLS
library(nlme)
library(MuMIn)


# global model ----

# need to either re-run or load the global model (from 05a_chl)
# this script is for generating and saving all subsets of the model
# re-running because copying and pasting is easier....
source(here::here("R", "Analyses_for_paper",
                  "05_predictive_modeling",
                  "050_setup_MDL.R"))

# pick the specific predictors we've agreed on
# center and scale all but response 
dat_chl <- dat_all3 |> 
  select(reserve,
         chla_trend,
         # lat/temp/domgl PCA
         tld_PC1,
         # wq medians
         spcond_median, turb_median.log,
         # wq trends
         temp_trend, spcond_trend, turb_trend,
         # nut medians
         chla_median.log, nh4_median.log, no23_median.log, po4_median.log,
         # nut trends
         nh4f_mdl_trend, no23f_mdl_trend, po4f_mdl_trend,
         # met
         precp_median, precp_trend) |> 
    mutate(across(!reserve,
                  function(x) as.vector(scale(x))))
    
# generate formula
formula_chl <- paste0("chla_trend ~ ", paste(names(dat_chl[3:ncol(dat_chl)]), collapse = " + "), " + (1|reserve)")
formula_nlme <- paste0("chla_trend ~ ", paste(names(dat_chl[3:ncol(dat_chl)]), collapse = " + "))

# generate model
# mod_chl <- glmmTMB(as.formula(formula_chl),
#                 data = dat_chl, 
#                 REML = FALSE)

mod_chl <- lme(as.formula(formula_nlme),
                data = dat_chl,
                random = ~ 1|reserve,
                method = "ML")
# run models ----
# establish cluster
cl <- makeCluster(10)  
registerDoParallel(cl)

options(na.action = "na.fail")

tic("run models")
chla_subsets <- MuMIn::dredge(mod_chl, eval = TRUE,
                              cluster = cl)
toc()
beepr::beep(8)


# turn off cluster
stopCluster(cl)


# save subsets ----
save(dat_chl, mod_chl, chla_subsets, 
     file = here::here("Outputs",
                       #"06_model_selection",
                       #"R_objects",
                       "chla_out_nlme_v3_mdl.RData"),
     compress = "xz")
