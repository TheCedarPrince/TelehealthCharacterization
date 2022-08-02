library("CohortGenerator")
library("Eunomia")
library("ROhdsiWebApi")

# A list of cohort IDs for use in this vignette
cohortIds <- c(1778211, 1778212, 1778213)

# Base URL for WebAPI of OHDSI
baseUrl <- "https://api.ohdsi.org/WebAPI"

# Get the SQL/JSON for the cohorts
cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(
        baseUrl = baseUrl,
        cohortIds = cohortIds
)

saveCohortDefinitionSet(
        cohortDefinitionSet = cohortDefinitionSet,
        settingsFileName = file.path("inst/settings/CohortsToCreate.csv"),
        jsonFolder = file.path("inst/cohorts"),
        sqlFolder = file.path("inst/sql/sql_server")
)

cohortDefinitionSet <- getCohortDefinitionSet(
        settingsFileName = file.path("inst/settings/CohortsToCreate.csv"),
        jsonFolder = file.path("inst/cohorts"),
        sqlFolder = file.path("inst/sql/sql_server")
)

# Get the Eunomia connection details
connectionDetails <- Eunomia::getEunomiaConnectionDetails()

# First get the cohort table names to use for this generation task
cohortTableNames <- getCohortTableNames(cohortTable = "cg_example")

# Next create the tables on the database
createCohortTables(
        connectionDetails = connectionDetails,
        cohortTableNames = cohortTableNames,
        cohortDatabaseSchema = "main"
)

# Generate the cohort set
cohortsGenerated <- generateCohortSet(
        connectionDetails = connectionDetails,
        cdmDatabaseSchema = "main",
        cohortDatabaseSchema = "main",
        cohortTableNames = cohortTableNames,
        cohortDefinitionSet = cohortDefinitionSet
)

getCohortCounts(
        connectionDetails = connectionDetails,
        cohortDatabaseSchema = "main",
        cohortTable = cohortTableNames$cohortTable
)
