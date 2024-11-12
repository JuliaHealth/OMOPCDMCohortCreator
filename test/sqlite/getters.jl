@testset "GetDatabasePersonIDs Tests" begin
    # Expected IDs from Eunomia person ids
    ids = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> x -> convert(Vector{Int}, x.person_id)

    @test ids == GetDatabasePersonIDs(sqlite_conn)
end

#= TODO: Determine how to add states to Eunomia database for testing 
Currently, states are not present in the Eunomia database - it may be as simple a fix as to alter the location table and insert random state initials in the appropriate locations for each patient.
labels: tests, moderate
=#
# @testset "GetPatientState Tests" begin
# 
# end



@testset "GetDatabaseYearRange Tests" begin
    # Test to see if correct years are reported for Eunomia
    first_year = 1922
    last_year = 2019

    check_first_year, check_last_year = GetDatabaseYearRange(sqlite_conn)
    years = (first_year=check_first_year |> unix2datetime |> year, last_year=check_last_year |> unix2datetime |> year)

    @test (first_year=first_year, last_year=last_year) == years
end

@testset "GetPatientGender Tests" begin
    genders = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id, Get.gender_concept_id) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    test_ids = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array

    @test genders == GetPatientGender(test_ids, sqlite_conn)
end

@testset "GetPatientRace Tests" begin
    races = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id, Get.race_concept_id) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    test_ids = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array

    @test races == GetPatientRace(test_ids, sqlite_conn)
end

@testset "GetPatientAgeGroup Tests" begin
    test_ids = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id) |> Limit(10) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array

    default_age_grouping = [[0, 9], [10, 19], [20, 29], [30, 39], [40, 49], [50, 59], [60, 69], [70, 79], [80, 89]]
    test_age_grouping_1 = [[40, 59]]
    test_age_grouping_2 = [[45, 49], [50, 54], [55, 59], [60, 64], [65, 69], [70, 74], [75, 79]]

    default_minuend = :now
    minuend_now = 2022

    default_age_grouping_values = ["0 - 9", "10 - 19", "20 - 29", "30 - 39", "40 - 49", "50 - 59", "60 - 69", "70 - 79", "80 - 89"]

    default_test = DataFrame(:person_id => [6.0, 123.0, 129.0, 16.0, 65.0, 74.0, 42.0, 187.0, 18.0, 111.0], :year_of_birth => [1963.0, 1950.0, 1974.0, 1971.0, 1967.0, 1972.0, 1909.0, 1945.0, 1965.0, 1975.0])

    default_test.age = year(now(tz"UTC")) .- default_test.year_of_birth

    age_groups = []
    for age in default_test.age
        for (idx, grouping) in enumerate([default_age_grouping..., missing])
            if !ismissing(grouping) && (grouping[1] <= age <= grouping[2])
                push!(age_groups, default_age_grouping_values[idx])
                break
            elseif ismissing(grouping)
                push!(age_groups, "Unspecified")
            end
        end
    end

    default_test.age_group = age_groups
    default_test = default_test[!, [:person_id, :age_group]]
    default_test.age_group = convert(Vector{Union{Missing,String}}, default_test.age_group)

    minuend_now_test = DataFrame(:person_id => [6.0, 123.0, 129.0, 16.0, 65.0, 74.0, 42.0, 187.0, 18.0, 111.0], :age_group => ["55 - 59", "70 - 74", "45 - 49", "50 - 54", "55 - 59", "50 - 54", "Unspecified", "75 - 79", "55 - 59", "45 - 49"])

    @test isequal(default_test, GetPatientAgeGroup(test_ids, sqlite_conn; minuend=default_minuend, age_groupings=default_age_grouping))
    @test isequal(minuend_now_test, GetPatientAgeGroup(test_ids, sqlite_conn; minuend=minuend_now, age_groupings=test_age_grouping_2))
end

