#!/usr/bin/env python3

import subprocess
import requests
import time
import matplotlib.pyplot as plt
import numpy as np
from requests_toolbelt.multipart.encoder import MultipartEncoder  # pour créer un formulaire au format from-data
import concurrent.futures as cf
import random

form_cats = MultipartEncoder(fields={'vote': 'Cats'})
form_cats_s = form_cats.to_string()
form_dogs = MultipartEncoder(fields={'vote': 'Dogs'})
form_dogs_s = form_dogs.to_string()

res = []

def vote():
    for _ in range(0, 100):
        i = random.randint(0, 100)
        if i%2 == 0:
            vote = form_cats_s
            ct = form_cats.content_type
        else:   
            vote = form_dogs_s
            ct = form_dogs.content_type
        r = requests.post("http://votingapp-b4g4ld-rg.eastus.cloudapp.azure.com/", data=vote, headers={'Content-Type': ct})

        if not r.ok:
            print("Bad server response", r.status_code)
            continue

        print(r.headers['X-HANDLED-BY'])


with cf.ThreadPoolExecutor(8) as exc:
    futures = []
    for _ in range(0, 100):
        future = exc.submit(vote)
        futures.append(future)
        future = exc.submit(vote)
        futures.append(future)
        time.sleep(300)