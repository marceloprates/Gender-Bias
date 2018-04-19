
from googletrans import Translator
from googletrans import LANGUAGES
from xpinyin import Pinyin
import csv
import numpy as np

translator = Translator()
p = Pinyin()

# Get language list
languages = []
with open('languages.csv', 'r') as f:
    f.readline()
    for line in f:
    	language,family,pronomial_gender_system,supported = line.split(";")
    	if(pronomial_gender_system != 'Yes' and supported.rstrip() == 'Yes'):
    		languages.append(language)
#end with

# Define list of discarded languages
discarded_languages = ['Tagalog','English','Maithili','Oriya','Korean','Cantonese','Pipil','Quechuan','Esperanto','Ido','Lingua Franca Nova','Interlingua']

# Read job occupations list into table
table = np.array(list(csv.reader(open('jobs/bureau_of_labor_statistics_profession_list_gender_filtered_expanded.tsv','r'), delimiter='\t')))

# Compute list of categories
categories = list(set(table[1:,-3]))

# Get dictionary of category -> jobs (jobs per category)
categories_dict = dict([ (category, table[table[:,-3] == category,0]) for category in categories ])

"""
	Create a table with the translated version (provided by Google Translate) of each job,
	in the following structure:
		1. Each line corresponds to a single occupation
		2. The first column is the occupation category ("Computer and mathematical occupations", "Healthcare practitioners and technical occupations", etc.)
		3. The following N columns give a translated version of that occupation for each language (of N) in our list
"""
if False:
	with open("Results/jobs-translations.tsv","w") as output:
	
		# Write header
		# First column is category
		output.write("Category")
		# Then follows one column per language
		output.write("\tEnglish")
		for language in languages:
			output.write('\t' + language)
		#end for
		output.write('\n')
	
		# Not iterate over all categories
		for category in categories:
			print("Translating occupations from category {} ...".format(category))
			# Get all jobs for this category
			for job in categories_dict[category]:
				print("\tTranslating occupation \"{}\" ...".format(job))
				output.write(category)
				output.write('\t' + job)
				# For each language L in our list, translate 'job' from English to L
				for language in languages:
					try:
						if language == 'Chinese':
							translated_job = (translator.translate(job.rstrip().lower(),src='en',dest='zh-cn').text).lower()
						else:
							translated_job = (translator.translate(job.rstrip().lower(),src='en',dest=language).text).lower()
						#end if
					except Exception:
						print("\tCould not translate occupation %s to language %s" % (job.rstrip(),language))
						translated_job = "?"
					#end try
					output.write('\t' + translated_job)
				#end for
				output.write('\n')
			#end for
		#end for
	#end with
#end if

# Get table with one occupation for row, translated to every language (one per column)
translated_occupations = list(csv.reader(open('Results/jobs-translations.tsv','r'), delimiter='\t'))

# Define function to obtain the translated gender of an occupation in a given language (through Google Translate)
def get_gender(occupation,language,case=None):

	translation = ''

	if(language == 'Malay'):
		translation = translator.translate('dia adalah %s' % occupation, src=language, dest='en').text
	elif(language == 'Estonian'):
		translation = translator.translate('ta on %s' % occupation, src=language, dest='en').text
	elif(language == 'Finnish'):
		translation = translator.translate('hän on %s' % occupation, src=language, dest='en').text
	elif(language == 'Hungarian'):
		translation = translator.translate('ő egy %s' % occupation, src=language, dest='en').text
	elif(language == 'Armenian'):
		translation = translator.translate('նա %s է' % occupation, src=language, dest='en').text
	
	elif(language == 'Bengali'):
		if(case == 'HF'):
			translation = translator.translate('এ একজন %s' % occupation, src=language, dest='en').text
		elif(case == 'HP'):
			translation = translator.translate('যিনি একজন %s' % occupation, src=language, dest='en').text
		elif(case == 'TF'):
			translation = translator.translate('ও একজন %s' % occupation, src=language, dest='en').text
		elif(case == 'TP'):
			translation = translator.translate('উনি একজন %s' % occupation, src=language, dest='en').text
		elif(case == 'EF'):
			translation = translator.translate('সে একজন %s' % occupation, src=language, dest='en').text
		elif(case == 'EP'):
			translation = translator.translate('তিনি একজন %s' % occupation, src=language, dest='en').text

	elif(language == 'Japanese'):
		translation = translator.translate('あの人は%sです' % occupation, src=language, dest='en').text
	elif(language == 'Turkish'):
		translation = translator.translate('o bir %s' % occupation, src=language, dest='en').text
	elif(language == 'Yoruba'):
		translation = translator.translate('o jẹ %s' % occupation, src=language, dest='en').text
	elif(language == 'Basque'):
		translation = translator.translate('%s bat da' % occupation, src=language, dest='en').text
	elif(language == 'Swahili'):
		translation = translator.translate('yeye ni %s' % occupation, src=language, dest='en').text
	elif(language == 'Chinese'):
		translation = translator.translate('ta shi %s' % p.get_pinyin(occupation,''), src='zh-cn', dest='en').text

	translation = translation.lower()
	
	female_markers = ["she", "she's", "her"]
	male_markers = ["he", "he's", "his"]
	neuter_markers = ["it","it's","its","they","they're","them","who","this","that"]
	
	has_any = lambda markers, translation: any( [ marker.lower() in translation.lower().split() for marker in markers ] )

	if( has_any(female_markers, translation) or translation[0:10].find("that woman") != -1):
		return 'Female' # Suggestion: (1,0,0)
	elif( has_any(male_markers, translation) or translation[0:8].find("that man") != -1):
		return 'Male' # Suggestion: (0,1,0)
	elif( has_any(neuter_markers, translation) ):
		return 'Neutral' # Suggestion: (0,0,1)
	else:
		return '?'