#Tests for GetPatientVisits
@testset "GetPatientVisits Tests" begin
    #test for person with multiple visits 
    test_ids = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array
    test_visits = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id, Get.visit_occurrence_id) |> Where(Fun.in(Get.person_id, test_ids...)) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame
    @test test_visits == GetPatientVisits(test_ids, sqlite_conn)

    #test for person with single visit
    test_id = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id) |> Limit(1) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array

    test_visit = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id, Get.visit_occurrence_id) |> Where(Fun.in(Get.person_id, test_id...)) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    @test test_visit == GetPatientVisits(test_id, sqlite_conn)
end

@testset "GetMostRecentConditions Tests" begin
        # Test to get most recent conditions for multiple patients
        test_ids = [1, 110, 6]

        test_df = DataFrame(person_id = [1.0, 110.0, 6.0], condition_concept_id = [40481087.0, 260139.0, 4218389.0])

        @test test_df == GetMostRecentConditions(test_ids, sqlite_conn)

        # Test to get most recent conditions for single patient with two conditions
        test_ids = 245

        test_df = DataFrame(person_id = [245.0, 245.0], condition_concept_id = [4230399.0, 40480160.0])

        @test test_df == GetMostRecentConditions(test_ids, sqlite_conn)
end

@testset "GetMostRecentVisit Tests" begin
    test_ids = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array
    data_table = From(OMOPCDMCohortCreator.visit_occurrence) |> Group(Get.person_id) |> Select(:id => Get.person_id, :count => Agg.count()) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame
    test_visits = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id, Get.visit_occurrence_id) |> Where(Fun.in(Get.person_id, test_ids...)) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    #id with multiple visits = 222
    sql = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id, Get.visit_occurrence_id, Get.visit_end_date) |> Where(Fun.in(Get.person_id, [222]...)) |> render
    result = DBInterface.execute(sqlite_conn, sql) |> DataFrame
    result.Date = Dates.unix2datetime.(result.visit_end_date)
    max_index = argmax(result.Date)
    most_recent_visit = result.visit_occurrence_id[max_index]
    evaluated_visit = (GetMostRecentVisit(222, sqlite_conn)).visit_occurrence_id
    @test most_recent_visit == evaluated_visit[1]

    #id with 1 visits = 986
    recent_visit = test_visits[in([986]).(test_visits.person_id), :].visit_occurrence_id
    evaluated_visit = (GetMostRecentVisit(986, sqlite_conn))
    evaluated_visit.visit_occurrence_id
    @test recent_visit == evaluated_visit.visit_occurrence_id
end

@testset "GetVisitConcept Tests" begin
	test_ids = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.visit_occurrence_id) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array
    test_concept_ids = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.visit_occurrence_id, Get.visit_concept_id) |> Where(Fun.in(Get.visit_occurrence_id, test_ids...)) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    @test test_concept_ids == GetVisitConcept(test_ids, sqlite_conn)
end

@testset "GetVisitCondition Tests" begin

    #test for 3 visit ids with only 1 condition each
    visit_codes_single = [17479.0, 18192.0, 18859.0]
    test_condition_ids = [4.112343e6, 192671.0, 28060.0]
    test_df_single = DataFrame(visit_occurrence_id=[17479.0, 18192.0, 18859.0], condition_concept_id=[4.112343e6, 192671.0, 28060.0])

    evaluated_result_single = GetVisitCondition(visit_codes_single, sqlite_conn)
    @test test_df_single == evaluated_result_single

    #test for person with multiple visits
    visit_codes_multiple = [3.0]
    test_condition_ids_multiple = [372328.0, 81893.0]
    test_df_multiple = DataFrame(visit_occurrence_id=[3.0, 3.0], condition_concept_id=[372328.0, 81893.0])

    evaluated_result_multiple = GetVisitCondition(visit_codes_multiple, sqlite_conn)
    @test test_df_multiple == evaluated_result_multiple

end

