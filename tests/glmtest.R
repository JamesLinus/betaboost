library(betaboost)
require(gamlss.dist)

# simple simulated example
set.seed(1234)
x1 <- rnorm(100)
x2 <- rnorm(100)
x3 <- rnorm(100)
x4 <- rnorm(100)
y <- rBE(n = 100, mu = plogis(x1 +x2),
         sigma = plogis(x3 + x4))
data <- data.frame(y ,x1, x2, x3, x4)
data <- data[!data$y%in%c(0,1),]
rm(x1,x2,x3,x4,y)

# just modelling mu

b1 <- betaboost(formula = y ~ x1 + x2, data = data, form.type = "classic",
      iterations = 120, sl = 0.1)
rb1 <- R2.betaboost(model = b1, data = data)
b1b <- betaboost(formula = y ~ x1 + x2, data = data, form.type = "gamboost",
                iterations = 120, sl = 0.1)
b1c <- betaboost(formula = y ~ x1 + x2, data = data, 
                 iterations = 120, sl = 0.1)
g1 <- glmboost(y ~ x1 + x2, data = data, family = BetaReg(),
               control = boost_control(mstop = 120))
rg1 <- R2.betaboost(model = g1, data = data)
stopifnot(identical(coef(b1),coef(b1b), coef(b1c), coef(g1)))


# now with smooth

b2 <- betaboost(formula = y ~ x1 + s(x2), data = data, form.type = "classic",
                iterations = 120, sl = 0.1)
rb2 <- R2.betaboost(model = b2, data = data)

b2b <- betaboost(formula = y ~ bols(x1) + bbs(x2), data = data, form.type = "gamboost",
                 iterations = 120, sl = 0.1)
b2c <- betaboost(formula = y ~ x1 + bbs(x2), data = data, 
                 iterations = 120, sl = 0.1)
g2 <- gamboost(y ~ bols(x1) + bbs(x2), data = data, family = BetaReg(),
               control = boost_control(mstop = 120))
rg2 <- R2.betaboost(model = g2, data = data)

stopifnot(identical(coef(b2),coef(b2b)))
stopifnot(identical(coef(b2c),coef(g2)))
cbind(rb1, rg1, rb2, rg2)


# now modelling also phi

b3 <- betaboost(formula = y ~ x1 + x2, 
                phi.formula = y ~ x3 + x4, 
                data = data, form.type = "classic",
                iterations = 120, sl = 0.1)
R2.betaboost(b3, data = data)

g3 <- glmboostLSS(list(mu = y ~ x1 + x2, phi = y ~ x3 + x4), 
                  families = BetaLSS(), 
                  data = data)
stopifnot(identical(coef(b3, off2int = TRUE),  
                    coef(g3[120], off2int = TRUE)))

# method 

b3b <- betaboost(formula = y ~ x1 + x2, 
                phi.formula = y ~ x3 + x4, 
                data = data, form.type = "classic",
                iterations = 400, method = "noncyclic", sl = 0.1)
R2.betaboost(b3, data = data)

g3b<- glmboostLSS(list(mu = y ~ x1 + x2, phi = y ~ x3 + x4), 
                  families = BetaLSS(), 
                  data = data, method = "noncyclic")
stopifnot(identical(round(unlist(coef(b3b, off2int = TRUE)),2),  
                    round(unlist(coef(g3b[400], off2int = TRUE)),2)))

# now with smooth

b4 <- betaboost(formula = y ~ s(x1) + x2, 
                phi.formula = y ~ x3 + s(x4), 
                data = data, form.type = "classic",
                iterations = 120, sl = 0.1)

g4 <- gamboostLSS(list(mu = y ~ bbs(x1) + bols(x2), 
                       phi = y ~ bols(x3) + bbs(x4)), 
                  families = BetaLSS(), 
                  data = data)
stopifnot(identical(coef(b4),  
                    coef(g4[120])))

# change step length

# now change step-length
b3 <- betaboost(formula = y ~ x1 + x2, 
                phi.formula = y ~ x3 + x4, 
                data = data, iterations = 120, 
                method = "cyclic", sl = 0.01)
coef(b3, off2int = TRUE)


# different values
b4 <- betaboost(formula = y ~ x1 + x2, 
                phi.formula = y ~ x3 + x4, 
                data = data, iterations = 120, 
                method = "cyclic", sl = c(mu = 0.01, phi = .1))
coef(b4, off2int = TRUE)

# change offset 

b4 <- betaboost(formula = y ~ x1 + x2, 
                phi.formula = y ~ x3 + x4, 
                data = data, iterations = 120, 
                start.mu = 0.5, start.phi = 1,
                method = "cyclic", sl = c(mu = 0.01, phi = .1))
coef(b4, off2int = TRUE)
stopifnot(b4$mu$offset == qlogis(0.5) & 
          b4$phi$offset == log(1))

# should be ignored if only mu is modelled
b4 <- betaboost(formula = y ~ x1 + x2, start.mu = 0.1, 
                data = data, iterations = 120, sl = 0.1)
# should trigger a warning
stopifnot(identical(coef(b1, off2int = TRUE),
  coef(b4, off2int = TRUE)))


# Errors 
try(betaboost(formula = y ~ x1, phi.formula = x1 ~ x2, 
         data = data))
b2d <- betaboost(formula = y ~ x1 + bbs(x2), data = data, form.type = "gamboost",
                 iterations = 120)

