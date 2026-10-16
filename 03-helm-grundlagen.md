# Modul 03 – Helm-Grundlagen

## Kurzbeschreibung

In diesem Modul wandelst du manuelle YAML-Deployments in ein wiederverwendbares Helm-Chart fuer deine Beispiel-App `azubi-portal` um. Du lernst, wie ein Chart aufgebaut ist, wie du Konfiguration ueber `values.yaml` steuerst und wie du Releases installierst, aktualisierst und zurueckrollst.

## Lernziele

- Aufbau eines Helm-Charts verstehen (Chart.yaml, values.yaml, Templates)
- bestehende Charts installieren und anpassen
- ein eigenes einfaches Helm-Chart fuer `azubi-portal` nutzen und verstehen
- Helm-Release-Lifecycle (install, upgrade, rollback) anwenden

## Voraussetzungen

- Modul 01 und 02 abgeschlossen

## Theorie (Kurzüberblick)

### Was ist Helm?

[Helm](https://helm.sh/) ist ein Paketmanager für Kubernetes. Ein **Chart** bündelt alle Manifeste, die für eine Anwendung nötig sind, inklusive Standardkonfiguration. Über `values.yaml` kannst du die Anwendung pro Umgebung konfigurieren, ohne Templates zu ändern.

Typischer Aufbau eines Charts (siehe auch [Helm Chart Template Guide](https://helm.sh/docs/chart_template_guide/)):

- `Chart.yaml`: Metadaten (Name, Version, Beschreibung)
- `values.yaml`: Standardwerte für Variablen
- `templates/`: YAML-Templates, die mit den Werten gefüllt werden

### Templates und Values

In den Templates kannst du Platzhalter verwenden, die aus `values.yaml` kommen (z. B. `{{ .Values.image.repository }}`). Beim Rendern ersetzt Helm die Platzhalter durch konkrete Werte und erzeugt fertige Kubernetes-Manifeste.

## Aufgaben

### Aufgabe 1: Helm installieren und erstes Demo-Chart deployen

**Ziel:** Helm im Lab nutzen und ein erstes Chart ausrollen.

1. Installiere Helm entsprechend der offiziellen Anleitung.
2. Füge ein öffentliches Helm-Repository hinzu (z. B. `bitnami`).
3. Suche dir ein einfaches Chart (z. B. eine Web-Anwendung oder Datenbank) und installiere es in deinem Cluster (eigener Namespace empfohlen).
4. Prüfe mit `helm list` und `kubectl get all -n <namespace>`, was installiert wurde.

Beispielbefehle:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install demo bitnami/nginx --namespace demo --create-namespace
helm list -n demo
kubectl get all -n demo
```

### Aufgabe 2: `azubi-portal`-Chart-Struktur verstehen

**Ziel:** Aufbau eines konkreten Charts nachvollziehen.

In diesem Lab gibt es ein minimales Referenz-Chart fuer `azubi-portal` unter `examples/azubi-portal-chart/`.

1. Sieh dir die Dateien `Chart.yaml`, `values.yaml` und die Dateien im Ordner `templates/` an.
2. Notiere dir:
   - welche Konfigurationswerte in `values.yaml` definiert sind (z. B. `replicaCount`, `image.repository`, `service.port`, `welcomeMessage`)
   - an welchen Stellen diese Werte in den Templates verwendet werden.

Achte insbesondere darauf, wie das Deployment, der Service und die ConfigMap fuer die statische HTML-Seite aufgebaut sind.

### Aufgabe 3: `azubi-portal` mit Helm deployen

**Ziel:** `azubi-portal` als Helm-Release ausrollen und ueber `values.yaml` steuern.

1. Kopiere das Referenz-Chart in einen Arbeitsordner, z. B.:

   ```bash
   mkdir -p ~/k8s-lab/azubi-portal-chart
   cp -r examples/azubi-portal-chart/* ~/k8s-lab/azubi-portal-chart/
   cd ~/k8s-lab/azubi-portal-chart
   ```

2. Installiere das Chart in deinem Cluster im Namespace `azubi-portal`:

   ```bash
   helm install azubi-portal . -n azubi-portal --create-namespace
   ```

3. Pruefe mit `kubectl get deploy,po,svc -n azubi-portal`, ob Deployment, Pods und Service erstellt wurden.

4. Oeffne im Browser deine `azubi-portal`-Seite, z. B. per Port-Forwarding:

   ```bash
   kubectl port-forward svc/azubi-portal -n azubi-portal 8080:80
   # Danach im Browser: http://localhost:8080
   ```

### Aufgabe 4: Werte anpassen und Rollback testen

**Ziel:** Konfiguration ueber `values.yaml` steuern und Rollback nutzen.

1. Oeffne `values.yaml` in deinem `azubi-portal`-Chart.
2. Passe mindestens folgende Werte an:
   - `replicaCount` (z. B. erhoehen oder verringern)
   - `welcomeMessage` (Text, der in der HTML-Seite angezeigt wird)
3. Fuehre ein Upgrade deines Releases durch:

   ```bash
   helm upgrade azubi-portal . -n azubi-portal
   ```

4. Pruefe mit `kubectl get deploy -n azubi-portal` und `kubectl describe deploy azubi-portal -n azubi-portal`, ob die neuen Werte uebernommen wurden.
5. Beobachte die HTML-Seite im Browser und pruefe, ob sich die Welcome-Message geaendert hat.

6. Erzeuge nun absichtlich eine fehlerhafte Konfiguration (z. B. ein ungueltiges Image-Tag), fuehre erneut `helm upgrade` aus und beobachte, was mit deinem Release passiert (z. B. CrashLoopBackOff).
7. Nutze `helm history` und `helm rollback`, um zum letzten funktionierenden Release zurueckzukehren, und verifiziere, dass `azubi-portal` wieder laeuft.

Beispielbefehle:

```bash
helm history azubi-portal -n azubi-portal
helm rollback azubi-portal <versionsnummer> -n azubi-portal
```

### Bonus-Aufgaben (fuer Fortgeschrittene)

- Fuege einen weiteren Wert in `values.yaml` hinzu (z. B. ein zusaetzliches Label oder eine Annotation) und nutze ihn in einem Template.
- Nutze `helm template .` und vergleiche die generierten Manifeste mit der Variante aus Modul 02.

## Haeufige Stolperfallen & Tipps

- `helm install` schlaegt fehl, weil der Namespace noch nicht existiert: nutze `--create-namespace` oder lege den Namespace vorher mit `kubectl create namespace azubi-portal` an.
- Template-Fehler (z. B. falsche `Values`-Pfadanzeige) erkennst du gut mit `helm template .` und einem Blick in die generierten YAMLs.
- Wenn ein Upgrade fehlschlaegt, hilft `helm status azubi-portal -n azubi-portal` zusammen mit `kubectl describe` und `kubectl logs`, um die Ursache zu finden.
- Halte dein Chart moeglichst schlank: entferne nicht benoetigte Dateien, statt alles aus einem `helm create`-Geruest mitzuschleppen.