"""
There is no data currently in the Eunomia database to be tested

@testset "GetVisitPlaceOfService Tests" begin



end
"""

@testset "GetPatientEthnicity Tests" begin
	ethnicities = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id, Get.ethnicity_concept_id) |> Limit(20) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

	test_ids = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id) |> Limit(20) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array

	@test ethnicities == GetPatientEthnicity(test_ids, sqlite_conn)
end

@testset "GetVisitDate Tests" begin

    #test with interval = start
    test_visit_ids= [65475.0, 14930.0, 25743.0, 14888.0]
    test_start_dates = [840585600.0, 575510400.0, 1336953600.0, 1063497600.0]
    test_df_start = DataFrame(visit_occurrence_id=test_visit_ids, visit_start_date=test_start_dates)

    @test test_df_start == GetVisitDate(test_visit_ids, sqlite_conn, interval=Symbol("start"))

    #test with interval = end
    test_end_dates = [840672000.0, 575596800.0, 1337040000.0, 1063584000.0]
    test_df_end = DataFrame(visit_occurrence_id=test_visit_ids, visit_end_date=test_end_dates)

    @test test_df_end == GetVisitDate(test_visit_ids, sqlite_conn, interval=Symbol("end"))
    
end

#=
@testset "GetDrugExposureIDs Tests" begin

    test_ids = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id) |> Limit(10) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    test_query = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id) |> Limit(10)
    drug_exposures = From(OMOPCDMCohortCreator.drug_exposure)
    Drug_exposure_ids = test_query |> LeftJoin(drug_exposures, on =  test_query.person_id.== drug_exposures.person_id) |>
    Select(test_query.person_id, drug_exposures.drug_exposure_id)  |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame
    Drug_exposure_ids = sort( Drug_exposure_ids, :person_id)
    df = GetDrugExposureIDs(test_ids, sqlite_conn)

	@test Drug_exposure_ids == sort(df, :person_id)
end
=#

@testset "GetDrugConceptIDs Tests" begin

	test_ids = From(OMOPCDMCohortCreator.drug_exposure) |> Select(Get.drug_exposure_id) |> Limit(10) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array
	Drug_concept_ids = From(OMOPCDMCohortCreator.drug_exposure) |> Select(Get.drug_exposure_id ,Get.drug_concept_id) |> Where(Fun.in(Get.drug_exposure_id, test_ids...))|> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame 
    Drug_concept_ids = sort( Drug_concept_ids, :drug_exposure_id)
    df = GetDrugConceptIDs(test_ids, sqlite_conn)

	@test Drug_concept_ids == sort(df, :drug_exposure_id)
end

@testset "GetCohortSubjects Tests" begin
    
    test_cohort_definition_ids = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

    test_subject_ids = [1.0, 5.0, 9.0, 11.0, 12.0, 17.0, 18.0, 19.0]

    res = sort(GetCohortSubjects([1.0], sqlite_conn))
    test_df1 = DataFrame(cohort_definition_id = test_cohort_definition_ids, subject_id = res.subject_id[1:8])

    new = GetCohortSubjects(test_df1[:,"cohort_definition_id"], sqlite_conn) 

    @test test_subject_ids == res.subject_id[1:8]
    @test isa(GetCohortSubjects(test_cohort_definition_ids, sqlite_conn), DataFrame)
    @test new.subject_id[1:8] == test_df1.subject_id[1:8]
    
end

