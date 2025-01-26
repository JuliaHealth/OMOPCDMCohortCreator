"""
GetDatabasePersonIDs(conn; tab = person)

Get all unique `person_id`'s from a database.

# Arguments:

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `ids::Vector{Int64}` - the list of persons
"""
function GetDatabasePersonIDs(conn; tab= person)
    ids = DBInterface.execute(conn, String(GetDatabasePersonIDs(tab=tab))) |> DataFrame

    return convert(Vector{Int}, ids.person_id)

end

"""
GetDatabaseYearRange(conn; tab = observation_period)

Get the years for which data is available from a database.

# Arguments:

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Observation Period table; default `observation_period`

# Returns

- `year_range::NamedTuple{(:first_year, :last_year), Tuple{Int64, Int64}}` - a NamedTuple where `first_year` is the first year data from the database was available and `last_year` where the last year data from the database was available
"""
function GetDatabaseYearRange(conn; tab=observation_period)
    years = DBInterface.execute(conn, String(GetDatabaseYearRange(tab=tab))) |> DataFrame

    return (first_year=first(years.first_year), last_year=first(years.last_year))

end

"""
GetDatabaseYearRange(; tab = observation_period)

Return SQL to find the years for which data is available from a database.

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Observation Period table; default `observation_period`

# Returns

- `year_range::NamedTuple{(:first_year, :last_year), Tuple{Int64, Int64}}` - a NamedTuple where `first_year` is the first year data from the database was available and `last_year` where the last year data from the database was available
"""
function GetDatabaseYearRange(; tab=observation_period)
    sql = From(tab) |>
          Group() |>
          Select(:first_year => Agg.min(Get.observation_period_end_date),
              :last_year => Agg.max(Get.observation_period_end_date)) |>
          q -> render(q, dialect=OMOPCDMCohortCreator.dialect)

    return String(sql)

end

"""
GetDatabasePersonIDs(; tab = person)

Return SQL statement that gets all unique `person_id`'s from a database.

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `sql::String` - Prepared SQL statement as a `String`
"""
function GetDatabasePersonIDs(; tab=person)
    sql =
        From(tab) |>
        Group(Get.person_id) |>
        q ->
            render(q, dialect=dialect)

    return String(sql)
end

"""
GetPatientState(ids, conn; tab = location, join_tab = person)

Given a list of person IDs, find their home state.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Location table; default `location`

- `join_tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:state`
"""
function GetPatientState(
    ids,
    conn;
    tab=location,
    join_tab=person
)
    df = DBInterface.execute(conn, GetPatientState(ids; tab=tab, join_tab=join_tab)) |> DataFrame

    return df

end

"""
GetPatientState(df:DataFrame, conn; tab = location)

Given a `DataFrame` with a `:person_id` column, return the `DataFrame` with an associated `:state` for each person in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetPatientState(ids, conn; tab = location)`
"""

function GetPatientState(
    df::DataFrame,
    conn;tab=location,
    join_tab=person
    )

    df_ids= df[:,"person_id"]
    

    return outerjoin(GetPatientState(df_ids,conn, ; tab=tab, join_tab=join_tab), df, on = :person_id)
end
"""
GetPatientState(ids; tab = location, join_tab = person)

Return SQL statement where if given a list of person IDs, find their home state.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Location table; default `location`

- `join_tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:state`
"""
function GetPatientState(
    ids;
    tab=location,
    join_tab=person
)
    sql =
        From(tab) |>
        Select(Get.location_id, Get.state) |>
        Join(:join => join_tab, Get.location_id .== Get.join.location_id) |>
        Where(Fun.in(Get.join.person_id, ids...)) |>
        Select(Get.join.person_id, Get.state) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetPatientGender(ids, conn; tab = person)

Given a list of person IDs, find their gender.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:gender_concept_id`
"""
function GetPatientGender(
    ids,
    conn;
    tab=person
)
    df = DBInterface.execute(conn, GetPatientGender(ids; tab=tab)) |> DataFrame

    return df

end

"""
GetPatientGender(df:DataFrame, conn; tab = person)

Given a `DataFrame` with a `:person_id` column, return the `DataFrame` with an associated `:gender_concept_id` for each person in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetPatientGender(ids, conn; tab = person)`
"""

function GetPatientGender(
    df::DataFrame,
    conn;tab=person
    )

    df_ids= df[:,"person_id"]
    

    return outerjoin(GetPatientGender(df_ids, conn; tab=tab), df, on = :person_id)
end

"""
GetPatientGender(ids; tab = person)

Return SQL statement that gets the `gender_concept_id` for a given list of `person_id`'s

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:gender_concept_id`
"""
function GetPatientGender(
    ids;
    tab=person
)
    sql =
        From(tab) |>
        Where(Fun.in(Get.person_id, ids...)) |>
        Select(Get.person_id, Get.gender_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetPatientEthnicity(ids, conn; tab = person)

Given a list of person IDs, find their ethnicity.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:ethnicity_concept_id`
"""
function GetPatientEthnicity(
    ids,
    conn;
    tab=person
)
    df = DBInterface.execute(conn, GetPatientEthnicity(ids; tab=tab)) |> DataFrame

    return df

end

"""
GetPatientEthnicity(df:DataFrame, conn; tab = person)

Given a `DataFrame` with a `:person_id` column, return the `DataFrame` with an associated `:ethnicity` for each person in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetPatientEthnicity(ids, conn; tab = person)`
"""

function GetPatientEthnicity(
    df::DataFrame,
    conn;
    tab=person
    )

    df_ids= df[:,"person_id"]
    

    return outerjoin(GetPatientEthnicity(df_ids, conn; tab=tab), df, on = :person_id)
end


"""
GetPatientEthnicity(ids, conn; tab = person)

Return SQL statement that gets the `ethnicity_concept_id` for a given list of `person_id`'s

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:ethnicity_concept_id`
"""
function GetPatientEthnicity(ids; tab=person)
    sql =
        From(tab) |>
        Where(Fun.in(Get.person_id, ids...)) |>
        Select(Get.person_id, Get.ethnicity_concept_id) |>
        q ->
            render(q, dialect=dialect)

    return String(sql)

end

"""
GetPatientRace(ids, conn; tab = person)

Given a list of person IDs, find their race.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:race_concept_id`
"""
function GetPatientRace(ids, conn; tab=person)
    df = DBInterface.execute(conn, GetPatientRace(ids; tab=tab)) |> DataFrame

    return df

end

"""
GetPatientRace(df:DataFrame, conn; tab = person)

Given a `DataFrame` with a `:person_id` column, return the `DataFrame` with an associated `:race` for each person in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetPatientRace(ids, conn; tab = person)`
"""

function GetPatientRace(
    df::DataFrame,
    conn;
    tab=person
    )

    df_ids= df[:,"person_id"]
    

    return outerjoin(GetPatientRace(df_ids, conn; tab=tab), df, on = :person_id)
end
"""
GetPatientRace(ids; tab = person)

