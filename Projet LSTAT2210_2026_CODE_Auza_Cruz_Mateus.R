#==========================================
# Project of LMM in August
#==========================================

# Packages needed

library(nlme)
library(lme4)
library(gt)
library(emmeans)
library(tidyverse)


# Preprocessing
#-------------------------------------------

setwd("C:\\Users\\mtpla\\Downloads")
bmi=read.csv("Datafile 28732200.csv")
bmi

# Image slide 2
# ----------------------
# Wide format
wide_table <- data.frame(
  ID = 1,
  Group = 3,
  BMIb = 30.2,
  BMI_T1 = 32.3,
  BMI_T2 = 32.0,
  BMI_T3 = 29.7,
  BMI_T4 = 28.4,
  BMI_T5 = 30.3
)

gt(wide_table) |>
  tab_header(
    title = "Wide format",
    subtitle = "Original dataset"
  )

long_table <- data.frame(
  ID = c(1,1,1),
  Group = c(3,3,3),
  Time = c("Baseline","T1","T2"),
  BMI = c(30.2,32.3,32.0)
)

gt(long_table) |>
  tab_header(
    title = "Long format",
    subtitle = "Used for analysis"
  )


# Exploratory analysis
#---------------------------------------

bmi_long <- bmi %>%
  pivot_longer(
    cols = c(BMIb, BMI_T1, BMI_T2, BMI_T3, BMI_T4, BMI_T5),
    names_to = "Time",
    values_to = "BMI"
  )

bmi_long <- bmi_long %>%
  select(-X)

bmi_long$Time <- factor(
  bmi_long$Time,
  levels = c("BMIb", "BMI_T1", "BMI_T2", "BMI_T3", "BMI_T4", "BMI_T5"),
  labels = c("Baseline", "T1", "T2", "T3", "T4", "T5")
)


summary_bmi <- bmi_long %>%
  group_by(GROUP, Time) %>%
  summarise(
    mean_BMI = mean(BMI, na.rm = TRUE),
    sd_BMI = sd(BMI, na.rm = TRUE),
    n = sum(!is.na(BMI)),
    se = sd_BMI / sqrt(n),
    .groups = "drop"
  )

ggplot(summary_bmi,
       aes(x = Time,
           y = mean_BMI,
           colour = factor(GROUP),
           group = GROUP)) +

  geom_line(size = 1) +

  geom_point(size = 2) +

  geom_errorbar(aes(ymin = mean_BMI - se,
                    ymax = mean_BMI + se),
                width = 0.15) +

  labs(
    title = "Mean BMI Profiles by Group",
    x = "Time",
    y = "Mean BMI",
    colour = "Group"
  ) + theme_grey()


#================================================================
# Modelisation: Choice of linear mixed effects model - Step 1+ 2
#================================================================
# Putting relevant variables as factors
#--------------------------------------------
bmi_long$Time <- factor(bmi_long$Time)
bmi_long$GROUP <- factor(bmi_long$GROUP)
bmi_long$SMOKE <- factor(bmi_long$SMOKE)
bmi_long$LIVE <- factor(bmi_long$LIVE)
bmi_long$GENDER <- factor(bmi_long$GENDER)


# Full model
m1 <- lme(BMI~Time*GROUP+GENDER+SMOKE+LIVE,
        data=bmi_long, random= ~ 1+ as.numeric(Time)|ID,
        na.action = na.omit)

# The random slope is specified on the numeric ordering of Time,
# since random effects require a continuous covariate.

summary(m1)

# Random intercept model
m2 <- update(m1, random = ~1 | ID)
summary(m2)
# LRT comparison
anova(m1,m2)

# The random slope does significantly improves model fit (LRT p<0.0001), indicating that students differ both in their baseline BMI and how BMI changes over time.

# M1: Students differ both in baseline BMI and in their rate of BMI change over time.

# M2: Students have different baseline BMI values but are assumed to follow the same average trajectory over time.

#================================================================
# STEP 3 - Selecting the residual covariance structure
#================================================================

# m1 - Homogeneous residual variance
#------------------------------------
# Assumes that the residual variance is the same at every visit.
# No additional residual correlation structure is specified.

