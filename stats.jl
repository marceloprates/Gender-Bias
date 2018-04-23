
using DataFrames, CSV, Gadfly, Colors, HypothesisTests

# Function to count the # of occurences of a gender (among languages) within a table
function count_gender(gender, table)
    
    return count(x -> x==gender, convert(Array,table[:,3:7])) + round((1/6)*count(x -> x==gender, convert(Array,table[:,8:13]))) + count(x -> x==gender, convert(Array,table[:,14:end]))
end

function count_total(table)

    return count(x -> true, convert(Array,table[:,3:7])) + round((1/6)*count(x -> true, convert(Array,table[:,8:13]))) + count(x -> true, convert(Array,table[:,14:end]))
end

function get_tables()

    # Group results by category

    # Get a list of categories
    categories = convert(Array{String,1},unique(dat_jobs[:,:Category]))

    results_by_category = DataFrame(Category=[], Female=[], Male=[], Neutral=[])
    for category in categories

        # Query the table rows relative to this category
        category_filtered = dat_jobs[dat_jobs[:,:Category] .== category, :]

        female_count    = count_gender("Female",   category_filtered)
        male_count      = count_gender("Male",     category_filtered)
        neutral_count   = count_gender("Neutral",  category_filtered)
        total           = count_total(category_filtered)

        push!(results_by_category, [category, round(100*female_count/total,3), round(100*male_count/total,3), round(100*neutral_count/total,3)])
    end

    # Get "totals" row
    female_count    = count_gender("Female",   dat_jobs)
    male_count      = count_gender("Male",     dat_jobs)
    neutral_count   = count_gender("Neutral",  dat_jobs)
    total           = count_total(dat_jobs)
    push!(results_by_category, ["Total", round(100*female_count/total,3), round(100*male_count/total,3), round(100*neutral_count/total,3)])

    CSV.write("Results/results-by-category.dat",delim='\t',results_by_category)

    # Get a list of languages
    languages = vcat( names(dat_jobs)[3:7], "Bengali", names(dat_jobs)[14:end] )
    
    results_by_language = DataFrame(Language=[],Female=[],Male=[],Neutral=[])
    
    for language in languages
        if language == "Bengali"
            female_count    = 0
            male_count      = 0
            neutral_count   = 0
            total           = 0
            for case in ["HF","HP","TF","TP","EF","EP"]
                female_count    += count(x -> x=="Female",   dat_jobs[:,Symbol("Bengali-$(case)")])
                male_count      += count(x -> x=="Male",     dat_jobs[:,Symbol("Bengali-$(case)")])
                neutral_count   += count(x -> x=="Neutral",  dat_jobs[:,Symbol("Bengali-$(case)")])
                total           += count(x -> true,          dat_jobs[:,Symbol("Bengali-$(case)")])
            end

            push!(results_by_language,[language, round(100 * female_count / total,3), round(100 * male_count / total,3), round(100 * neutral_count / total,3)  ])
        else
            female_count    = count(x -> x=="Female",   dat_jobs[:,language])
            male_count      = count(x -> x=="Male",     dat_jobs[:,language])
            neutral_count   = count(x -> x=="Neutral",  dat_jobs[:,language])
            total           = count(x -> true,          dat_jobs[:,language])

            push!(results_by_language,[language, round(100 * female_count / total,3), round(100 * male_count / total,3), round(100 * neutral_count / total,3)  ])
        end
    end

    # Get a list of adjectives
    adjectives = convert(Array{String,1},unique(dat_adjectives[:,:Adjective]))
    
    results_by_adjective = DataFrame(Adjective=[],Female=[],Male=[],Neutral=[])
    
    for adjective in adjectives

        # Query the table rows relative to this adjective
        adjective_filtered = dat_adjectives[dat_adjectives[:,:Adjective] .== adjective, :]

        female_count    = count_gender("Female",   adjective_filtered)
        male_count      = count_gender("Male",     adjective_filtered)
        neutral_count   = count_gender("Neutral",  adjective_filtered)
        total           = count_total(adjective_filtered)

        push!(results_by_adjective, [adjective, round(100*female_count/total,3), round(100*male_count/total,3), round(100*neutral_count/total,3)])

    end

     # Get "totals" row
    female_count    = count_gender("Female",   dat_adjectives)
    male_count      = count_gender("Male",     dat_adjectives)
    neutral_count   = count_gender("Neutral",  dat_adjectives)
    total           = count_total(dat_jobs)
    push!(results_by_adjective, ["Total", round(100*female_count/total,3), round(100*male_count/total,3), round(100*neutral_count/total,3)])

    CSV.write("Results/results-by-adjective.dat",results_by_adjective)

