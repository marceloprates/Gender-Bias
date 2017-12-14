
from googletrans import Translator
from xpinyin import Pinyin

translator = Translator()
p = Pinyin()

def get_gender(occupation,language):

	translation = ''

	if(language == 'Malay'):
		translation = translator.translate('dia adalah %s' % occupation, src=language, dest='en').text
	elif(language == 'Estonian'):
		translation = translator.translate('ta on %s' % occupation, src=language, dest='en').text
	elif(language == 'Finnish'):
		translation = translator.translate('hän on %s' % occupation, src=language, dest='en').text
	elif(language == 'Hungarian'):
		translation = translator.translate('ő %s' % occupation, src=language, dest='en').text
	elif(language == 'Armenian'):
		translation = translator.translate('նա %s է' % occupation, src=language, dest='en').text
	#else if(language == 'Bengali'):
	#	translation = translator.translate('dia adalah %s' % occupation,dest='en').text
	#else if(language == 'Nepali'):
	#	translation = translator.translate('dia adalah %s' % occupation,dest='en').text
	elif(language == 'Japanese'):
		translation = translator.translate('は %s です' % occupation, src=language, dest='en').text
	#elif(language == 'Korean'):
	#	translation = translator.translate('그는 %s' % occupation, src=language, dest='en').text
	elif(language == 'Turkish'):
		translation = translator.translate('o bir %s' % occupation, src=language, dest='en').text
	elif(language == 'Yoruba'):
		translation = translator.translate('o jẹ %s' % occupation, src=language, dest='en').text
	elif(language == 'Basque'):
		translation = translator.translate('%s da' % occupation, src=language, dest='en').text
	elif(language == 'Swahili'):
		translation = translator.translate('yeye ni %s' % occupation, src=language, dest='en').text
	elif(language == 'Chinese'):
		translation = translator.translate('ta %s' % p.get_pinyin(occupation,''), src='zh-cn', dest='en').text

	translation = translation.lower()

	if(translation[0:4].find("she") != -1 or translation[0:4].find("she's") != -1 or translation[0:4].find("her") != -1):
		return 'Female'
	elif(translation[0:4].find("he") != -1 or translation[0:4].find("he's") != -1 or translation[0:4].find("his") != -1):
		return 'Male'
	else:
		return 'Neutral'

with open('jobs.csv','r') as jobs:
	with open('job-genders-2.csv','w') as output:

		languages = list(map(lambda x: x.rstrip(), jobs.readline().split(';')[2:]))
		discarded_languages = ['Bengali','Nepali','Korean']

		# Write header
		output.write('category')
		output.write(';English')
		output.write('\n')
		for language in languages:
			if language not in discarded_languages:
				output.write(';%s' % language)
	
		# For each job, translate into each language and fetch the corresponding gender
		for line in jobs:
			category = line.split(';')[0]
			english_name = line.split(';')[1]
			foreign_names = list(map(lambda x: x.rstrip(), line.split(';')[2:]))

			output.write('%s' % category)
			output.write(';%s' % english_name)
	
			for (language,occupation) in zip(languages,foreign_names):
				if(language not in discarded_languages):
					try:
						gender = get_gender(occupation,language)
						output.write(';%s' % gender)
					except ValueError:
						output.write(';?')

			output.write('\n')