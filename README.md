
IL N'Y A PAS DE CHANGE LOG POUR LES VERSION 6 ET ANTÉRIEUR.
LA VERSION 6 EST LA PREMIÈRE PROD DE LA MISSION OPERATION ANGRY VIKINGS



v.7
REMPLACEMENT DE LA LOGIQUE D'APPEL DES .LUA POUR FACILITÉ LA GESTION ENTRE LES PROD ET LES DEV.
PROD LES .LUA SONT À MÊME LE .MIZ. POUR DEV LES LUA SONT RÉFÉRENCÉ, UN FLAG SERA UTILISÉ POUR IDENTIFIER L'INSTANCE DE LA MISSION
0 = PROD
1 = QA
2 = DEV

- ménage dans les menu et meilleure structure
- ajustement des message de spawn pour les exclure de la prod



v.8
- ajout de mig-25 en interception de fighter dans l'ouest de la map.
- ajout de F-16 bleu en patrouile
- correction de la logique de spawn des Su-27 qui évaluait mal la présence de F-14 dans le ciel.
- ménage dans les menus radio
- ajustement des waypoint des F-14 et conversion de leur rôle de intercept à CAP
- séparation des duo de su-27 et su-25 pour faire des respawn plus dynamique au cas où un des wingman est endommagé il fallait attendre sa fin avant que le respawn recommence.

v.9
- ajout d'une fonction de générateur de template de spawn

v.10
- Ajout de Tu-160 qui lancent des cruises missile sur Jokkmokk
- Ajout de Su-30 qui tentent de faire du air superiority à partir de Kuusamo
- ajout de SAM Site dans la zone russe
- Kirkenes est rendu russe et un sam site y est placé


v.11

- Ajout de huey à Kalixfors pour fabriquer des sam site sur la trajectoire des cruise missile -not tested
- ajout de 2 drop zone près de Kalixfors -not tested
- Ajout de beacon dans les 2 dropzone, freq 51MHz et 55MHz pour zone 1 et 2
- Ajout d'une patrouille AH-64 près de Kalixfors 
- SAM Site de Kirkenes respanable, 900sec cooldown. Sera un objectif SEAD/DEAD éventuellement.
- CVN-75, ROE Weapon Free.
- ajout d'un flight de Mi-24 qui attaque Banak, pour le show ne cause pas de dommage dans l'attaque selon les tests.

v.11.1
- Fix du logistic site de Kalixfors, typo dans le nom des units logistic
- déplacement de la SAM zone 1 pour la mettre sur le top de la montagne 

v.12
- fix du pointage des bleus pour abattre les cruise missile Kh-65 et Kh-22. la détection des kill ne fonctionnait pas.
- ajout de chinook qui supply kalixfor en troupes
- ajout de gazelles qui patrouille la route des chinook avec des fox 2

v. 13.
- Ajout de frappe d'artillerie sur Ivalo à partir de la zone russe
- ajustement des mécaniques de rearming


v. 14
- plus de tuning à la foinction de rearming, devrait pouvoir fonctionner avec n'importe quelle unit et avec fonction pour commencer et arrêter le rearming. (En gros ça fait respawn les units près du supply unit)
- ajout d'un strike bleu pour attaquer l'ammo depot des artillery

v. 15
- ajustement de la logique de spawn des Su-30 de Kuusamo, ils ne vont spawner que si la frontière russe est franchit (ou presque) par des avion bleus
- ajout de f-14 estétique sur le CVN-75.


v. 16
- ajout de plusiers condition pour limiter le spam dans le log pour la version de prod et QA
- ajout du CVN-73 pour les joueurs et éviter des problèmes avec les AIs sur le CVN-75
- ajout d'hélico qui suivent les carriers
- séparation de la frontière rouge en 2 zones, nord et sud, pour gérer les spawn de Su-30, un groupe sud à Kuusamo et un groupe nord à Kirkenes
- ajout de chinook client à Kiruna
- détruire un Seawise Giant donne maintenant +200 pts aux bleus