end

function draw_histograms_occupations()
    
    results_by_occupation = DataFrame(Female=[],Male=[],Neutral=[],Category=[])
    results_by_occupation_dodged = DataFrame(Category=[],Gender=[],Count=[])
    for occupation in unique(dat_jobs[:Occupation])
        
        # Query the table row relative to this occupation
        occupation_filtered = dat_jobs[dat_jobs[:,:Occupation] .== occupation, :]

        # Get the category of this occupation
        category = ucfirst(occupation_filtered[1,:Category])

        female_count    = count_gender("Female",    occupation_filtered)
        male_count      = count_gender("Male",      occupation_filtered)
        neutral_count   = count_gender("Neutral",   occupation_filtered)

        push!(results_by_occupation, [female_count,male_count,neutral_count,category])

        push!(results_by_occupation_dodged, [category,"Female",  female_count])
        push!(results_by_occupation_dodged, [category,"Male",    male_count])
        push!(results_by_occupation_dodged, [category,"Neutral", neutral_count])
    end

    # Get a list of categories
    categories = convert(Array{String,1},unique(dat_jobs[:,:Category]))

    # Draw one histogram for each gender per category
    for category in categories

        # Query the table rows relative to this category
        category_filtered = results_by_occupation[results_by_occupation[:,:Category] .== category, :]
        category_filtered_dodged = results_by_occupation_dodged[results_by_occupation_dodged[:,:Category] .== category, :]

        # Draw a single "gender dodged" histogram with all 3 genders
        p = plot(
            category_filtered_dodged,
            x=:Count, color=:Gender,
            Guide.xlabel("\# Translated Pronouns (grouped among languages)"),
            Guide.ylabel("Occupations"),
            Geom.histogram(position=:dodge),
            Coord.Cartesian(xmax=12),
            Theme(key_max_columns=1, key_label_font_size=8pt, plot_padding=[1cm,1cm,1cm,1cm])
            )
        draw(PDF("Paper/pictures/histograms/categories/gender-dodged-$(category).pdf", 7.50inch, 5.625inch),p)
        
        # Draw a (non-dodged) histogram for each gender
        for gender in ["Female","Male","Neutral"]
            # Save histograms
            p = plot(
                category_filtered,
                x=Symbol(gender),
                Guide.xlabel("\# Translated $(gender) Pronouns (grouped among languages)"),
                Guide.ylabel("Occupations"),
                Geom.histogram(),
                Coord.Cartesian(xmax=12),
                Theme(key_max_columns=1, key_label_font_size=8pt, plot_padding=[1cm,1cm,1cm,1cm])
                )
            draw(PDF("Paper/pictures/histograms/categories/$(category)-$(gender).pdf", 7.50inch, 5.625inch),p)
        end
    end

    # Draw a an histogram with categories vertically stacked to compose histogram bars
    for gender in ["Female","Male","Neutral"]
        # Save histograms
        p = plot(
            results_by_occupation,
            x=Symbol(gender), color=:Category,
            Guide.xlabel("\# Translated $(gender) Pronouns (grouped among languages)"),
            Guide.ylabel("Occupations"),
            Geom.histogram(),
            Coord.Cartesian(xmax=12),
            Theme(key_max_columns=1, key_label_font_size=8pt, plot_padding=[1cm,1cm,1cm,1cm])
            )
        draw(PDF("Paper/pictures/histograms/all-categories-stacked-$(gender)$(grouped_categories ? "-grouped" : "").pdf", 7.50inch, 5.625inch),p)
    end

    # Draw a single histogram "gender dodged" histogram, grouped among all categories
    p = plot(
        results_by_occupation_dodged,
        x=:Count, color=:Gender,
        Guide.xlabel("\# Translated Pronouns (grouped among languages)"),
        Guide.ylabel("Occupations"),
        Geom.histogram(bincount=12, position=:dodge),
        Coord.Cartesian(xmax=12),
        Theme(key_max_columns=1, key_label_font_size=8pt, plot_padding=[1cm,1cm,1cm,1cm])
        )
    draw(PDF("Paper/pictures/histograms/all-categories-gender-dodged$(grouped_categories ? "-grouped" : "").pdf", 7.50inch, 5.625inch),p)

    # Draw one histogram for each gender, grouped among all categories
    for gender in ["Female","Male","Neutral"]
        # Save histograms
        p = plot(
            results_by_occupation,
            x=Symbol(gender),
            Guide.xlabel("\# Translated $(gender) Pronouns (grouped among languages)"),
            Guide.ylabel("Occupations"),
            Geom.histogram(),
            Coord.Cartesian(xmax=12),
            Theme(key_max_columns=1, key_label_font_size=8pt, plot_padding=[1cm,1cm,1cm,1cm])
            )
        draw(PDF("Paper/pictures/histograms/all-categories-$(gender)$(grouped_categories ? "-grouped" : "").pdf", 7.50inch, 5.625inch),p)
    end
