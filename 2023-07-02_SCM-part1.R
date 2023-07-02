#Intro to structural causal modelling
# CJ Brown
# 2023-07-02

library(ggplot2)
library(patchwork)
library(ggdag)

library(dagitty)

theme_set(theme_dag())

king_mod <- dagify(lncelld ~ PI + Diuron, 
                   PI ~ Light + Diuron)
g1 <- ggdag(king_mod, text_size =2, 
            node_size = 12)
g1

king <- read.csv("data/Kings-multistressor-experiment.csv")
head(king)

king_mod %>% 
  ggdag_paths(from="Light", to = "PI",
              shadow = TRUE)
adjustmentSets(king_mod, 
               exposure = "Light",
               outcome = "PI", 
               type = "minimal",
               effect = "total")
adjustmentSets(king_mod, 
               exposure = "Light",
               outcome = "PI", 
               type = "canonical",
               effect = "total")

mod_pi_min <- lm(PI ~ Light, data = king)
summary(mod_pi_min)

lm(PI ~ Light * Diuron, dat = king) %>%
  summary()

#
# Step 6: Causes of lncelld
#

king_mod %>%
  ggdag_paths(from = "Light", to = "lncelld", shadow = TRUE)

adjustmentSets(king_mod, 
               exposure = "Light",
               outcome = "lncelld",
                type = "canonical",
               effect = "total")

?adjustmentSets

lm(lncelld ~ Light*Diuron, data = king) %>%
  summary()

king_mod %>% 
  ggdag_paths(from = "Diuron", to = "lncelld",
              shadow = TRUE)
adjustmentSets(king_mod, 
               exposure = "Diuron",
               outcome = "lncelld",
               type = "canonical",
               effect = "total")
adjustmentSets(king_mod, 
               exposure = "Diuron",
               outcome = "lncelld",
               type = "minimal",
               effect = "direct")

lm(lncelld ~ PI+Diuron, data = king) %>%
  summary()

coral_mod <- dagify(survival ~ Temp + skill, 
                   Temp ~ time,
                   time ~ skill,
                   skill ~ expert,
                   time ~ expert)
g1 <- ggdag(coral_mod, text_size =2, 
            node_size = 12)
g1

adjustmentSets(coral_mod, 
               exposure = "Temp",
               outcome = "survival",
               effect = "direct")

#
# Urchin example 
#

urchinmod <- dagify(Kelp ~ Urchins + Temp,
                    Urchins ~ ULarvae,
                    ULarvae ~ Temp,
                    coords = list(x = c(Kelp = 1, Urchins = -1, Temp = 1, ULarvae = 0), 
                                  y = c(Kelp = -1, Urchins = -0.8, Temp = 1, ULarvae = 0))) 
ggdag(urchinmod, text_size = 3, 
      node_size = 20)
urchinmod %>%
  ggdag_paths(from = "Urchins", to = "Kelp",
              shadow = TRUE, text_size = 3)

urchinmod2 <- dagify(Kelp ~ Urchins + Temp,
                     Urchins ~ coin_flip,
                     ULarvae ~ Temp,
                     coords = list(x = c(Kelp = 1, Urchins = -1, Temp = 1, ULarvae = 0, coin_flip=-1), 
                                   y = c(Kelp = -1, Urchins = -0.8, Temp = 1, ULarvae = 0, coin_flip=1)))
ggdag(urchinmod, text_size = 2, 
      node_size = 15) + 
  ggdag(urchinmod2, text_size = 2, 
        node_size = 15)
adjustmentSets(urchinmod, 
               exposure = "Urchins",
               outcome = "Kelp",
               effect = "direct")
adjustmentSets(urchinmod2, 
               exposure = "Urchins",
               outcome = "Kelp",
               effect = "direct")

urchinmod %>% 
  ggdag_paths(from="ULarvae", 
              to = "Kelp", 
              shadow = 
                TRUE, text_size = 3)

#
# Collider bias example 
#

