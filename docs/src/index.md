# Welcome to the `OMOPCDMCohortCreator.jl` Docs! 👋

Hello Skylar! This should refresh browser! 

> Create cohorts from databases utilizing the OMOP CDM.

This package uses a functional approach to query databases in the [OMOP Common Data Model format](https://www.ohdsi.org/data-standardization/the-common-data-model/) whereby you could build rapidly lines of inquiry into the database.
Furthermore, this package is a companion to those tools found in the [HADES](https://ohdsi.github.io/Hades/) ecosystem.
To get started, visit the [Tutorials](@ref) section as well as visit the [API](@ref) section to see all the functions available.
If you want to contribute, please check out our [Contributing](@ref) guide!

```@example
sleep(.1)
```

## Main Features 🔧

The biggest features of this package are:

- Incremental building blocks for creating an analysis pipeline in the form of (more information in [API](@ref)):
  - "Getter" functions to "get" information from a database 
  - "Filter" functions to "filter" information from a database 
  - "Generator" functions to "generate" database information and connections
  - "Executor" functions to "execute" on retrieved information 
- Automatic targeting and support for the SQL flavors (via [FunSQL.jl](https://mechanicalrabbit.github.io/FunSQL.jl/)):
  - `postgresql`
  - `sqlite`
  - `redshift`
- Prepare SQL queries if unable to connect to database via OMOPCDMCohortCreator that could then be run on a given SQL database directly
- Does not mutate database or require temp tables
- Interoperable with the R language via [JuliaConnectoR](https://github.com/stefan-m-lenz/JuliaConnectoR) to work directly within R syntax (see [Tutorials](@ref))
- Readily parallelizable via [Distributed.jl](https://docs.julialang.org/en/v1/manual/distributed-computing/)
- Complementary to [OHDSI HADES](https://ohdsi.github.io/Hades/) ecosystem tools
- Extensive [test suite](https://github.com/JuliaHealth/OMOPCDMCohortCreator.jl/tree/main/test) to ensure correctness and compliance with privacy preserving methods (HITECH, etc.)

## Why? 🤔

This package was created as the result of work in the [MentalHealthEquity](https://github.com/ohdsi-studies/MentalHealthEquity) network study.
Phenotype definitions work alongside this package and OMOPCDMCohortCreator allows an investigator to quickly iterate and build on top of phenotype definitions and/or concept sets.
Where I personally see this being of use is when an investigator needs to quickly pull information out of a database, iterate and test ideas for a formal phenotype definition rapidly, and reason simply about queries.

## Why Julia? 🤓

Julia itself is built for High Performance Computing and readability.
We wanted to work in a language that could handle the high amounts of data that could manifest in working with OMOP CDM databases.
Julia not only made sense for "big data" operations and readability but also was attractive due to it's ability to work with other programming languages such as R or Python.
Therefore, the benefit is:

- High performance more easily reached on all ranges of hardware
- Lower barrier to entry for new contributors
- Interoperation with other programming languages

In our eyes, we do not see anything lost by choosing Julia as we can easily bridge to other languages.
The idea is that this approach can keep users in the language they are comfortable with while working with a flexible package to quickly perform analyses.
