
from googletrans import Translator
from googletrans import LANGUAGES
translator = Translator()

# Get language list
languages = []
with open('languages.csv', 'r') as f:
    f.readline()
    for line in f:
    	language,family,pronomial_gender_system,supported = line.split(";")
    	if(pronomial_gender_system != 'Yes' and supported.rstrip() == 'Yes'):
    		languages.append(language)

# Initialize job categories list
job_categories = ["artistic","computer","corporate","dance","film-television","healthcare","science","service","theatre","writing"]

with open('jobs.csv', 'w') as output:

	output.write('category')
	output.write(';english')
	for language in languages:
		output.write(';' + language)
	output.write('\n')

	for category in job_categories:
		print('Category: %s' % category)
		with open('jobs/%s-jobs-english.txt' % category,'r') as jobs:
			i = 0
			for job in jobs:
				print('Occupation: %s' % job.rstrip())
				translations = []
				for language in languages:
					try:
						if language == 'Chinese':
							translated_job = (translator.translate(job.rstrip().lower(),src='en',dest='zh-cn').text).lower()
							translations.append(translated_job)
						else:
							translated_job = (translator.translate(job.rstrip().lower(),src='en',dest=language).text).lower()
							translations.append(translated_job)
					except Exception:
						print("Could not translate occupation %s to language %s" % (job.rstrip(),language))
						translations.append("?")

				output.write(category)
				output.write(';'+job.rstrip().lower())
				for translation in translations:
					output.write(';'+translation)
				output.write('\n')