@testset "GetCohortSubjectStartDate" begin
    
    test_cohort_definition_ids = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

    test_subject_ids = [1.0, 5.0, 9.0, 11.0, 12.0, 17.0, 18.0, 19.0]

    test_start_dates = [-533347200.0, 334281600.0, 555811200.0, -117849600.0, 74563200.0, -312336000.0, 296352000.0, 958348800.0]

    res = sort(GetCohortSubjectStartDate([1.0], test_subject_ids, sqlite_conn))
    test_df1 = DataFrame(cohort_definition_id = test_cohort_definition_ids, subject_id = test_subject_ids, cohort_start_date = res.cohort_start_date[1:8])

    new = GetCohortSubjectStartDate(test_df1[:,"cohort_definition_id"], test_df1[:,"subject_id"], sqlite_conn)

    @test test_start_dates == res.cohort_start_date[1:8]
    @test isa(GetCohortSubjectStartDate(test_cohort_definition_ids, test_subject_ids, sqlite_conn), DataFrame)
    @test new.cohort_start_date[1:8] == test_df1.cohort_start_date[1:8]
    
end

@testset "GetCohortSubjectEndDate" begin
    
    test_cohort_definition_ids = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

    test_subject_ids = [1.0, 5.0, 9.0, 11.0, 12.0, 17.0, 18.0, 19.0]

    test_end_dates = [1558656000.0, 1535500800.0, 1540425600.0, 1557187200.0, 1551830400.0, 1546819200.0, 1541548800.0, 1534636800.0]

    res = sort(GetCohortSubjectEndDate([1.0], test_subject_ids, sqlite_conn))
    test_df1 = DataFrame(cohort_definition_id = test_cohort_definition_ids, subject_id = test_subject_ids, cohort_end_date = res.cohort_end_date[1:8])

    new = GetCohortSubjectEndDate(test_df1[:,"cohort_definition_id"], test_df1[:,"subject_id"], sqlite_conn)

    @test test_end_dates == res.cohort_end_date[1:8]
    @test isa(GetCohortSubjectEndDate(test_cohort_definition_ids, test_subject_ids, sqlite_conn), DataFrame)
    @test new.cohort_end_date[1:8] == test_df1.cohort_end_date[1:8]
end

@testset "GetDatabaseCohorts" begin

    test_ids=[1.0]
    new=GetDatabaseCohorts(sqlite_conn)

    @test test_ids == new[1:1]
end

"""
This testset will work once amount_value is added to the eunomia database


@testset "GetDrugAmounts Tests" begin

	test_ids = From(OMOPCDMCohortCreator.drug_exposure) |> Select(Get.drug_concept_id) |> Limit(10) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array

	drug_amounts = From(OMOPCDMCohortCreator.drug_exposure) |> Select(Get.drug_concept_id, Get.amount_value) |>  Where(Fun.in(Get.drug_concept_id, test_ids...)) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame
    drug_amounts = sort(drug_amounts, :Drug_concept_id)
    df = GetDrugAmounts(test_ids, sqlite_conn)
	#drug_concept_ids = From(OMOPCDMCohortCreator.drug_exposure) |> Select(Get.drug_concept_id) |> Limit(20) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array

	@test drug_amounts == sort(df, :drug_exposure_id)
end

"""
################################################
########## Multiple Dispatch Tests #############
################################################

@testset "GetPatientGender multiple dispatch Tests" begin
    genders = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id, Get.gender_concept_id, Get.race_concept_id ) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    test_ids = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    @test genders == GetPatientGender(GetPatientRace(test_ids, sqlite_conn), sqlite_conn)
end

@testset "GetPatientRace multiple dispatch Tests" begin
    races = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id, Get.race_concept_id, Get.gender_concept_id) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    test_ids = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    @test races == GetPatientRace(GetPatientGender(test_ids, sqlite_conn), sqlite_conn)
end