end

###

function histograms_compare()
    # Read compare data file
    cpm_GT_real = CSV.read("Results/translate-real-histogram-data.tsv",delim='\t',nullable=false)
    # Save histograms
    # "GT_F/A"	"GT_F/(M+F)"	"BLS_Data"
    cpm_GT_real[:,2] *= 100
    p = plot(
        cpm_GT_real,
        x="12-quantile",
        y="Frequency (%)",
        color=:Data,
        Geom.bar(position=:dodge),
        Guide.xticks(ticks=[1:12;]),
        Theme(key_max_columns=1,key_label_font_size=6pt, key_position = :top, key_title_font_size=12pt, key_label_font_size=8pt))
    draw(PDF("Paper/pictures/histogram-compare-gt-real.pdf", 5.625inch, 5.625inch),p)
end

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

function histograms_occupations_per_category()

    # Get the top 10 most frequent categories
    all_categories = convert(Array{String,1},unique(dat_jobs[:,:Category]))
    top_categories = sort!( all_categories, by = x -> size(dat_jobs[dat_jobs[:,:Category] .== x, :])[1] )

    # Compute results table (grouped by occupation, summed among languages)
    results_by_occupation = DataFrame(Count=[], Gender=[], Category=[])
    for occupation in unique(dat_jobs[:Occupation])

        aux = dat_jobs[ dat_jobs[:,:Occupation] .== occupation, : ]

        female_count    = count(x -> x=="Female",   convert(Array,aux[1,3:7])) + round((1/6)*count(x -> x=="Female",   convert(Array,aux[1,8:13]))) + count(x -> x=="Female",   convert(Array,aux[1,13:end]))
        male_count      = count(x -> x=="Male",     convert(Array,aux[1,3:7])) + round((1/6)*count(x -> x=="Male",     convert(Array,aux[1,8:13]))) + count(x -> x=="Male",     convert(Array,aux[1,13:end]))
        neutral_count   = count(x -> x=="Neutral",  convert(Array,aux[1,3:7])) + round((1/6)*count(x -> x=="Neutral",  convert(Array,aux[1,8:13]))) + count(x -> x=="Neutral",  convert(Array,aux[1,13:end]))
        ratio           = male_count/female_count

        #push!(results_by_occupation, [female_count,male_count,neutral_count,ucfirst(aux[1,:Category])])
        push!(results_by_occupation, [female_count,  "Female",  ucfirst(aux[1,:Category])])
        push!(results_by_occupation, [male_count,    "Male",    ucfirst(aux[1,:Category])])
        push!(results_by_occupation, [neutral_count, "Neutral", ucfirst(aux[1,:Category])])
    end

    # Print one CDF for each one of the 10 most frequent categories
    for category in top_categories

        aux = results_by_occupation[results_by_occupation[:Category] .== category,:]
        
        # Save histograms
        p = plot(
                aux,
                x=:Count, color=:Gender,
                Guide.xlabel("\# Translated pronouns (grouped among languages)"), Guide.ylabel("Occupations"),
                Geom.histogram(position=:dodge, bincount=12),
                Coord.Cartesian(xmax=12),
                Theme(key_max_columns=1, key_label_font_size=8pt, plot_padding=[1cm,1cm,1cm,1cm])
            )
        draw(PDF("Paper/pictures/histograms-per-category$(grouped_categories ? "/grouped" : "/ungrouped")/$(category).pdf", 7.50inch, 5.625inch),p)
    end
