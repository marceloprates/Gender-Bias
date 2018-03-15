#Pkg.add("DataFrames")
#Pkg.add("CSV")
#Pkg.add("Gadfly")
#Pkg.add("Cairo")
#Pkg.add("Fontconfig")

using DataFrames, CSV, Gadfly

# Read compare data file
cpm_GT_real = CSV.read("Results/translate-real-histogram-data-raw.tsv",delim='\t',nullable=false)
function histograms_compare()
    # Save histograms
    # "GT_F/A"	"GT_F/(M+F)"	"BLS_Data"
    p = plot(cpm_GT_real, x="GT_F/A", Geom.histogram(bincount=12), Theme(key_max_columns=1, key_label_font_size=6pt))
    draw(PDF("Paper/pictures/histogram-compare-gt-real.pdf", 5.0inch, 3.75inch),p)
end
histograms_compare()
exit()

# Read job-genders.csv into a Julia DataFrame
dat_jobs = CSV.read("Results/job-genders.tsv",delim='\t',nullable=false)

# Remove "occupations" from the end of all category names
dat_jobs[:Category] = map(x -> replace(x," occupations",""),dat_jobs[:Category])

function rename_category(label)
    if label=="Education, training, and library"
        return "Education / Training / Library"
    elseif label=="Business and financial operations"
        return "Business / Financial"
    elseif label=="Office and administrative support"
        return "Office / Administrative"
    elseif label=="Installation, maintenance, and repair"
        return "Installation / Maintenance / Repair"
    elseif label=="Healthcare practitioners and technical"
        return "Healthcare practitioners / technical"
    elseif label=="Life, physical, and social science"
        return "Life, physical, and social sciences"
    elseif label=="Arts, design, entertainment, sports, and media"
        return "Arts / Entertainment"
    elseif label=="Building and grounds cleaning and maintenance"
        return "Cleaning / Maintenance"
    elseif label=="Food preparation and serving related"
        return "Food prepaparation / serving"
    elseif label=="Transportation and material moving"
        return "Transportation / material moving"
    else
        return label
    end
end

function group_categories(label)
    if label == "Education, training, and library"
        return "Education"
    elseif label == "Business and financial operations"
        return "Corporate"
    elseif label == "Office and administrative support"
        return "Service"
    elseif label == "Healthcare support"
        return "Healthcare"
    elseif label == "Management"
        return "Corporate"
    elseif label == "Installation, maintenance, and repair"
        return "Service"
    elseif label == "Healthcare practitioners and technical"
        return "Healthcare"
    elseif label == "Community and social service"
        return "Service"
    elseif label == "Sales and related"
        return "Corporate"
    elseif label == "Production"
        return "Production"
    elseif label == "Architecture and engineering"
        return "STEM"
    elseif label == "Life, physical, and social science"
        return "STEM"
    elseif label == "Transportation and material moving"
        return "Service"
    elseif label == "Arts, design, entertainment, sports, and media"
        return "Arts \n Entertainment"
    elseif label == "Legal"
        return "Legal"
    elseif label == "Protective service"
        return "Service"
    elseif label == "Food preparation and serving related"
        return "Service"
    elseif label == "Farming, fishing, and forestry"
        return "Farming \n Fishing \n Forestry"
    elseif label == "Computer and mathematical"
        return "STEM"
    elseif label == "Personal care and service"
        return "Service"
    elseif label == "Construction and extraction"
        return "Construction \n Extraction"
    elseif label == "Building and grounds cleaning and maintenance"
        return "Service"
    end
end

dat_jobs[:Category] = map(x -> rename_category(x), dat_jobs[:Category])

# Read adjective-genders.csv into a Julia DataFrame
dat_adjectives = CSV.read("adjective-genders.csv",delim=';',nullable=false)

function barplot_adjectives()
    results_by_adjective = DataFrame(Adjective=[],Gender=[],Count=[],Ratio=[])

    for adjective in dat_adjectives[:Adjective]
        aux = dat_adjectives[ dat_adjectives[:,:Adjective] .== adjective, : ]
        
        female_count    = count(x -> x=="Female",   convert(Array,aux[:,3:end]))
        male_count      = count(x -> x=="Male",     convert(Array,aux[:,3:end]))
        neutral_count   = count(x -> x=="Neutral",  convert(Array,aux[:,3:end]))
        total           = count(x -> true,          convert(Array,aux[:,3:end]))
        ratio = male_count/female_count
        
        push!(results_by_adjective, [ucfirst(adjective),"Female",   100 * female_count    / total,  ratio])
        push!(results_by_adjective, [ucfirst(adjective),"Male",     100 * male_count      / total,  ratio])
        push!(results_by_adjective, [ucfirst(adjective),"Neutral",  100 * neutral_count   / total,  ratio])
    end

    CSV.write("Results/results-by-adjective.dat",results_by_adjective)

    sort!(results_by_adjective, cols = [order(:Ratio)])

    # Save bar plot
    p = plot(results_by_adjective, x=:Adjective, y=:Count, color=:Gender, Coord.Cartesian(ymin=0,ymax=100), Geom.bar(position=:stack), Theme(background_color="white",grid_color="gray",bar_highlight=colorant"black"), Guide.ylabel("\%"))
    draw(PDF("Paper/pictures/barplot-adjectives.pdf", 5inch, 3.75inch),p)
end

