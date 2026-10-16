# Modul 06 – ArgoCD & GitOps-Flow

## Kurzbeschreibung

In diesem Modul setzt du ArgoCD in deinem lokalen Cluster auf und verbindest es mit deinem GitLab-Repo. Du lernst, wie ArgoCD den gewünschten Zustand aus Git in den Cluster synchronisiert, Drift erkennt und Self-Healing durchführt.

## Lernziele

- ArgoCD im `kind`-Cluster installieren und erreichen
- ArgoCD mit dem GitLab-Repo verbinden
- Anwendungen als ArgoCD-Applications deklarativ definieren
- den GitOps-Flow Ende-zu-Ende nachvollziehen (Commit → Sync → Rollout)
- Config-Drift und Self-Healing beobachten

## Voraussetzungen

- Modul 01–05 abgeschlossen
- GitLab-Repo mit der Struktur aus Modul 05 (`gitops/apps/azubi-portal`)

## Theorie (Kurzüberblick)

### ArgoCD-Grundkonzepte

[ArgoCD](https://argo-cd.readthedocs.io/en/stable/) ist ein GitOps-Controller für Kubernetes. Wichtige Konzepte:

- **Application**: beschreibt, welche Manifeste (z. B. ein Helm-Chart) aus welchem Git-Repo und Pfad in welchen Cluster/Namespace deployt werden.
- **Project**: gruppiert Applications und begrenzt, welche Repos und Ziel-Namespaces erlaubt sind (Standard: `default`).
- **Sync**: Abgleich zwischen gewünschtem Zustand (Git) und aktuellem Cluster-Zustand.
- **Health**: Zustand der deployten Ressourcen (z. B. Healthy, Progressing, Degraded).

Der zentrale Gedanke: „Git ist Source of Truth“. Direkte Änderungen im Cluster gelten als **Drift**.

Wichtig für Helm: ArgoCD rendert das Chart selbst (wie `helm template`) und wendet die Manifeste an. Das Release taucht deshalb **nicht** in `helm list` auf.

## Aufgaben

### Aufgabe 1: ArgoCD im Cluster installieren

**Ziel:** ArgoCD im `kind`-Cluster bereitstellen.

1. Entferne das manuell installierte Helm-Release aus Modul 03, damit ArgoCD die App übernehmen kann:

   ```bash
   helm uninstall azubi-portal -n azubi-portal
   ```

2. Installiere ArgoCD aus den offiziellen Manifests in den Namespace `argocd`:

   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   kubectl get pods -n argocd -w
   ```

   Hinweis: In der Firma kommen die ArgoCD-Images idealerweise über das Artifactory (Modul 04). Wenn der Download von `quay.io` blockiert ist, frag deinen Ausbilder nach dem passenden Mirror.

3. Öffne das Web-UI per Port-Forwarding unter `https://localhost:9443`:

   ```bash
   kubectl port-forward svc/argocd-server -n argocd 9443:443
   ```

4. Melde dich mit dem Benutzer `admin` und dem initialen Passwort an und ändere es danach:

   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
   ```

5. Optional: Installiere das [ArgoCD-CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/) und melde dich an: `argocd login localhost:9443 --insecure`.

### Aufgabe 2: GitLab-Repo in ArgoCD hinterlegen

**Ziel:** ArgoCD darf dein (privates) Repo lesen.

1. Erzeuge in GitLab ein **Project Access Token** oder **Deploy Token** mit dem Recht `read_repository`.
2. Hinterlege das Repo in ArgoCD unter „Settings → Repositories → Connect Repo“ (Methode HTTPS) oder deklarativ als Secret mit dem Label `argocd.argoproj.io/secret-type: repository`.
3. Prüfe, ob der Verbindungsstatus „Successful“ ist.

Hinweis: Nutzt eure GitLab-Instanz ein Zertifikat der Firmen-CA, musst du die CA unter „Settings → Certificates“ hinterlegen.

### Aufgabe 3: Application für `azubi-portal` deklarativ anlegen

**Ziel:** `azubi-portal` über ArgoCD deployen – definiert als YAML in Git.

1. Lege in deinem GitLab-Repo `gitops/cluster/argocd-apps/azubi-portal.yaml` an:

   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: azubi-portal
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: <dein-gitlab-repo-url>
       targetRevision: main
       path: gitops/apps/azubi-portal
       helm:
         valueFiles:
           - values-lab.yaml
     destination:
       server: https://kubernetes.default.svc
       namespace: azubi-portal
     syncPolicy:
       syncOptions:
         - CreateNamespace=true
   ```

   `path` zeigt auf den Ordner mit der `Chart.yaml`; `valueFiles` ist relativ zu diesem Ordner.

2. Committe die Datei und wende sie **einmalig** an (in Modul 08 automatisierst du auch diesen Schritt):

   ```bash
   kubectl apply -f gitops/cluster/argocd-apps/azubi-portal.yaml
   ```

3. Die Application steht nun auf „OutOfSync“. Führe im UI einen **Sync** aus (oder `argocd app sync azubi-portal`) und prüfe die Ressourcen im Cluster.

### Aufgabe 4: GitOps-Flow erleben (Commit → Sync)

**Ziel:** Verstehen, wie Änderungen in Git im Cluster landen.

1. Ändere auf einem Feature-Branch `welcomeMessage` oder `replicaCount` in `values-lab.yaml`.
2. Erstelle einen Merge Request und merge ihn nach `main`.
3. Beobachte in ArgoCD, wie die Application „OutOfSync“ wird (ArgoCD prüft standardmäßig etwa alle 3 Minuten; mit „Refresh“ geht es sofort).
4. Synchronisiere und verifiziere mit `kubectl`, dass die Änderung angekommen ist.

### Aufgabe 5: Automatischer Sync, Drift und Self-Healing

**Ziel:** Verstehen, wie ArgoCD Abweichungen vom Git-Zustand erkennt und behebt.

1. Ändere eine Ressource direkt im Cluster:

   ```bash
   kubectl scale deploy azubi-portal -n azubi-portal --replicas=5
   ```

2. Beobachte im UI, wie die Application als „OutOfSync“ angezeigt wird. Klicke auf „App Diff“.
3. Aktiviere automatischen Sync mit Self-Healing und Pruning, indem du die `syncPolicy` in Git ergänzt und die Datei erneut anwendest:

   ```yaml
   syncPolicy:
     automated:
       prune: true
       selfHeal: true
     syncOptions:
       - CreateNamespace=true
   ```

4. Skaliere erneut manuell und beobachte, wie ArgoCD die Änderung nach kurzer Zeit zurücksetzt.
5. Teste `prune`: Entferne in Git eine Ressource (z. B. setze `ingress.enabled: false`) und beobachte, dass ArgoCD den Ingress löscht.
6. Notiere, welche Art von Änderungen du bei GitOps nie direkt im Cluster machen solltest.

### Aufgabe 6: Fehlerhaftes Release und Rollback per Git

**Ziel:** Verstehen, dass ein Rollback bei GitOps ein Git-Revert ist.

1. Setze in `values-lab.yaml` ein ungültiges Image-Tag und merge die Änderung.
2. Beobachte im UI den Health-Status „Degraded“/„Progressing“.
3. Mache die Änderung mit `git revert <commit>` rückgängig, pushe und beobachte, wie ArgoCD den alten Zustand wiederherstellt.

Warum ist `helm rollback` hier keine gute Idee?

### Bonus-Aufgaben (für Fortgeschrittene)

- **Chart aus dem Artifactory:** Lege eine zweite Application an, die ein OCI-Chart aus dem Artifactory nutzt und die Values aus Git holt ([Multiple Sources](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)). Hinterlege dazu das OCI-Repo in ArgoCD als Helm-Repository mit „Enable OCI“.
- Installiere den Monitoring-Stack aus Modul 07 als eigene ArgoCD-Application.
- Lege ein eigenes `AppProject` `lab` an, das nur dein GitLab-Repo und die Namespaces `azubi-portal` und `monitoring` erlaubt.

## Du bist fertig, wenn …

- [ ] die Application `azubi-portal` in ArgoCD „Synced“ und „Healthy“ ist
- [ ] eine Änderung per Merge Request automatisch im Cluster ankommt
- [ ] eine manuelle Änderung im Cluster von ArgoCD zurückgesetzt wird
- [ ] du ein fehlerhaftes Release per `git revert` behoben hast

## Verständnisfragen

1. Was ist der Unterschied zwischen „Sync Status“ und „Health Status“?
2. Was bewirken `prune` und `selfHeal` jeweils? Wann wäre `prune: false` sinnvoll?
3. Warum erscheint die per ArgoCD installierte App nicht in `helm list`?
4. Warum ist bei GitOps ein `git revert` der bessere Rollback als `helm rollback` oder `kubectl`?

## Häufige Stolperfallen & Tipps

- Privates Repo: ArgoCD braucht gültige Zugangsdaten (Aufgabe 2).
- `path` falsch: er muss auf den Ordner mit `Chart.yaml` zeigen (`gitops/apps/azubi-portal`), sonst meldet ArgoCD „app path does not exist“ oder rendert nichts.
- `valueFiles` ist relativ zum `path`. Ein Tippfehler im Dateinamen führt zu einem Fehler beim Rendern.
- Die Application muss im Namespace `argocd` liegen, sonst sieht der Controller sie nicht.
- Port-Forward bricht ab: einfach neu starten. Port 8080 ist vom kind-Cluster belegt, nutze 9443.

## Aufräumen

ArgoCD und `azubi-portal` bleiben für Modul 07 und 08 installiert.

## Weiterführend

- [App-of-Apps-Muster](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) (wird in Modul 08 genutzt)
- [Automated Sync Policy](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)

Eine Musterlösung findest du unter [solutions/modul-06](./solutions/modul-06/).