Return SQL statement that gets the `race_concept_id` for a given list of `person_id`'s

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:race_concept_id`
"""
function GetPatientRace(ids; tab=person)
    sql =
        From(tab) |>
        Where(Fun.in(Get.person_id, ids...)) |>
        Select(Get.person_id, Get.race_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetPatientAgeGroup(
    ids, conn;
    minuend = :now,
    age_groupings = [
        [0, 9],
        [10, 19],
        [20, 29],
        [30, 39],
        [40, 49],
        [50, 59],
        [60, 69],
        [70, 79],
        [80, 89],
    ],
    tab = person,
    ungrouped_label = "Unspecified"
)

Finds all individuals in age groups as specified by `age_groupings`.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `age_groupings` - a vector of age groups of the form `[[10, 19], [20, 29],]` denoting an age group of 10 - 19 and 20 - 29 respectively; age values must subtype of `Integer`

- `minuend` - the year that a patient's `year_of_birth` variable is subtracted from; default `:now`. There are two different options that can be set: 
    - `:now` - the year as of the day the code is executed given in UTC time
    - any year provided by a user as long as it is an `Integer` (such as 2022, 1998, etc.)

- `tab` - the `SQLTable` representing the Person table; default `person`
    
- `ungrouped_label` - the label to assign persons who do not fit to a provided matching age group; default label "Unspecified"

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:age_group`

# Note

Age can be difficult to be calculated consistently.
In this case, there are some assumptions made to ensure consistency: 

1. According to the OMOP CDM v5.4, only the variable `year_of_birth` is guaranteed for a given patient. This is one of three options used as the minuend in age calculations.

2. The subtrahend is based on what one chooses for the `minuend` key word argument.

The age is then calculated following what is selected based on 1 and 2.
This flexibility is encoded to allow a user to choose how they want age groups calculated as well as clear up an ambiguity on how this is determined.
"""
function GetPatientAgeGroup(
    ids,
    conn;
    minuend=:now,
    age_groupings=[
        [0, 9],
        [10, 19],
        [20, 29],
        [30, 39],
        [40, 49],
        [50, 59],
        [60, 69],
        [70, 79],
        [80, 89],
    ],
    tab=person,
    ungrouped_label = "Unspecified"
)

    df = DBInterface.execute(conn, GetPatientAgeGroup(ids; minuend=minuend, age_groupings=age_groupings, tab=tab, ungrouped_label=ungrouped_label)) |> DataFrame

    return df

end

"""
GetPatientAgeGroup(df:DataFrame, conn; minuend=:now,
age_groupings=[
    [0, 9],
    [10, 19],
    [20, 29],
    [30, 39],
    [40, 49],
    [50, 59],
    [60, 69],
    [70, 79],
    [80, 89],
], 
tab = person,
ungrouped_label = "Unspecified")

Given a `DataFrame` with a `:person_id` column, return the `DataFrame` with an associated `:ageGroup` for each person in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetPatientAgeGroup(ids, conn; tab = person)`
"""

function GetPatientAgeGroup(
    df::DataFrame,
    conn;
    minuend=:now,
    tab=person,
    ungrouped_label = "Unspecified"
    )

    df_ids= df[:,"person_id"]
    
    return outerjoin(GetPatientAgeGroup(df_ids, conn; minuend=minuend, tab=tab, ungrouped_label=ungrouped_label), df, on = :person_id)
end

"""
GetPatientAgeGroup(
    ids;
    minuend = :now,
    age_groupings = [
        [0, 9],
        [10, 19],
        [20, 29],
        [30, 39],
        [40, 49],
        [50, 59],
        [60, 69],
        [70, 79],
        [80, 89],
    ],
    tab = person,
    ungrouped_label = "Unspecified"
)

Return SQL statement that assigns an age group to each patient in a given patient list. 
Customized age groupings can be provided as a list.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `age_groupings` - a vector of age groups of the form `[[10, 19], [20, 29],]` denoting an age group of 10 - 19 and 20 - 29 respectively; age values must subtype of `Integer`

- `minuend` - the year that a patient's `year_of_birth` variable is subtracted from; default `:now`. There are two different options that can be set: 
    - `:now` - the year as of the day the code is executed given in UTC time
    - any year provided by a user as long as it is an `Integer` (such as 2022, 1998, etc.)

- `tab` - the `SQLTable` representing the Person table; default `person`

- `ungrouped_label` - the label to assign persons who do not fit to a provided matching age group; default label "Unspecified"

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:age_group`

# Note

Age can be difficult to be calculated consistently.
In this case, there are some assumptions made to ensure consistency: 

1. According to the OMOP CDM v5.4, only the variable `year_of_birth` is guaranteed for a given patient. This is one of three options used as the minuend in age calculations.

2. The subtrahend is based on what one chooses for the `minuend` key word argument.

The age is then calculated following what is selected based on 1 and 2.
This flexibility is encoded to allow a user to choose how they want age groups calculated as well as clear up an ambiguity on how this is determined.
"""
function GetPatientAgeGroup(
    ids;
    minuend=:now,
    age_groupings=[
        [0, 9],
        [10, 19],
        [20, 29],
        [30, 39],
        [40, 49],
        [50, 59],
        [60, 69],
        [70, 79],
        [80, 89],
    ],
    tab=person,
    ungrouped_label = "Unspecified"
)

    minuend = _determine_calculated_year(minuend)
    age_arr = []

    for grp in age_groupings
        push!(age_arr, Get.age .< grp[2] + 1)
        push!(age_arr, "$(grp[1]) - $(grp[2])")
    end

    sql = From(tab) |>
          Where(Fun.in(Get.person_id, ids...)) |>
          Select(Get.person_id, :age => minuend .- Get.year_of_birth) |>
          Define(:age_group => Fun.case(age_arr..., ungrouped_label)) |>
          Select(Get.person_id, Get.age_group) |>
          q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetPatientVisits(ids, conn; tab = visit_occurrence)

Given a list of person IDs, find all their visits.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Visit Occurrence table; default `visit_occurrence`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:visit_occurrence_id`

"""
function GetPatientVisits(
    ids,
    conn;
    tab=visit_occurrence
)

    df = DBInterface.execute(conn, GetPatientVisits(ids; tab=tab)) |> DataFrame

    return df

end

"""
GetPatientVisits(df:DataFrame, conn; tab = visit_occurrence)

Given a `DataFrame` with a `:person_id` column, return the `DataFrame` with an associated `:visit_occurrence_id` for each person in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetPatientVisits(ids, conn; tab = visit_occurrence)`
"""

function GetPatientVisits(
    df::DataFrame,
    conn;
    tab=visit_occurrence
)

    df_ids= df[:,"person_id"]
    
    return outerjoin(GetPatientVisits(df_ids, conn; tab=tab), df, on = :person_id)