@testset "GetPatientAgeGroup multiple dispatch Tests" begin
    test_ids = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id) |> Limit(10) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array
    races_ethnicity = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id, Get.race_concept_id, Get.ethnicity_concept_id) |> Limit(10) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    default_age_grouping = [[0, 9], [10, 19], [20, 29], [30, 39], [40, 49], [50, 59], [60, 69], [70, 79], [80, 89]]
    test_age_grouping_1 = [[40, 59]]
    test_age_grouping_2 = [[45, 49], [50, 54], [55, 59], [60, 64], [65, 69], [70, 74], [75, 79]]

    default_minuend = :now
    minuend_now = 2023

    default_age_grouping_values = ["0 - 9", "10 - 19", "20 - 29", "30 - 39", "40 - 49", "50 - 59", "60 - 69", "70 - 79", "80 - 89"]

    default_test = DataFrame(:person_id => [6.0, 123.0, 129.0, 16.0, 65.0, 74.0, 42.0, 187.0, 18.0, 111.0], :year_of_birth => [1963.0, 1950.0, 1974.0, 1971.0, 1967.0, 1972.0, 1909.0, 1945.0, 1965.0, 1975.0], :race_concept_id => [8516.0, 8527.0, 8527.0, 8527.0, 8516.0, 8527.0, 8527.0,8527.0,8527.0,8527.0], :ethnicity_concept_id => [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])

    default_test.age = year(now(tz"UTC")) .- default_test.year_of_birth

    age_groups = []
    for age in default_test.age
        for (idx, grouping) in enumerate([default_age_grouping..., missing])
            if !ismissing(grouping) && (grouping[1] <= age <= grouping[2])
                push!(age_groups, default_age_grouping_values[idx])
                break
            elseif ismissing(grouping)
                push!(age_groups, "Unspecified")
            end
        end
    end

    default_test.age_group = age_groups
    default_test = select!(default_test, Not(:age))
    default_test = select!(default_test, Not(:year_of_birth))
    default_test = select!(default_test, [:person_id, :age_group, :race_concept_id, :ethnicity_concept_id])

    @test isequal(default_test, GetPatientAgeGroup(races_ethnicity, sqlite_conn))
end

#=
#Tests for GetPatientVisits
@testset "GetPatientVisits multiple dispatch Tests" begin
    #test for person with multiple visits 
    visit_table = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id) |> Limit(5)|> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> unique

    test_ids =  From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id, Get.visit_occurrence_id) |> Limit(5)
    genders = From(OMOPCDMCohortCreator.person)
    test_ids_genders = test_ids |> LeftJoin(genders, on = genders.person_id .== test_ids.person_id) |>
    Select(genders.person_id, test_ids.visit_occurrence_id, genders.gender_concept_id)|> Limit(5)  |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame
    
    @test test_ids_genders == GetPatientVisits(GetPatientGender(visit_table,sqlite_conn), sqlite_conn)
end
=#

@testset "GetMostRecentConditions multiple dispatch Tests" begin
        # Test to get most recent conditions for multiple patients
        test_ids = [1, 110, 6]

        test_df = DataFrame(person_id = [6.0, 110.0, 1.0], condition_concept_id = [4218389.0, 260139.0, 40481087.0], gender_concept_id = [8532.0, 8532.0, 8507.0])

        @test test_df == GetMostRecentConditions(GetPatientGender(test_ids, sqlite_conn), sqlite_conn)
end

#tests for GetMostRecentVisit
@testset "GetMostRecentVisit multiple dispatch Tests" begin

    test_ids = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array
    data_table = From(OMOPCDMCohortCreator.visit_occurrence) |> Group(Get.person_id) |> Select(:id => Get.person_id, :count => Agg.count()) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame
    test_visits = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id, Get.visit_occurrence_id) |> Where(Fun.in(Get.person_id, test_ids...)) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    #id with multiple visits = 222
    sql = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id, Get.visit_occurrence_id, Get.visit_end_date) |> Where(Fun.in(Get.person_id, [222]...)) |> render
    result = DBInterface.execute(sqlite_conn, sql) |> DataFrame
    result.Date = Dates.unix2datetime.(result.visit_end_date)
    max_index = argmax(result.Date)
    most_recent_visit = DataFrame(person_id = [222], visit_occurrence_id = result.visit_occurrence_id[max_index], gender_concept_id = [8532] )
    test_set = DataFrame(person_id = [222], gender_concept_id = [8532])
    @test most_recent_visit == (GetMostRecentVisit(test_set, sqlite_conn))

