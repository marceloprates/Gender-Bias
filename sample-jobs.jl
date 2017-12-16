
using DataFrames, CSV, StatsBase

dat = CSV.read("jobs.csv",delim=';',nullable=false)

for category in unique(dat[:Category])
    println("$category $( length(dat[ dat[:,:Category] .== category, :Occupation ]) )")
end

#=
n,m = 10,3
occupations = sample(dat[:Occupation],n*m,replace=false)

output = open("test.txt","w")
for i=1:n
    for j=1:m
        if j > 1
            print(output,"& $(occupations[m*(i-1)+j]) ")
        else
            print(output,"$(occupations[m*(i-1)+j]) ")
        end
    end
    println(output,"\\\\ \\hline")
end
close(output)
=#