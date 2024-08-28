using OMOPCDMCohortCreator
using Documenter
using DocumenterVitepress

makedocs(;
    modules = [OMOPCDMCohortCreator],
    warnonly = true,
    checkdocs=:all,
    authors = "Jacob Zelko (aka TheCedarPrince) <jacobszelko@gmail.com> and contributors",
    sitename = "OMOPCDMCohortCreator.jl",
    format=DocumenterVitepress.MarkdownVitepress(
        repo = "github.com/JuliaHealth/OMOPCDMCohortCreator.jl", # this must be the full URL!
        devbranch = "main",
        md_output_path = ".",
        devurl = "dev",
        build_vitepress = false
    ),
    pages = [
        "Home" => "index.md",
        "Tutorials" => [
                        "tutorials.md",
                        "tutorials/beginner_tutorial.md",
                        "tutorials/r_tutorial.md"
                       ],
        "API" => "api.md",
        "Contributing" => "contributing.md"
    ],
    draft = false,
    source = "src",
    build = "build",
    clean = false
)

deploydocs(;
    repo = "github.com/JuliaHealth/OMOPCDMCohortCreator.jl",
    push_preview = true,
    devbranch = "main",
    target = "build", # this is where Vitepress stores its output
    branch = "gh-pages",
)
