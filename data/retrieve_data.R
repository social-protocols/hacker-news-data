# To run this script: 
# * generate a personal access token (PAT) on OSF
# * create a file .Renviron in this directory and save the PAT as an
#   environment variable (OSF_PAT = <YOUR TOKEN>)

library(osfr)

osf_proj <- osf_retrieve_node("bnysw")
