# Modul 03 – Helm-Grundlagen

## Kurzbeschreibung

In diesem Modul wandelst du manuelle YAML-Deployments in ein wiederverwendbares Helm-Chart für deine Beispiel-App `azubi-portal` um. Du lernst, wie ein Chart aufgebaut ist, wie du Konfiguration über `values.yaml` steuerst und wie du Releases installierst, aktualisierst und zurückrollst.

## Lernziele

- Aufbau eines Helm-Charts verstehen (`Chart.yaml`, `values.yaml`, Templates, Helper)
- bestehende Charts aus einem Helm-Repository installieren und anpassen
- das Referenz-Chart für `azubi-portal` nutzen und verstehen
- den Helm-Release-Lifecycle (install, upgrade, history, rollback) anwenden
- ein Chart als Paket (`.tgz`) bauen – Vorbereitung für Modul 04 (Artifactory)

## Voraussetzungen

- Modul 01 und 02 abgeschlossen
- Traefik ist als Ingress-Controller installiert (Modul 02, Aufgabe 6)

## Theorie (Kurzüberblick)

### Was ist Helm?

[Helm](https://helm.sh/) ist ein Paketmanager für Kubernetes. Ein **Chart** bündelt alle Manifeste, die für eine Anwendung nötig sind, inklusive Standardkonfiguration. Über `values.yaml` kannst du die Anwendung pro Umgebung konfigurieren, ohne Templates zu ändern. Ein installiertes Chart heißt **Release**.

Typischer Aufbau eines Charts (siehe [Helm Chart Template Guide](https://helm.sh/docs/chart_template_guide/)):

- `Chart.yaml`: Metadaten (Name, Chart-Version, App-Version)
- `values.yaml`: Standardwerte für Variablen
- `templates/`: YAML-Templates, die mit den Werten gefüllt werden
- `templates/_helpers.tpl`: wiederverwendbare Template-Bausteine (z. B. gemeinsame Labels)

### Templates und Values

In den Templates verwendest du Platzhalter, die aus `values.yaml` kommen (z. B. `{{ .Values.image.repository }}`). Beim Rendern ersetzt Helm die Platzhalter durch konkrete Werte und erzeugt fertige Kubernetes-Manifeste. Werte kannst du beim Installieren überschreiben – per eigener Datei (`-f values-lab.yaml`) oder einzeln (`--set replicaCount=3`).

### Chart-Version vs. App-Version

- `version` in `Chart.yaml` ist die Version des **Charts** (der Verpackung). Sie muss bei jeder Änderung am Chart erhöht werden ([SemVer](https://semver.org/lang/de/)).
- `appVersion` ist die Version der **Anwendung** im Chart.

Das wird in Modul 04 wichtig: Eine Registry wie Artifactory speichert jede Chart-Version als eigenes, unveränderliches Artefakt.

## Aufgaben

### Aufgabe 1: Helm installieren und ein öffentliches Chart deployen

**Ziel:** Helm im Lab nutzen und ein erstes fremdes Chart ausrollen.

1. Prüfe mit `helm version`, ob Helm installiert ist (spätestens in Modul 02 für Traefik passiert). Sonst installiere es.
2. Füge das Helm-Repository von [podinfo](https://github.com/stefanprodan/podinfo) hinzu – eine kleine Demo-App, die extra für Kubernetes-Tests gebaut wurde.
3. Sieh dir die verfügbaren Werte des Charts an, bevor du es installierst.
4. Installiere das Chart in einen eigenen Namespace und prüfe, was installiert wurde.

```bash
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update
helm search repo podinfo
helm show values podinfo/podinfo | less
helm install demo podinfo/podinfo -n demo --create-namespace --set replicaCount=2
helm list -n demo
kubectl get all -n demo
kubectl port-forward svc/demo-podinfo -n demo 9080:9898
```

Öffne `http://localhost:9080`.

### Aufgabe 2: Die Struktur des `azubi-portal`-Charts verstehen

**Ziel:** Aufbau eines konkreten Charts nachvollziehen.

Das Referenz-Chart liegt unter [`examples/azubi-portal-chart/`](./examples/azubi-portal-chart/). Eine Beschreibung aller Werte findest du in [docs/azubi-portal-chart.md](./docs/azubi-portal-chart.md).

1. Sieh dir `Chart.yaml`, `values.yaml` und die Dateien in `templates/` an.
2. Notiere dir:
   - welche Werte in `values.yaml` definiert sind (`replicaCount`, `image.*`, `containerPort`, `service.*`, `welcomeMessage`, `resources`, `ingress.*`)
   - an welchen Stellen diese Werte in den Templates verwendet werden
   - was `include "azubi-portal.labels"` in `_helpers.tpl` macht
3. Rendere das Chart lokal, ohne es zu installieren, und vergleiche das Ergebnis mit deinem YAML aus Modul 02:

   ```bash
   helm lint examples/azubi-portal-chart
   helm template azubi-portal examples/azubi-portal-chart
   ```

4. Im Deployment-Template steht die Annotation `checksum/config`. Finde heraus, wozu sie dient. Tipp: Was passiert mit laufenden Pods, wenn sich nur eine ConfigMap ändert?

### Aufgabe 3: `azubi-portal` mit Helm deployen

**Ziel:** `azubi-portal` als Helm-Release ausrollen.

1. Kopiere das Referenz-Chart in einen Arbeitsordner:

   ```bash
   mkdir -p ~/k8s-lab
   cp -r examples/azubi-portal-chart ~/k8s-lab/
   cd ~/k8s-lab/azubi-portal-chart
   ```

2. Installiere das Chart im Namespace `azubi-portal` und schalte dabei den Ingress ein:

   ```bash
   helm install azubi-portal . -n azubi-portal --create-namespace --set ingress.enabled=true
   kubectl get deploy,po,svc,ingress -n azubi-portal
   ```

3. Öffne `http://azubi-portal.localhost:8080` oder nutze alternativ Port-Forwarding:

   ```bash
   kubectl port-forward svc/azubi-portal -n azubi-portal 9080:80
   ```

### Aufgabe 4: Werte anpassen und Rollback testen

**Ziel:** Konfiguration über eine eigene Values-Datei steuern und Rollback nutzen.

1. Lege eine Datei `values-lab.yaml` an, die nur die Werte enthält, die du ändern willst:

   ```yaml
   replicaCount: 3
   welcomeMessage: "Hallo aus meinem Lab"
   ingress:
     enabled: true
   ```

2. Führe ein Upgrade durch und prüfe das Ergebnis:

   ```bash
   helm upgrade azubi-portal . -n azubi-portal -f values-lab.yaml
   kubectl get deploy -n azubi-portal
   helm get values azubi-portal -n azubi-portal
   ```

3. Lade die Seite im Browser neu. Ist die neue Welcome-Message sofort sichtbar? Erkläre das mit der `checksum/config`-Annotation.
4. Erzeuge absichtlich einen Fehler mit einem ungültigen Image-Tag:

   ```bash
   helm upgrade azubi-portal . -n azubi-portal -f values-lab.yaml --set image.tag=gibtesnicht
   kubectl get pods -n azubi-portal
   ```

   Beobachte den Status `ErrImagePull`/`ImagePullBackOff`. Warum bleiben die alten Pods weiterhin erreichbar?
5. Kehre mit `helm history` und `helm rollback` zum letzten funktionierenden Release zurück:

   ```bash
   helm history azubi-portal -n azubi-portal
   helm rollback azubi-portal <revision> -n azubi-portal
   ```

### Aufgabe 5: Chart paketieren

**Ziel:** Aus dem Chart-Ordner ein versioniertes Artefakt machen.

1. Erhöhe in `Chart.yaml` die `version` (z. B. auf `0.2.1`).
2. Baue das Paket:

   ```bash
   helm package . -d ~/k8s-lab/packages
   ls ~/k8s-lab/packages
   ```

3. Installiere testweise direkt aus der `.tgz`-Datei in einen anderen Namespace und lösche das Release danach wieder.

Dieses Paket lädst du in Modul 04 in eine Registry hoch.

### Bonus-Aufgaben (für Fortgeschrittene)

- Füge einen neuen Wert hinzu (z. B. `podAnnotations`) und nutze ihn im Deployment-Template.
- Stelle das Release per `values-lab.yaml` auf das gehärtete Image `nginxinc/nginx-unprivileged` aus Modul 02 um (Tipp: Wert `containerPort`) und ergänze im Template einen `securityContext`.
- Erstelle mit `helm create testchart` ein neues Chart und vergleiche es mit `azubi-portal`. Welche Dateien würdest du entfernen?

## Du bist fertig, wenn …

- [ ] `helm list -A` die Releases `demo` und `azubi-portal` zeigt
- [ ] `azubi-portal` mit deiner eigenen `values-lab.yaml` läuft und die neue Welcome-Message zeigt
- [ ] du ein kaputtes Release per `helm rollback` repariert hast
- [ ] eine Datei `azubi-portal-<version>.tgz` existiert

## Verständnisfragen

1. Wozu dient eine eigene `values-lab.yaml`, statt direkt `values.yaml` zu ändern?
2. Was ist der Unterschied zwischen `version` und `appVersion`?
3. Warum ist `helm template` beim Debuggen hilfreich?
4. Warum braucht es die Annotation `checksum/config`?

## Häufige Stolperfallen & Tipps

- `helm install` scheitert, weil das Release schon existiert: nutze `helm upgrade --install`.
- Template-Fehler erkennst du mit `helm lint` und `helm template . --debug`.
- Wenn ein Upgrade fehlschlägt, helfen `helm status`, `kubectl describe` und `kubectl logs`.
- Halte dein Chart schlank: entferne nicht benötigte Dateien, statt alles aus einem `helm create`-Gerüst mitzuschleppen.

## Aufräumen

```bash
helm uninstall demo -n demo
kubectl delete namespace demo
```

Das Release `azubi-portal` kannst du stehen lassen. Spätestens in Modul 06 übernimmt ArgoCD – dann deinstallierst du es dort.

## Weiterführend

- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Helm Template-Funktionen](https://helm.sh/docs/chart_template_guide/function_list/)

Eine Musterlösung findest du unter [solutions/modul-03](./solutions/modul-03/).
