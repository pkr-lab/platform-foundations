# Modul 04 – GitLab & GitOps-Struktur

## Kurzbeschreibung

In diesem Modul bereitest du dein GitLab-Repository für GitOps vor. Du entwirfst eine sinnvolle Struktur für Cluster- und Applikationskonfiguration und lernst einfache, generische Regeln für Branches und Merge Requests kennen.

## Lernziele

- GitLab-Repository für das Lab anlegen oder auswählen
- sinnvolle Verzeichnisstruktur für GitOps-Konfiguration definieren
- grundlegende Regeln für Branches und Merge Requests formulieren (generisch)

## Voraussetzungen

- Modul 01–03 abgeschlossen
- Zugriff auf GitLab und ein Projekt, in dem du arbeiten darfst

## Theorie (Kurzüberblick)

### GitOps-Grundidee

Beim [GitOps](https://opengitops.dev/)-Ansatz ist der gewünschte Zustand des Clusters in Git gespeichert. Änderungen erfolgen per Commit und Merge Request; ein GitOps-Controller (z. B. ArgoCD) synchronisiert diesen Zustand in den Cluster.

### Repo-Struktur

Eine klare Verzeichnisstruktur hilft, Basis-Konfiguration des Clusters von Applikations-Konfiguration zu trennen. Beispiele:

- `cluster/` für Cluster-weite Einstellungen (z. B. Namespaces, Basis-RBAC, ArgoCD-Applications)
- `apps/` für Applikationen (z. B. pro App ein Unterordner mit Helm-Chart-Referenzen)

Du kannst diese Struktur bei Bedarf weiter verfeinern, z. B. mit Unterordnern wie `cluster/base` und `cluster/apps`.

### Branches und Merge Requests (generisch)

Auch im Lab lohnt sich ein einfacher Flow (siehe auch [GitLab Branches](https://docs.gitlab.com/ee/user/project/repository/branches/) und [Merge Requests](https://docs.gitlab.com/ee/user/project/merge_requests/)):

- eine Hauptbranch (z. B. `main`), die den gewünschten Zustand im Lab-Cluster repräsentiert
- Feature- oder Topic-Branches für Änderungen
- Merge Requests, um Änderungen zu besprechen und bewusst zu übernehmen

## Aufgaben

### Aufgabe 1: GitLab-Repo vorbereiten

**Ziel:** Ein eigenes GitLab-Repo für das Lab nutzen.

1. Erstelle ein neues Projekt in GitLab oder wähle ein bestehendes, das du für das Lab verwenden darfst.
2. Klone das Repo in deine WSL-Umgebung.
3. Lege einen Ordner an, z. B. `gitops/`, in dem du alle Konfigurationen sammelst.

Beispiel:

```bash
git clone <gitlab-url-deines-projekts>
cd <projektordner>
mkdir -p gitops
```

### Aufgabe 2: Grundstruktur für GitOps-Konfiguration definieren

**Ziel:** Eine erste Struktur für Cluster- und App-Konfiguration anlegen.

1. Erzeuge unter `gitops/` mindestens folgende Ordner:
   - `gitops/cluster/`
   - `gitops/apps/`
2. Lege im Ordner `gitops/apps/` einen Unterordner für deine Beispiel-App `azubi-portal` an, z. B. `gitops/apps/azubi-portal/`.
3. Füge eine `README.md` in `gitops/` hinzu, die kurz erklärt, wofür die einzelnen Ordner gedacht sind (z. B. `cluster/` für Cluster-weite Ressourcen wie Namespaces und ArgoCD-Applications, `apps/` für App-spezifische Konfigurationen wie Helm-Charts und Values-Dateien).

### Aufgabe 3: Helm-Release-Konfiguration für `azubi-portal` ins Repo bringen

**Ziel:** Helm-Konfiguration aus Modul 03 in Git ablegen.

1. Nimm dein `azubi-portal`-Helm-Chart aus Modul 03 (oder eine darauf basierende Variante).
2. Lege die Chart-Dateien (oder eine Referenz darauf, z. B. als Git-Submodul) im Ordner `gitops/apps/azubi-portal/` ab (z. B. in einem Unterordner `chart/`).
3. Überlege, welche Konfigurationswerte (Values) du in Git versionieren möchtest, und lege entsprechende Values-Dateien an, z. B. `gitops/apps/azubi-portal/values-lab.yaml` für dein Lab-Setup.
4. Committe deine Änderungen mit einer sinnvollen Commit-Message.

Hinweis: Du kannst Charts direkt in diesem Repo ablegen oder externe Charts aus einem Helm-Repository nutzen und nur deine `values-*.yaml`-Dateien versionieren.

Beispiel:

```bash
git status
git add gitops/
git commit -m "Add initial GitOps structure and azubi-portal configuration"
git push origin <branch-name>
```

### Aufgabe 4: Einfache Branch- und MR-Regeln festlegen

**Ziel:** Minimalen Git-Workflow im Lab definieren.

1. Notiere in der `gitops/README.md` kurz deinen vorgeschlagenen Workflow, z. B.:
   - Änderungen an Konfiguration immer auf einem Feature-Branch durchführen (z. B. wenn du `values-lab.yaml` für `azubi-portal` änderst)
   - Merge Requests in `main` stellen
   - vor Merge kurz prüfen, ob die Änderung plausibel ist (z. B. passt die Änderung an `replicaCount` oder `welcomeMessage` zum gewünschten Lab-Zustand?)
2. Optional: Lege in GitLab eine einfache Branch-Regel an, die direkte Pushes auf `main` verhindert (wenn du die Berechtigungen hast).

### Bonus-Aufgaben (für Fortgeschrittene)

- Überlege dir, wie du zusätzlich zu `values-lab.yaml` eine weitere Umgebung (z. B. `values-test.yaml`) innerhalb derselben Struktur abbilden würdest.
- Skizziere in der `gitops/README.md`, wie du ArgoCD-Applications im Ordner `gitops/cluster/` als YAML-Ressourcen versionieren könntest (z. B. eine `azubi-portal-application.yaml`).

## Häufige Stolperfallen & Tipps

- Unterschiedliche Pfade zwischen ArgoCD-Application und Repository: stelle sicher, dass du überall denselben Pfad (z. B. `gitops/apps/azubi-portal`) verwendest.
- Zu viele Dateien im Root deines GitLab-Projekts: halte dich an die `gitops/`-Struktur, um Konfiguration übersichtlich zu halten.
- Commit-Messages ohne Aussagekraft erschweren spätere Nachvollziehbarkeit. Nutze kurze, sprechende Beschreibungen (z. B. "Adjust azubi-portal replicas for lab").

## Weiterführend

- Schau dir Beispiele von öffentlichen GitOps-Repositories an, um Ideen für Strukturen zu bekommen.
- Überlege, wie du verschiedene Umgebungen (dev, test) später innerhalb derselben Struktur abbilden würdest.