fishdag <- dagify(Survey ~ Diversity + Exposure, 
                  coords = list(x = c(Survey = 0, Diversity = 1, Exposure=-1), 
                                y = c(Survey = 0, Diversity = 1, Exposure=1))) 
fishdag %>% ggdag_collider(text_size = 2.5,
                           node_size = 20)

#
# Creat some data 
#
set.seed(35)
n <- 500

fishdat <- data.frame(diversity = rpois(n, 10),
                      exposure = rnorm(n))

fishdat <- within(fishdat, {
  surv_prob = plogis(0.5 * exposure + 0.1*diversity)
  surveyed = rbinom(n, 1, surv_prob)
})
# with(fishdat, plot(exposure, surv_prob,
                   # ylim = c(0,1)))
fishdat_biased <- fishdat[fishdat$surveyed ==1, ]
nbiased <- nrow(fishdat_biased)
nbiased

rand_select <- sample(1:nrow(fishdat), 
                      size = nbiased, 
                      replace = FALSE)
fishdat_random <- fishdat[rand_select,]

ggplot(fishdat_biased) + 
  aes(x = exposure, y = diversity, colour = surv_prob) +
  theme_classic() +
  geom_point()

with(fishdat_random, cor.test(diversity, exposure))
with(fishdat_biased, cor.test(diversity, exposure))


#
# Kelp mdoel GLMs
#

urchinmod <- dagify(Kelp ~ Urchins + Temp, 
                    Urchins ~ ULarvae + Rock, 
                    ULarvae ~ Temp)

ggdag(urchinmod, text_size = 3,
      node_size = 20) 

set.seed(42)
n <- 50
udat <- data.frame(Temp = rnorm(n, mean = 16, sd = 1))

udat <- within(udat, {
  ULarvae_hat = 1*Temp - 1
  ULarvae = ULarvae_hat + rnorm(n, sd = 0.4)
})
pairs(udat)

library(visreg)
mlarvae <- glm(ULarvae ~ Temp, data = udat)
coef(mlarvae)
confint(mlarvae)
plot(mlarvae)

summary(mlarvae)

urchinmod <- dagify(Kelp ~ Urchins + Temp, 
                    Urchins ~ ULarvae + Rock, 
                    ULarvae ~ Temp)

ggdag(urchinmod, text_size = 3,
      node_size = 20)

# Poisson GLM

set.seed(105)
udat <- within(udat, {
  Rock = rep(c(0,1), each = n/2)
  Urchins_hat = exp(0.25*ULarvae + 0.3*Rock - 0.5)
  Urchins = rpois(n, Urchins_hat)
})
ggplot(udat) + 
  aes(x = ULarvae, y = Urchins, color = Rock) + 
  geom_point() +
  theme_classic()

adjustmentSets(urchinmod, 
               exposure = "ULarvae",
               outcome = "Urchins", 
               type = "canonical")

murchin <- glm(Urchins ~ Rock + ULarvae, 
               data = udat, 
               family = "poisson")
visreg(murchin, xvar = "ULarvae",
       by = "Rock",
       scale = "response")

summary(murchin)
confint(murchin)


set.seed(5)
nPIT <- 100

udat <- within(udat, {
  Kelp_hat = plogis(-0.1*Temp - 0.1*Urchins + 1)
  Kelp = rbinom(n, size = nPIT, 
                Kelp_hat)
})

ggplot(udat) + 
  aes(x = Urchins, y = Kelp, color = Temp) + 
  geom_point() + 
  theme_classic()
adjustmentSets(urchinmod, exposure = "Urchins",
               outcome = "Kelp",
               type = "minimal")
Kelp2 <- cbind(udat$Kelp, nPIT - udat$Kelp)
mkelp <- glm(Kelp2 ~ Urchins + Temp , 
             data = udat,
             family = "binomial")
visreg(mkelp, xvar = "Urchins",
       by = "Temp",
       scale = "response")

murchin_collider <- glm(Urchins ~ Temp,
                        data = udat, 
                        family = "poisson")
confint(murchin_collider)