#---------------------------------------------------------------
# m3 - Heterogeneous residual variances
#---------------------------------------------------------------
# Allows the residual variability to differ across measurement
# occasions.


m3 <- update(
  m1,
  weights = varIdent(form = ~1 | Time))

summary(m3)


#---------------------------------------------------------------
# m4 - Compound symmetry
#---------------------------------------------------------------
# Assumes that residuals from the same student have the same
# correlation regardless of the time interval between visits.

m4 <- update(
  m1,
  correlation = corCompSymm(form = ~as.numeric(Time) | ID)
)

summary(m4)

# The estimated compound-symmetry correlation was essentially
# zero, suggesting that the random intercept already captures
# most of the within-student dependence.


#---------------------------------------------------------------
# m5 - AR(1)
#---------------------------------------------------------------
# Assumes that residual correlation decreases as the time
# between measurements increases.

m5 <- update(
  m1,
  correlation = corAR1(form = ~as.numeric(Time) | ID)
)

# Convergence issue in m5


#---------------------------------------------------------------
# Model comparison
#---------------------------------------------------------------

AIC(m1, m3, m4)


# The best model for now is the random intercept+ random slope with heterogeneous variances

#=============================================================
# Step 4 - Testing fixed effects
#=============================================================
# We keep m3
m3_ml <- update(m3, method = "ML") # To estimate the fixed effects we need ML

anova(m3_ml)

# The overall Time × GROUP interaction is highly significant,
# indicating that BMI trajectories differ between the prevention approaches.
# GENDER is also highly significant, whereas SMOKE and LIVE do not
# contribute significantly to the model.

# Testing the interaction

m3.1_ml <- update(
  m3_ml,
  . ~ . - Time:GROUP
)

anova(m3.1_ml, m3_ml)

# We do not remove the interaction

# Testing SMOKE and LIVE
m3.2_ml <- update(
  m3_ml,
  . ~ . - LIVE - SMOKE
)

anova(m3.2_ml, m3_ml)

# We can see that both variables are not significant so we can drop them - a more parsimonious model

m_final <- update(m3.2_ml, method= "REML") # Final estimates need to come from the REML

#=================================
# Model diagnostics
#=================================

# Residual vs fitted graph
#-----------------------------
plot(m_final, resid(., type = "pearson") ~ fitted(.), abline = 0)

# It looks like a random cloud, so we suspect we have linearity

# Normal QQ-plot of residuals
#-----------------------------------------
qqnorm(resid(m_final, type = "normalized"), main= "Residual Q-Q plot")
qqline(resid(m_final, type = "normalized"))
# We can see that residuals are fairly normal. Slightly skewed along the tails

# QQ-plot of random effects
#--------------------------------

qqnorm(ranef(m_final)[,1], main= "Random effects Q-Q", col="darkgreen")
qqline(ranef(m_final)[,1], col="darkgreen")

# The distributions of the random intercepts were approximately normal, supporting the assumptions of the mixed-effects model.

# Correlation between random effects
VarCorr(m_final)

# Diagnostic plots did not reveal major violations of the model assumptions.

#===============================
# Conclusion
#===============================

summary(m_final)

anova(m_final)

# Scientific conclusions

# A significant Time × Group interaction (p < 0.0001) indicates that BMI trajectories differed between prevention approaches.

# Groups did not differ significantly at baseline.

# Residual variability differed across measurement times, supporting a heterogeneous residual variance structure.

# There was substantial between-student variability in both baseline BMI (random-intercept SD = 3.01) and BMI trajectories (random-slope SD = 1.38).

# Estimated marginal means - to compare between group 2 and group 3

emm <- emmeans(m_final, ~ GROUP | Time)
pairs(emm, adjust = "tukey")

# From T1 onward, Group 3 showed the greatest reduction in BMI, with significantly lower BMI than both Groups 1 and 2 at every follow-up time.

# At T5, BMI was 3.64 units lower in Group 3 than Group 2 (Tukey-adjusted p < 0.0001).
# Gender was significantly associated with BMI (p < 0.0001).
