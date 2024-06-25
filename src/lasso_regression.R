# Clear the workspace
rm(list=ls(all=TRUE))

# Load necessary library
library('glmnet')

# Load data files
load('./team_obs.RData')
load('./team_lineups.RData')
# load('team_beta0s.RData')

# Initialize lists to store results
team_lineup_coef = list()
team_lineup_starting = list()
team_lassoDF = list()

# Loop through each team
for (teamT in names(team_obs))
{
  my_T = team_obs[[teamT]][[1]]
  my_LU = team_lineups[[teamT]]
  
  n_lineups = dim(my_LU)[1]
  numgamesplayed = length(unique(my_T$rawdate))
  lassoDF = matrix(0,numgamesplayed,n_lineups+1)
  times_starting = rep(0,n_lineups)
  
  lu = as.integer(sort(my_T[1,4:8]))
  ind = which(apply(my_LU,1, function(x) identical(x,lu)))
  times_starting[ind] = times_starting[ind] + 1
  
  G = 1
  L = 1
  while (L < dim(my_T)[1])
  {
    while ((my_T[L,]$rawdate == my_T[L+1,]$rawdate) && ((L+1) <= dim(my_T)[1]))
    {
      if (my_T[L,]$timePlayed != 0)
      {	
        if (my_T[L,]$Hteam == teamT)
          tmp = as.integer(sort(my_T[L,4:8]))
        else if (my_T[L,]$Vteam == teamT)
          tmp = as.integer(sort(my_T[L,9:13]))
        ind = which(apply(my_LU,1, function(x) identical(x,tmp)))
        
        lassoDF[G,ind] = lassoDF[G,ind] + my_T[L,]$timePlayed
      }
      
      L = L + 1	
    }
    if ((L+1) > dim(my_T)[1])		
      break
    
    if (my_T[L,]$Hteam == teamT)
    {
      tmp = as.integer(sort(my_T[L,4:8]))
      lassoDF[G,n_lineups+1] =  my_T[L,]$Hscore - my_T[L,]$Vscore
    }
    else if (my_T[L,]$Vteam == teamT)
    {
      tmp = as.integer(sort(my_T[L,9:13]))
      lassoDF[G,n_lineups+1] = my_T[L,]$Vscore - my_T[L,]$Hscore
    }
    ind = which(apply(my_LU,1, function(x) identical(x,tmp)))
    lassoDF[G,ind] = lassoDF[G,ind] + my_T[L,]$timePlayed
    
    L = L + 1
    G = G + 1
    
    if (my_T[L,]$Hteam == teamT)
      tmp = as.integer(sort(my_T[L,4:8]))
    else if (my_T[L,]$Vteam == teamT)
      tmp = as.integer(sort(my_T[L,9:13]))
    
    ind = which(apply(my_LU,1, function(x) identical(x,tmp)))
    times_starting[ind] = times_starting[ind] + 1
  }
  lu = as.integer(sort(my_T[L,9:13]))
  ind = which(apply(my_LU,1, function(x) identical(x,lu)))
  lassoDF[G,ind] = lassoDF[G,ind] + my_T[L,]$timePlayed
  lassoDF[G,n_lineups+1] = my_T[L,]$Vscore - my_T[L,]$Hscore
  
  team_lassoDF[[teamT]] = lassoDF
  
  X = lassoDF[,1:n_lineups]
  Y = lassoDF[,n_lineups+1]
  
  # get beta0 in a better way
  # beta0 = apply(X, 2, function(x) { t_ind = which(x != 0); return(sum(Y[t_ind])/sum(x))} )
  # maybe use average of [row] averages 
  # beta0_simple = team_beta0s[[teamT]][[1]]
  
  # Y_hat = Y - X %*% beta0_simple
  
  grid = 10^seq(10,-2,length=100)
  train = sample(1:nrow(lassoDF), 2*nrow(lassoDF)/3)
  test = (-train)
  
  rlm_t = glmnet(X[train,], Y[train], lambda=grid, family="gaussian", alpha=1, intercept=FALSE)
  r.pred = predict(rlm_t, newx = X[test,])
  errors = apply(r.pred, 2, function(x) mean((x - Y[test])^2))
  
  lam = grid[which.min(errors)]
  rlm = glmnet(X, Y, lambda=lam, family="gaussian", alpha=1, intercept=FALSE)
  
  team_lineup_coef[[teamT]] = as.vector(coef(rlm)[,1])[-1]
  team_lineup_starting[[teamT]] = times_starting
  
  # Using SVD for comparison, as in the original code
  # s = svd(X, nu=dim(X)[1], nv=dim(X)[2])
  
  # s$d[s$d != 0] = 1/ s$d[s$d != 0]
  # D = rbind(diag(s$d), matrix(0, dim(X)[2] - length(s$d), dim(X)[1]))
  # X_inv = s$v %*% D %*% t(s$u)
  # beta = X_inv %*% Y
  
  # team_lineup_coef[[teamT]] = beta 
  # team_lineup_starting[[teamT]] = times_starting
}

save(team_lineup_coef, file = "lasso_team_lineup_coef.RData")
save(team_lineup_starting, file = "lasso_team_lineup_starting.RData")
save(team_lassoDF, file = "team_lassoDF.RData")