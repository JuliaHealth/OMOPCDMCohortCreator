# Beginner Tutorial 🐣

```@contents
Pages = ["beginner_tutorial.md"]
```

This tutorial presents a step by step guide on using OMOPCDMCohortCreator to run a mini characterization study!
You will learn the basics of OMOPCDMCohortCreator and how to use it with fake data that you could then apply to your real data sets.
Basic knowledge of Julia (such as installing packages into environments and working with the Julia REPL and Julia files) is necessary; you can learn all [that here](https://pkgdocs.julialang.org/v1/getting-started/).

## Environment Set-Up 📝

For this tutorial, you will need to activate an environment; to get into package mode within your Julia REPL, write `]`:

```julia-repl
pkg> activate TUTORIAL
```

### Packages 

You will need the following packages for this tutorial which you can install in package mode:

```julia-repl
TUTORIAL> add OMOPCDMCohortCreator
TUTORIAL> add SQLite
TUTORIAL> add DataFrames
TURORIAL> add HealthSampleData
```

To learn more about these packages, see the [Appendix](#appendix).

### Data 

For this tutorial, we will work with data from [Eunomia](https://github.com/OHDSI/Eunomia) that is stored in a SQLite format.
To install the data on your machine, execute the following code block and follow the prompts - you will need a stable internet connection for the download to complete: 

```julia
import HealthSampleData: Eunomia

eunomia = Eunomia()
```

## Connecting to the Eunomia Database 💾

After you have finished your set up in the Julia, we need to establish a connection to the Eunomia SQLite database that we will use for the rest of the tutorial: 

```julia
import SQLite: DB

conn = DB(eunomia)
```

With Eunomia, the database's schema is simply called "main".
We will use this to generate database connection details that will inform `OMOPCDMCohortCreator` about the type of queries we will write (i.e. SQLite) and the name of the database's schema.
For this step, we will use `OMOPCDMCohortCreator`:

```julia
import OMOPCDMCohortCreator as occ

occ.GenerateDatabaseDetails(
    :sqlite,
    "main"
)
```

Finally, we will generate internal representations of each table found within Eunomia for OMOPCDMCohortCreator to use:

```julia
occ.GenerateTables(conn)
```

As a check to make sure everything was correctly installed and works properly, the following block should work and return a list of all person ids in this data:

```julia
occ.GetDatabasePersonIDs(conn)
```

## Characterizing Patients Who Have Had Strep Throat 🤒

### Background 

As all the tools are working properly, let's do what is called a characterization study - a study that *characterizes* a group of patients with a certain condition (or conditions) across various attributes like race, age, and combinations thereof.
We are going to do miniature version of such a study looking at patients with strep throat.
For this, we will use the `condition_concept_id`: $28060$ - this will be needed for you to get correct results.

> **NOTE:** As we go through this example, do not immediately jump to the code block required but try to use the [API](@ref) to come up with solutions as there may be more than one answer.

### Task: Find All Patients with Strep Throat

Using the [API](@ref), find all patients with strep throat.

Suggested solution:

```julia
strep_patients = occ.ConditionFilterPersonIDs(28060, conn)
```
Note: This function can accept more than one condition_concept_id. 
Example:
```
concept_ids = [28060, 433037, 372654, 443599, 436519]
patients = occ.ConditionFilterPersonIDs(concept_ids, conn)
```

### Task: Find the Race of Patients with Strep Throat

For the patients who have strep throat diagnoses, find their race.

Suggested solution:

```julia
strep_patients_race = occ.GetPatientRace(strep_patients.person_id, conn)
```

### Task: Find the Gender of Patients with Strep Throat

For the patients who have strep throat diagnoses, find their gender.

Suggested solution:

```julia
strep_patients_gender = occ.GetPatientGender(strep_patients.person_id, conn)
```

### Task: Create Age Groupings of Patients with Strep Throat

For this task, for every single person who has a strep throat diagnosis, assign them an age group.
The age groupings must follow $5$ year intervals when assigned to a person up to $99$ years of age (e.g. $[0, 4], [5, 10], ... [95, 99]$).

Suggested solution:

```julia
age_groups = [
	[0, 4],
	[5, 9],
	[10, 14],
	[15, 19],
	[20, 24],
	[25, 29],
	[30, 34],
	[35, 39],
	[40, 44],
	[45, 49],
	[50, 54],
	[55, 59],
	[60, 64],
	[65, 69],
	[70, 74],
	[75, 79],
	[80, 84],
	[85, 89],
	[90, 94],
	[95, 99]
]
strep_patients_age_group = occ.GetPatientAgeGroup(strep_patients.person_id, conn; age_groupings = age_groups)
```

### Task: Characterize Each Person by Gender, Race, and Age Group

With the previous tasks, we now know patients' gender, race, and age group.
Using this information, combine these features to create a final table where each patient's `person_id`, gender, race, and age group is found in a given row.
Hint: The DataFrames.jl [documentation section on joins](https://dataframes.juliadata.org/stable/man/joins/) will be of strong use here.

Suggested solution:

```julia
import DataFrames as DF

strep_patients_characterized = DF.outerjoin(strep_patients_race, strep_patients_gender, strep_patients_age_group; on = :person_id, matchmissing = :equal)
```

### Task: Create Patient Groupings

Often with characterization style studies, it is extremely important to aggregate patient populations.
Why?
To protect the anonymity of patients with perhaps severely sensitive conditions (e.g. mental illnesses, sexually transmitted diseases, etc.) from possible repercussions from accidental disclosure of this patient information.

For this task, add to the table you created in the previous task a new column called `count` and remove the `person_id` column.
The `count` column should represent the total number of patients belonging to a group's gender, race, and age group.
Here is an example on how to calculate `count`: if there are $5$ rows in your table that have patients who are between the ages of $20 - 24$, are African American, and are female, the value for that age, race, and gender group is $5$.
The $5$ rows would then collapse into $1$ row as unique patient identifiers (the `person_id` column) would be removed. Hint: removing the `person_id` column first may make things easier; also, look at the [DataFrames.jl documentation on the Split-Apply-Combine](https://dataframes.juliadata.org/stable/man/split_apply_combine/) approach to generate the `count` column.

Suggested solution:

```julia
strep_patients_characterized = strep_patients_characterized[:, DF.Not(:person_id)]
strep_patient_groups = DF.groupby(strep_patients_characterized, [:race_concept_id, :gender_concept_id, :age_group])
strep_patient_groups = DF.combine(strep_patient_groups, DF.nrow => :count)
```

### Task: Execute Safety Audit

To ensure the safety of the patients in this table, we can execute an audit.
One such auditing standard are those put forth by "[HITECH](https://www.hhs.gov/hipaa/for-professionals/special-topics/hitech-act-enforcement-interim-final-rule/index.html)" which, amongst other things, requires researchers to filter out from a table patient counts $< 11$ in subpopulation groups -- the kind of groups we created!
We can apply that as follows:

```julia
audited_strep_patient_groups = occ.ExecuteAudit(strep_patient_groups; hitech = true)
```

## Conclusion 🎉

This mini characterization study that we just conducted on this dataset opens up a whole new avenue for a researcher to pursue.
For example, we could now calculate prevalence rates across different patient characteristics or compare and contrast multiple conditions at once.
It should also be apparent that the API is set up in a very particular way: it is functional meaning that each function does one thing only.
This gives a lot of flexibility to a user to build together study incrementally using OMOPCDMCohortCreator.
Congratulations on finishing this tutorial and if there are any issues you encountered, [feel free to open an issue here](https://github.com/JuliaHealth/OMOPCDMCohortCreator.jl/issues/new/choose)!

## Appendix 🕵️

### Packages Used in Analysis

Package descriptions:

- [`DataFrames`](https://github.com/JuliaData/DataFrames.jl) - Julia's dataframe handler for easily manipulating data

- [`OMOPCDMCohortCreator`](https://github.com/JuliaHealth/OMOPCDMCohortCreator.jl) - Create cohorts from databases utilizing the OMOP CDM

- [`HealthSampleData`](https://github.com/JuliaHealth/HealthSampleData.jl) - Sample health data for a variety of health formats and use cases

- [`SQLite`](https://github.com/JuliaDatabases/SQLite.jl) - A Julia interface to the SQLite library
