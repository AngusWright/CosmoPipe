  #!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import argparse
import numpy as np
import requests
import base64

# Function to read the input catalogue and convert it to base64
def encode_to_base64(file_path):
    with open(file_path, "rb") asfile:
        return base64.b64encode(file.read()).decode('utf-8')


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--data', type=str, help='Path to datafiles', default='', required=True)
    parser.add_argument('--api_key', type=str, help='ChatGPT api key', default='', required=True)
    args = parser.parse_args()

    data = args.data
    api_key = args.api_key
    
    if api_key is '':
        raise ValueError('OpenAI API key is not set!')
        
    encoded_data = encode_image_to_base64(data)
    
    question = 'Plese analyse this catalogue of galaxies like in the paper from Wrigth et al. 2025 and write the whole scientific paper!'
    
    # This line is for providing base line instructions for any answer
    rule_instructions = 'You are a postdoctoral researcher, apply all the necessary scientific steps, report statistics, and create relevant figures.'
    
    headers = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {api_key}'
    }
    
    payload = {
    'model': 'gpt-4o-mini',
    'messages': [
        {'role': 'system', 'content': f'{rule_instructions}.'},
        {
        'role': 'user',
        'content': [
            {
            'type': 'text',
            'text': f'{question}'
            },
            {
            'type': 'file',
            'file': {
                'filename': f'{data}',
                'file_data': f'{encoded_data}'
                }
            }
        ]
        }
    ],
    'max_tokens': 300
    }
    
    response = requests.post('https://api.openai.com/v1/chat/completions', headers=headers, json=payload)
    # Extracting the message content
    message_content = response_dict['choices'][0]['message']['content']
    
    # Printing the message
    print('AI Response Message:')
    print(message_content)
    
    message=response['choices[0].message']
    
    usage_info = response['usage']
    
    print('Usage Information:')
    print(f"Prompt Tokens: {usage_info['prompt_tokens']}")
    print(f"Completion Tokens: {usage_info['completion_tokens']}")
    print(f"Total Tokens: {usage_info['total_tokens']}")
    
