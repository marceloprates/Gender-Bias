# Gender Bias

## In an attempt to shed further light on the phenomenon of Machine Bias, this repository provides a self-contained set of data and code resources to analyze and visualize gender assymetries in the output of statistical machine translation.

## Recently there has been a certain amount

![Example](paper/pictures/screenshot-gtranslate-hungarian.png)

### A Python script (*script.py*) translates a list of occupations collected from the [U.S. Bureau of Labor Statistics](https://www.bls.gov/) into a set of selected gender-neutral languages, which is made available on TSV format in */Results/job-translations.tsv*. Each of these occupations is then inputed into a template to build a simple sentence ("He/She is a \<Occupation Name\>") in each of the selected languages, and this sentences are afterwards translated into English. This processes potentially translates the gender neutral pronoun of the source language into a gender specific English pronoun (He or She). The results are made available on TSV format in */Results/job-genders.tsv*.

### Collecting statistics about the gender ratio among different occupations grouped according to different categories helps uncover the extent of implicit gender stereotypes in statistical translation tools trained with real-world data. A Julia Gadfly script (*stats.jl*) can be used to generate visualizations of the translation data, such as (for example) histograms on the frequency of translated male, female and neutral gender pronouns for each occupation category.