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

# x = le temps
# y = nombres de réponses

url = "http://votingapp-b4g4ld-rg.eastus.cloudapp.azure.com/"

# Création des formulaires
form_cats = MultipartEncoder(fields={'vote': 'Cats'})
form_dogs = MultipartEncoder(fields={'vote': 'Dogs'})

form_cats_s = form_cats.to_string()
form_dogs_s = form_dogs.to_string()

first_instance_id = ""

lines = defaultdict(list) # Contient les données des courbe

instances = Counter() # Contient les données à afficher pour la prochaine seconde (se clear à chaque utilisation)
instances_l = threading.Lock()

offset = defaultdict(list) # Contient le décalage de chaque courbes

def update_graph(_): # Chaque seconde
    # Création de la courbe
    plt.cla()
 
    with instances_l:
        for k, v in instances.items():
            lines[k].append(v)
        instances.clear()
        
    for instance in lines:
        indexes = list(range(len(lines[instance])))
        
        print(instance, lines[instance])
        
        if offset[instance] == []:
            offset[instance] = (len(lines[first_instance_id]) - len(lines[instance]))

        shifted_values = [0] * offset[instance] 
        shifted_values.extend(lines[instance])

        plt.plot(list(range(len(shifted_values))), shifted_values, label = instance, linestyle="-")

def vote():
    global first_instance_id
    
    for _ in range(0, 100):
        # Génération d'un vote aléatoire
        i = random.randint(0, 100)
        
        if i % 2 == 0:
            vote = form_cats_s
            ct = form_cats.content_type
        else:   
            vote = form_dogs_s
            ct = form_dogs.content_type
        
        r = requests.post(url, data=vote, headers={'Content-Type': ct})

        if not r.ok:
            print("Bad server response", r.status_code)
            continue
        
        container_id = r.headers['X-HANDLED-BY']
        
        if first_instance_id == "":
            first_instance_id = container_id
        
        with instances_l:
            instances[container_id] += 1
       
def loadtest(exc):
    futures = []
    for _ in range(0, 100):
        future = exc.submit(vote)
        futures.append(future)
        future = exc.submit(vote)
        futures.append(future)
        time.sleep(3)

with cf.ThreadPoolExecutor(9) as exc:
    # Création d'un thread séparé pour le loadtest
    exc.submit(loadtest, exc)
    
    # Lancement de l'animation
    ani = FuncAnimation(plt.gcf(), update_graph, 1000)
    plt.tight_layout()
    plt.show()