end

function barplots_category()
    # Compute results table (grouped by category)
    # Get list of occupation categories
    categories = unique(dat_jobs[:Category])
    results_by_category = DataFrame(Category=[],Gender=[],Count=[],Male=[],Female=[],Neutral=[])
    for category in categories

        aux = dat_jobs[dat_jobs[:,:Category] .== category, 3:end]

        female_count    = count_gender("Female",aux)
        male_count      = count_gender("Male",aux)
        neutral_count   = count_gender("Neutral",aux)
        total           = count_total(aux)

        female_prob     = 100 * female_count / total
        male_prob       = 100 * male_count / total
        neutral_prob    = 100 * neutral_count / total

        push!(results_by_category,[ucfirst(category),"Neutral", neutral_prob, male_prob, female_prob, neutral_prob ])
        push!(results_by_category,[ucfirst(category),"Female",  female_prob, male_prob, female_prob, neutral_prob ])
        push!(results_by_category,[ucfirst(category),"Male",    male_prob, male_prob, female_prob, neutral_prob ])
    end

    sort!(results_by_category, cols=(:Male, :Female, :Neutral))

    # Save bar plot
    p = plot(
        results_by_category,
        x="Category", y="Count", color="Gender",
        Coord.Cartesian(ymin=0,ymax=100),
        Geom.bar(position=:stack),
        
        Theme(
            background_color="white",
            grid_color="gray",
            bar_highlight=colorant"black",
            bar_spacing=1mm,
            key_position = :right,
            key_title_font_size=12pt,
            key_label_font_size=8pt,
            plot_padding=[0pt,5mm,5mm,0pt]),
        
        Guide.ylabel("\%"),
        Guide.xticks(orientation=:vertical))
    draw(PDF("Paper/pictures/barplot-gender-by-category.pdf", 5.625inch, 5.625inch),p)
end

function barplots_language()
    # Get a list of languages
    languages = vcat( names(dat_jobs)[3:7], "Bengali", names(dat_jobs)[14:end] )
    
    results_by_language = DataFrame(Language=[],Gender=[],Count=[],Male=[],Female=[],Neutral=[])
    
    for language in languages
        if language == "Bengali"
            female_count    = 0
            male_count      = 0
            neutral_count   = 0
            total           = 0
            for case in ["HF","HP","TF","TP","EF","EP"]
                female_count    += count(x -> x=="Female",   dat_jobs[:,Symbol("Bengali-$(case)")])
                male_count      += count(x -> x=="Male",     dat_jobs[:,Symbol("Bengali-$(case)")])
                neutral_count   += count(x -> x=="Neutral",  dat_jobs[:,Symbol("Bengali-$(case)")])
                total           += count(x -> true,          dat_jobs[:,Symbol("Bengali-$(case)")])
            end

            female_prob     = 100 * female_count / total
            male_prob       = 100 * male_count / total
            neutral_prob    = 100 * neutral_count / total

            push!(results_by_language,[language,"Neutral",  neutral_prob, male_prob, female_prob, neutral_prob ])
            push!(results_by_language,[language,"Female",   female_prob, male_prob, female_prob, neutral_prob ])
            push!(results_by_language,[language,"Male",     male_prob, male_prob, female_prob, neutral_prob ])
        else
            female_count    = count(x -> x=="Female",   dat_jobs[:,language])
            male_count      = count(x -> x=="Male",     dat_jobs[:,language])
            neutral_count   = count(x -> x=="Neutral",  dat_jobs[:,language])
            total           = count(x -> true,          dat_jobs[:,language])

            female_prob     = 100 * female_count / total
            male_prob       = 100 * male_count / total
            neutral_prob    = 100 * neutral_count / total

            push!(results_by_language,[language,"Neutral",  neutral_prob, male_prob, female_prob, neutral_prob ])
            push!(results_by_language,[language,"Female",   female_prob, male_prob, female_prob, neutral_prob ])
            push!(results_by_language,[language,"Male",     male_prob, male_prob, female_prob, neutral_prob ])
        end
    end

    sort!(results_by_language, cols=(:Male, :Female, :Neutral))

    # Save bar plot
    p = plot(
        results_by_language,
        x="Language", y="Count", color="Gender",
        Coord.Cartesian(ymin=0,ymax=100),
        Geom.bar(position=:stack),
        Theme(
            background_color="white",
            grid_color="gray",
            bar_highlight=colorant"black",
            bar_spacing=1mm,
            key_position = :right,
            key_title_font_size=12pt,
            key_label_font_size=8pt,
            plot_padding=[0pt,5mm,5mm,0pt]),
        Guide.ylabel("\%"),
        Guide.xticks(orientation=:vertical))
    draw(PDF("Paper/pictures/barplot-gender-by-language.pdf", 5.625inch, 5.625inch),p)
