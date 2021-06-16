using DataFrames
using Glob
using CSV

# column names of final scheme
COLUMN_NAMES = [
    "id", "score", "descendants", 
    "submissionTime", "sampleTime", "tick", "samplingWindow",
    "topRank", "newRank", "bestRank", "askRank", "showRank", "jobRank"
]
    
# column names to rename
COLUMN_RENAME_MAP = [
    :rank => :topRank,
    :submission_time => :submissionTime,
    :sample_time => :sampleTime
]

# update column names to match the final scheme
function update_column_names!(dataset)
    for new_name_pair in COLUMN_RENAME_MAP
        try
            rename!(dataset, new_name_pair)
        catch
        end
    end
    return dataset
end

# add a column enumerating the sampling time slices
function add_tick!(dataset)
    if !("tick" in names(dataset))
        dataset[!, :tick] .= -1
        dataset = groupby(dataset, :sampleTime)
        for (j, g) in enumerate(dataset)
            g.tick .= j - 1
        end
        dataset = vcat(dataset..., cols = :orderequal)
    end
    return dataset
end

# construct CSV file to append to
struc_data = Dict()
for cn in COLUMN_NAMES
    struc_data[Symbol(cn)] = Int64[]
end
struc_data = DataFrame(struc_data)
select!(struc_data, [Symbol(cn) for cn in COLUMN_NAMES])
CSV.write("hacker-news-dataset.csv", struc_data)

# file names of all tsv files in the data directory
files = glob("*.tsv", "data")

# write initial dataset (first sampling window)
hacker_news_exploratory = DataFrame(CSV.File(popfirst!(files), missingstring = "\\N", type = Int64, silencewarnings = true))
CSV.write("hacker-news-exploratory.csv", hacker_news_exploratory, missingstring = "NULL")

# merge datasets
for (i, f) in enumerate(files)
    # load raw dataset
    dataset = DataFrame(CSV.File(f, missingstring = "\\N", type = Int64, silencewarnings = true))
    
    # reformat data to match final scheme
    dataset[!, :samplingWindow] .= i
    update_column_names!(dataset)
    add_tick!(dataset)
    
    # append to compiled file
    dataset = vcat(struc_data, dataset, cols = :union)
    CSV.write("hacker-news-dataset.csv", dataset, append = true, missingstring = "NULL")

    # clear memory
    dataset = nothing
end
