using DataFrames
using Dates
using DBInterface
using FunSQL:
	From,
	Fun,
	Get,
	Where,
	Group,
	Limit,
	Select,
	render, 
	Agg,
	LeftJoin,
  reflect,
  render
using HealthSampleData
using OMOPCDMCohortCreator
using SQLite
using Test
using TimeZones

using JSON3
using OHDSICohortExpressions: translate, Model

# For allowing HealthSampleData to always download sample data
ENV["DATADEPS_ALWAYS_ACCEPT"] = true

# SQLite Data Source
sqlite_conn = SQLite.DB(Eunomia())
GenerateDatabaseDetails(:sqlite, "main")
GenerateTables(sqlite_conn)

cohort_expression = read("./assets/strep_throat.json", String)

fun_sql = translate(
    cohort_expression,
    cohort_definition_id = 1,
);

include("./assets/catalog.jl")

sql = render(catalog, fun_sql);

DBInterface.execute(sqlite_conn,
"DELETE FROM cohort;")

res = DBInterface.execute(sqlite_conn,
    """
    INSERT INTO
        cohort
    SELECT
        *
    FROM
        ($sql) AS foo;
    """
)


@testset "OMOPCDMCohortCreator" begin
	@testset "SQLite Helper Functions" begin
		include("sqlite/helpers.jl")
	end
	@testset "SQLite Getter Functions" begin
		include("sqlite/getters.jl")
	end
	@testset "SQLite Filter Functions" begin
		include("sqlite/filters.jl")
	end
	#= TODO: Add Generator function testset
	This set of tests needs a bit more scrutiny as there are some functions that need to be reviewed and most likely deprecated.
	labels: tests, moderate
	assignees: thecedarprince
	=#
	# @testset "SQLite Generator Functions" begin
	#	include("sqlite/generators.jl")
	# end
	@testset "SQLite Executors Functions" begin
		include("sqlite/executors.jl")
	end

end