end

function barplots_adjectives()
    results_by_adjective = DataFrame(Adjective=[],Gender=[],Count=[],Male=[],Female=[],Neutral=[])

    for adjective in dat_adjectives[:Adjective]
        aux = dat_adjectives[ dat_adjectives[:,:Adjective] .== adjective, : ]
        
        female_count    = count_gender("Female",    aux)
        male_count      = count_gender("Male",      aux)
        neutral_count   = count_gender("Neutral",   aux)
        total           = count_total(aux)
        ratio = male_count/female_count

        female_prob     = 100 * female_count / total
        male_prob       = 100 * male_count / total
        neutral_prob    = 100 * neutral_count / total
        
        push!(results_by_adjective, [ucfirst(adjective),"Neutral",  neutral_prob, male_prob, female_prob, neutral_prob ])
        push!(results_by_adjective, [ucfirst(adjective),"Female",   female_prob, male_prob, female_prob, neutral_prob ])
        push!(results_by_adjective, [ucfirst(adjective),"Male",     male_prob, male_prob, female_prob, neutral_prob ])
    end

    CSV.write("Results/results-by-adjective.dat",results_by_adjective)

    sort!(results_by_adjective, cols = (:Male, :Female, :Neutral))

    # Save bar plot
    p = plot(
        results_by_adjective,
        x=:Adjective, y=:Count, color=:Gender,
        Coord.Cartesian(ymin=0,ymax=100),
        Geom.bar(position=:stack),
        Theme(
            background_color="white",
            grid_color="gray",
            bar_highlight=colorant"black",
            bar_spacing=1mm,
            key_position = :right,
            key_title_font_size=12pt,
            key_label_font_size=8pt,
            plot_padding=[0pt,5mm,5mm,0pt]),
        Guide.ylabel("\%"))
    draw(PDF("Paper/pictures/barplot-adjectives.pdf", 5.625inch, 5.625inch),p)
end

function BLS_comparison()

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
    draw(PDF("test.pdf", 7.50inch, 5.625inch), p)
end

