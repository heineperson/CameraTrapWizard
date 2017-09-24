# -*- coding: utf-8 -*-
"""
Created on Sat Sep 23 10:47:39 2017

@author: Obelix
"""
import numpy as np
import pandas as pd
import os
from watson_developer_cloud import VisualRecognitionV3 as vr

instance = vr(api_key='0c8b4616e514d148fa5d12f0be8c728b2fa23e7a', version='2016-05-20')

"""Important Directories"""
test_dir = 'C:/Users/Obelix/Documents/Vachan_documents/Projects/ZooHackathon2K17/test_sample'
thepics = 'Zoohackathon2017_SamplePhotos/'

my_df = pd.DataFrame()

"""test bulk reading of files"""
os.chdir('Zoohackathon2017_SamplePhotos/')
directory = os.fsencode('./')


for file in os.listdir(directory):
    filename = os.fsdecode(file)
    filename = filename.lower()

    if filename.endswith(".jpg") or filename.endswith(".jpeg"):
        print(filename)
        img_dict = instance.classify(images_file= open(filename, 'rb'))
        
        a_df = pd.DataFrame(img_dict['images'][0]['classifiers'][0]['classes'])
        a_df.insert(loc=0, column='Filename', value=filename)
        
        my_df = pd.concat([my_df, a_df])
    
print(my_df)   
my_df.to_csv('IBM_Watson_results.csv', index=False)