function histograms_occupations()
    # Compute results table (grouped by occupation, averaged among languages)
    results_by_occupation = DataFrame(Female=[],Male=[],Neutral=[],Category=[])
    for occupation in unique(dat_jobs[:Occupation])

        aux = dat_jobs[ dat_jobs[:,:Occupation] .== occupation, : ]

        female_count    = count(x -> x=="Female",   convert(Array,aux[1,3:end]))
        male_count      = count(x -> x=="Male",     convert(Array,aux[1,3:end]))
        neutral_count   = count(x -> x=="Neutral",  convert(Array,aux[1,3:end]))
        ratio           = male_count/female_count

        push!(results_by_occupation, [female_count,male_count,neutral_count,ucfirst(aux[1,:Category])])
    end

    CSV.write("Results/results-by-occupation.dat",results_by_occupation)

    # Save histograms
    p = plot(results_by_occupation, x=:Female, color=:Category, Guide.xlabel("\# Female Pronouns"), Geom.histogram, Theme(key_max_columns=1, key_label_font_size=6pt))
    draw(PDF("Paper/pictures/histogram-female-grouped.pdf", 5.0inch, 3.75inch),p)

    p = plot(results_by_occupation, x=:Male, color=:Category, Guide.xlabel("\# Male Pronouns"), Geom.histogram, Theme(key_max_columns=1, key_label_font_size=6pt))
    draw(PDF("Paper/pictures/histogram-male-grouped.pdf", 5.0inch, 3.75inch),p)

    p = plot(results_by_occupation, x=:Neutral, color=:Category, Guide.xlabel("\# Gender Neutral Pronouns"), Geom.histogram, Theme(key_max_columns=1, key_label_font_size=6pt))
    draw(PDF("Paper/pictures/histogram-neutral-grouped.pdf", 5.0inch, 3.75inch),p)
end

function barplots_category()
    # Compute results table (grouped by category)
    # Get list of occupation categories
    categories = unique(dat_jobs[:Category])
    results_by_category = DataFrame(Category=[],Gender=[],Count=[])
    for category in categories

        aux = dat_jobs[dat_jobs[:,:Category] .== category, 3:end]

        female_count    = count(x -> x=="Female",   convert(Array,aux[:,3:end]))
        male_count      = count(x -> x=="Male",     convert(Array,aux[:,3:end]))
        neutral_count   = count(x -> x=="Neutral",  convert(Array,aux[:,3:end]))
        total           = count(x -> true,          convert(Array,aux[:,3:end]))

        push!(results_by_category,[ucfirst(category),"Female",  round(100 * female_count    / total,3) ])
        push!(results_by_category,[ucfirst(category),"Male",    round(100 * male_count      / total,3) ])
        push!(results_by_category,[ucfirst(category),"Neutral", round(100 * neutral_count   / total,3) ])
    end

    CSV.write("Results/results-by-category.dat",results_by_category)

    # Save bar plot
    p = plot(results_by_category, x="Category", y="Count", color="Gender", Coord.Cartesian(ymin=0,ymax=100), Geom.bar(position=:stack), Theme(background_color="white",grid_color="gray",bar_highlight=colorant"black"), Guide.ylabel("\%"))
    draw(PDF("Paper/pictures/gender-by-category.pdf", 5inch, 3.75inch),p)
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

        push!(results_by_language,[language,"Female",   100 * female_count    / total  ])
        push!(results_by_language,[language,"Male",     100 * male_count      / total  ])
        push!(results_by_language,[language,"Neutral",  100 * neutral_count   / total  ])
    end

    CSV.write("Results/results-by-language.dat",results_by_language)

    # Save bar plot
    p = plot(results_by_language, x="Language", y="Count", color="Gender", Coord.Cartesian(ymin=0,ymax=100), Geom.bar(position=:stack), Theme(background_color="white",grid_color="gray",bar_highlight=colorant"black"), Guide.ylabel("\%"))
    draw(PDF("Paper/pictures/gender-by-language.pdf", 5inch, 3.75inch),p)
end

function a()

    # Read BLS data into a Julia DataFrame
    dat_BLS = CSV.read("jobs/bureau_of_labor_statistics_profession_list_gender_filtered_expanded.tsv", delim='\t', nullable=false, types=Dict(2=>String, 6=>String))

    dat_BLS = dat_BLS[dat_BLS[:,3] .!= "-",:]

    # Update columns 2 and 6 (from string) to numerical format
    dat_BLS[:,2] = map(x -> parse(Float64, replace(x,",","")), dat_BLS[:,2] )
    dat_BLS[:,3] = map(x -> parse(Float64, x), dat_BLS[:,3] )

    aux1 = copy(dat_BLS)
    aux2 = copy(dat_BLS)

    aux1[:,:Gender] = "Female"
    aux2[:,:Gender] = "Male"

    # Add new column "Women total", which is given by "total employed" x "women participation"
    aux1[:,:Count]  = dat_BLS[:,2] .* (dat_BLS[:,3]/100)
    aux2[:,:Count]  = dat_BLS[:,2] .* (1-dat_BLS[:,3]/100)

    #append!(aux1,aux2)

    p = plot(aux2, x=:Count, color=:Gender, Geom.histogram)
    draw(PDF("test.pdf", 5.0inch, 3.75inch), p)
end


#a()
#barplot_adjectives()
#histograms_occupations()
#barplots_category()
#barplots_language()

