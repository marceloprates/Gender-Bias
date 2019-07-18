# Gender Bias

## In an attempt to shed further light on the phenomenon of Machine Bias, this repository provides a self-contained set of data and code resources to analyze and visualize gender assymetries in the output of statistical machine translation.

![Example](figures/gtranslate-screenshot-hungarian-portuguese.png)

Recently there has been a growing concern about machine bias, where trained statistical models grow to reflect controversial societal asymmetries, such as gender or racial bias. A significant number of AI tools have recently been suggested to be harmfully biased towards some minority, with reports of racist criminal behavior predictors, Iphone X failing to differentiate between two Asian people and Google photos' mistakenly classifying black people as gorillas. Although a systematic study of such biases can be difficult, we believe that automated translation tools can be exploited through gender neutral languages to yield a window into the phenomenon of gender bias in AI.
In this paper, we start with a comprehensive list of job positions from the U.S. Bureau of Labor Statistics (BLS) and used it to build sentences in constructions like "He/She is an Engineer" in 12 different gender neutral languages such as Hungarian, Chinese, Yoruba, and several others. We translate these sentences into English using the Google Translate API, and collect statistics about the frequency of female, male and gender-neutral pronouns in the translated output. We show that GT exhibits a strong tendency towards male defaults, in particular for fields linked to unbalanced gender distribution such as STEM jobs. We ran these statistics against BLS' data for the frequency of female participation in each job position, showing that GT fails to reproduce a real-world distribution of female workers. We provide experimental evidence that even if one does not expect in principle a 50:50 pronominal gender distribution, GT yields male defaults much more frequently than what would be expected from demographic data alone.
We are hopeful that this work will ignite a debate about the need to augment current statistical translation tools with debiasing techniques which can already be found in the scientific literature. 

A Python script (*script.py*) translates a list of occupations collected from the [U.S. Bureau of Labor Statistics](https://www.bls.gov/) into a set of selected gender-neutral languages, which is made available on TSV format in */Results/job-translations.tsv*. Each of these occupations is then inputed into a template to build a simple sentence ("He/She is a \<Occupation Name\>") in each of the selected languages, and this sentences are afterwards translated into English. This processes potentially translates the gender neutral pronoun of the source language into a gender specific English pronoun (He or She). The results are made available on TSV format in */Results/job-genders.tsv*.

Collecting statistics about the gender ratio among different occupations grouped according to different categories helps uncover the extent of implicit gender stereotypes in statistical translation tools trained with real-world data. A Julia Gadfly script (*stats.jl*) can be used to generate visualizations of the translation data, such as (for example) histograms on the frequency of translated male, female and neutral gender pronouns for each occupation category.
