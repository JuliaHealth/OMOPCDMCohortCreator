"""
VisitFilterPersonIDs(visit_codes, conn; tab = visit_occurrence)

Given a list of visit concept IDs, `visit_codes` return from the database patients matching at least one of the provided visit codes from the Visit Occurrence table.

# Arguments:

- `visit_codes` - a vector of `visit_concept_id`'s; must be a subtype of `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Visit Occurrence table; default `visit_occurrence`

# Returns

- `ids::Vector{Int64}` - the list of persons resulting from the filter
"""
function VisitFilterPersonIDs(visit_codes, conn; tab = visit_occurrence)
    df = DBInterface.execute(conn, VisitFilterPersonIDs(visit_codes; tab = tab)) |> DataFrame

    return df

end

"""
VisitFilterPersonIDs(visit_codes; tab = visit_occurrence)

Generates a SQL statement that, given a list of visit concept IDs, `visit_codes`, return from the database patients matching at least one of the provided visit codes from the Visit Occurrence table.

# Arguments:

- `visit_codes` - a vector of `visit_concept_id`'s; must be a subtype of `Integer`

`conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Visit Occurrence table; default `visit_occurrence`

# Returns

- `sql::String` - the SQL representation that runs this filter
"""
function VisitFilterPersonIDs(visit_codes; tab = visit_occurrence)
    sql =
        From(tab) |>
        Where(Fun.in(Get.visit_concept_id, visit_codes...)) |>
        Group(Get.person_id) |>
        q -> render(q, dialect = dialect) 

        return String(sql)

end

"""
ConditionFilterPersonIDs(condition_codes, conn; tab = condition_occurrence)

Given a list of condition concept IDs, `condition_codes`, return from the database individuals having at least one entry in the Condition Occurrence table matching at least one of the provided condition types.

# Arguments:

- `condition_codes` - a vector of `condition_concept_id`'s; must be a subtype of `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `condition_occurrence`

# Returns

- `ids::Vector{Int64}` - the list of persons resulting from the filter
"""
function ConditionFilterPersonIDs(
    condition_codes, conn;
    tab = condition_occurrence,
)
    df = DBInterface.execute(conn, ConditionFilterPersonIDs(condition_codes; tab = tab)) |> DataFrame

    return df 

end

"""
ConditionFilterPersonIDs(condition_codes; tab = condition_occurrence)

Generates a SQL statement that, given a list of condition concept IDs, `condition_codes`, return from the database individuals having at least one entry in the Condition Occurrence table matching at least one of the provided condition types.

# Arguments:

- `condition_codes` - a vector of `condition_concept_id`'s; must be a subtype of `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Condition Occurrence table; default `condition_occurrence`

# Returns

- `sql::String` - the SQL representation that runs this filter
"""
function ConditionFilterPersonIDs(
    condition_codes;
    tab = condition_occurrence,
)
    sql =
        From(tab) |>
        Where(Fun.in(Get.condition_concept_id, condition_codes...)) |>
        Group(Get.person_id) |>
        q -> render(q, dialect = dialect)

        return String(sql)

end

"""
RaceFilterPersonIDs(race_codes, conn; tab = person)

Given a list of condition concept IDs, `race_codes`, return from the database individuals having at least one entry in the Person table matching at least one of the provided race types.

# Arguments:

- `race_codes` - a vector of `race_concept_id`'s; must be a subtype of `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `ids::Vector{Int64}` - the list of persons resulting from the filter
"""
function RaceFilterPersonIDs(race_codes, conn; tab = person)
    df = DBInterface.execute(conn, RaceFilterPersonIDs(race_codes; tab = tab)) |> DataFrame

    return df

end

"""
RaceFilterPersonIDs(race_codes; tab = person)

Generates a SQL statement that, given a list of `race_concept_id`'s, return from the database individuals having at least one entry in the Person table matching at least one of the provided race types.

# Arguments:

- `race_codes` - a vector of `race_concept_id`'s; must be a subtype of `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `sql::String` - the SQL representation that runs this filter
"""
function RaceFilterPersonIDs(race_codes; tab = person)
    sql =
        From(tab) |>
        Where(Fun.in(Get.race_concept_id, race_codes...)) |>
        Group(Get.person_id) |>
        q -> render(q, dialect = dialect)

    return String(sql)

