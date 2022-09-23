#!/usr/bin/env python3

import subprocess
import requests
import time
import matplotlib.pyplot as plt
import numpy as np
from requests_toolbelt.multipart.encoder import MultipartEncoder  # pour créer un formulaire au format from-data
import concurrent.futures as cf
import random
from matplotlib.animation import FuncAnimation
from itertools import count
from collections import defaultdict, Counter
from datetime import datetime as dt
import threading

form_cats = MultipartEncoder(fields={'vote': 'Cats'})
form_cats_s = form_cats.to_string()
form_dogs = MultipartEncoder(fields={'vote': 'Dogs'})
form_dogs_s = form_dogs.to_string()

x = [] # le temps
y = [] # nombres de réponses

res = []

lines = defaultdict(list)

instances = Counter()
instances_l = threading.Lock()


def update_graph(_):
    global index
    
    # Création de la courbe
    plt.cla()
 
    with instances_l:
        for k, v in instances.items():
            lines[k].append(v)
        instances.clear()

    for instance in lines:
        indexes = list(range(len(lines[instance])))
        plt.plot(indexes, lines[instance], label = instance, linestyle="-.")

def vote():
    for _ in range(0, 100):
        i = random.randint(0, 100)
        
        if i % 2 == 0:
            vote = form_cats_s
            ct = form_cats.content_type
        else:   
            vote = form_dogs_s
            ct = form_dogs.content_type
        
        r = requests.post("http://votingapp-b4g4ld-rg.eastus.cloudapp.azure.com/", data=vote, headers={'Content-Type': ct})

        if not r.ok:
            print("Bad server response", r.status_code)
            continue
        
        # Enregistrement de la réponse
        container_id = r.headers['X-HANDLED-BY']
        
        print(container_id)

        
        with instances_l:
            instances[container_id] += 1

def test_charge(exc):
    futures = []
    for _ in range(0, 100):
        future = exc.submit(vote)
        futures.append(future)
        future = exc.submit(vote)
        futures.append(future)
        time.sleep(3)


with cf.ThreadPoolExecutor(9) as exc:
    # Création d'un thread séparé
    exc.submit(test_charge, exc)
    
    # Lancement de l'animation
    ani = FuncAnimation(plt.gcf(), update_graph, 1000)
    plt.tight_layout()
    plt.show()