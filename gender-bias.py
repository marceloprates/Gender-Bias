
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
discarded_languages = ['Nepali','Tagalog','English','Maithili','Oriya','Korean','Cantonese','Pipil','Quechuan','Esperanto','Ido','Lingua Franca Nova','Interlingua']

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
def get_gender(language, occupation=None, adjective=None, case=None):

	occupation_dict = dict()
	occupation_dict['Malay'] 		= 'dia adalah %s'
	occupation_dict['Estonian'] 	= 'ta on %s'
	occupation_dict['Finnish']		= 'hän on %s'
	occupation_dict['Hungarian'] 	= 'ő egy %s'
	occupation_dict['Armenian']		= 'նա %s է'
	occupation_dict['Bengali-HF']	= 'এ একজন %s'
	occupation_dict['Bengali-HP']	= 'যিনি একজন %s'
	occupation_dict['Bengali-TF']	= 'ও একজন %s'
	occupation_dict['Bengali-TP']	= 'উনি একজন %s'
	occupation_dict['Bengali-EF']	= 'সে একজন %s'
	occupation_dict['Bengali-EP']	= 'তিনি একজন %s'
	occupation_dict['Japanese']		= 'あの人は%sです'
	occupation_dict['Turkish']		= 'o bir %s'
	occupation_dict['Yoruba']		= 'o jẹ %s'
	occupation_dict['Basque']		= '%s bat da'
	occupation_dict['Swahili']		= 'yeye ni %s'
	occupation_dict['Chinese']		= 'ta shi %s'

	adjective_dict = dict()
	adjective_dict['Malay'] 		= 'dia %s'
	adjective_dict['Estonian'] 		= 'ta on %s'
	adjective_dict['Finnish']		= 'hän on %s'
	adjective_dict['Hungarian'] 	= 'ő %s'
	adjective_dict['Armenian']		= 'նա %s է'
	adjective_dict['Bengali-HF']	= 'এ %s'
	adjective_dict['Bengali-HP']	= 'যিনি %s'
	adjective_dict['Bengali-TF']	= 'ও %s'
	adjective_dict['Bengali-TP']	= 'উনি %s'
	adjective_dict['Bengali-EF']	= 'সে %s'
	adjective_dict['Bengali-EP']	= 'তিনি %s'
	adjective_dict['Japanese']		= 'あの人は%sです'
	adjective_dict['Turkish']		= 'o %s'
	adjective_dict['Yoruba']		= 'o jẹ %s'
	adjective_dict['Basque']		= '%s da'
	adjective_dict['Swahili']		= 'yeye ni %s'
	adjective_dict['Chinese']		= 'ta hen %s'

	if occupation is not None:
		if language == 'Bengali':
			phrase = occupation_dict['Bengali-%s' % case] % occupation
		else:
			phrase = occupation_dict[language] % occupation
		#end if
	elif adjective is not None:
		if language == 'Bengali':
			phrase = adjective_dict['Bengali-%s' % case] % adjective
		else:
			phrase = adjective_dict[language] % adjective
		#end if
	else:
		raise Exception("Neither and occupation nor an adjective has been provided")
	#end if

	translation = translator.translate(phrase, src=language, dest='en').text
	translation = translation.lower()

	print("Language: {} | Phrase: {} | Translation: {}".format(language, phrase, translation))
	
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
			if language not in discarded_languages:
				try:
					if language == 'Bengali':
						for case in ['HF','HP','TF','TP','EF','EP']:
							gender = get_gender(language, occupation=foreign_name, case=case)
							output.write('\t%s' % gender)
					else:
						gender = get_gender(language, occupation=foreign_name)
						output.write('\t%s' % gender)
				except ValueError:
					output.write('\t?')
				#end try
			#end if
		#end for

		output.write('\n')
		output.flush()
	#end for
#end with