using DataFrames
using Glob
using CSV

# file names of all tsv files in the data directory
files = glob("*.tsv", "data")

# column names of final scheme
column_names = [
    "id", "score", "descendants", 
    "submissionTime", "sampleTime", "tick", "samplingWindow",
    "topRank", "newRank", "bestRank", "askRank", "showRank", "jobRank"
]

# construct CSV file to append to
struc_data = Dict()
for cn in column_names
    struc_data[Symbol(cn)] = Int64[]
end
struc_data = DataFrame(struc_data)
select!(struc_data, [Symbol(cn) for cn in column_names])
CSV.write("hacker-news-dataset.csv", struc_data)

# column names to rename
column_rename_map = [
    :rank => :topRank,
    :submission_time => :submissionTime,
    :sample_time => :sampleTime
]

# merge datasets
for (i, f) in enumerate(files)
    # load raw dataset
    dataset = DataFrame(CSV.File(f, missingstring = "\\N", type = Int64, silencewarnings = true))
    
    # reformat data to match final scheme
    dataset[!, :samplingWindow] .= i
    for new_name_pair in column_rename_map
        try
            rename!(dataset, new_name_pair)
        catch
        end
    end
    if !("tick" in names(dataset))
        dataset[!, :tick] .= -1
        dataset = groupby(dataset, :sampleTime)
        for (j, g) in enumerate(dataset)
            g.tick .= j
        end
        dataset = vcat(dataset..., cols = :orderequal)
    end
    dataset = vcat(struc_data, dataset, cols = :union)

    # append to compiled file
    CSV.write("hacker-news-dataset.csv", dataset, append = true, missingstring = "NULL")

    # clear memory
    dataset = nothing
end
