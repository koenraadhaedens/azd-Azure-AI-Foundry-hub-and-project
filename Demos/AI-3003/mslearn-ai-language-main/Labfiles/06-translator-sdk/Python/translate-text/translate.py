from dotenv import load_dotenv
from datetime import datetime
import os


# Import namespaces
from azure.identity import DefaultAzureCredential
import azure.cognitiveservices.speech as speech_sdk

def main():
    try:
        global speech_config
        global translation_config

        # Get Configuration Settings
        load_dotenv()
        speech_region = os.getenv('TRANSLATOR_REGION')
        speech_resource_id = os.getenv('TRANSLATOR_ENDPOINT')

        # Get access token from managed identity
        credential = DefaultAzureCredential()
        token = credential.get_token('https://cognitiveservices.azure.com/.default')

        # Configure translation
        auth_token = 'aad#' + speech_resource_id + '#' + token.token
        translation_config = speech_sdk.translation.SpeechTranslationConfig(auth_token=auth_token, region=speech_region)
        translation_config.speech_recognition_language = 'en-US'
        translation_config.add_target_language('fr')
        translation_config.add_target_language('es')
        translation_config.add_target_language('hi')
        print('Ready to translate from',translation_config.speech_recognition_language)

       
        # Configure speech
        speech_config = speech_sdk.SpeechConfig(auth_token=auth_token, region=speech_region)
        print('Ready to use speech service in:', speech_config.region)

        # Get user input
        targetLanguage = ''
        while targetLanguage != 'quit':
            targetLanguage = input('\nEnter a target language\n fr = French\n es = Spanish\n hi = Hindi\n Enter anything else to stop\n').lower()
            if targetLanguage in translation_config.target_languages:
                Translate(targetLanguage)
            else:
                targetLanguage = 'quit'
                

    except Exception as ex:
        print(ex)

def Translate(targetLanguage):
    translation = ''

    # Translate speech


    # Synthesize translation



if __name__ == "__main__":
    main()