end

@testset "GetVisitConcept multiple dispatch Tests" begin
	visit_ids = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.visit_occurrence_id, Get.person_id) |> Limit(20) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame 
    test_ids = visit_ids.visit_occurrence_id
    test_concept_ids = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.visit_occurrence_id, Get.visit_concept_id, Get.person_id) |> Where(Fun.in(Get.visit_occurrence_id, test_ids...)) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    @test test_concept_ids == GetVisitConcept(visit_ids, sqlite_conn)
end

@testset "GetVisitCondition multiple dispatch Tests" begin

    #test for 3 visit ids with only 1 condition each
    visit_patient_ids = From(OMOPCDMCohortCreator.visit_occurrence) |> Select(Get.person_id, Get.visit_occurrence_id) |> Limit(3) |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame
    visit_ids = visit_patient_ids.visit_occurrence_id
    test_condition_ids = From(OMOPCDMCohortCreator.condition_occurrence)|>
           Where(Fun.in(Get.visit_occurrence_id, visit_ids...)) |>
           Select(Get.visit_occurrence_id, Get.condition_concept_id, Get.person_id) |>
           q -> render(q, dialect=OMOPCDMCohortCreator.dialect)|> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    @test test_condition_ids == sort(GetVisitCondition(visit_patient_ids, sqlite_conn),:person_id)
  
end

@testset "GetPatientEthnicity multiple dispatch Tests" begin
	ethnicities = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id, Get.ethnicity_concept_id, Get.race_concept_id) |> Limit(20) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

	test_ids = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id) |> Limit(20) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame |> Array

	@test ethnicities == GetPatientEthnicity(GetPatientRace(test_ids, sqlite_conn), sqlite_conn)
end

@testset "GetVisitDate multiple dispatch Tests" begin

    #test with interval = start
    test_visit_ids= [65475.0, 14930.0, 25743.0, 14888.0]
    patient_ids = [986.0, 222.0, 392.0, 222.0]
    test_visit_patients = DataFrame(visit_occurrence_id = test_visit_ids, person_id = patient_ids)
    test_start_dates = [840585600.0, 575510400.0, 1336953600.0, 1063497600.0]
    test_df_start = DataFrame(visit_occurrence_id = test_visit_ids, visit_start_date = test_start_dates, person_id = patient_ids)

    @test test_df_start == GetVisitDate(test_visit_patients, sqlite_conn, interval=Symbol("start"))

    #test with interval = end
    test_end_dates = [840672000.0, 575596800.0, 1337040000.0, 1063584000.0]
    test_df_end = DataFrame(visit_occurrence_id=test_visit_ids, visit_end_date=test_end_dates, person_id = patient_ids)

    @test test_df_end == GetVisitDate(test_visit_patients, sqlite_conn, interval=Symbol("end"))
    
end