function heatmap_languages_categories()
    
    languages = vcat(names(dat_jobs)[3:7], :Bengali, names(dat_jobs)[14:end])
    categories = unique(dat_jobs[:,:Category])

    for gender in ["Female","Male","Neutral"]
        
        heatmap = Array{Tuple{Float64,String,String},2}(size(languages)[1], size(categories)[1])

        categories_order = Dict([ (category,count_gender(gender,dat_jobs[dat_jobs[:,:Category].==category,:])/count_total(dat_jobs[dat_jobs[:,:Category].==category,:])) for category in categories ])
        languages_order = Dict()

        for i = 1:size(languages)[1]
            for j = 1:size(categories)[1]
                h = 0
                if languages[i] == :Bengali
                    total = 0
                    for case in ["HF","HP","TF","TP","EF","EP"] 
                        h       += count(x -> x==gender, dat_jobs[ dat_jobs[:,:Category] .== categories[j], Symbol("Bengali-$(case)") ])
                        total   += count(x -> x=="Female" || x=="Male" || x=="Neutral", dat_jobs[ dat_jobs[:,:Category] .== categories[j], Symbol("Bengali-$(case)") ] )
                    end
                    h /= total
                else
                    h       = count(x -> x==gender, dat_jobs[dat_jobs[:,:Category] .== categories[j], languages[i]])
                    total   = count(x -> x=="Female" || x=="Male" || x=="Neutral", dat_jobs[ dat_jobs[:,:Category] .== categories[j], languages[i]])
                    h /= total
                end

                heatmap[i,j] = (h,string(languages[i]),string(categories[j]))
            end

            if languages[i] == :Bengali
                total = 0
                for case in ["HF","HP","TF","TP","EF","EP"] 
                    h       += count(x -> x==gender, dat_jobs[:,Symbol("Bengali-$(case)") ])
                    total   += count(x -> x=="Female" || x=="Male" || x=="Neutral", dat_jobs[:,Symbol("Bengali-$(case)") ] )
                end
                h /= total
            else
                h       = count(x -> x==gender, dat_jobs[:,languages[i]])
                total   = count(x -> x=="Female" || x=="Male" || x=="Neutral", dat_jobs[:,languages[i]])
                h /= total
            end

            languages_order[string(languages[i])] = h
        end

        # Sort heatmap rows (corresponding to languages)
        heatmap = sortrows(heatmap, by = x -> languages_order[x[1][2]] )

        # Now sort heatmap columns (corresponding to categories)
        heatmap = permutedims(heatmap, (2,1))
        heatmap = sortrows(heatmap, by = x -> categories_order[x[1][3]] )
        heatmap = permutedims(heatmap, (2,1))
        
        matrix = zeros(size(languages)[1], size(categories)[1])
        for i = 1:size(languages)[1]
            for j = 1:size(categories)[1]
                matrix[i,j] = 100*heatmap[i,j][1]
            end
        end
    
        p = spy(matrix,
            Scale.y_discrete(labels = i -> heatmap[i,1][2]),
            Scale.x_discrete(labels = i -> heatmap[1,i][3]),
            Guide.xticks(orientation=:vertical),
            Guide.ylabel("Language"),
            Guide.xlabel("Category"),
            Guide.colorkey(title="Probability"),
            #Scale.color_continuous(colormap=p->RGB(p,0.5*abs(0.5-p),1-p))
            )
        
        draw(PDF("Paper/pictures/heatmap-languages-categories-$(gender).pdf",5.625inch, 5.625inch), p)
    end
end

function statistical_tests()

    # Get a list of languages
    languages = vcat( names(dat_jobs)[3:7], Symbol("Bengali"), names(dat_jobs)[14:end] )

    # Get list of occupation categories
    categories = unique(dat_jobs[:Category])

    pvalues = DataFrame(Language=[], Category=[], MF=[], FM=[], MN=[], NM=[], NF=[], FN=[])

    for language in vcat(languages, [Symbol("Total")])
        for category in vcat(categories, [Symbol("Total")])

            # Filter by category (or not, if total)
            if category == :Total
                filtered = dat_jobs[:,:]
            else
                filtered = dat_jobs[dat_jobs[:,:Category].==category,:]
            end

            # Filter by language (or not, if total)
            if language == :Total
                filtered = convert(Array{String,2}, filtered[:,:])
                filtered = reshape(filtered, size(filtered)[1]*size(filtered)[2])
            elseif language == :Bengali
                filtered = convert(Array{String,2}, filtered[:,8:13])
                filtered = reshape(filtered, size(filtered)[1]*size(filtered)[2])
            else
                filtered = convert(Array{String,1}, filtered[:,language])
            end

            male    = map(x -> convert(Int64,x=="Male"), filtered)
            female  = map(x -> convert(Int64,x=="Female"), filtered)
            neutral = map(x -> convert(Int64,x=="Neutral"), filtered)

            p_MF = pvalue(OneSampleTTest(male,female,0),tail=:right)
            p_FM = pvalue(OneSampleTTest(male,female,0),tail=:left)
            p_MN = pvalue(OneSampleTTest(male,neutral,0),tail=:right)
            p_NM = pvalue(OneSampleTTest(male,neutral,0),tail=:left)
            p_NF = pvalue(OneSampleTTest(neutral,female,0),tail=:right)
            p_FN = pvalue(OneSampleTTest(neutral,female,0),tail=:left)

            push!(pvalues,[language,category,p_MF,p_FM,p_MN,p_NM,p_NF,p_FN])
        end
    end

    alpha = 0.005

    output = open("latex-pvalues-table.txt","w")
    for category in vcat(categories, [Symbol("Total")])
        print(output,"$(category)")
        for language in vcat(languages, [Symbol("Total")])

            if category == "Total" && language == "Total"
                print("\t\& -")
            else
                MF = convert(Float64,pvalues[ (pvalues[:,:Language] .== language) & (pvalues[:,:Category] .== category), :MF][1])
                FM = convert(Float64,pvalues[ (pvalues[:,:Language] .== language) & (pvalues[:,:Category] .== category), :FM][1])
                
                MN = convert(Float64,pvalues[ (pvalues[:,:Language] .== language) & (pvalues[:,:Category] .== category), :MN][1])
                NM = convert(Float64,pvalues[ (pvalues[:,:Language] .== language) & (pvalues[:,:Category] .== category), :NM][1])
                
                NF = convert(Float64,pvalues[ (pvalues[:,:Language] .== language) & (pvalues[:,:Category] .== category), :NF][1])
                FN = convert(Float64,pvalues[ (pvalues[:,:Language] .== language) & (pvalues[:,:Category] .== category), :FN][1])
                
                if NF < alpha
                    print(output,"\t\&\t\$<\\alpha\$")
                elseif FN < alpha
                    print(output,"\t\&\t\\cellcolor{blue!45}\$$(round(NF,3))\$")
                else
                    print(output,"\t\&\t\\cellcolor{blue!25}\$$(round(NF,3))\$")
                end
            end
        end
        print(output,"\t \\\\ \\hline \n")
    end
    close(output)
