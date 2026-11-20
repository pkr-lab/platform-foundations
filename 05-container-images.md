# Modul 05 – Container-Images bauen

## Kurzbeschreibung

Bisher hast du nur fertige Images verwendet. In diesem Modul baust du mit Podman ein **eigenes Image** für `azubi-portal`: Du schreibst ein `Containerfile`, verstehst Layer und Build-Cache, achtest darauf, dass das Image nicht als root läuft, und lädst es ins Artifactory hoch. Am Ende läuft `azubi-portal` im Cluster mit deinem eigenen Image.

## Lernziele

- den Aufbau eines `Containerfile` (bzw. `Dockerfile`) verstehen und eigene schreiben
- Images mit `podman build` bauen, taggen und mit `podman history`/`podman inspect` untersuchen
- Layer und Build-Cache erklären und die Reihenfolge der Anweisungen bewusst wählen
- Images bauen, die als normaler Benutzer laufen
- Build-Argumente und Multi-Stage-Builds einsetzen
- ein eigenes Image ins Artifactory pushen und im Cluster verwenden

## Voraussetzungen

- Modul 01–04 abgeschlossen
- `azubi-portal` läuft als Helm-Release mit dem Pull-Secret `artifactory-pull` (Modul 04)
- Schreibrechte auf `<docker-local-repo>` im Artifactory. Ohne Schreibrechte nutzt du in Aufgabe 5 die Variante B.

## Theorie (Kurzüberblick)

### Containerfile

