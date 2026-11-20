# Modul 04 – JFrog Artifactory & Artefakt-Management

## Kurzbeschreibung

Bei uns kommen alle Container-Images und Helm-Charts über **JFrog Artifactory** – einen anderen Weg gibt es nicht. In Modul 01 hast du schon ein Image gezogen und den Registry-Mirror eingerichtet. In diesem Modul lernst du Artifactory richtig kennen: wie es aufgebaut ist, wie du Images und Charts findest und bewertest, wie der Cluster sich anmeldet und wie du ein eigenes Chart hochlädst.

## Lernziele

- erklären können, wozu wir JFrog Artifactory verwenden
- die Repository-Typen **Local**, **Remote** und **Virtual** unterscheiden
- Images und Charts über **Packages** finden, Versionen vergleichen und den Pull-Befehl übernehmen
- mit Tokens statt Passwörtern arbeiten und Zugangsdaten sicher behandeln
- dem Cluster über ein Pull-Secret Zugriff auf das Artifactory geben
- Helm-Charts aus dem Artifactory installieren und ein eigenes Chart hochladen
- Sicherheits-Scans (Xray) einordnen

## Voraussetzungen

- Modul 01–03 abgeschlossen
- ein Benutzerkonto für JFrog Artifactory unter `https://<artifactory-host>/`
- die Werte für die Platzhalter aus [docs/Artifactory.md](./docs/Artifactory.md#platzhalter)
- für Aufgabe 6: Schreibrechte auf `<helm-oci-repo>` (frag deinen Ausbilder)

## Theorie (Kurzüberblick)

### Wozu Artifactory?

[JFrog Artifactory](https://jfrog.com/artifactory/) ist unser zentraler Speicher für Artefakte: Container-Images, Helm-Charts, Pakete und Binaries.

- **Kontrolle:** Nur was über das Artifactory kommt, darf ins Firmennetz. Direkte Downloads aus dem Internet sind gesperrt.
- **Cache:** Artifactory hebt eine Kopie jedes heruntergeladenen Artefakts auf. Das ist schneller und funktioniert auch, wenn die Original-Quelle ausfällt oder Download-Limits hat.
- **Sicherheit:** JFrog Xray prüft die Artefakte auf bekannte Sicherheitslücken und kann gefährliche Versionen blockieren.
- **Eigene Artefakte:** Selbst gebaute Images (Modul 05) und Charts liegen versioniert neben den öffentlichen.

### Repository-Typen

| Typ | Beschreibung | Beispiel |
| --- | --- | --- |
| **Remote** | Cache für eine externe Quelle | `<docker-remote-repo>` spiegelt Docker Hub |
| **Local** | Speicher für eigene Artefakte, nur hierhin kann man pushen | `<docker-local-repo>`, `<helm-oci-repo>` |
| **Virtual** | eine Adresse für mehrere Repos | `<helm-repo>` bündelt alle öffentlichen Chart-Repos |

### Aufbau einer Image-Adresse

```text
<artifactory-host>/<docker-remote-repo>/nginxinc/nginx-unprivileged:1.28.0
└── Host ────────┘ └── Repo-Key ──────┘ └── Image-Name ──────────┘ └ Tag ┘
```

### Tags und Digests

Ein **Tag** ist ein Name, der auf ein Image zeigt – und umgehängt werden kann. Der **Digest** (`sha256:…`) ist der Fingerabdruck des Inhalts und ändert sich nie. `stable` oder `latest` zeigen nach jedem Release auf einen anderen Digest; ein fester Tag wie `1.28.0` bleibt in der Praxis stabil.

### Zugriff aus dem Cluster

Der Cluster nutzt zwei Wege ins Artifactory (Details in [docs/Artifactory.md](./docs/Artifactory.md#welche-adresse-wann)):

- **Registry-Mirror** (Modul 01): für fremde Charts, deren Images mit Original-Adresse angegeben sind.
- **Vollständige Artifactory-Adresse + Pull-Secret:** für alles, was du selbst schreibst. Das ist bei uns die Regel, weil sofort sichtbar ist, woher ein Image kommt.

## Aufgaben

### Aufgabe 1: Artifactory erkunden

**Ziel:** Den Aufbau des Artifactory verstehen.

1. Melde dich unter `https://<artifactory-host>/` an.
2. Öffne die Repository-Liste (z. B. **Artifactory → Artifacts** bzw. **Administration → Repositories**, je nach Rechten). Finde die Repos aus [docs/Artifactory.md](./docs/Artifactory.md#platzhalter) und notiere jeweils den Typ (Local, Remote, Virtual) und – bei Remote-Repos – die Original-Quelle.
3. Öffne bei `<docker-remote-repo>` den Baum unter **Artifacts**. Welche Images liegen schon im Cache? Findest du das `nginx`-Image aus Modul 01?
4. Öffne bei einem Repo **Set Me Up** und sieh dir an, welche Befehle Artifactory für Docker bzw. Helm vorschlägt.

### Aufgabe 2: Mit einem Token anmelden

**Ziel:** Nicht mit dem persönlichen Passwort, sondern mit einem widerrufbaren Token arbeiten.

1. Erzeuge in deinem Profil ein **Identity Token** (falls euer Artifactory das erlaubt – sonst frag deinen Ausbilder, welcher Weg vorgesehen ist).
2. Melde dich mit Podman neu an und nutze das Token als Passwort:

   ```bash
   podman logout <artifactory-host>
   podman login <artifactory-host> -u <benutzer>
   ```

3. Finde heraus, wo Podman die Zugangsdaten speichert, und überlege, wer darauf Zugriff hat.

### Aufgabe 3: Ein Image mit festem Tag auswählen

**Ziel:** Versionen vergleichen und verstehen, warum feste Tags wichtig sind.

1. Suche unter **Packages** nach `nginx-unprivileged` (Pakettyp **Docker**). Vergleiche die Versionen `1.28.0`, `1.28` und `stable`.
2. Lade zwei Tags und vergleiche die Digests:

   ```bash
   podman pull <artifactory-host>/<docker-remote-repo>/nginxinc/nginx-unprivileged:1.28.0
   podman pull <artifactory-host>/<docker-remote-repo>/nginxinc/nginx-unprivileged:stable
   podman images --digests | grep nginx-unprivileged
   ```

3. Sieh dir in der Ansicht der Version die Ergebnisse des Sicherheits-Scans (Xray) an, falls sie angezeigt werden. Wie viele Lücken mit hoher Schwere hat die Version?
4. Entscheide dich für eine Version und begründe kurz schriftlich, warum.

### Aufgabe 4: Image aus Artifactory im Cluster verwenden

**Ziel:** In deiner `values-lab.yaml` die vollständige Artifactory-Adresse verwenden und dem Cluster die nötigen Zugangsdaten geben.

1. Lege im Namespace `azubi-portal` ein Pull-Secret an. Den technischen Benutzer und das Token bekommst du von deinem Ausbilder – **nicht** dein persönliches Konto:

   ```bash
   kubectl create secret docker-registry artifactory-pull -n azubi-portal \
     --docker-server=<artifactory-host> \
     --docker-username=<technischer-benutzer> \
     --docker-password=<token>
   ```

2. Ergänze deine `~/k8s-lab/azubi-portal-chart/values-lab.yaml` aus Modul 03:

   ```yaml
   image:
     repository: <artifactory-host>/<docker-remote-repo>/nginxinc/nginx-unprivileged
     tag: "1.28.0"
   imagePullSecrets:
     - name: artifactory-pull
   ```

3. Führe ein Upgrade durch und prüfe, ob die Pods mit dem neuen Image laufen:

   ```bash
   cd ~/k8s-lab/azubi-portal-chart
   helm upgrade azubi-portal . -n azubi-portal -f values-lab.yaml
   kubectl get pods -n azubi-portal
   kubectl get pods -n azubi-portal -o jsonpath='{.items[*].spec.containers[*].image}'; echo
   ```

4. Lies das Pull-Secret aus und dekodiere es (`kubectl get secret artifactory-pull -n azubi-portal -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d`). Was folgt daraus für die Frage, wer im Namespace Secrets lesen darf?

### Aufgabe 5: Helm-Charts aus dem Artifactory

**Ziel:** Verstehen, wie Charts über das Artifactory bezogen werden.

Das Helm-Repo `artifactory` hast du in Modul 02 angelegt. Es zeigt auf das virtuelle Repo `<helm-repo>`.

1. Suche alle Versionen des Traefik-Charts und finde heraus, welche Version bei dir installiert ist:

   ```bash
   helm search repo artifactory/traefik --versions | head -n 5
   helm list -n traefik
   ```

2. Lade ein Chart herunter, ohne es zu installieren, und sieh es dir an:

   ```bash
   helm pull artifactory/podinfo --version <chart-version> --untar -d ~/k8s-lab/charts
   ls ~/k8s-lab/charts/podinfo
   ```

3. Suche das Chart `podinfo` in der Web-Oberfläche unter **Packages** (Pakettyp **Helm**). In welchem Repo liegt es tatsächlich?

### Aufgabe 6: Eigenes Chart ins Artifactory hochladen

**Ziel:** Das in Modul 03 gepackte Chart als versioniertes Artefakt veröffentlichen.

1. Melde Helm am OCI-Repo an und lade das Paket aus Modul 03 hoch:

   ```bash
   helm registry login <artifactory-host>
   helm push ~/k8s-lab/packages/azubi-portal-0.3.1.tgz oci://<artifactory-host>/<helm-oci-repo>
   ```

2. Suche dein Chart unter **Packages** und prüfe die Version.
3. Installiere es testweise direkt aus dem Artifactory in einen eigenen Namespace und entferne es wieder:

   ```bash
   helm install portal-oci oci://<artifactory-host>/<helm-oci-repo>/azubi-portal --version 0.3.1 -n portal-oci --create-namespace
   helm list -n portal-oci
   helm uninstall portal-oci -n portal-oci
   kubectl delete namespace portal-oci
   ```

4. Versuche, dieselbe Version ein zweites Mal hochzuladen. Was passiert, und warum ist das sinnvoll?

Falls euer Artifactory kein OCI-Helm-Repo hat, zeigt dir **Set Me Up** beim lokalen Helm-Repo den passenden Upload-Befehl.

### Bonus-Aufgaben (für Fortgeschrittene)

- Prüfe mit `podman inspect --format '{{.RepoDigests}}' <image>`, welcher Digest hinter deinem Tag steckt, und verwende ihn im Chart als `image.tag: "1.28.0@sha256:…"`. Was ist der Vorteil, was der Nachteil?
- Hänge das Pull-Secret an den ServiceAccount `default` im Namespace `azubi-portal` (`kubectl patch serviceaccount default …`), statt es im Chart anzugeben. Wann ist das praktisch?
- Finde heraus, ob das Artifactory eine REST-API für die Suche anbietet, und suche damit nach allen Versionen von `nginx-unprivileged`.

## Du bist fertig, wenn …

- [ ] du die Repo-Typen Local, Remote und Virtual an einem Beispiel aus unserem Artifactory erklären kannst
- [ ] du mit einem Token statt deinem Passwort angemeldet bist
- [ ] `azubi-portal` mit einer vollständigen Artifactory-Adresse und dem Pull-Secret `artifactory-pull` läuft
- [ ] dein Chart `azubi-portal` in Version `0.3.1` im Artifactory liegt
- [ ] du begründen kannst, warum du dich für einen bestimmten Image-Tag entschieden hast

## Verständnisfragen

1. Warum laden wir Images über Artifactory und nicht direkt von Docker Hub?
2. Was ist der Unterschied zwischen einem Remote- und einem Local-Repo? Wohin kannst du pushen?
3. Warum solltest du einen festen Tag (z. B. `1.28.0`) statt `latest` oder `stable` verwenden?
4. Warum verwendet der Cluster einen technischen Benutzer und nicht dein persönliches Konto?
5. Warum lässt sich eine einmal veröffentlichte Chart-Version nicht überschreiben?
6. Wann reicht der Registry-Mirror, wann brauchst du ein Pull-Secret?

## Häufige Stolperfallen & Tipps

- **`unauthorized` beim Pull:** Du bist nicht angemeldet oder das Token ist abgelaufen. Führe `podman login <artifactory-host>` aus.
- **`manifest unknown`:** Tag oder Image-Name sind falsch. Kopiere den Befehl am besten direkt aus Artifactory, statt ihn abzutippen.
- **`x509: certificate signed by unknown authority`:** Die Firmen-CA fehlt in WSL (siehe [docs/Fehlerbehebung.md](./docs/Fehlerbehebung.md)).
- **`403 Forbidden` mit Hinweis auf eine Policy:** Xray blockiert die Version wegen Sicherheitslücken. Wähle eine andere Version.
- **Image nicht gefunden:** Suche ohne Tag nur nach dem Namen (z. B. `nginx`) und achte auf den Pakettyp **Docker**.
- **`ImagePullBackOff` im Cluster:** Liegt das Pull-Secret im selben Namespace wie der Pod? Stimmt `--docker-server` (nur der Host, ohne `https://`)?
- **`helm push` scheitert mit `unauthorized`:** `helm registry login` vergessen oder keine Schreibrechte auf `<helm-oci-repo>`.

## Aufräumen

```bash
podman rmi <artifactory-host>/<docker-remote-repo>/nginxinc/nginx-unprivileged:stable
rm -rf ~/k8s-lab/charts/podinfo
```

Das Release `azubi-portal`, das Pull-Secret und dein Chart im Artifactory brauchst du in den folgenden Modulen weiter.

## Weiterführend

- [JFrog Artifactory Dokumentation](https://jfrog.com/help/r/jfrog-artifactory-documentation)
- [Helm – OCI-Registries](https://helm.sh/docs/topics/registries/)
- [Kubernetes – Images aus privaten Registries](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)

Eine Musterlösung findest du unter [solutions/modul-04](./solutions/modul-04/).
