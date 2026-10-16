# Modul 04 – JFrog Artifactory: Images finden und herunterladen

## Kurzbeschreibung

Bei uns kommen Container-Images nicht direkt aus dem Internet, sondern über **JFrog Artifactory**. In diesem Modul lernst du, wie du ein benötigtes Image in Artifactory über **Packages** suchst, dir dort den Befehl zum Herunterladen holst und das Image anschließend nutzt.

## Lernziele

- erklären können, wozu wir JFrog Artifactory verwenden
- ein Image in Artifactory über **Packages** finden
- den Download-Befehl aus Artifactory übernehmen und das Image mit Podman herunterladen
- die Image-Adresse aus Artifactory in einem Deployment bzw. Helm-Chart verwenden

## Voraussetzungen

- Modul 01–03 abgeschlossen
- ein Benutzerkonto für JFrog Artifactory unter `https://dev-repos-prod-web.services.debeka.de/`

## Theorie (Kurzüberblick)

[JFrog Artifactory](https://jfrog.com/artifactory/) ist unser zentraler Speicher für Artefakte, z. B. Container-Images und Helm-Charts. Für dich bedeutet das:

- Images werden **nicht** direkt von Docker Hub geladen, sondern **über Artifactory**.
- Artifactory speichert eine Kopie (Cache). Dadurch geht der Download schneller, er funktioniert auch im Firmennetz, und die Images werden auf Sicherheitslücken geprüft.
- Die Image-Adresse ändert sich dabei. Statt `docker.io/library/nginx:stable` lautet sie z. B. `dev-repos-prod-web.services.debeka.de/<repository>/nginx:stable`.

Die richtige Adresse musst du dir nicht merken, denn Artifactory zeigt sie dir an.

## Aufgaben

### Aufgabe 1: Image in Artifactory suchen

**Ziel:** Das benötigte Image in Artifactory finden.

1. Melde dich unter `https://dev-repos-prod-web.services.debeka.de/` an.
2. Öffne links im Menü **Artifactory → Packages**.
3. Suche nach dem Image, das du brauchst, z. B. `nginx`. Wähle bei Bedarf als Pakettyp **Docker** aus.
4. Klicke auf das Paket und wähle die gewünschte **Version** (den Tag), z. B. `stable`.

### Aufgabe 2: Download-Befehl übernehmen und Image herunterladen

**Ziel:** Das Image mit dem Befehl aus Artifactory herunterladen.

1. In der Ansicht der Version zeigt Artifactory einen fertigen Befehl zum Herunterladen an, z. B.:

   ```text
   docker pull dev-repos-prod-web.services.debeka.de/<repository>/nginx:stable
   ```

2. Kopiere den Befehl. Wir verwenden Podman statt Docker, ersetze deshalb `docker` durch `podman`.

3. Lade das Image herunter und prüfe, ob es da ist:

   ```bash
   podman pull dev-repos-prod-web.services.debeka.de/<repository>/nginx:stable
   podman images
   ```

### Aufgabe 3: Image aus Artifactory im Cluster verwenden

**Ziel:** Das Image aus Artifactory statt von Docker Hub nutzen.

1. Übernimm die Image-Adresse aus Aufgabe 2, also alles hinter `podman pull`.
2. Trage sie in deine `values-lab.yaml` für das `azubi-portal`-Chart ein:

   ```yaml
   image:
     repository: dev-repos-prod-web.services.debeka.de/<repository>/nginx
     tag: stable
   ```

3. Führe ein Upgrade durch und prüfe, ob die Pods mit dem neuen Image laufen:

   ```bash
   helm upgrade azubi-portal ~/k8s-lab/azubi-portal-chart -n azubi-portal -f values-lab.yaml
   kubectl get pods -n azubi-portal
   kubectl describe pod -n azubi-portal -l app=azubi-portal | grep Image:
   ```

Falls die Pods mit `ImagePullBackOff` hängen bleiben, braucht der Cluster eigene Zugangsdaten. Frag in diesem Fall deinen Ausbilder nach einem technischen Benutzer und lege ein Pull-Secret an:

```bash
kubectl create secret docker-registry artifactory-pull -n azubi-portal \
  --docker-server=dev-repos-prod-web.services.debeka.de \
  --docker-username=<technischer-benutzer> \
  --docker-password=<token>
```

```yaml
imagePullSecrets:
  - name: artifactory-pull
```

## Du bist fertig, wenn …

- [ ] du ein Image in Artifactory über **Packages** finden kannst
- [ ] du ein Image mit dem Befehl aus Artifactory per `podman pull` heruntergeladen hast
- [ ] `azubi-portal` im Cluster mit einem Image aus Artifactory läuft

## Verständnisfragen

1. Warum laden wir Images über Artifactory und nicht direkt von Docker Hub?
2. Wie unterscheidet sich die Image-Adresse aus Artifactory von der Adresse auf Docker Hub?
3. Warum solltest du einen festen Tag (z. B. `1.27`) statt `latest` verwenden?

## Häufige Stolperfallen & Tipps

- **`unauthorized` beim Pull:** Du bist nicht angemeldet. Führe `podman login dev-repos-prod-web.services.debeka.de` aus.
- **`manifest unknown`:** Tag oder Image-Name sind falsch. Kopiere den Befehl am besten direkt aus Artifactory, statt ihn abzutippen.
- **`x509: certificate signed by unknown authority`:** Die Firmen-CA fehlt in WSL (siehe [docs/Troubleshooting.md](./docs/Troubleshooting.md)).
- **Image nicht gefunden:** Suche ohne Tag nur nach dem Namen (z. B. `nginx`) und achte auf den Pakettyp **Docker**.

## Weiterführend

- [JFrog Artifactory Dokumentation](https://jfrog.com/help/r/jfrog-artifactory-documentation)