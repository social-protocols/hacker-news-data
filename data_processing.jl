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

# column names to rename
column_rename_map = [
    :rank => :topRank,
    :submission_time => :submissionTime,
    :sample_time => :sampleTime
]

# merge datasets
begin
    dataset_list = DataFrame[]
    for (i, f) in enumerate(files)
        dataset = DataFrame(CSV.File(f))
        allowmissing!(dataset)
    
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
            dataset = vcat(dataset..., cols = :union)
        end    
        for col in column_names
            if !(col in names(dataset))
                dataset[!, col] .= -1
            end
        end
        
        # replace all missing data by -1 (makes type inference easier)
        for col in names(dataset)
            replace!(dataset[!, col], "\\N" => "-1")
            dataset[!, col] = coalesce.(dataset[!, col], -1)
            if !(eltype(dataset[!, col]) == Int64)
                overwrite_col = parse.(Int64, dataset[!, col])
                dataset[!, col] = overwrite_col    
            end
        end
    
        push!(dataset_list, deepcopy(dataset))
    end
    
    dataset_final = vcat(dataset_list..., cols = :setequal)
end

CSV.write(joinpath("data", "hacker-news-dataset.csv"), dataset_final)
