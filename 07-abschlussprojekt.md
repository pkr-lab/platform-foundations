# Modul 07 – Abschlussprojekt (GitOps-Fokus)

## Kurzbeschreibung

Im Abschlussprojekt setzt du das Gelernte aus den vorherigen Modulen ein, um ein kleines, aber vollständiges Szenario umzusetzen. Du planst und betreibst eine einfache Anwendung, die ausschließlich über GitOps (GitLab + ArgoCD) in den Cluster gelangt.

## Lernziele

- ein kleines Anwendungsszenario selbst planen
- Anwendung als Helm-Chart modellieren oder vorhandenes Chart sauber anpassen
- GitOps-Flow mit GitLab und ArgoCD vollständig umsetzen
- die wichtigsten Schritte dokumentieren und erklären können

## Voraussetzungen

- Modul 01–06 abgeschlossen

## Projektbeschreibung

Wähle eine einfache Anwendung (z. B. statische Website, kleiner API-Service oder ähnliches), die in einem Pod laufen kann. Das Projekt soll bewusst klein bleiben, damit du dich auf den GitOps-Flow konzentrieren kannst.

Anforderungen:

- Deployment der Anwendung erfolgt ausschließlich über GitLab + ArgoCD
- Konfiguration liegt in deinem GitOps-Repo
- der Zustand im Cluster wird nicht manuell per `kubectl apply` geändert (außer für Debugging/Analyse)

## Projektphasen & Aufgaben

### Phase 1: Planung

1. Beschreibe in einem kurzen Abschnitt (z. B. in einer Datei `abschlussprojekt-notes.md` oder im GitLab-Repo-README), welche Anwendung du deployen möchtest und wie sie grob aufgebaut ist.
2. Überlege dir, welche Konfiguration du brauchst (z. B. Port, Umgebungsvariablen, evtl. ConfigMap/Secret).

### Phase 2: Helm-Chart / App-Konfiguration

1. Erstelle ein neues Helm-Chart für deine Anwendung oder passe ein bestehendes Chart so an, dass es deine Anforderungen erfüllt.
2. Lege passende Values-Dateien an (z. B. `values-lab.yaml`).
3. Teste das Chart einmal lokal per `helm install`/`helm upgrade`, um sicherzustellen, dass es grundsätzlich funktioniert.

Beispiel:

```bash
helm install abschlussprojekt ./<pfad-zu-deinem-chart> -n abschlussprojekt --create-namespace
helm upgrade abschlussprojekt ./<pfad-zu-deinem-chart> -n abschlussprojekt -f values-lab.yaml
```

### Phase 3: GitOps-Integration

1. Integriere dein Chart und die Values-Datei in die bestehende GitOps-Struktur (z. B. unter `gitops/apps/<deine-app>/`).
2. Lege in ArgoCD eine Application für dein Abschlussprojekt an, die auf diesen Pfad zeigt.
3. Halte die Definition dieser Application idealerweise ebenfalls als YAML im GitOps-Repo fest (z. B. unter `gitops/cluster/argocd-apps/`) und wende sie per `kubectl apply` an.
4. Führe einen Sync durch und prüfe, ob die Anwendung im Cluster läuft.

### Phase 4: Änderungen und Rollbacks

1. Führe mindestens eine sinnvolle Änderung an deiner Anwendung oder Konfiguration durch (z. B. Anpassung eines Textes, Änderung der Replikas, neue Env-Variable).
2. Committe die Änderung in GitLab und beobachte, wie ArgoCD sie ausrollt.
3. Optional: Simuliere ein fehlerhaftes Release (z. B. falsches Image-Tag) und nutze GitOps/Helm, um wieder auf einen funktionierenden Stand zurückzukehren.

### Phase 5: Dokumentation & Reflexion

1. Erstelle ein kurzes Markdown-Dokument in deinem Repo (z. B. `abschlussprojekt-bericht.md`) mit:
   - kurzer Beschreibung der Anwendung
   - Überblick über den GitOps-Flow (welche Repos, Pfade, Applications)
   - 2–3 Punkten, was gut funktioniert hat
   - 2–3 Punkten, was du beim nächsten Mal anders machen würdest
2. (Optional) Bereite eine kurze mündliche Vorstellung vor, in der du deinem Team den Flow live zeigst.

## Weiterführend

- Überlege, wie du dein Projekt erweitern könntest (z. B. zweiter Service, Hintergrundjobs, einfache Authentifizierung).
- Denke darüber nach, welche Teile deines Labs du später produktionsnäher gestalten würdest (z. B. mehr Security, komplexere Monitoring/Alerting-Konzepte).
