# Modul 08 – Abschlussprojekt (GitOps-Fokus)

## Kurzbeschreibung

Im Abschlussprojekt setzt du das Gelernte aus den vorherigen Modulen ein, um ein kleines, aber vollständiges Szenario umzusetzen. Du planst und betreibst eine einfache Anwendung, deren Artefakte im Artifactory liegen und die ausschließlich über GitOps (GitLab + ArgoCD) in den Cluster gelangt.

## Lernziele

- ein kleines Anwendungsszenario selbst planen
- die Anwendung als Helm-Chart modellieren oder ein vorhandenes Chart sauber anpassen
- Images und Charts über ein Artifactory (oder die lokale Registry) bereitstellen
- den GitOps-Flow mit GitLab und ArgoCD vollständig umsetzen – inklusive Bootstrap per App-of-Apps
- die wichtigsten Schritte dokumentieren und erklären können

## Voraussetzungen

- Modul 01–07 abgeschlossen

## Projektbeschreibung

Wähle eine einfache Anwendung (z. B. statische Website, kleiner API-Service, [podinfo](https://github.com/stefanprodan/podinfo)), die in einem Pod laufen kann. Das Projekt soll bewusst klein bleiben, damit du dich auf den Ablauf konzentrieren kannst.

Anforderungen:

- Das Container-Image liegt in einer Registry (Artifactory oder lokale Registry aus Modul 04) mit einem **festen Versions-Tag**.
- Die Konfiguration liegt in deinem GitOps-Repo, Secrets nur verschlüsselt (Sealed Secrets) oder gar nicht.
- Das Deployment erfolgt ausschließlich über ArgoCD. Nach dem einmaligen Bootstrap wird **kein** `kubectl apply` mehr ausgeführt (außer `get`/`describe`/`logs` zur Analyse).
- Die App hat Probes, Ressourcen-Requests/-Limits und läuft nicht als root.

## Projektphasen & Aufgaben

### Phase 1: Planung

1. Beschreibe in `abschlussprojekt-notes.md`, welche Anwendung du deployen möchtest und wie sie aufgebaut ist.
2. Überlege dir, welche Konfiguration du brauchst (Port, Umgebungsvariablen, ConfigMap/Secret, Ingress-Host).
3. Skizziere den Weg eines Commits bis in den Cluster (z. B. als Liste oder Diagramm): Git → ArgoCD → Cluster, Image aus Artifactory.

### Phase 2: Image und Helm-Chart

1. Baue (falls nötig) ein eigenes Image und pushe es mit Versions-Tag in die Registry (Modul 04).
2. Erstelle ein Helm-Chart oder passe ein bestehendes an.
3. Lege eine `values-lab.yaml` an.
4. Teste das Chart lokal **ohne** es zu installieren:

   ```bash
   helm lint ./<chart> -f values-lab.yaml
   helm template abschlussprojekt ./<chart> -f values-lab.yaml
   ```

### Phase 3: GitOps-Integration mit App-of-Apps

Statt jede Application einzeln per `kubectl apply` anzulegen, nutzt du das [App-of-Apps-Muster](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/): eine **Root-Application** zeigt auf den Ordner `gitops/cluster/argocd-apps/` und legt alle dort liegenden Applications automatisch an.

1. Lege dein Chart unter `gitops/apps/<deine-app>/` ab.
2. Lege die Application für deine App unter `gitops/cluster/argocd-apps/<deine-app>.yaml` ab (Aufbau wie in Modul 06).
3. Lege die Root-Application `gitops/cluster/root.yaml` an:

   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: root
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: <dein-gitlab-repo-url>
       targetRevision: main
       path: gitops/cluster/argocd-apps
     destination:
       server: https://kubernetes.default.svc
       namespace: argocd
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
   ```

4. Wende **nur** die Root-Application einmalig an (Bootstrap). Ab jetzt entstehen neue Applications allein dadurch, dass du sie in Git hinzufügst:

   ```bash
   kubectl apply -f gitops/cluster/root.yaml
   ```

5. Prüfe in ArgoCD, dass `root`, `azubi-portal` und deine neue App „Synced“ und „Healthy“ sind.

### Phase 4: Änderungen und Rollbacks

1. Führe mindestens eine sinnvolle Änderung per Merge Request durch (z. B. neue Image-Version, geänderter Text, mehr Replikas).
2. Beobachte, wie ArgoCD die Änderung ausrollt.
3. Simuliere ein fehlerhaftes Release (z. B. falsches Image-Tag) und stelle den funktionierenden Stand per `git revert` wieder her.

### Phase 5: Betrieb

1. Ergänze dein Grafana-Dashboard aus Modul 07 um deine neue App.
2. Prüfe mit `kubectl top pods`, ob deine Requests/Limits realistisch sind.

### Phase 6: Dokumentation & Reflexion

1. Erstelle `abschlussprojekt-bericht.md` mit:
   - kurzer Beschreibung der Anwendung
   - Überblick über den Ablauf (Registry, Repos, Pfade, Applications)
   - 2–3 Punkten, was gut funktioniert hat
   - 2–3 Punkten, was du beim nächsten Mal anders machen würdest
2. Bereite eine kurze Vorstellung (10–15 Minuten) vor, in der du deinem Team den Ablauf live zeigst: Commit → Merge Request → ArgoCD → Browser.

## Bewertungs-Checkliste

- [ ] Image liegt mit festem Tag in einer Registry, kein `latest`
- [ ] Chart besteht `helm lint`
- [ ] App wird über die Root-Application (App-of-Apps) verwaltet
- [ ] keine Klartext-Secrets im Repo
- [ ] Probes, Requests/Limits und `runAsNonRoot` sind gesetzt
- [ ] mindestens eine Änderung und ein Rollback sind über Merge Requests in der Git-Historie nachvollziehbar
- [ ] Bericht und Vorstellung erklären den Ablauf verständlich

## Weiterführend

- Wie könntest du dein Projekt erweitern (zweiter Service, CronJob, Datenbank mit PersistentVolume)?
- Wie würde eine GitLab-CI-Pipeline aussehen, die bei einem neuen Tag das Image baut, ins Artifactory pusht und automatisch einen Merge Request mit dem neuen `image.tag` im GitOps-Repo erstellt?
- Welche Teile des Labs würdest du produktionsnäher gestalten (Security, Alerting, Backups, mehrere Umgebungen)?

Eine Beispiel-Root-Application findest du unter [solutions/modul-08](./solutions/modul-08/).