end
"""
GetPatientVisits(ids; tab = visit_occurrence)

Return SQL statement that returns all `visit_occurrence_id` for a given patient list

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Visit Occurrence table; default `visit_occurrence`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:visit_occurrence_id`

"""
function GetPatientVisits(
    ids;
    tab=visit_occurrence
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.person_id, ids...)) |>
        Select(Get.person_id, Get.visit_occurrence_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetMostRecentConditions(ids, conn; tab = condition_occurrence)

Given a list of person IDs, find their last recorded conditions.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `condition_occurrence`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:condition_concept_id`
"""
function GetMostRecentConditions(
    ids,
    conn;
    tab=condition_occurrence
)

    df = DBInterface.execute(conn, GetMostRecentConditions(ids; tab=tab)) |> DataFrame

    return df

end

"""
GetMostRecentConditions(df:DataFrame, conn; tab = condition_occurrence)

Given a `DataFrame` with a `:person_id` column, return the `DataFrame` with an associated `:condition_concept_id` for each person in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetMostRecentConditions(ids, conn; tab = condition_occurrence)`
"""

function GetMostRecentConditions(
    df::DataFrame,
    conn;
    tab=condition_occurrence
)

    df_ids= df[:,"person_id"]
    
    return outerjoin(GetMostRecentConditions(df_ids, conn; tab=tab), df, on = :person_id)

end

"""
GetMostRecentConditions(ids; tab = condition_occurrence)

Produces SQL statement that, given a list of person IDs, finds their last recorded conditions.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `condition_occurrence`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:condition_concept_id`
"""
function GetMostRecentConditions(
    ids;
    tab=condition_occurrence
)

    sql =
        From(tab) |>
        Join(
            :date_tab =>
                From(tab) |>
                Where(Fun.in(Get.person_id, ids...)) |>
                Group(Get.person_id) |>
                Select(Get.person_id, :last_date => Agg.max(Get.condition_end_date)),
            on=Fun.and(
                Get.person_id .== Get.date_tab.person_id,
                Get.condition_end_date .== Get.date_tab.last_date,
            ),
        ) |>
        Select(Get.person_id, Get.condition_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetMostRecentVisit(ids, conn; tab = visit_occurrence)

Given a list of person IDs, find their last recorded visit.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Visit Occurrence table; default `visit_occurrence`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:visit_occurrence_id`
"""
function GetMostRecentVisit(
    ids,
    conn;
    tab=visit_occurrence
)

    df = DBInterface.execute(conn, GetMostRecentVisit(ids; tab=tab)) |> DataFrame

    return df
end

"""
function GetMostRecentVisit(df:DataFrame, conn; tab = visit_occurrence)

Given a `DataFrame` with a `:person_id` column, return the `DataFrame` with an associated `:visit_occurrence_id` for each person in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetMostRecentVisit(ids, conn; tab = visit_occurrence)`
"""

function GetMostRecentVisit(
    df::DataFrame,
    conn;
    tab=visit_occurrence
)

    df_ids= df[:,"person_id"]
    
    return outerjoin(GetMostRecentVisit(df_ids, conn; tab=tab), df, on = :person_id)

end
"""
GetMostRecentVisit(ids, conn; tab = visit_occurrence)

Produces SQL statement that, given a list of person IDs, finds their last recorded visit.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Visit Occurrence table; default `visit_occurrence`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:visit_occurrence_id`
"""
function GetMostRecentVisit(
    ids;
    tab=visit_occurrence
)

    sql =
        From(tab) |>
        Join(
            :date_tab =>
                From(tab) |>
                Where(Fun.in(Get.person_id, ids...)) |>
                Group(Get.person_id) |>
                Select(Get.person_id, :last_date => Agg.max(Get.visit_end_date)),
            on=Fun.and(
                Get.person_id .== Get.date_tab.person_id,
                Get.visit_end_date .== Fun.cast(Get.date_tab.last_date, "date"),
            ),
        ) |>
        Group(Get.person_id) |>
        Select(Get.person_id, :visit_occurrence_id => Agg.max(Get.visit_occurrence_id)) |> # ASSUMPTION: IF MULTIPLE VISITS IN ONE DAY, SELECT MOST RECENT visit_occurrence_id
        q -> render(q, dialect=dialect)

    return String(sql)
end

"""
GetVisitCondition(visit_ids, conn; tab = visit_occurrence)

Given a list of visit IDs, find their corresponding conditions.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `condition_occurrence`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:condition_concept_id`
"""
function GetVisitCondition(
    visit_ids,
    conn;
    tab=condition_occurrence
)

    df = DBInterface.execute(conn, GetVisitCondition(visit_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetVisitCondition(df:DataFrame, conn; tab = condition_occurrence)

Given a `DataFrame` with a `:visit_occurrence_id` column, return the `DataFrame` with an associated `:condition_concept_id` for each `visit_occurrence_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetVisitCondition(ids, conn; tab = condition_occurrence)`
"""

function GetVisitCondition(
    df::DataFrame,
    conn;
    tab=condition_occurrence
)

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitCondition(df_ids, conn; tab=tab), df, on = :visit_occurrence_id)

end
"""
GetVisitCondition(visit_ids; tab = visit_occurrence)

Produces SQL statement that, given a list of `visit_id`'s, finds the conditions diagnosed associated with that visit.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `condition_occurrence`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:condition_concept_id`
"""
function GetVisitCondition(
    visit_ids;
    tab=condition_occurrence
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
        Select(Get.visit_occurrence_id, Get.condition_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

#= TODO: Write tests for GetVisitPlaceOfService
Only needs one or two tests; may be difficult to test as I do not think Eunomia has anything other than missing
labels: tests, good first issue
assignees: VarshC
=#

"""
GetVisitPlaceOfService(visit_ids, conn; tab = visit_occurrence, join_tab = care_site)

Given a list of visit IDs, find their place of service 

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `visit_occurrence`

- `join_tab` - the `SQLTable` representing the Person table; default `care_site`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:condition_concept_id`
"""
function GetVisitPlaceOfService(
    visit_ids,
    conn;
    tab=visit_occurrence,
    join_tab=care_site
)

    df = DBInterface.execute(conn, GetVisitPlaceOfService(visit_ids; tab=tab, join_tab=join_tab)) |> DataFrame

    return df

end

"""
function GetVisitPlaceOfService(df:DataFrame, conn; tab = visit_occurrence, join_tab=care_site)

Given a `DataFrame` with a `:visit_occurrence_ids` column, return the `DataFrame` with an associated `:visit_occurrence_id` and `:condition_concept_id` for each `visit_id` in the `DataFrame` joined by `care_site` table.

Multiple dispatch that accepts all other arguments like in `GetVisitPlaceOfService(ids, conn; tab = visit_occurrence, join_tab=care_site)`
"""

function GetVisitPlaceOfService(
    df::DataFrame,
    conn;
    tab=visit_occurrence,
    join_tab=care_site
)

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitPlaceOfService(df_ids, conn; tab=tab, join_tab=join_tab ), df, on = :visit_occurrence_id)

end

"""
GetVisitPlaceOfService(visit_ids; tab = visit_occurrence, join_tab = care_site)

Produces SQL statement that, given a list of visit IDs, find their place of service 

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `visit_occurrence`

- `join_tab` - the `SQLTable` representing the Person table; default `care_site`

# Returns

- `sql::String` - Prepared SQL statement as a `String`
"""
function GetVisitPlaceOfService(
    visit_ids;
    tab=visit_occurrence,
    join_tab=care_site
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
        Select(Get.visit_occurrence_id, Get.care_site_id) |>
        Join(:join => join_tab, Get.care_site_id .== Get.join.care_site_id) |>
        Select(Get.visit_occurrence_id, Get.join.place_of_service_concept_id) |> 
        q -> render(q, dialect=dialect)

    return String(sql)

end

#= TODO: Write tests for GetVisitConcept
Only needs one or two tests; should have everything that is required in Eunomia to run!
labels: tests, good first issue
assignees: VarshC
=#
"""
GetVisitConcept(visit_ids, conn; tab = visit_occurrence)

Given a list of visit IDs, find their corresponding visit_concept_id's.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `visit_occurrence`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:visit_concept_id`
"""
function GetVisitConcept(
    visit_ids,
    conn;
    tab=visit_occurrence
)

    df = DBInterface.execute(conn, GetVisitConcept(visit_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetVisitConcept(df:DataFrame, conn; tab = visit_occurrence)

Given a `DataFrame` with a `:visit_occurrence_id` column, return the `DataFrame` with an associated `:visit_occurrence_id` and `:visit_concept_id` for each `visit_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetVisitConcept(ids, conn; tab = visit_occurrence)`
"""

function GetVisitConcept(
    df::DataFrame,
    conn;
    tab=visit_occurrence,
    )

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitConcept(df_ids, conn; tab=tab ), df, on = :visit_occurrence_id)