#end def

"""
	Now create
"""
#discarded_languages = ['Bengali','Nepali','Korean']
with open('Results/job-genders.tsv','w') as output:

	# Write header
	output.write("Category")
	output.write("\tOccupation")
	for language in languages:
		if language not in discarded_languages:
			if language=='Bengali':
				for case in ['HF','HP','TF','TP','EF','EP']:
					output.write('\t' + language + '-' + case)
			else:
				output.write('\t' + language)
	#end for
	output.write('\n')

	for entry in translated_occupations[1:]:
		
		category 		= entry[0]
		english_name 	= entry[1]
		foreign_names 	= entry[2:]

		print("Translating occupation \"{}\" ...".format(english_name))

		output.write(category)
		output.write('\t' + english_name)

		for (language, foreign_name) in zip(languages, foreign_names):
			try:
				if language == 'Bengali':
					for case in ['HF','HP','TF','TP','EF','EP']:
						gender = get_gender(foreign_name,language,case)
						output.write('\t%s' % gender)
				else:
					gender = get_gender(foreign_name,language)
					output.write('\t%s' % gender)
			except ValueError:
				output.write('\t?')
			#end try
		#end for

		output.write('\n')
		output.flush()
	#end for

#end with



"""
For adjectives use the following templates:

	if(language == 'Malay'):
		translation = translator.translate('dia %s' % occupation, src=language, dest='en').text
	elif(language == 'Estonian'):
		translation = translator.translate('ta on %s' % occupation, src=language, dest='en').text
	elif(language == 'Finnish'):
		translation = translator.translate('hän on %s' % occupation, src=language, dest='en').text
	elif(language == 'Hungarian'):
		translation = translator.translate('ő %s' % occupation, src=language, dest='en').text
	elif(language == 'Armenian'):
		translation = translator.translate('նա %s է' % occupation, src=language, dest='en').text
	
	elif(language == 'Bengali'):
		if(case == 'HF'):
			translation = translator.translate('এ %s' % occupation, src=language, dest='en').text
		elif(case == 'HP'):
			translation = translator.translate('যিনি %s' % occupation, src=language, dest='en').text
		elif(case == 'TF'):
			translation = translator.translate('ও %s' % occupation, src=language, dest='en').text
		elif(case == 'TP'):
			translation = translator.translate('উনি %s' % occupation, src=language, dest='en').text
		elif(case == 'EF'):
			translation = translator.translate('সে %s' % occupation, src=language, dest='en').text
		elif(case == 'EP'):
			translation = translator.translate('তিনি %s' % occupation, src=language, dest='en').text

	elif(language == 'Japanese'):
		translation = translator.translate('あの人は%sです' % occupation, src=language, dest='en').text
		translation = translator.translate('あの人は%s' % occupation, src=language, dest='en').text
	elif(language == 'Turkish'):
		translation = translator.translate('o %s' % occupation, src=language, dest='en').text
	elif(language == 'Yoruba'):
		translation = translator.translate('o jẹ %s' % occupation, src=language, dest='en').text
	elif(language == 'Basque'):
		translation = translator.translate('%s da' % occupation, src=language, dest='en').text
	elif(language == 'Swahili'):
		translation = translator.translate('yeye ni %s' % occupation, src=language, dest='en').text
		translation = translator.translate('yeye %s' % occupation, src=language, dest='en').text
	elif(language == 'Chinese'):
		translation = translator.translate('ta hen %s' % p.get_pinyin(occupation,''), src='zh-cn', dest='en').text
"""
