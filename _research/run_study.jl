using DataDeps
using DataFrames
using DBInterface
using FunSQL
using LibPQ
using OMOPCDMCohortCreator
using OMOPCDMDatabaseConnector

function datasets()

register(DataDep(
    "Eunomia",
    "A standard CDM dataset for testing and demonstration purposes; link: https://github.com/OHDSI/Eunomia",
    "https://app.box.com/index.php?rm=box_download_shared_file&shared_name=n5a21tbu1rwpilgcm6q9oip30ti86ven&file_id=f_988456839468",
    "b9a6e4662107cfdbd80d96c3600f292eb480652b47ec06410158220f43326042"
))

end

datasets()

conn = DBInterface.connect(LibPQ.Connection, "")  

GenerateDatabaseDetails(
    :postgresql,
    "synpuf5"
)

tables = GenerateTables(conn, exported = true)
person = tables[:person]

include("concept_sets.jl")

#######################################
# DEFINE PATIENT TELEHEALTH VISITS
#######################################

visit_codes = [vcat(telehealth_e_visits, telehealth_visits, medicare_telehealth_visits), nothing]

###############################
# DEFINE PATIENT RACES
###############################

races =
    FunSQL.From(person) |>
    FunSQL.Group(FunSQL.Get.race_concept_id) |>
    q -> FunSQL.render(q) |>
    x -> LibPQ.execute(conn, x) |> DataFrame

race_codes = vcat(races.race_concept_id, nothing)

###############################
# DEFINE PATIENT AGE GROUPS
###############################

age_groups = [
    [0, 9],
    [10, 19],
    [20, 29],
    [30, 39],
    [40, 49],
    [50, 59],
    [60, 69],
    [70, 79],
    [80, 89],
    nothing,
]

###############################
# DEFINE PATIENT GENDERS
###############################

genders =
    FunSQL.From(person) |>
    FunSQL.Group(FunSQL.Get.gender_concept_id) |>
    q -> FunSQL.render(q) |>
    x -> DBInterface.execute(conn, String(x)) |> DataFrame

gender_codes = vcat(genders.gender_concept_id, nothing) |> vals -> filter(x -> !ismissing(x), vals)

###############################
# RUN THE STUDY
###############################

cohort_defs = collect(
    Iterators.product(visit_codes, gender_codes, race_codes, age_groups),
);

cohort_ids = []

counter = 1
for (visit, gender, race, age_group) in cohort_defs

    ids = GenerateCohorts(
	conn;
        visit_codes = visit,
        gender_codes = gender,
        race_codes = race,
        age_groupings = [age_group],
    )
    push!(cohort_ids, ids)

    break

end

populations = []

for (idx, cohort) in enumerate(cohort_ids)

    definition = cohort_defs[idx]

    df = GenerateStudyPopulations(
        cohort,
        conn;
        by_visit = isnothing(definition[1]) ? false : true,
        by_state = isnothing(definition[2]) ? false : true,
        by_gender = isnothing(definition[3]) ? false : true,
        by_race = isnothing(definition[4]) ? false : true,
        # by_age_group = isnothing(definition[5]) ? false : true,
    )

    push!(populations, df)

    break

end

# study_pop = []
# for i in 1:3

# idx = findall(def -> 
# # Find by visit type
# def[1] == visit_codes[i] && 
# # Find by condition type
# def[2] == suicidality_df.CONCEPT_ID && 
# # Find by gender
# def[3] == nothing && 
# # Find by race
# def[4] == nothing && 
# # Find by age group
# def[5] == nothing, 
# cohort_defs)

# cohort_def = cohort_defs[idx][1]

# cohort = GenerateCohorts(
    # conn;
    # visit_codes = cohort_def[1],
    # condition_codes = cohort_def[2] |> x -> convert(Vector{Int}, x),
    # gender_codes = cohort_def[3],
    # race_codes = cohort_def[4],
    # age_groupings = [cohort_def[5]],
# )

# df = GenerateStudyPopulations(cohort, conn; by_race = true, by_age_group = true)

# push!(study_pop, df)

# end
