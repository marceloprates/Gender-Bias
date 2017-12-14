
using DataFrames, CSV, Gadfly

# Read job-genders.csv into a Julia DataFrame
dat = CSV.read("job-genders-2.csv",delim=';',nullable=false)

# Get list of occupation categories
categories = unique(dat[:Category])

# Initialize results table
#results = DataFrame(Category=[],Female=[],Male=[],Neutral=[],Ratio=[],Total=[])
#results = DataFrame(Category=[],Gender=[],Count=[])

#=
results = DataFrame(Category=[],Gender=[],Count=[])
for category in categories

    aux = dat[dat[:,:Category] .== category, 3:11]

    female_count    = sum([ count(x -> x=="Female",     aux[language]) for language in names(aux) ])
    male_count      = sum([ count(x -> x=="Male",       aux[language]) for language in names(aux) ])
    neutral_count   = sum([ count(x -> x=="Neutral",    aux[language]) for language in names(aux) ])
    total           = sum([ count(x -> true,            aux[language]) for language in names(aux) ]

    #push!(results,[ucfirst(category),female_count,male_count,neutral_count,male_count/female_count,total])
    push!(results,[ucfirst(category),"Female",  100*female_count/total])
    push!(results,[ucfirst(category),"Male",    100*male_count/total])
    push!(results,[ucfirst(category),"Neutral", 100*neutral_count/total])
end
=#

results = DataFrame(Language=[],Gender=[],Count=[])

languages = names(dat)[3:end]
for language in languages
    female_count    = count(x -> x=="Female", dat[language])
    male_count      = count(x -> x=="Male", dat[language])
    neutral_count   = count(x -> x=="Neutral", dat[language])
    total           = count(x -> true, dat[language])
    push!(results,[language,"Female",   100*female_count/total    ])
    push!(results,[language,"Male",     100*male_count/total      ])
    push!(results,[language,"Neutral",  100*neutral_count/total   ])
end

println(results)
#p = plot(results, x="Category", y="Count", color="Gender", Coord.Cartesian(ymin=0,ymax=100), Geom.bar(position=:stack), Theme(background_color="white",grid_color="gray",bar_highlight=colorant"black"), Guide.ylabel("\%"))
#draw(PDF("paper/pictures/sex-ratio-hist.pdf", 5inch, 3.75inch),p)

p = plot(results, x="Language", y="Count", color="Gender", Coord.Cartesian(ymin=0,ymax=100), Geom.bar(position=:stack), Theme(background_color="white",grid_color="gray",bar_highlight=colorant"black"), Guide.ylabel("\%"))
draw(PDF("paper/pictures/gender-by-language.pdf", 5inch, 3.75inch),p)