end

function draw_ECDFs()
  
    results_by_occupation = DataFrame(Female=[],Male=[],Neutral=[],Category=[])
    results_by_occupation_dodged = DataFrame(Category=[],Gender=[],Count=[])
    for occupation in unique(dat_jobs[:Occupation])
        
        # Query the table row relative to this occupation
        occupation_filtered = dat_jobs[dat_jobs[:,:Occupation] .== occupation, :]

        # Get the category of this occupation
        category = ucfirst(occupation_filtered[1,:Category])

        female_count    = count_gender("Female",    occupation_filtered)
        male_count      = count_gender("Male",      occupation_filtered)
        neutral_count   = count_gender("Neutral",   occupation_filtered)

        push!(results_by_occupation, [female_count,male_count,neutral_count,category])

        push!(results_by_occupation_dodged, [category,"Female",  female_count])
        push!(results_by_occupation_dodged, [category,"Male",    male_count])
        push!(results_by_occupation_dodged, [category,"Neutral", neutral_count])
    end

    # Get the top 10 most frequent categories
    all_categories = convert(Array{String,1},unique(dat_jobs[:,:Category]))
    top_categories = sort!( all_categories, by = x -> size(dat_jobs[dat_jobs[:,:Category] .== x, :])[1] )

    colors = linspace(convert(LCHuv, colorant"orange"), convert(LCHuv, colorant"sky blue"), 10)

    p = plot(ecdf( convert(Array{Float64,1},results_by_occupation[:,:Female]) ), 0, 12)
    for (category,color) in zip(top_categories,colors)

        category_filtered = results_by_occupation[ results_by_occupation[:,:Category] .== category, : ]

        push!(p.layers, 
            layer(
                ecdf(convert(Array{Float64,1},category_filtered[:,:Female])),
                0, 12,
                Theme(default_color=color)
                )[1])

    end

    draw(PDF("Paper/pictures/ecdf-Female.pdf", 7.50inch, 5.625inch),p)

end

grouped_categories = true

# Read job-genders.csv into a Julia DataFrame
dat_jobs = CSV.read("Results/job-genders.tsv",delim='\t',nullable=false)

# Remove "occupations" from the end of all category names
dat_jobs[:Category] = map(x -> replace(x," occupations",""),dat_jobs[:Category])

if grouped_categories
    # Group categories
    dat_jobs[:Category] = map(x -> group_categories(x), dat_jobs[:Category])
end

# Read adjective-genders.csv into a Julia DataFrame
dat_adjectives = CSV.read("Results/adj-genders.tsv",delim='\t',nullable=false)

#draw_histograms_occupations()
#heatmap_languages_categories()
#get_tables()
#barplots_category()
barplots_language()
barplots_adjectives()
#histograms_compare()
#statistical_tests()
#draw_ECDFs()