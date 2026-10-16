# Modul 05 – GitLab & GitOps-Struktur

## Kurzbeschreibung

In diesem Modul bereitest du dein GitLab-Repository für GitOps vor. Du entwirfst eine Struktur für Cluster- und Applikationskonfiguration, legst die Konfiguration von `azubi-portal` darin ab und lernst einfache Regeln für Branches, Merge Requests und den Umgang mit Secrets kennen.

## Lernziele

- ein GitLab-Repository für das Lab anlegen und klonen
- eine sinnvolle Verzeichnisstruktur für GitOps-Konfiguration definieren
- entscheiden, was in Git gehört und was in ein Artifactory (Modul 04)
- grundlegende Regeln für Branches und Merge Requests formulieren
- verstehen, warum Secrets nicht im Klartext ins Repo gehören und welche Alternativen es gibt

## Voraussetzungen

- Modul 01–04 abgeschlossen
- Zugriff auf GitLab und ein Projekt, in dem du arbeiten darfst

## Theorie (Kurzüberblick)

### GitOps-Grundidee

Beim [GitOps](https://opengitops.dev/)-Ansatz ist der gewünschte Zustand des Clusters in Git gespeichert. Änderungen erfolgen per Commit und Merge Request; ein GitOps-Controller (z. B. ArgoCD, Modul 06) synchronisiert diesen Zustand in den Cluster. Die vier OpenGitOps-Prinzipien: **deklarativ**, **versioniert und unveränderlich**, **automatisch gezogen** (pull), **kontinuierlich abgeglichen**.

### Git und Artifactory im Zusammenspiel

| Gehört in Git | Gehört ins Artifactory |
| --- | --- |
| Helm-Charts als Quelltext (oder nur eine Referenz darauf) | gebaute Container-Images |
| Values-Dateien pro Umgebung | paketierte Helm-Charts (`.tgz` / OCI) |
| ArgoCD-Applications | Binaries, Installer |
| Doku, README | |

In Git steht also z. B. `image.tag: "1.0.1"` – das Image selbst liegt im Artifactory.

### Repo-Struktur

Eine klare Verzeichnisstruktur trennt Cluster-weite von App-spezifischer Konfiguration. In diesem Lab verwenden wir **verbindlich** folgende Struktur (Module 06 und 08 beziehen sich darauf):

```text
gitops/
├── README.md
├── cluster/
│   └── argocd-apps/
│       └── azubi-portal.yaml
└── apps/
    └── azubi-portal/
        ├── Chart.yaml
        ├── values.yaml
        ├── values-lab.yaml
        └── templates/
            └── ...
```

Das Chart liegt also **direkt** im Ordner `gitops/apps/azubi-portal/`, daneben die umgebungsspezifische `values-lab.yaml`. So zeigt eine ArgoCD-Application später einfach auf `path: gitops/apps/azubi-portal`.

### Branches und Merge Requests

Auch im Lab lohnt sich ein einfacher Flow (siehe [GitLab Branches](https://docs.gitlab.com/ee/user/project/repository/branches/) und [Merge Requests](https://docs.gitlab.com/ee/user/project/merge_requests/)):

- `main` repräsentiert den gewünschten Zustand im Lab-Cluster
- Änderungen passieren auf Feature-Branches
- Merge Requests machen Änderungen sichtbar, diskutierbar und bewusst übernehmbar

### Secrets in GitOps

Weil im Git-Repo alles steht, was im Cluster laufen soll, stellt sich die Frage: Wohin mit Passwörtern? Ein Kubernetes-Secret ist nur base64-kodiert (Modul 02) und darf **nicht** ins Repo. Gängige Lösungen:

- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets): Secrets werden mit einem öffentlichen Schlüssel des Clusters verschlüsselt; nur der Controller im Cluster kann sie entschlüsseln. Das verschlüsselte `SealedSecret` darf ins Repo.
- [SOPS](https://github.com/getsops/sops): verschlüsselt Werte in YAML-Dateien, z. B. mit age- oder GPG-Schlüsseln.
- [External Secrets Operator](https://external-secrets.io/): Secrets bleiben in einem externen Tresor (z. B. HashiCorp Vault), im Repo steht nur eine Referenz.

## Aufgaben

### Aufgabe 1: GitLab-Repo vorbereiten

**Ziel:** Ein eigenes GitLab-Repo für das Lab nutzen.

1. Erstelle ein neues Projekt in GitLab (z. B. `k8s-lab-gitops`) oder wähle ein bestehendes, das du verwenden darfst.
2. Klone das Repo in deine WSL-Umgebung.
3. Lege einen Ordner `gitops/` an.

```bash
git clone <gitlab-url-deines-projekts>
cd <projektordner>
mkdir -p gitops/cluster/argocd-apps gitops/apps
```

### Aufgabe 2: `azubi-portal` ins Repo bringen

**Ziel:** Chart und Lab-Konfiguration nach der oben beschriebenen Struktur ablegen.

1. Arbeite auf einem Feature-Branch:

   ```bash
   git switch -c feature/azubi-portal
   ```

2. Kopiere dein Chart aus Modul 03 **direkt** nach `gitops/apps/azubi-portal/`:

   ```bash
   cp -r ~/k8s-lab/azubi-portal-chart gitops/apps/azubi-portal
   ```

3. Lege `gitops/apps/azubi-portal/values-lab.yaml` an bzw. übernimm sie aus Modul 03/04. Achte darauf, dass sie **keine Zugangsdaten** enthält – `imagePullSecrets` verweist nur auf den Namen eines Secrets, das ist unkritisch.
4. Prüfe das Chart, bevor du committest:

   ```bash
   helm lint gitops/apps/azubi-portal -f gitops/apps/azubi-portal/values-lab.yaml
   helm template azubi-portal gitops/apps/azubi-portal -f gitops/apps/azubi-portal/values-lab.yaml
   ```

5. Committe und pushe:

   ```bash
   git add gitops/
   git commit -m "Add GitOps structure and azubi-portal chart"
   git push -u origin feature/azubi-portal
   ```

### Aufgabe 3: README und Workflow dokumentieren

**Ziel:** Struktur und Regeln für andere nachvollziehbar machen.

1. Lege `gitops/README.md` an und beschreibe:
   - wofür `cluster/` und `apps/` gedacht sind
   - welche Values-Datei für welche Umgebung gilt
   - wo die Images und Charts liegen (Artifactory-Repos aus Modul 04)
2. Beschreibe deinen Workflow, z. B.:
   - Änderungen nur auf Feature-Branches
   - Merge Requests nach `main`, mit kurzer Beschreibung *was* und *warum*
   - vor dem Merge: `helm lint` / `helm template` erfolgreich, Änderung plausibel
3. Erstelle in GitLab einen Merge Request von `feature/azubi-portal` nach `main`, lass ihn von jemandem anschauen und merge ihn.
4. Optional: Richte unter „Settings → Repository → Protected branches“ ein, dass niemand direkt auf `main` pushen darf.

### Aufgabe 4: Secrets richtig behandeln

**Ziel:** Verstehen, wie ein Secret sicher in ein GitOps-Repo kommt.

1. Lege zum Test eine Datei mit einem Klartext-Secret an und schau dir mit `git diff` an, was im Repo landen würde. **Committe sie nicht.**
2. Ergänze eine `.gitignore`, die z. B. `*.secret.yaml` und `*.tar` ausschließt.
3. Installiere den Sealed-Secrets-Controller und das CLI `kubeseal` ([Anleitung](https://github.com/bitnami-labs/sealed-secrets#installation)).
4. Verschlüssele das Secret aus Modul 02 und lege das Ergebnis unter `gitops/apps/azubi-portal/templates/sealedsecret.yaml` ab:

   ```bash
   kubectl create secret generic azubi-portal-secret -n azubi-portal \
     --from-literal=PASSWORD=supergeheim --dry-run=client -o yaml \
     | kubeseal --format yaml > sealedsecret.yaml
   ```

5. Schau dir die Datei an. Warum ist es in Ordnung, diese Datei zu committen?

### Bonus-Aufgaben (für Fortgeschrittene)

- Lege eine zweite Umgebung `values-test.yaml` an. Welche Werte würden sich zwischen `lab` und `test` unterscheiden?
- Schreibe eine GitLab-CI-Pipeline (`.gitlab-ci.yml`), die bei jedem Merge Request `helm lint` und `helm template | kubeconform` ausführt. Tipp: Das Image für die Pipeline kommt natürlich aus dem Artifactory.
- Variante „Chart aus dem Artifactory“: Lege in Git nur noch die `values-lab.yaml` ab und referenziere ein Chart, das als OCI-Artefakt im Artifactory liegt. Welche Vor- und Nachteile hat das? (Umsetzung in Modul 06, Bonus.)

## Du bist fertig, wenn …

- [ ] dein GitLab-Repo die Struktur `gitops/cluster/argocd-apps` und `gitops/apps/azubi-portal` enthält
- [ ] `helm lint gitops/apps/azubi-portal` ohne Fehler durchläuft
- [ ] die Änderungen über einen Merge Request nach `main` gekommen sind
- [ ] kein Klartext-Secret im Repo liegt (prüfe mit `git log -p | grep -i password`)

## Verständnisfragen

1. Was unterscheidet GitOps von „ich mache `helm upgrade` von meinem Laptop“?
2. Warum liegt das Image nicht im Git-Repo, sondern im Artifactory?
3. Warum ist ein Secret, das einmal committet wurde, auch nach dem Löschen nicht mehr sicher?
4. Wozu dient ein Merge Request, wenn du sowieso alleine im Repo arbeitest?

## Häufige Stolperfallen & Tipps

- Pfade müssen überall gleich sein: Repo-Struktur, `helm lint`-Aufruf und später die ArgoCD-Application (`gitops/apps/azubi-portal`).
- Halte dich an die `gitops/`-Struktur, statt Dateien in den Root deines Projekts zu legen.
- Commit-Messages sollten sagen, *was* sich ändert (z. B. "Increase azubi-portal replicas to 3").
- Ein versehentlich committetes Secret: sofort das Passwort ändern – das Entfernen aus der Historie allein reicht nicht.

## Weiterführend

- [OpenGitOps-Prinzipien](https://opengitops.dev/)
- [Kubernetes: Good practices for Secrets](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)

Eine Musterlösung findest du unter [solutions/modul-05](./solutions/modul-05/).