Ein `Containerfile` ist ein Bauplan für ein Image. Podman versteht dasselbe Format wie Docker; die Datei darf auch `Dockerfile` heißen. Wichtige Anweisungen ([Referenz](https://docs.docker.com/reference/dockerfile/)):

| Anweisung | Bedeutung |
| --- | --- |
| `FROM` | Basis-Image, auf dem du aufbaust – bei uns immer aus dem Artifactory |
| `WORKDIR` | Arbeitsverzeichnis für die folgenden Anweisungen |
| `COPY` | Dateien aus dem Build-Kontext ins Image kopieren |
| `RUN` | einen Befehl beim Bauen ausführen (z. B. Pakete installieren) |
| `ARG` | Variable, die nur beim Bauen existiert (`--build-arg`) |
| `ENV` | Umgebungsvariable, die auch im laufenden Container gilt |
| `USER` | Benutzer, mit dem der Container startet |
| `EXPOSE` | dokumentiert, auf welchem Port die Anwendung lauscht – öffnet aber nichts |
| `CMD` / `ENTRYPOINT` | Startbefehl des Containers |

### Layer und Build-Cache

Jede Anweisung, die Dateien verändert, erzeugt einen **Layer**. Ein Image ist ein Stapel solcher Layer. Beim erneuten Bauen verwendet Podman unveränderte Layer aus dem **Cache** wieder. Ändert sich eine Anweisung oder eine kopierte Datei, werden dieser Layer und alle darüber neu gebaut. Deshalb gehört das, was sich selten ändert, nach oben, und das, was sich oft ändert, nach unten.

Der **Build-Kontext** ist das Verzeichnis, das du `podman build` übergibst (meist `.`). Nur Dateien daraus kann `COPY` verwenden. Eine Datei `.containerignore` schließt Dateien aus.

### Basis-Images aus dem Artifactory

Auch das Basis-Image in `FROM` kommt bei uns aus dem Artifactory. Wir bauen auf `nginxinc/nginx-unprivileged` auf: Es läuft bereits als Benutzer mit der ID `101` und lauscht auf Port 8080. Die **numerische** User-ID ist wichtig, denn Kubernetes kann `runAsNonRoot: true` nur bei einer Zahl prüfen.

### Namen und Tags

Ein Image hat lokal und im Artifactory unterschiedliche Namen:

| Ort | Name |
| --- | --- |
| lokal nach `podman build -t azubi-portal:1.0.0` | `localhost/azubi-portal:1.0.0` |
| im Artifactory | `<artifactory-host>/<docker-local-repo>/azubi-portal:1.0.0` |

Mit `podman tag` gibst du demselben Image einen zweiten Namen. Für jede Änderung gibt es eine neue Version ([SemVer](https://semver.org/lang/de/)); eine veröffentlichte Version wird nicht überschrieben.

## Aufgaben

### Aufgabe 1: Das erste eigene Image

**Ziel:** Ein Image mit eigener Startseite bauen und lokal starten.

1. Lege einen Arbeitsordner an:

   ```bash
   mkdir -p ~/k8s-lab/azubi-portal-image
   cd ~/k8s-lab/azubi-portal-image
   ```

2. Erstelle eine `index.html` mit einer eigenen Startseite für das Azubi-Portal (Überschrift, ein Satz über dich, ein Platzhalter `__VERSION__` für später).
3. Erstelle ein `Containerfile`. Suche das Basis-Image `nginxinc/nginx-unprivileged:1.28.0` unter **Packages** und übernimm die Adresse:

   ```dockerfile
   FROM <artifactory-host>/<docker-remote-repo>/nginxinc/nginx-unprivileged:1.28.0
   COPY index.html /usr/share/nginx/html/index.html
   EXPOSE 8080
   ```

4. Baue das Image und starte es:

   ```bash
   podman build -t azubi-portal:1.0.0 .
   podman images | grep azubi-portal
   podman run -d --rm --name portal -p 8081:8080 localhost/azubi-portal:1.0.0
   curl -s localhost:8081
   podman stop portal
   ```

### Aufgabe 2: Layer und Build-Cache verstehen

**Ziel:** Nachvollziehen, woraus ein Image besteht und wann neu gebaut wird.

1. Sieh dir die Layer deines Images an. Welche Zeilen stammen von dir, welche vom Basis-Image?

   ```bash
   podman history localhost/azubi-portal:1.0.0
   ```

2. Baue das Image ohne Änderung erneut. Achte in der Ausgabe auf `Using cache`.
3. Ändere die `index.html` und baue erneut. Welche Schritte kommen aus dem Cache, welche nicht?
4. Lege im Ordner eine Datei `notizen.txt` und eine `.containerignore` mit dem Inhalt `notizen.txt` an. Ergänze im `Containerfile` testweise `COPY . /tmp/kontext/`, baue und prüfe mit `podman run --rm localhost/azubi-portal:1.0.0 ls /tmp/kontext`, ob `notizen.txt` im Image gelandet ist. Entferne die Zeile danach wieder.

### Aufgabe 3: Als normaler Benutzer laufen

**Ziel:** Prüfen, mit welchem Benutzer dein Image startet, und verstehen, warum das wichtig ist.

1. Lies den Benutzer aus der Image-Konfiguration und im laufenden Container aus:

   ```bash
   podman inspect --format '{{.Config.User}}' localhost/azubi-portal:1.0.0
   podman run --rm localhost/azubi-portal:1.0.0 id
   ```

2. Vergleiche mit dem offiziellen `nginx`-Image aus Modul 01:

   ```bash
   podman inspect --format '{{.Config.User}}' <artifactory-host>/<docker-remote-repo>/nginx:1.28.0
   ```

3. Erkläre mit deinem Wissen aus Modul 02, warum das offizielle Image mit `runAsNonRoot: true` nicht startet, dein Image aber schon.

### Aufgabe 4: Build-Argumente und Multi-Stage-Build

**Ziel:** Beim Bauen eine Versionsnummer einsetzen, ohne Werkzeuge ins fertige Image zu packen.

In einem **Multi-Stage-Build** gibt es mehrere `FROM`-Zeilen. Eine erste Stage bereitet etwas vor, die letzte Stage übernimmt mit `COPY --from=<stage>` nur das Ergebnis.

1. Schreibe das `Containerfile` so um, dass eine erste Stage (Basis: `alpine:3.20.3` aus dem Artifactory) den Platzhalter `__VERSION__` in der `index.html` durch den Wert eines Build-Arguments `APP_VERSION` ersetzt. Die zweite Stage basiert wie bisher auf `nginx-unprivileged` und kopiert nur die fertige `index.html`.

   Hinweise: `ARG APP_VERSION` muss **nach** dem `FROM` der Stage stehen, in der du es nutzt. `sed -i "s/__VERSION__/${APP_VERSION}/" index.html` ersetzt den Platzhalter.

2. Baue mit Versionsnummer und prüfe das Ergebnis:

   ```bash
   podman build --build-arg APP_VERSION=1.0.0 -t azubi-portal:1.0.0 .
   podman run -d --rm --name portal -p 8081:8080 localhost/azubi-portal:1.0.0
   curl -s localhost:8081 | grep -i version
   podman stop portal
   ```

3. Prüfe mit `podman history`, dass im fertigen Image keine Layer aus der Alpine-Stage stecken.

### Aufgabe 5: Image ins Artifactory bringen

**Ziel:** Dein Image so bereitstellen, dass der Cluster es laden kann.

**Variante A – Push ins Artifactory (Standard):**

1. Gib dem Image seinen Artifactory-Namen und lade es hoch:

   ```bash
   podman tag localhost/azubi-portal:1.0.0 <artifactory-host>/<docker-local-repo>/azubi-portal:1.0.0
   podman push <artifactory-host>/<docker-local-repo>/azubi-portal:1.0.0
   ```

2. Suche dein Image unter **Packages**. Welche Informationen zeigt Artifactory an (Größe, Layer, Scan-Ergebnisse)?

**Variante B – ohne Schreibrechte direkt in den kind-Node laden:**

```bash
podman save -o ~/k8s-lab/azubi-portal-1.0.0.tar localhost/azubi-portal:1.0.0
kind load image-archive ~/k8s-lab/azubi-portal-1.0.0.tar --name lab
podman exec lab-control-plane crictl images | grep azubi-portal
```

Das Image heißt im Cluster dann `localhost/azubi-portal:1.0.0`. Diese Variante funktioniert nur in deinem lokalen Cluster – in echten Clustern führt kein Weg am Artifactory vorbei.

### Aufgabe 6: Eigenes Image im Cluster verwenden

**Ziel:** `azubi-portal` mit deinem Image betreiben und eine neue Version ausrollen.

1. Ergänze deine `~/k8s-lab/azubi-portal-chart/values-lab.yaml`. `htmlFromConfigMap: false` sorgt dafür, dass das Chart keine eigene `index.html` einhängt, sondern die aus deinem Image verwendet wird:

   ```yaml
   image:
     repository: <artifactory-host>/<docker-local-repo>/azubi-portal
     tag: "1.0.0"
   htmlFromConfigMap: false
   imagePullSecrets:
     - name: artifactory-pull
   ```

   Bei Variante B: `repository: localhost/azubi-portal` und zusätzlich `pullPolicy: Never` unter `image`.

2. Rolle die Änderung aus und öffne `http://azubi-portal.localhost:8080`:

   ```bash
   cd ~/k8s-lab/azubi-portal-chart
   helm upgrade azubi-portal . -n azubi-portal -f values-lab.yaml
   kubectl rollout status deploy/azubi-portal -n azubi-portal
   ```

3. Ändere die Startseite, baue und pushe Version `1.0.1`, setze `image.tag` auf `"1.0.1"` und führe erneut ein Upgrade durch. Beobachte den Rollout:

   ```bash
   kubectl get pods -n azubi-portal -w
   kubectl rollout history deploy/azubi-portal -n azubi-portal
   ```

### Bonus-Aufgaben (für Fortgeschrittene)

- Baue eine Variante auf Basis von `nginx-unprivileged:1.28.0-alpine` und vergleiche die Größe mit `podman images`. Welche Vor- und Nachteile hat das kleinere Image?
- Ergänze OCI-Labels (`LABEL org.opencontainers.image.version=…`, `…source=…`) und lies sie mit `podman inspect` aus. Wo zeigt Artifactory sie an?
- Tagge ein Image zusätzlich mit dem kurzen Git-Commit (`git rev-parse --short HEAD`). Wofür ist das nützlich?
- Ergänze `readOnlyRootFilesystem: true` im `securityContext` des Charts. Welche Verzeichnisse braucht Nginx trotzdem beschreibbar, und wie löst du das mit einem `emptyDir`?

## Du bist fertig, wenn …

- [ ] du ein Image auf einem Basis-Image aus dem Artifactory gebaut und lokal unter `http://localhost:8081` gestartet hast
- [ ] du mit `podman history` erklären kannst, welche Layer von dir stammen und wann der Cache greift
- [ ] dein Image als Benutzer `101` läuft
- [ ] dein Image `azubi-portal:1.0.0` im Artifactory liegt (oder per `kind load` im Cluster ist)
- [ ] `http://azubi-portal.localhost:8080` deine eigene Seite zeigt und du Version `1.0.1` ausgerollt hast

## Verständnisfragen

1. Was ist der Unterschied zwischen `Containerfile`, Image und Container?
2. Warum spielt die Reihenfolge der Anweisungen im `Containerfile` eine Rolle?
3. Warum sollte ein Image als normaler Benutzer laufen, und warum muss der Benutzer als Zahl angegeben sein?
4. Was bewirkt `EXPOSE` – und was nicht?
5. Welchen Vorteil hat ein Multi-Stage-Build?
6. Warum baust du für jede Änderung eine neue Version, statt `1.0.0` zu überschreiben?
7. Was ist der Unterschied zwischen einem Push ins Artifactory und `kind load image-archive`?

## Häufige Stolperfallen & Tipps

- **`FROM docker.io/…` scheitert:** Im Firmennetz ist Docker Hub gesperrt. Das Basis-Image muss aus dem Artifactory kommen.
- **`COPY failed: no such file or directory`:** Die Datei liegt nicht im Build-Kontext oder steht in der `.containerignore`. Den Punkt am Ende von `podman build … .` nicht vergessen.
- **`bind() to 0.0.0.0:80 failed (13: Permission denied)`:** Ein normaler Benutzer darf im Container keine Ports unter 1024 öffnen. `nginx-unprivileged` lauscht deshalb auf 8080.
- **`unauthorized` oder `method not allowed` beim Push:** Du pushst in ein Remote-Repo statt in `<docker-local-repo>` oder hast keine Schreibrechte.
- **Push einer bestehenden Version wird abgelehnt:** Das ist gewollt – erhöhe die Version.
- **Neue Version, aber der Cluster zeigt die alte Seite:** Hast du den Tag geändert? Mit gleichem Tag und `pullPolicy: IfNotPresent` lädt Kubernetes das Image nicht neu.
- **Eigene Seite fehlt, stattdessen „Willkommen im Azubi-Portal“:** `htmlFromConfigMap` steht noch auf `true`, die ConfigMap überdeckt deine Datei.

## Aufräumen

```bash
podman rmi localhost/azubi-portal:1.0.0 localhost/azubi-portal:1.0.1
podman image prune
rm -f ~/k8s-lab/azubi-portal-1.0.0.tar
```

Die Images im Artifactory und das Release `azubi-portal` bleiben für die folgenden Module bestehen.

## Weiterführend

- [Dockerfile-Referenz](https://docs.docker.com/reference/dockerfile/) (gilt auch für Podman)
- [podman build](https://docs.podman.io/en/latest/markdown/podman-build.1.html)
- [Best Practices für Dockerfiles](https://docs.docker.com/build/building/best-practices/)
- [OCI Image Specification](https://github.com/opencontainers/image-spec)

Eine Musterlösung findest du unter [solutions/modul-05](./solutions/modul-05/).
