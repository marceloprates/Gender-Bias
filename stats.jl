
using DataFrames, CSV, Gadfly

# Read job-genders.csv into a Julia DataFrame
dat_jobs = CSV.read("job-genders.csv",delim=';',nullable=false)
# Read adjective-genders.csv into a Julia DataFrame
dat_adjectives = CSV.read("adjective-genders.csv",delim=';',nullable=false)

function barplot_adjectives()
    results_by_adjective = DataFrame(Adjective=[],Gender=[],Count=[],Ratio=[])

    for adjective in dat_adjectives[:Adjective]
        aux = dat_adjectives[ dat_adjectives[:,:Adjective] .== adjective, : ]
        
        female_count    = sum([ count(x -> x=="Female",     aux[language]) for language in names(dat_adjectives)[1:end] ])
        male_count      = sum([ count(x -> x=="Male",       aux[language]) for language in names(dat_adjectives)[1:end] ])
        neutral_count   = sum([ count(x -> x=="Neutral",    aux[language]) for language in names(dat_adjectives)[1:end] ])
        total           = sum([ count(x -> true,            aux[language]) for language in names(dat_adjectives)[1:end] ])
        ratio = male_count/female_count
        
        push!(results_by_adjective, [ucfirst(adjective),"Female",   100*female_count/total,   ratio])
        push!(results_by_adjective, [ucfirst(adjective),"Male",     100*male_count/total,     ratio])
        push!(results_by_adjective, [ucfirst(adjective),"Neutral",  100*neutral_count/total,  ratio])
    end

    sort!(results_by_adjective, cols = [order(:Ratio)])

    # Save bar plot
    p = plot(results_by_adjective, x=:Adjective, y=:Count, color=:Gender, Coord.Cartesian(ymin=0,ymax=100), Geom.bar(position=:stack), Theme(background_color="white",grid_color="gray",bar_highlight=colorant"black"), Guide.ylabel("\%"))
    draw(PDF("paper/pictures/barplot-adjectives.pdf", 5inch, 3.75inch),p)
end

function histograms_occupations()
    # Compute results table (grouped by occupation, averaged among languages)
    results_by_occupation = DataFrame(Female=[],Male=[],Neutral=[],Category=[])
    for occupation in dat_jobs[:Occupation]

        aux = dat_jobs[ dat_jobs[:,:Occupation] .== occupation, : ]
        
        female_count    = sum([ count(x -> x=="Female",     aux[language]) for language in names(dat_jobs)[3:end] ])
        male_count      = sum([ count(x -> x=="Male",       aux[language]) for language in names(dat_jobs)[3:end] ])
        neutral_count   = sum([ count(x -> x=="Neutral",    aux[language]) for language in names(dat_jobs)[3:end] ])
        ratio           = male_count/female_count

        push!(results_by_occupation, [female_count,male_count,neutral_count,ucfirst(aux[1,:Category])])
    end

    # Save histograms
    p = plot(results_by_occupation, x=:Female, color=:Category, Guide.xlabel("\# Female Pronouns"), Geom.histogram)
    draw(PDF("paper/pictures/histogram-female.pdf", 5inch, 3.75inch),p)

    p = plot(results_by_occupation, x=:Male, color=:Category, Guide.xlabel("\# Male Pronouns"), Geom.histogram)
    draw(PDF("paper/pictures/histogram-male.pdf", 5inch, 3.75inch),p)

    p = plot(results_by_occupation, x=:Neutral, color=:Category, Guide.xlabel("\# Gender Neutral Pronouns"), Geom.histogram)
    draw(PDF("paper/pictures/histogram-neutral.pdf", 5inch, 3.75inch),p)
end

function barplots_category()
    # Compute results table (grouped by category)
    # Get list of occupation categories
    categories = unique(dat_jobs[:Category])
    results_by_category = DataFrame(Category=[],Gender=[],Count=[])
    for category in categories

        aux = dat_jobs[dat_jobs[:,:Category] .== category, 3:end]

        female_count    = sum([ count(x -> x=="Female",     aux[language]) for language in names(aux) ])
        male_count      = sum([ count(x -> x=="Male",       aux[language]) for language in names(aux) ])
        neutral_count   = sum([ count(x -> x=="Neutral",    aux[language]) for language in names(aux) ])
        total           = sum([ count(x -> true,            aux[language]) for language in names(aux) ])

        push!(results_by_category,[ucfirst(category),"Female",  100*female_count/total  ])
        push!(results_by_category,[ucfirst(category),"Male",    100*male_count/total    ])
        push!(results_by_category,[ucfirst(category),"Neutral", 100*neutral_count/total ])
    end

    # Save bar plot
    p = plot(results_by_category, x="Category", y="Count", color="Gender", Coord.Cartesian(ymin=0,ymax=100), Geom.bar(position=:stack), Theme(background_color="white",grid_color="gray",bar_highlight=colorant"black"), Guide.ylabel("\%"))
    draw(PDF("paper/pictures/gender-by-category.pdf", 5inch, 3.75inch),p)
end

function barplots_language()
    # Compute results table (grouped by languages)
    results_by_language = DataFrame(Language=[],Gender=[],Count=[])
    languages = names(dat_jobs)[3:end]
    for language in languages
        
        female_count    = count(x -> x=="Female",   dat_jobs[language])
        male_count      = count(x -> x=="Male",     dat_jobs[language])
        neutral_count   = count(x -> x=="Neutral",  dat_jobs[language])
        total           = count(x -> true,          dat_jobs[language])
        
        push!(results_by_language,[language,"Female",   100*female_count/total    ])
        push!(results_by_language,[language,"Male",     100*male_count/total      ])
        push!(results_by_language,[language,"Neutral",  100*neutral_count/total   ])
    end
    # Save bar plot
    p = plot(results_by_language, x="Language", y="Count", color="Gender", Coord.Cartesian(ymin=0,ymax=100), Geom.bar(position=:stack), Theme(background_color="white",grid_color="gray",bar_highlight=colorant"black"), Guide.ylabel("\%"))
    draw(PDF("paper/pictures/gender-by-language.pdf", 5inch, 3.75inch),p)
end

barplot_adjectives()
histograms_occupations()
barplots_category()
barplots_language()