#=
@testset "GetDrugExposureIDs multiple dispatch Tests" begin
    test_ids = From(OMOPCDMCohortCreator.drug_exposure) |> Select(Get.person_id) |> Limit(1) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    test_query = From(OMOPCDMCohortCreator.drug_exposure) |> Select(Get.drug_exposure_id, Get.person_id) |> Where(Get.person_id .== 573.0)
    genders = From(OMOPCDMCohortCreator.person)
    Drug_exposure_genders = test_query |> LeftJoin(genders, on =  test_query.person_id.== genders.person_id) |>
    Select(genders.person_id, test_query.drug_exposure_id, genders.gender_concept_id)  |> q -> render(q, dialect=OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    @test Drug_exposure_genders == GetDrugExposureIDs(GetPatientGender(test_ids, sqlite_conn), sqlite_conn)
end
=#


@testset "GetDrugConceptIDs multiple dispatch Tests" begin
    test_ids = From(OMOPCDMCohortCreator.drug_exposure) |> Select(Get.person_id) |> Limit(1) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

	drug_exposure_ids = From(OMOPCDMCohortCreator.drug_exposure) |> Select(Get.drug_exposure_id, Get.person_id) |> Where(Get.person_id .== 573.0) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame 

	@test GetDrugConceptIDs(drug_exposure_ids, sqlite_conn) == GetDrugConceptIDs(GetDrugExposureIDs(test_ids, sqlite_conn), sqlite_conn)
end

@testset "GetCohortSubjects Tests" begin
    
    test_cohort_definition_ids = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

    test_subject_ids = [1.0, 5.0, 9.0, 11.0, 12.0, 17.0, 18.0, 19.0]

    res = sort(GetCohortSubjects([1.0], sqlite_conn))
    test_df1 = DataFrame(cohort_definition_id = test_cohort_definition_ids, subject_id = res.subject_id[1:8])

    new = GetCohortSubjects(test_df1[:,"cohort_definition_id"], sqlite_conn) 

    @test test_subject_ids == res.subject_id[1:8]
    @test isa(GetCohortSubjects(test_cohort_definition_ids, sqlite_conn), DataFrame)
    @test new.subject_id[1:8] == test_df1.subject_id[1:8]
    
end

@testset "GetCohortSubjectStartDate" begin
    
    test_cohort_definition_ids = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

    test_subject_ids = [1.0, 5.0, 9.0, 11.0, 12.0, 17.0, 18.0, 19.0]

    test_start_dates = [-533347200.0, 334281600.0, 555811200.0, -117849600.0, 74563200.0, -312336000.0, 296352000.0, 958348800.0]

    res = sort(GetCohortSubjectStartDate([1.0], test_subject_ids, sqlite_conn))
    test_df1 = DataFrame(cohort_definition_id = test_cohort_definition_ids, subject_id = test_subject_ids, cohort_start_date = res.cohort_start_date[1:8])

    new = GetCohortSubjectStartDate(test_df1[:,"cohort_definition_id"], test_df1[:,"subject_id"], sqlite_conn)

    @test test_start_dates == res.cohort_start_date[1:8]
    @test isa(GetCohortSubjectStartDate(test_cohort_definition_ids, test_subject_ids, sqlite_conn), DataFrame)
    @test new.cohort_start_date[1:8] == test_df1.cohort_start_date[1:8]
    
end

@testset "GetCohortSubjectEndDate" begin
    
    test_cohort_definition_ids = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

    test_subject_ids = [1.0, 5.0, 9.0, 11.0, 12.0, 17.0, 18.0, 19.0]

    test_end_dates = [1558656000.0, 1535500800.0, 1540425600.0, 1557187200.0, 1551830400.0, 1546819200.0, 1541548800.0, 1534636800.0]

    res = sort(GetCohortSubjectEndDate([1.0], test_subject_ids, sqlite_conn))
    test_df1 = DataFrame(cohort_definition_id = test_cohort_definition_ids, subject_id = test_subject_ids, cohort_end_date = res.cohort_end_date[1:8])

    new = GetCohortSubjectEndDate(test_df1[:,"cohort_definition_id"], test_df1[:,"subject_id"], sqlite_conn)

    @test test_end_dates == res.cohort_end_date[1:8]
    @test isa(GetCohortSubjectEndDate(test_cohort_definition_ids, test_subject_ids, sqlite_conn), DataFrame)
    @test new.cohort_end_date[1:8] == test_df1.cohort_end_date[1:8]
end

@testset "GetDatabaseCohorts" begin

    test_ids=[1.0]
    new=GetDatabaseCohorts(sqlite_conn)

    @test test_ids == new[1:1]
end

@testset "GetDrugExposureEndDate" begin

    test_drug_exposure_ids = [1.0, 2.0, 3.0, 4.0, 5.0]

    test_drug_exposure_end_date_ids = [-364953600, 31449600, -532483200, -80006400, 1330387200]

    res = sort(GetDrugExposureEndDate(test_drug_exposure_ids, sqlite_conn))
    test_df1 = DataFrame(drug_exposure_id = test_drug_exposure_ids, drug_exposure_end_date = res.drug_exposure_end_date[1:5])

    new = GetDrugExposureEndDate(test_df1[:,"drug_exposure_id"], sqlite_conn)

    @test test_drug_exposure_end_date_ids == res.drug_exposure_end_date[1:5]
    @test new.drug_exposure_end_date[1:5] == test_df1.drug_exposure_end_date[1:5]
    @test isa(GetDrugExposureEndDate(test_drug_exposure_ids, sqlite_conn), DataFrame)

end

@testset "GetDrugExposureStartDate" begin
    
    test_drug_exposure_ids = [1.0, 2.0, 3.0, 4.0, 5.0]

    test_drug_exposure_start_date_ids = [-3.727296e8, 2.90304e7, -5.333472e8, -8.18208e7, 1.3291776e9]

    res = sort(GetDrugExposureStartDate(test_drug_exposure_ids, sqlite_conn))
    test_df1 = DataFrame(drug_exposure_id = test_drug_exposure_ids, drug_exposure_start_date = res.drug_exposure_start_date[1:5])

    new = GetDrugExposureStartDate(test_df1[:,"drug_exposure_id"], sqlite_conn)

    @test test_drug_exposure_start_date_ids == res.drug_exposure_start_date[1:5]
    @test new.drug_exposure_start_date[1:5] == test_df1.drug_exposure_start_date[1:5]
    @test isa(GetDrugExposureStartDate(test_drug_exposure_ids, sqlite_conn), DataFrame)

end

@testset "GetVisitProcedure Tests" begin
    test_visit_occurrence_ids = [22951.0, 23670.0, 26205.0, 26759.0, 27401.0, 28537.0, 29330.0, 30237.0, 31282.0, 32616.0]

    test_procedure_concept_ids = [4.107731e6, 4.107731e6, 4.107731e6, 4.107731e6, 4.107731e6, 4.058899e6, 4.107731e6, 4.043071e6, 4.043071e6, 4.151422e6]

    test_df = DataFrame(visit_occurrence_id = test_visit_occurrence_ids, procedure_concept_id = test_procedure_concept_ids)

    test_ids = [22951.0, 23670.0, 26205.0, 26759.0, 27401.0, 28537.0, 29330.0, 30237.0, 31282.0, 32616.0]

    @test test_df == GetVisitProcedure(test_ids, sqlite_conn)
    @test isa(GetVisitProcedure(test_ids, sqlite_conn), DataFrame)
    @test test_df == GetVisitProcedure(test_df[:,"visit_occurrence_id"], sqlite_conn)

end

"""

This test is blocked as there is no amount_value in eunomia, Looking at the https://ohdsi.github.io/CommonDataModel/cdm54.html#DRUG_STRENGTH to add it says there is no primary key!


@testset "GetDrugAmounts Multiple dispatch Tests" begin
    test_ids = From(OMOPCDMCohortCreator.person) |> Select(Get.person_id) |> Where(Get.person_id .== 573.0) |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame

    drug_conceptIDs_exposures = GetDrugConceptIDs(From(OMOPCDMCohortCreator.drug_exposure) |> Select( Get.drug_exposure_id, Get.person_id)|> Where(Get.person_id .== 573.0)  |> q -> render(q, dialect = OMOPCDMCohortCreator.dialect) |> q -> DBInterface.execute(sqlite_conn, q) |> DataFrame,sqlite_conn)

	@test GetDrugAmounts(drug_conceptIDs_exposures, sqlite_conn) == GetDrugAmounts(GetDrugConceptIDs(GetDrugExposureIDs(test_ids,sqlite_conn),sqlite_conn), sqlite_conn)
end

"""