end

"""
GenderFilterPersonIDs(gender_codes, conn; tab = visit_occurrence)

Given a list of visit concept IDs, `gender_codes` return from the database individuals having at least one entry in the Person table matching at least one of the provided gender types.

# Arguments:

- `visit_codes` - a vector of `gender_concept_id`'s; must be a subtype of `Integer`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `ids::Vector{Int64}` - the list of persons resulting from the filter
"""
function GenderFilterPersonIDs(gender_codes, conn; tab = person)
    df = DBInterface.execute(conn, GenderFilterPersonIDs(gender_codes; tab = tab)) |> DataFrame

    return df

end

"""
GenderFilterPersonIDs(gender_codes; tab = visit_occurrence)

Generates a SQL statement that, given a list of visit concept IDs, `gender_codes` return from the database individuals having at least one entry in the Person table matching at least one of the provided gender types.

# Arguments:

- `visit_codes` - a vector of `gender_concept_id`'s; must be a subtype of `Integer`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `sql::String` - the SQL representation that runs this filter
"""
function GenderFilterPersonIDs(gender_codes; tab = person)
    sql =
        From(tab) |>
        Where(Fun.in(Get.gender_concept_id, gender_codes...)) |>
        Group(Get.person_id) |>
        q -> render(q, dialect = dialect)

    return String(sql)

end

"""
StateFilterPersonIDs(states, conn; tab = location, join_tab = person)

Given a list of states, `states`, return from the database individuals found in the provided state list.

# Arguments:

- `states` - a vector of state abbreviations; must be a subtype of `AbstractString`

- `conn` - database connection using DBInterface

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Location table; default `location`

- `join_tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `ids::Vector{Int64}` - the list of persons resulting from the filter
"""
function StateFilterPersonIDs(states, conn; tab = location, join_tab = person)
    df = DBInterface.execute(conn, StateFilterPersonIDs(states; tab = tab, join_tab = join_tab)) |> DataFrame

    return df

end

"""
StateFilterPersonIDs(states; tab = location, join_tab = person)

Generates a SQL statement that, given a list of states, `states`, return from the database individuals found in the provided state list.

# Arguments:

- `states` - a vector of state abbreviations; must be a subtype of `AbstractString`

# Keyword Arguments:

- `tab` - the `SQLTable` representing the Location table; default `location`

- `join_tab` - the `SQLTable` representing the Person table; default `person`

# Returns

- `sql::String` - the SQL representation that runs this filter
"""
function StateFilterPersonIDs(states; tab = location, join_tab = person)
    sql =
        From(tab) |>
        Select(Get.location_id, Get.state) |>
        Where(Fun.in(Get.state, uppercase.(states)...)) |>
        Join(:join => join_tab, Get.location_id .== Get.join.location_id) |>
        Select(Get.join.person_id) |>
        q -> render(q, dialect = dialect)

    return String(sql)

end

"""
TODO: Update these docstrings
"""
function DrugExposureFilterPersonIDs(
    drug_concept_ids, conn;
    tab = drug_exposure,
)
    df = DBInterface.execute(conn, DrugExposureFilterPersonIDs(drug_concept_ids; tab = tab)) |> DataFrame

    return df 

end

function DrugExposureFilterPersonIDs(
    drug_concept_ids;
    tab = drug_exposure,
)
    sql =
        From(tab) |>
        Where(Fun.in(Get.drug_concept_id, drug_concept_ids...)) |>
        Group(Get.person_id) |>
        q -> render(q, dialect = dialect)

        return String(sql)

end

export VisitFilterPersonIDs, ConditionFilterPersonIDs, RaceFilterPersonIDs, GenderFilterPersonIDs, StateFilterPersonIDs