end

"""
GetVisitConcept(visit_ids; tab = visit_occurrence)

Produces SQL statement that, given a list of visit IDs, find their corresponding visit_concept_id's.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `visit_occurrence`

# Returns

- `sql::String` - Prepared SQL statement as a `String`
"""
function GetVisitConcept(
    visit_ids;
    tab=visit_occurrence
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
        Select(Get.visit_occurrence_id, Get.visit_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetVisitDate(visit_occurrence_id; interval::Symbol = :start, tab = visit_occurrence)

This function queries a database for the start or end date of the visit occurrence associated with the given `visit_occurrence_id` or list of `visit_occurrence_id`'s.

# Arguments:
- `visit_occurrence_id`: A single `visit_occurrence_id` or a vector of `visit_occurrence_id`'s to query for.

- `conn` - database connection using DBInterface

# Keyword Arguments

- `interval`: A keyword argument that determines whether to query for the visit start date (`interval=:start`) or the visit end date (`interval=:end`). Default value is `interval=:start`.

# Returns:
A dataframe with two columns: `visit_occurrence_id` and either `visit_start_date` or `visit_end_date`, depending on the value of the `interval` argument.
"""
function GetVisitDate(
    visit_occurrence_ids,
    conn;
    interval::Symbol = :start,
    tab=visit_occurrence
)
    df = DBInterface.execute(conn, GetVisitDate(visit_occurrence_ids; interval, tab=tab)) |> DataFrame
    return df
end

"""
function GetVisitDate(df:DataFrame, conn; interval::Symbol = :start, tab = visit_occurrence)

Given a `DataFrame` with a `:visit_occurrence_id` column, return the `visit_occurrence_id` and either `visit_start_date` or `visit_end_date`, depending on the value of the `interval` for each `visit_occurrence_id` 

Multiple dispatch that accepts all other arguments like in `GetVisitDate(ids, conn; interval, tab = visit_occurrence)`
"""

function GetVisitDate(
    df::DataFrame,
    conn;
    interval::Symbol = :start,
    tab=visit_occurrence,
    )

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitDate(df_ids, conn; interval, tab=tab ), df, on = :visit_occurrence_id)

end

"""
GetVisitDate(visit_occurrence_id; interval::Symbol = :start, tab = visit_occurrence)

Produces SQL statement that, given a list of visit IDs, finds the visit start or end date.

# Arguments:

- `visit_occurrence_id`: A single `visit_occurrence_id` or a vector of `visit_occurrence_id`'s to query for.

# Keyword Arguments

- `interval`: A keyword argument that determines whether to query for the visit start date (`interval=:start`) or the visit end date (`interval=:end`). Default value is `interval=:start`.

# Returns:

A dataframe with two columns: `visit_occurrence_id` and either `visit_start_date` or `visit_end_date`, depending on the value of the `interval` argument.
"""
function GetVisitDate(
    visit_occurrence_id;
    interval::Symbol = :start,
    tab=visit_occurrence
)
    if (interval == :start)
        sql =
            From(tab) |>
            Where(Fun.in(Get.visit_occurrence_id, visit_occurrence_id...)) |>
            Select(Get.visit_occurrence_id, Get.visit_start_date) |>
            q -> render(q, dialect=dialect)
        return String(sql)
    elseif (interval == :end)
        sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_occurrence_id...)) |>
        Select(Get.visit_occurrence_id, Get.visit_end_date) |>
        q -> render(q, dialect=dialect)
        return String(sql)
    else
        return "NA"
    end

end

"""
GetDrugExposureIDs(ids, conn; tab = drug_exposure)

Given a list of person IDs, find their drug exposure.

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the the drug_exposure table; default `drug_exposure`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:drug_exposure_id`
"""
function GetDrugExposureIDs(
    ids,
    conn;
    tab=drug_exposure
)
    df = DBInterface.execute(conn, GetDrugExposureIDs(ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetDrugExposureIDs(df:DataFrame, conn; tab = drug_exposure)

Given a `DataFrame` with a `:person_id` column, return the `DataFrame` with an associated `:drug_exposure_id`for each `person_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetDrugExposureIDs(ids, conn; tab = drug_exposure)`
"""

function GetDrugExposureIDs(
    df::DataFrame,
    conn;
    tab=drug_exposure
    )

    df_ids= df[:,"person_id"]
    

    return outerjoin(GetDrugExposureIDs(df_ids, conn; tab=tab), df, on = :person_id)
end

"""
GetDrugExposureIDs(ids; tab = drug_exposure)

Return SQL statement that gets the `drug_exposure_id` for a given list of `person_id`'s

# Arguments:

- `ids` - list of `person_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the drug_exposure table; default `drug_exposure`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:person_id` and `:drug_exposure_id`
"""

function GetDrugExposureIDs(
    ids;
    tab=drug_exposure
)
    sql =
        From(tab) |>
        Where(Fun.in(Get.person_id, ids...)) |>
        Select(Get.person_id, Get.drug_exposure_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetDrugConcepts(drug_exposure_ids; tab = drug_exposure)

Given a list of drug Exposure IDs, find their drug_concept_id.

# Arguments:

- `drug_exposure_ids` - list of `drug_exposure_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the drug_exposure table; default `drug_exposure`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:drug_exposure_id` and `:drug_concept_id`
"""
function GetDrugConceptIDs(
    drug_exposure_ids,
    conn;
    tab=drug_exposure
)
    df = DBInterface.execute(conn, GetDrugConceptIDs(drug_exposure_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetDrugConceptIDs(df:DataFrame, conn; tab = drug_exposure)

Given a `DataFrame` with a `:drug_exposure_id` column, return the `DataFrame` with an associated `:drug_concept_id`for each `drug_exposure_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetDrugConceptIDs(ids, conn; tab = drug_exposure)`
"""


function GetDrugConceptIDs(
    df::DataFrame,
    conn;
    tab=drug_exposure
    )

    df_ids= df[:,"drug_exposure_id"]
    

    return outerjoin(GetDrugConceptIDs(df_ids, conn; tab=tab), df, on = :drug_exposure_id)
end
"""
GetDrugConcepts(drug_exposure_ids; tab = drug_exposure)

Return SQL statement that gets the `drug_concept_id` for a given list of `drug_exposure_id`'s

# Arguments:

- `drug_exposure_ids` - list of `drug_exposure_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the drug_exposure table; default `drug_exposure`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:drug_exposure_id` and `:drug_concept_id`
"""
function GetDrugConceptIDs(
    drug_exposure_ids;
    tab=drug_exposure
)
    sql =
        From(tab) |>
        Where(Fun.in(Get.drug_exposure_id, drug_exposure_ids...)) |>
        Select(Get.drug_exposure_id, Get.drug_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetDrugAmounts(drug_concept_ids, conn; tab = drug_strength)

Given a list of drugs concept IDs, find their amount.

# Arguments:

- `drug_concept_ids` - list of `drug_concept_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the drug_strength table; default `drug_strength`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:drug_concept_id` and `:amount_value`
"""
function GetDrugAmounts(
    drug_concept_ids,
    conn;
    tab=drug_strength
)
    df = DBInterface.execute(conn, GetDrugAmounts(drug_concept_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetDrugAmounts(df:DataFrame, conn; tab = drug_strength)

Given a `DataFrame` with a `:drug_concept_id` column, return the `DataFrame` with an associated `:amount_value`for each `drug_concept_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetDrugAmounts(ids, conn; tab = drug_exposure)`
"""


function GetDrugAmounts(
    df::DataFrame,
    conn;
    tab=drug_strength
    )

    df_ids= df[:,"drug_concept_id"]
    

    return outerjoin(GetDrugAmounts(df_ids, conn; tab=tab), df, on = :drug_concept_id)
end
"""
GetDrugAmounts(drug_concept_ids; tab = drug_strength)

Return SQL statement that gets the `amount_value` for a given list of `drug_concept_id`'s

# Arguments:

- `drug_concept_ids` - list of `drug_concept_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the drug_strength table; default `drug_strength`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:drug_concept_id` and `:amount_value`
"""
function GetDrugAmounts(
    drug_concept_ids;
    tab=drug_strength
)
    sql =
        From(tab) |>
        Where(Fun.in(Get.drug_concept_id, drug_concept_ids...)) |>
        Select(Get.drug_concept_id, Get.amount_value) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetVisitProcedure(visit_ids, conn; tab = procedure_occurrence)

Given a list of visit IDs, find their corresponding procedures.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `procedure_occurrence`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:procedure_concept_id`
"""
function GetVisitProcedure(
    visit_ids,
    conn;
    tab=procedure_occurrence
)

    df = DBInterface.execute(conn, GetVisitProcedure(visit_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetVisitProcedure(df:DataFrame, conn; tab = procedure_occurrence)

Given a `DataFrame` with a `:visit_occurrence_id` column, return the `DataFrame` with an associated `:procedure_concept_id` for each `visit_occurrence_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetVisitProcedure(ids, conn; tab = procedure_occurrence)`
"""

function GetVisitProcedure(
    df::DataFrame,
    conn;
    tab=procedure_occurrence
)

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitProcedure(df_ids, conn; tab=tab), df, on = :visit_occurrence_id)

end

"""
GetVisitProcedure(visit_ids; tab = procedure_occurrence)

Produces SQL statement that, given a list of `visit_id`'s, finds the procedures associated with that visit.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Procedure Occurrence table; default `procedure_occurrence`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:procedure_concept_id`
"""
function GetVisitProcedure(
    visit_ids;
    tab=procedure_occurrence
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
        Select(Get.visit_occurrence_id, Get.procedure_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetCohortSubjects(cohort_ids, conn; tab = cohort)

Given a list of cohort IDs, find their corresponding subjects.

# Arguments:

- `cohort_ids` - list of `cohort_id`'s; each ID must be of subtype `Float64`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the `cohort` table; default `cohort`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:cohort_definition_id` and `:subject_id`
"""
function GetCohortSubjects(
    cohort_ids, 
    conn; 
    tab = cohort
)

    df = DBInterface.execute(conn, GetCohortSubjects(cohort_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetCohortSubjects(df:DataFrame, conn; tab = cohort)

Given a `DataFrame` with a `:cohort_definition_id` column, return the `DataFrame` with an associated `:subject_id` for each `cohort_definition_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetCohortSubjects(ids, conn; tab = cohort)`
"""

function GetCohortSubjects(
    df::DataFrame,
    conn;
    tab = cohort
)

    df_ids= df[:,"cohort_definition_id"]
    
    return outerjoin(GetCohortSubjects(df_ids, conn; tab=tab), df, on = :cohort_definition_id)

end

"""
GetCohortSubjects(cohort_ids; tab = cohort)

Produces SQL statement that, given a list of `cohort_id`'s, finds the subjects associated with that cohort.

# Arguments:

- `cohort_ids` - list of `cohort_id`'s; each ID must be of subtype `Float64`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the `cohort` table; default `cohort`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:cohort_definition_id` and `:subject_id`
"""
function GetCohortSubjects(
    cohort_ids;
    tab = cohort
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.cohort_definition_id, cohort_ids...)) |>
        Select(Get.cohort_definition_id, Get.subject_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
function GetCohortSubjectStartDate(cohort_ids, subject_ids, conn; tab=cohort)

    Given a single or list of cohort IDs and subject IDs, return their start dates.
    
    # Arguments:
    
    - `cohort_ids` - list of `cohort_id`'s; each ID must be of subtype `Float64`
        
    - `subject_id` - list of `subject_id`'s; each ID must be of subtype `Float64`
        
    - `conn` - database connection using DBInterface
        
    # Keyword Arguments:
        
    - `tab` - the `SQLTable` representing the `cohort` table; default `cohort`

# Returns

- `df::DataFrame` - a three column `DataFrame` comprised of columns: `:cohort_definition_id` , `:subject_id` and `:cohort_start_date`
"""
function GetCohortSubjectStartDate(
    cohort_ids,
    subject_ids,
    conn;
    tab = cohort
)

    df = DBInterface.execute(conn, GetCohortSubjectStartDate(cohort_ids, subject_ids; tab=tab)) |> DataFrame

    return df
    
end

"""
function GetCohortSubjectStartDate(df:DataFrame, conn; tab = cohort)

Given a `DataFrame` with a `:cohort_definition_id` column and `:subject_id` column, return the `DataFrame` with an associated `:cohort_start_date` corresponding to a cohort's subject ID in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetCohortSubjectStartDate(ids, conn; tab = cohort)`
"""
function GetCohortSubjectStartDate(
    df::DataFrame, 
    conn; 
    tab = cohort
)

    return outerjoin(GetCohortSubjectStartDate(df[:,"cohort_definition_id"], df[:,"subject_id"], conn; tab=tab), df, on = :cohort_definition_id)

end

"""
function GetCohortSubjectStartDate(cohort_ids, subject_ids; tab=cohort)

Given a list of cohort IDs and subject IDs return their start dates.

# Arguments:

- `cohort_ids` - list of `cohort_id`'s; each ID must be of subtype `Float64`
    
- `subject_id` - list of `subject_id`'s; each ID must be of subtype `Float64`
    
- `conn` - database connection using DBInterface
    
# Keyword Arguments:
    
- `tab` - the `SQLTable` representing the `cohort` table; default `cohort`
    
# Returns
    
- `df::DataFrame` - a three column `DataFrame` comprised of columns: `:cohort_definition_id` , `:subject_id` and `:cohort_start_date`

"""
function GetCohortSubjectStartDate(
    cohort_ids,
    subject_ids;
    tab = cohort
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.cohort_definition_id, cohort_ids...)) |>
        Where(Fun.in(Get.subject_id, subject_ids...)) |>
        Select(Get.cohort_definition_id, Get.subject_id, Get.cohort_start_date) |>
        q -> render(q, dialect=dialect)

    return String(sql)
    
end

"""
function GetCohortSubjectEndDate(cohort_ids, subject_ids, conn; tab=cohort)

    Given a list of cohort IDs and subject IDs return their end dates.
    
    # Arguments:
    
    - `cohort_ids` - list of `cohort_id`'s; each ID must be of subtype `Float64`
        
    - `subject_id` - list of `subject_id`'s; each ID must be of subtype `Float64`
        
    - `conn` - database connection using DBInterface
        
    # Keyword Arguments:
        
    - `tab` - the `SQLTable` representing the `cohort` table; default `cohort`

# Returns

- `df::DataFrame` - a three column `DataFrame` comprised of columns: `:cohort_definition_id` , `:subject_id` and `:cohort_end_date`
"""
function GetCohortSubjectEndDate(
    cohort_ids,
    subject_ids,
    conn;
    tab = cohort
)

    df = DBInterface.execute(conn, GetCohortSubjectEndDate(cohort_ids, subject_ids; tab=tab)) |> DataFrame

    return df
    
end

"""
function GetCohortSubjectEndDate(df:DataFrame, conn; tab = cohort)

Given a `DataFrame` with a `:cohort_definition_id` column and `:subject_id` column, return the `DataFrame` with an associated `:cohort_end_date` corresponding to a given `cohort_definition_id` and `subject_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetCohortSubjectEndDate(ids, conn; tab = cohort)`
"""
function GetCohortSubjectEndDate(
    df::DataFrame, 
    conn; 
    tab = cohort
)

    return outerjoin(GetCohortSubjectEndDate(df[:,"cohort_definition_id"], df[:,"subject_id"], conn; tab=tab), df, on = :cohort_definition_id)

end

"""
function GetCohortSubjectEndDate(cohort_ids; subject_ids; tab=cohort)

Given a list of cohort IDs and subject IDs return their end date.

# Arguments:

- `cohort_ids` - list of `cohort_id`'s; each ID must be of subtype `Float64`
    
- `subject_id` - list of `subject_id`'s; each ID must be of subtype `Float64`
    
- `conn` - database connection using DBInterface
    
# Keyword Arguments:
    
- `tab` - the `SQLTable` representing the `cohort` table; default `cohort`
   
# Returns
    
- `df::DataFrame` - a three column `DataFrame` comprised of columns: `:cohort_definition_id` , `:subject_id` and `:cohort_end_date`

"""
function GetCohortSubjectEndDate(
    cohort_ids,
    subject_ids;
    tab=cohort
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.cohort_definition_id, cohort_ids...)) |>
        Where(Fun.in(Get.subject_id, subject_ids...)) |>
        Select(Get.cohort_definition_id, Get.subject_id, Get.cohort_end_date) |>
        q -> render(q, dialect=dialect)

    return String(sql)
    
end

"""
GetDatabaseCohorts(conn; tab=cohort)

Given a `DataFrame` returns all unique cohort_definition_id associated with a database.

#Arguments:

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Cohort table; default `cohort`

# Returns
    
- `df::DataFrame` - a one column `DataFrame` comprised of columns: `:cohort_definition_id`


"""
function GetDatabaseCohorts(
    conn; 
    tab=cohort
)
    ids = DBInterface.execute(conn, GetDatabaseCohorts(tab=tab))  |> DataFrame

    return convert(Vector{Int}, ids.cohort_definition_id)
    
end

"""
function GetDatabaseCohorts(; tab=cohort)

Given a cohort table returns all unique IDs associated with a database.

# Arguments:

- `tab` - the `SQLTable` representing the Cohort table; default `cohort`

# Returns
    
- `df::DataFrame` - a one column `DataFrame` comprised of columns: `:cohort_definition_id`

"""

function GetDatabaseCohorts(
   ; tab=cohort
)

    sql = 
        From(tab)  |>
        Group(Get.cohort_definition_id) |>
        Select(Get.cohort_definition_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)
    
end

"""
function GetDrugExposureEndDate(drug_exposure_ids, conn; tab = drug_exposure)

Given a list of drug_exposure IDs, find their exposure end dates.

# Arguments:

- `drug_exposure_ids` - list of `drug_exposure_id`'s; each ID must be of subtype `Float64`

- `conn` - database connection using DBInterface


# Keyword Arguments:

- `tab` - the `SQLTable` representing the Drug Exposure table; default `drug_exposure`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:drug_exposure_id` and `:drug_exposure_end_date`
"""

function GetDrugExposureEndDate(
    drug_exposure_ids,
    conn;
    tab = drug_exposure 
)

    df = DBInterface.execute(conn, GetDrugExposureEndDate(drug_exposure_ids; tab=tab)) |> DataFrame

    return df
end

"""
function GetDrugExposureEndDate(df:DataFrame, conn; tab = drug_exposure)

Given a DataFrame with a :drug_exposure_id column, return the DataFrame with an associated :drug_exposure_end_date corresponding to a given drug_exposure_id in the DataFrame.

Multiple dispatch that accepts all other arguments like in ` GetDrugExposureEndDate(ids, conn; tab = drug_exposure)`
"""

function GetDrugExposureEndDate(
    df::DataFrame,
    conn;
    tab = drug_exposure
)

    df_ids = df[:,"drug_exposure_id"]

    return outerjoin(GetDrugExposureEndDate(df_ids, conn; tab=tab), df, on = :drug_exposure_id)
    
end

"""
function GetDrugExposureEndDate(drug_exposure_ids; tab = drug_exposure)

Given a list of drug_exposure IDs, find their corresponding drug_exposure_end_date ID.

# Arguments:

- `drug_exposure_ids` - list of `drug_exposure_id`'s; each ID must be of subtype `Float64`


# Keyword Arguments:

- `tab` - the `SQLTable` representing the Drug Exposure table; default `drug_exposure`

# Returns

- SQL statement comprised of: `:drug_exposure_id` and `:drug_exposure_end_date`
"""
function GetDrugExposureEndDate(
    drug_exposure_ids;
    tab = drug_exposure
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.drug_exposure_id, drug_exposure_ids...)) |>
        Select(Get.drug_exposure_id, Get.drug_exposure_end_date) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
function GetDrugExposureStartDate(drug_exposure_ids, conn; tab = drug_exposure)

Given a list of drug_exposure IDs, find their exposure start dates.

# Arguments:

- `drug_exposure_ids` - list of `drug_exposure_id`'s; each ID must be of subtype `Float64`

- `conn` - database connection using DBInterface


# Keyword Arguments:

- `tab` - the `SQLTable` representing the Drug Exposure table; default `drug_exposure`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:drug_exposure_id` and `:drug_exposure_start_date`
"""

function GetDrugExposureStartDate(
    drug_exposure_ids,
    conn;
    tab = drug_exposure 
)

    df = DBInterface.execute(conn, GetDrugExposureStartDate(drug_exposure_ids; tab=tab)) |> DataFrame

    return df
end

"""
function GetDrugExposureStartDate(df:DataFrame, conn; tab = drug_exposure)

Given a DataFrame with a :drug_exposure_id column, return the DataFrame with an associated :drug_exposure_start_date corresponding to a given drug_exposure_id in the DataFrame.

Multiple dispatch that accepts all other arguments like in ` GetDrugExposureStartDate(ids, conn; tab = drug_exposure)`
"""
function GetDrugExposureStartDate(
    df::DataFrame,
    conn;
    tab = drug_exposure
)

    df_ids = df[:,"drug_exposure_id"]

    return outerjoin(GetDrugExposureStartDate(df_ids, conn; tab=tab), df, on = :drug_exposure_id)
    
end

"""
function GetDrugExposureStartDate(drug_exposure_ids; tab = drug_exposure)


    Given a list of drug_exposure IDs, find their corresponding drug_exposure_start_date ID.

    # Arguments:
    
    - `drug_exposure_ids` - list of `drug_exposure_id`'s; each ID must be of subtype `Float64`
    
    
    # Keyword Arguments:
    
    - `tab` - the `SQLTable` representing the Drug Exposure table; default `drug_exposure`
    
    # Returns
    
    - SQL statement comprised of: `:drug_exposure_id` and `:drug_exposure_start_date`
"""
function GetDrugExposureStartDate(
    drug_exposure_ids;
    tab = drug_exposure
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.drug_exposure_id, drug_exposure_ids...)) |>
        Select(Get.drug_exposure_id, Get.drug_exposure_start_date) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetVisitDrug(visit_ids, conn; tab = visit_occurrence)

Given a list of visit IDs, find their corresponding drug conditions.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `drug_exposure`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:drug_concept_id`
"""
function GetVisitDrug(
    visit_ids,
    conn;
    tab=drug_exposure
)

    df = DBInterface.execute(conn, GetVisitDrug(visit_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetVisitDrug(df:DataFrame, conn; tab = drug_exposure)

Given a `DataFrame` with a `:visit_occurrence_id` column, return the `DataFrame` with an associated `:drug_concept_id` for each `visit_occurrence_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetVisitDrug(ids, conn; tab = drug_exposure)`
"""

function GetVisitDrug(
    df::DataFrame,
    conn;
    tab=drug_exposure
)

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitDrug(df_ids, conn; tab=tab), df, on = :visit_occurrence_id)

end
"""
GetVisitDrug(visit_ids; tab = visit_occurrence)

Produces SQL statement that, given a list of `visit_id`'s, finds the conditions diagnosed associated with that visit.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `drug_exposure`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:drug_concept_id`
"""
function GetVisitDrug(
    visit_ids;
    tab=drug_exposure
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
        Select(Get.visit_occurrence_id, Get.drug_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetVisitObservation(visit_ids, conn; tab = visit_occurrence)

Given a list of visit IDs, find their corresponding observations.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Observation table; default `observation`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:observation_concept_id`
"""
function GetVisitObservation(
    visit_ids,
    conn;
    tab=observation
)

    df = DBInterface.execute(conn, GetVisitObservation(visit_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetVisitObservation(df:DataFrame, conn; tab = observation)

Given a `DataFrame` with a `:visit_occurrence_id` column, return the `DataFrame` with an associated `:observation_concept_id` for each `visit_occurrence_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetVisitObservation(ids, conn; tab = observation)`
"""

function GetVisitObservation(
    df::DataFrame,
    conn;
    tab=observation
)

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitObservation(df_ids, conn; tab=tab), df, on = :visit_occurrence_id)

end
"""
GetVisitObservation(visit_ids; tab = visit_occurrence)

Produces SQL statement that, given a list of `visit_id`'s, finds the conditions diagnosed associated with that visit.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Observation table; default `observation`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:observation_concept_id`
"""
function GetVisitObservation(
    visit_ids;
    tab=observation
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
        Select(Get.visit_occurrence_id, Get.observation_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetVisitMeasurement(visit_ids, conn; tab = visit_occurrence)

Given a list of visit IDs, find their corresponding measurements.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Measurement table; default `measurement`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:measurement_concept_id`
"""
function GetVisitMeasurement(
    visit_ids,
    conn;
    tab=measurement
)

    df = DBInterface.execute(conn, GetVisitMeasurement(visit_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetVisitMeasurement(df:DataFrame, conn; tab = measurement)

Given a `DataFrame` with a `:visit_occurrence_id` column, return the `DataFrame` with an associated `:measurement_concept_id` for each `visit_occurrence_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetVisitMeasurement(ids, conn; tab = measurement)`
"""

function GetVisitMeasurement(
    df::DataFrame,
    conn;
    tab=measurement
)

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitMeasurement(df_ids, conn; tab=tab), df, on = :visit_occurrence_id)

end
"""
GetVisitMeasurement(visit_ids; tab = visit_occurrence)

Produces SQL statement that, given a list of `visit_id`'s, finds the conditions diagnosed associated with that visit.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Measurement table; default `measurement`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:measurement_concept_id`
"""
function GetVisitMeasurement(
    visit_ids;
    tab=measurement
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
        Select(Get.visit_occurrence_id, Get.measurement_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetVisitDevice(visit_ids, conn; tab = visit_occurrence)

Given a list of visit IDs, find their corresponding devices.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Device Exposure table; default `device_exposure`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:device_concept_id`
"""
function GetVisitDevice(
    visit_ids,
    conn;
    tab=device_exposure
)

    df = DBInterface.execute(conn, GetVisitDevice(visit_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetVisitDevice(df:DataFrame, conn; tab = device_exposure)

Given a `DataFrame` with a `:visit_occurrence_id` column, return the `DataFrame` with an associated `:device_concept_id` for each `visit_occurrence_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetVisitDevice(ids, conn; tab = device_exposure)`
"""

function GetVisitDevice(
    df::DataFrame,
    conn;
    tab=device_exposure
)

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitDevice(df_ids, conn; tab=tab), df, on = :visit_occurrence_id)

end
"""
GetVisitDevice(visit_ids; tab = visit_occurrence)

Produces SQL statement that, given a list of `visit_id`'s, finds the conditions diagnosed associated with that visit.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Device Exposure table; default `device_exposure`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:device_concept_id`
"""
function GetVisitDevice(
    visit_ids;
    tab=device_exposure
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
        Select(Get.visit_occurrence_id, Get.device_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetVisitMetadata(visit_ids, conn; tab = visit_occurrence)

Given a list of visit IDs, find their corresponding metadata.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Metadata table; default `metadata`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:metadata_concept_id`
"""
function GetVisitMetadata(
    visit_ids,
    conn;
    tab=metadata
)

    df = DBInterface.execute(conn, GetVisitMetadata(visit_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetVisitMetadata(df:DataFrame, conn; tab = metadata)

Given a `DataFrame` with a `:visit_occurrence_id` column, return the `DataFrame` with an associated `:metadata_concept_id` for each `visit_occurrence_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetVisitMetadata(ids, conn; tab = metadata)`
"""

function GetVisitMetadata(
    df::DataFrame,
    conn;
    tab=metadata
)

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitMetadata(df_ids, conn; tab=tab), df, on = :visit_occurrence_id)

end
"""
GetVisitMetadata(visit_ids; tab = visit_occurrence)

Produces SQL statement that, given a list of `visit_id`'s, finds the conditions diagnosed associated with that visit.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Metadata table; default `metadata`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:metadata_concept_id`
"""
function GetVisitMetadata(
    visit_ids;
    tab=metadata
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
        Select(Get.visit_occurrence_id, Get.metadata_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetVisitMeasurementValue(visit_ids, conn; tab = visit_occurrence)

Given a list of visit IDs, find their corresponding measurement values.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Measurement table; default `measurement`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:value_as_concept_id`
"""
function GetVisitMeasurementValue(
    visit_ids,
    conn;
    tab=measurement
)

    df = DBInterface.execute(conn, GetVisitMeasurementValue(visit_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetVisitMeasurementValue(df:DataFrame, conn; tab = measurement)

Given a `DataFrame` with a `:visit_occurrence_id` column, return the `DataFrame` with an associated `:value_as_concept_id` for each `visit_occurrence_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetVisitMeasurementValue(ids, conn; tab = measurement)`
"""

function GetVisitMeasurementValue(
    df::DataFrame,
    conn;
    tab=measurement
)

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitMeasurementValue(df_ids, conn; tab=tab), df, on = :visit_occurrence_id)

end
"""
GetVisitMeasurementValue(visit_ids; tab = visit_occurrence)

Produces SQL statement that, given a list of `visit_id`'s, finds the conditions diagnosed associated with that visit.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Measurement table; default `measurement`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:value_as_concept_id`
"""
function GetVisitMeasurementValue(
    visit_ids;
    tab=measurement
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
        Select(Get.visit_occurrence_id, Get.value_as_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetVisitMeasurementValue(visit_ids, conn; tab = visit_occurrence)

Given a list of visit IDs, find their corresponding measurement values.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Measurement table; default `measurement`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:value_as_concept_id`
"""
function GetVisitMeasurementValue(
    visit_ids,
    conn;
    tab=measurement
)

    df = DBInterface.execute(conn, GetVisitMeasurementValue(visit_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetVisitMeasurementValue(df:DataFrame, conn; tab = measurement)

Given a `DataFrame` with a `:visit_occurrence_id` column, return the `DataFrame` with an associated `:value_as_concept_id` for each `visit_occurrence_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetVisitMeasurementValue(ids, conn; tab = measurement)`
"""

function GetVisitMeasurementValue(
    df::DataFrame,
    conn;
    tab=measurement
)

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitMeasurementValue(df_ids, conn; tab=tab), df, on = :visit_occurrence_id)

end
"""
GetVisitMeasurementValue(visit_ids; tab = visit_occurrence)

Produces SQL statement that, given a list of `visit_id`'s, finds the conditions diagnosed associated with that visit.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Measurement table; default `measurement`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:value_as_concept_id`
"""
function GetVisitMeasurementValue(
    visit_ids;
    tab=measurement
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
        Select(Get.visit_occurrence_id, Get.value_as_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

"""
GetVisitAnatomicSite(visit_ids, conn; tab = visit_occurrence)

Given a list of visit IDs, find their corresponding anatomic specimens.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Specimen table; default `specimen`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:anatomic_site_concept_id`
"""
function GetVisitAnatomicSite(
    visit_ids,
    conn;
    tab=specimen
)

    df = DBInterface.execute(conn, GetVisitAnatomicSite(visit_ids; tab=tab)) |> DataFrame

    return df

end

"""
function GetVisitAnatomicSite(df:DataFrame, conn; tab = specimen)

Given a `DataFrame` with a `:visit_occurrence_id` column, return the `DataFrame` with an associated `:anatomic_site_concept_id` for each `visit_occurrence_id` in the `DataFrame`

Multiple dispatch that accepts all other arguments like in `GetVisitAnatomicSite(ids, conn; tab = specimen)`
"""

function GetVisitAnatomicSite(
    df::DataFrame,
    conn;
    tab=specimen
)

    df_ids= df[:,"visit_occurrence_id"]
    
    return outerjoin(GetVisitAnatomicSite(df_ids, conn; tab=tab), df, on = :visit_occurrence_id)

end
"""
GetVisitAnatomicSite(visit_ids; tab = visit_occurrence)

Produces SQL statement that, given a list of `visit_id`'s, finds the conditions diagnosed associated with that visit.

# Arguments:

- `visit_ids` - list of `visit_id`'s; each ID must be of subtype `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Specimen table; default `specimen`

# Returns

- `df::DataFrame` - a two column `DataFrame` comprised of columns: `:visit_occurrence_id` and `:anatomic_site_concept_id`
"""
function GetVisitAnatomicSite(
    visit_ids;
    tab=specimen
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
        Select(Get.visit_occurrence_id, Get.anatomic_site_concept_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

export GetDatabasePersonIDs, GetPatientState, GetPatientGender, GetPatientRace, GetPatientAgeGroup, GetPatientVisits, GetMostRecentConditions, GetMostRecentVisit, GetVisitCondition, GetPatientEthnicity, GetDatabaseYearRange, GetVisitPlaceOfService, GetVisitConcept, GetVisitDate, GetDrugExposures, GetDrugConceptIDs, GetDrugAmounts, GetVisitProcedure, GetDatabaseCohorts, GetCohortSubjects, GetCohortSubjectStartDate, GetCohortSubjectEndDate, GetDrugExposureIDs, GetDrugExposureEndDate, GetDrugExposureStartDate, GetVisitObservation, GetVisitDrug, GetVisitMeasurement, GetVisitDevice, GetVisitMetadata, GetVisitMeasurementValue, GetVisitAnatomicSite
