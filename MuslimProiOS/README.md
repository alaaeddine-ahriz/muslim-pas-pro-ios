# Muslim Pro iOS

Une application iOS développée en Swift pour les musulmans, offrant plusieurs fonctionnalités essentielles:

- **Prières**: Affichage des heures de prière en fonction de la localisation
- **Coran**: Lecture du Coran en arabe et en français
- **Qibla**: Boussole indiquant la direction de la Mecque

## Fonctionnalités

### Prières
- Affichage des heures de prière basées sur la position actuelle
- Compte à rebours jusqu'à la prochaine prière
- Affichage de la date grégorienne et hégirienne

### Coran
- Liste complète des sourates
- Lecture des versets en français
- Fonction de recherche dans le Coran

### Qibla
- Boussole indiquant la direction de la Mecque
- Calcul précis de l'angle de la Qibla basé sur les coordonnées actuelles

## Prérequis

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## Installation

1. Clonez ce dépôt
```bash
git clone https://github.com/votre-nom/muslim-pro-ios.git
```

2. Ouvrez le fichier MuslimProiOS.xcodeproj dans Xcode

3. Sélectionnez un simulateur ou un appareil cible

4. Lancez l'application

## Configuration

L'application nécessite l'accès à la localisation pour fonctionner correctement. Lors du premier lancement, vous devrez autoriser l'accès à votre position.

## Architecture

L'application est construite avec:

- SwiftUI pour l'interface utilisateur
- Combine pour la gestion des états
- CoreLocation pour les fonctions de géolocalisation
- CoreMotion pour la boussole de la Qibla

## Structure du projet

```
MuslimProiOS/
├── MuslimProiOSApp.swift   # Point d'entrée de l'application
├── ContentView.swift       # Vue principale avec la TabView
├── Views/                  # Vues principales de l'application
│   ├── PrayerView.swift    # Vue des heures de prière
│   ├── QuranView.swift     # Vue du Coran
│   └── QiblaView.swift     # Vue de la boussole Qibla
└── Managers/               # Gestionnaires des fonctionnalités
    ├── LocationManager.swift  # Gestion de la localisation
    ├── ThemeManager.swift     # Gestion du thème (clair/sombre)
    ├── PrayerManager.swift    # Gestion des heures de prière
    ├── QuranManager.swift     # Gestion des sourates et versets
    ├── QiblaManager.swift     # Gestion de la boussole Qibla
    └── NetworkManager.swift   # Gestion des appels API
```

## Licence

Ce projet est distribué sous licence MIT. 