
using DataFrames, CSV, Gadfly

# Read job-genders.csv into a Julia DataFrame
dat = CSV.read("job-genders.csv",delim=';',nullable=false)

# Compute results table (grouped by occupation, averaged among languages)
results_by_occupation = DataFrame(Occupation=[],Category=[],Ratio=[],Neutral=[])
for occupation in dat[:Occupation]

    aux = dat[ dat[:,:Occupation] .== occupation, : ]
    
    female_count    = sum([ count(x -> x=="Female",     aux[language]) for language in names(dat)[3:end] ])
    male_count      = sum([ count(x -> x=="Male",       aux[language]) for language in names(dat)[3:end] ])
    neutral_count   = sum([ count(x -> x=="Neutral",    aux[language]) for language in names(dat)[3:end] ])
    ratio           = male_count/female_count

    push!(results_by_occupation, [occupation,ucfirst(aux[1,:Category]),ratio,100*neutral_count/(11-3+1)])
end
# Save scatter plot
p = plot(results_by_occupation, x=:Ratio, y=:Neutral, color=:Category, Guide.xlabel("Sex Ratio"), Guide.ylabel("\% of Gender Neutral Pronouns"), Stat.x_jitter(range=2), Stat.y_jitter(range=2), Coord.Cartesian(xmin=0, ymin=0), Geom.point)
draw(PDF("paper/pictures/scatterplot-languages.pdf", 5inch, 3.75inch),p)

#=
# Compute results table (grouped by category)
# Get list of occupation categories
categories = unique(dat[:Category])
#results_by_category = DataFrame(Category=[],Gender=[],Count=[])
results_by_category = DataFrame(Category=[],Female=[],Male=[],Neutral=[],Ratio=[],Total=[])
for category in categories

    aux = dat[dat[:,:Category] .== category, 3:11]

    female_count    = sum([ count(x -> x=="Female",     aux[language]) for language in names(aux) ])
    male_count      = sum([ count(x -> x=="Male",       aux[language]) for language in names(aux) ])
    neutral_count   = sum([ count(x -> x=="Neutral",    aux[language]) for language in names(aux) ])
    total           = sum([ count(x -> true,            aux[language]) for language in names(aux) ])

    #push!(results_by_category,[ucfirst(category),"Female",  100*female_count/total  ])
    #push!(results_by_category,[ucfirst(category),"Male",    100*male_count/total    ])
    #push!(results_by_category,[ucfirst(category),"Neutral", 100*neutral_count/total ])
    push!(results_by_category,[ucfirst(category),female_count,male_count,neutral_count,male_count/female_count,total])
end
push!(results_by_category,["Total",sum(results_by_category[:Female]),sum(results_by_category[:Male]),sum(results_by_category[:Neutral]),0,0])
print(results_by_category)
# Save bar plot
#p = plot(results_by_category, x="Category", y="Count", color="Gender", Coord.Cartesian(ymin=0,ymax=100), Geom.bar(position=:stack), Theme(background_color="white",grid_color="gray",bar_highlight=colorant"black"), Guide.ylabel("\%"))
#draw(PDF("paper/pictures/gender-by-category.pdf", 5inch, 3.75inch),p)


# Compute results table (grouped by languages)
#results_by_language = DataFrame(Language=[],Gender=[],Count=[])
results_by_language = DataFrame(Language=[],Female=[],Male=[],Neutral=[],Ratio=[],Total=[])
languages = names(dat)[3:end]
for language in languages
    
    female_count    = count(x -> x=="Female",   dat[language])
    male_count      = count(x -> x=="Male",     dat[language])
    neutral_count   = count(x -> x=="Neutral",  dat[language])
    total           = count(x -> true,          dat[language])
    
    #push!(results_by_language,[language,"Female",   100*female_count/total    ])
    #push!(results_by_language,[language,"Male",     100*male_count/total      ])
    #push!(results_by_language,[language,"Neutral",  100*neutral_count/total   ])
    push!(results_by_language,[language,female_count,male_count,neutral_count,male_count/female_count,total])
end
push!(results_by_language,["Total",sum(results_by_language[:Female]),sum(results_by_language[:Male]),sum(results_by_language[:Neutral]),0,0])
println(results_by_language)
# Save bar plot
#p = plot(results_by_language, x="Language", y="Count", color="Gender", Coord.Cartesian(ymin=0,ymax=100), Geom.bar(position=:stack), Theme(background_color="white",grid_color="gray",bar_highlight=colorant"black"), Guide.ylabel("\%"))
#draw(PDF("paper/pictures/gender-by-language.pdf", 5inch, 3.75inch),p)
=#