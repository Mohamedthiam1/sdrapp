# sdr

A new Flutter project.

## Getting Started

Bienvenue dans SDR, un projet Flutter de visualisation et de surveillance en temps réel de ruches instrumentées. 
Ce projet a pour but de permettre une analyse comportementale automatique des abeilles à partir de données IoT : température, activité d’entrée/sortie et spectre sonore.

**# Données surveillées**

Chaque ruche est surveillée à l’aide des capteurs suivants :

1. Température (°C)
2. Entrées / Sorties (abeilles)
3. Activité Totale
4. Spectre sonore (liste de double)

1. Température anormale

   **Condition	            Alerte	                   Risque**
   
   Température < 10°C	    Température trop basse	   Ruche inactive ou en danger
   Température > 40°C	    Température trop élevée	   Risque de surchauffe

2. Activité d’entrée/sortie incohérente

   **Condition	                 Alerte                              	Risque**
  
   total == 0	                 Aucune activité détectée             	Ruche morte ou capteur HS
   out ≥ 90% de total	         Abeilles massivement sorties	        Perturbation externe (panique, prédateur...)
   in > 0 && out == 0	         Entrées sans sorties	                Blocage ou problème à la sortie

3. Spectre sonore anormal

   **Condition	                 Alerte	                   Risque**

   max(spectre) > 0.9	         Pics sonores élevés	   Agitation ou bruit anormal
   moyenne(spectre) < 0.05	     Son très faible	       Silence anormal, ruche peut-être affaiblie
   spectre vide ou absent	     Données absentes	       Capteur audio défaillant

Développé par **Mohamed Thiam**