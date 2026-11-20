# Modul 07 – ArgoCD & GitOps-Flow

## Kurzbeschreibung

In diesem Modul setzt du ArgoCD in deinem lokalen Cluster auf und verbindest es mit deinem GitLab-Repo. Du lernst, wie ArgoCD den gewünschten Zustand aus Git in den Cluster synchronisiert, Drift erkennt und Self-Healing durchführt.

## Lernziele

- ArgoCD im `kind`-Cluster installieren und erreichen
- ArgoCD mit dem GitLab-Repo verbinden
- Anwendungen als ArgoCD-Applications deklarativ definieren
- den GitOps-Flow Ende-zu-Ende nachvollziehen (Commit → Sync → Rollout)
- Config-Drift und Self-Healing beobachten

## Voraussetzungen

- Modul 01–06 abgeschlossen
- GitLab-Repo mit der Struktur aus Modul 06 (`gitops/apps/azubi-portal`)

## Theorie (Kurzüberblick)

### ArgoCD-Grundkonzepte

[ArgoCD](https://argo-cd.readthedocs.io/en/stable/) ist ein GitOps-Controller für Kubernetes. Wichtige Konzepte:

- **Application**: beschreibt, welche Manifeste (z. B. ein Helm-Chart) aus welchem Git-Repo und Pfad in welchen Cluster/Namespace deployt werden.
- **Project**: gruppiert Applications und begrenzt, welche Repos und Ziel-Namespaces erlaubt sind (Standard: `default`).
- **Sync**: Abgleich zwischen gewünschtem Zustand (Git) und aktuellem Cluster-Zustand.
- **Health**: Zustand der deployten Ressourcen (z. B. Healthy, Progressing, Degraded).

Der zentrale Gedanke: „Git ist Source of Truth“. Direkte Änderungen im Cluster gelten als **Drift**.

Wichtig für Helm: ArgoCD rendert das Chart selbst (wie `helm template`) und wendet die Manifeste an. Das Release taucht deshalb **nicht** in `helm list` auf. ArgoCD selbst installierst du dagegen mit Helm – es erscheint in `helm list -n argocd`.

## Aufgaben

### Aufgabe 1: ArgoCD im Cluster installieren

**Ziel:** ArgoCD im `kind`-Cluster bereitstellen.

1. Entferne das manuell installierte Helm-Release aus Modul 03 und das von Hand angelegte Pull-Secret aus Modul 04, damit ArgoCD die App übernehmen kann. Das Pull-Secret kommt ab jetzt als `SealedSecret` aus Git (Modul 06):

   ```bash
   helm uninstall azubi-portal -n azubi-portal
   kubectl delete secret artifactory-pull -n azubi-portal
   ```

2. Installiere ArgoCD mit dem Helm-Chart `argo-cd` aus dem Artifactory in den Namespace `argocd`. Dex (Single Sign-on) brauchst du im Lab nicht:

   ```bash
   helm search repo artifactory/argo-cd --versions | head -n 5
   helm install argocd artifactory/argo-cd --version <chart-version> -n argocd --create-namespace \
     --set dex.enabled=false
   kubectl get pods -n argocd -w
   ```

   Die ArgoCD-Images stehen im Chart mit ihren Original-Adressen (z. B. `quay.io/argoproj/argocd`) und kommen über den Registry-Mirror aus dem Artifactory. Hängt ein Pod in `ImagePullBackOff`, zeigt `kubectl describe pod` die Registry. Gibt es für sie keinen Mirror, frag deinen Ausbilder nach dem passenden Remote-Repo.

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

2. Committe die Datei und wende sie **einmalig** an (in Modul 09 automatisierst du auch diesen Schritt):

   ```bash
   kubectl apply -f gitops/cluster/argocd-apps/azubi-portal.yaml
   ```

3. Die Application steht nun auf „OutOfSync“. Führe im UI einen **Sync** aus (oder `argocd app sync azubi-portal`) und prüfe die Ressourcen im Cluster.
4. Prüfe, ob die `SealedSecret`-Dateien aus Modul 06 entschlüsselt wurden und das Passwort im Container ankommt:

   ```bash
   kubectl get sealedsecrets,secrets -n azubi-portal
   kubectl exec -n azubi-portal deploy/azubi-portal -- env | grep PASSWORD
   ```

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
5. Teste `prune`: Entferne in Git eine Ressource (z. B. setze `ingress.enabled: false`) und beobachte, dass ArgoCD den Ingress löscht. Setze den Wert danach per Merge Request wieder auf `true` – in Modul 08 brauchst du den Ingress für den Lasttest.
6. Notiere, welche Art von Änderungen du bei GitOps nie direkt im Cluster machen solltest.

### Aufgabe 6: Fehlerhaftes Release und Rollback per Git

**Ziel:** Verstehen, dass ein Rollback bei GitOps ein Git-Revert ist.

1. Setze in `values-lab.yaml` ein Image-Tag, das es im Artifactory nicht gibt, und merge die Änderung.
2. Beobachte im UI den Health-Status „Degraded“/„Progressing“.
3. Mache die Änderung mit `git revert <commit>` rückgängig, pushe und beobachte, wie ArgoCD den alten Zustand wiederherstellt.

Warum ist `helm rollback` hier keine gute Idee?

### Bonus-Aufgaben (für Fortgeschrittene)

- **Chart aus dem Artifactory:** Lege eine zweite Application an, die dein Chart `azubi-portal` in Version `0.3.1` aus dem OCI-Repo im Artifactory (Modul 04) nutzt und die Values aus Git holt ([Multiple Sources](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)). Hinterlege dazu das OCI-Repo in ArgoCD als Helm-Repository mit „Enable OCI“ und den Zugangsdaten eines technischen Benutzers.
- Installiere den Monitoring-Stack aus Modul 08 als eigene ArgoCD-Application. Als `repoURL` dient das Helm-Repo im Artifactory (`https://<artifactory-host>/artifactory/api/helm/<helm-repo>`), dazu `chart` und eine feste `targetRevision`.
- Lege ein eigenes `AppProject` `lab` an, das nur dein GitLab-Repo und die Namespaces `azubi-portal` und `monitoring` erlaubt.

## Du bist fertig, wenn …

- [ ] die Application `azubi-portal` in ArgoCD „Synced“ und „Healthy“ ist
- [ ] eine Änderung per Merge Request automatisch im Cluster ankommt
- [ ] eine manuelle Änderung im Cluster von ArgoCD zurückgesetzt wird
- [ ] du ein fehlerhaftes Release per `git revert` behoben hast
- [ ] `PASSWORD` aus dem `SealedSecret` im Container ankommt

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
- `SealedSecret` wird nicht entschlüsselt (`kubectl describe sealedsecret -n azubi-portal`): Existiert schon ein gleichnamiges, von Hand angelegtes Secret, lässt der Controller es in Ruhe. Lösche das alte Secret einmalig.
- Pods hängen mit `ImagePullBackOff` und `401`: Das `SealedSecret` für `artifactory-pull` fehlt im Chart oder wurde für einen anderen Namespace verschlüsselt.

## Aufräumen

ArgoCD und `azubi-portal` bleiben für Modul 08 und 09 installiert.

## Weiterführend

- [App-of-Apps-Muster](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) (wird in Modul 09 genutzt)
- [Automated Sync Policy](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)

Eine Musterlösung findest du unter [solutions/modul-07](./solutions/modul-07/).
