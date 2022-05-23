# The Causal Effect of Rank on Upvotes on HN

## Summary

Stories on the Hacker News home page get more upvotes. But do they get more upvotes **because** they are on the home page? Or are they on the home page **because** they get more upvotes?

Obviously, it is both. The chart below shows the number of upvotes stories receive on average at each rank on HN, and breaks this down into upvotes received **because** of rank, and upvotes received **because** of the story that was shown at that rank.

[ chart ]


## The Causal Graph


We figured this out using an approach influenced by Judea Pearl's work on Graphical Models, having recently read the textbook [Causal Inference in Statistics]. 

We start with a DAG showing our assumptions about the causal relationships in the data. 

                          story
                         ↙     ↘
                      rank  →  upvotes

There are obviously other factors effecting each of these three. But we assume that they are mutually independent and are therefore not confounders, so it is convenient to ignore them.

## Simulating an Intervention

To isolate the effect or rank on upvotes, we **simulate an intervention**. We imagine that rank is held constant at some quantity, instead of being determined by the HN ranking algorithm, then we deduce the number of upvotes a story **would receive** in this simulated model.

The post-intervention model looks like this:

                          story
                               ↘
     intervention  →  rank  →  upvotes


Since the arrows pointing from story and rank into upvotes are undisturbed, their combined influence is not changed by the invervention: a given story at a given rank gets the same number of upvotes per second in the simulation. Only the time that each story spends at each rank changes. 

## The Adjustment Formula

We can now use very similar reasoning to that used to derive the Backdoor Adjustment Formula (section X in the book), except we are dealing with upvote rates instead of a probabilities.

The upvote rate at a rank can be written as a weighted average across all stories that were shown at that rank.

    upvoteRate(rank) = ( \sum_story upvoteRate(rank, story) * timeAt(rank,story) ) / totalTime

This equation is true by definition: we are just describing the data we have. 

Now to simulate an intervention, we simply change the time each story spends at each rank. If rank is independent of story, then each story should get the same amount of time at each rank. So we simply replace timeAt(rank,story) with the average time a story spends at each rank, which is totalTime/nStories. Borrowing "do" notation to indicate that we are intervening on rank, we have:

    upvoteRate(do(rank))    = ( sum_story upvoteRate(rank,story) * totalTime/nStories ) / totalTime
                              = ( sum_story upvoteRate(rank,story) / nStories )


[
In other words, for each rank, we just take the average upvote rate across all stories at that rank. Instinctively, taking the average of rates without any sort of weight may seem suspect, but this is because we are intentionally ignoring information in the manipulated formula.
]

## Missing Data

Unfortunately not every story gets displayed at every rank. And we can't just take the average over the data points that we have, because there is a correlation between a story's upvote rate and the rank it is actually shown at, so selecting only higher-ranked stories would introduce bias.

So we need to fill in gaps of the data an estimate what the upvoteRate **would have** been for these stories.

## Modeling Story Quality

To solve this problem, we first need to model the effect of the stories themselves on upvotes. 

We assume each story has some true **quality**, which causes the story to get more or less votes than average in the long run. Note we are not using the term "quality" in the sense of "good". Rather, it is whatever qualities effect a story's score or people's propensity to upvote it, including possibly undesirable qualities such as click-baityness.

The upvote rate for a story at a rank should on average be the average upvote rate at that rank, times story quality:

     upvoteRate(rank,story) ≈ quality(story) * upvoteRate(rank) 

## Upvote Rate Ratios

This means that **ratio** of upvote rates between two ranks, for a given story, should be approximately the same for every story.

    upvoteRatio(N,M,story) = upvoteRate(N,story)/upvoteRate(M,story) 
                           ≈ quality(story)*upvoteRate(N)
                               / (quality(story)*upvoteRate(M))
                           ≈ upvoteRate(N)/upvoteRate(M) 

The geometric mean of this ratio across all stories gives us an approximation of the relative causal effect of rank on upvotes. 


    log upvoteRatio(N,M) = 1/n \sum_stories log upvoteRatio(N,M,story) 

For example, it tells us that stories receive X fewer upvotes/second at rank N **because** they are rank N and not rank 1.


## Projected Upvote Rate

We can now estimate the upvote rate for any story at rank N based on its upvote rate at rank M.

    upvoteRate(N,story) ≈ upvoteRate(M,story) * upvoteRatio(N,M)

Where M is any rank for which we have data. For a more accurate estimate, we can take the average of across all ranks where the story was shown.

    upvoteRate(N,story) ≈ 1/nRanks(story)  ∑_m in ranks(story) upvoteRate(M,story) * upvoteRatio(N,M)

We now have the information that was missing for formula (X). 


[
A more complex approach is to create a matrix with all upvote ratios for all combination of ranks, and then calculate some sort of average. 

    sum_n upvoteRateRatio()

the eigenvector of this matrix, divided by the eigenvalue (the number of ranks). This gives us a  
]

## Results

Plugging (X) into (Y) we have:

    upvoteRate(do(rank)) 
        = 1/nStories ∑_story 
            1/nRanks(story)  ∑_m in ranks(story) upvoteRate(m,story) * upvoteRatio(rank,m)

        = 1/nStories ∑_story 
            1/nRanks(story) ∑_m in ranks(story) upvoteRate(m,story) * upvoteRatio(1,m) * upvoteRatio(rank,1)

        =  upvoteRatio(rank,1) 1/nStories ∑_story 
            1/nRanks(story)  
            ∑_{m in ranks(story)} upvoteRate(m,story) * upvoteRatio(1,m)



The results are shown in this chart (same as the introduction). 

By moving higher-quality stories to the top, the HN news ranking algorithm causes X% more votes to be received at rank 1, and X% more votes overall on the site. 

Note that this considers only first-order effects: if HN were to switch to a chronological feed for example, then people's experience and behavior on the site would probably completely change. But this model gives us a basis for predicting the immediate effect of algorithm changes. 

In the [next essay], we use this model to create a simulation that reproduces the pattern of upvotes actually received at each rank, and then show how a modified algorithm could increase the overall quality of stories on the home page.


