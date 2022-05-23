data{
    //927 if we limit to top 30
    array[4632] int upvotes;
    array[4632] real expectedUpvotes;
    array[4632] int rank;
    array[4632] int sid;
}
parameters{
    real<lower=-5.0,upper=5.0> avgLogQuality;
    vector[100] logQuality;
    real<lower=0,upper=5> sigmaQuality;
}
model{
    vector[4632] lambda;
    sigmaQuality ~ uniform( 0 , 5 );
    logQuality ~ normal( avgLogQuality , sigmaQuality );
    avgLogQuality ~ uniform( -5.0, 5.0 );
    for ( i in 1:4632 ) {
        lambda[i] = exp(logQuality[sid[i]]) * (expectedUpvotes[i]);
    }
    upvotes ~ poisson( lambda );
}

