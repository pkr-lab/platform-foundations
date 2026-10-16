# Modul 05 – ArgoCD & GitOps-Flow

## Kurzbeschreibung

In diesem Modul setzt du ArgoCD in deinem lokalen Cluster auf und verbindest es mit deinem GitLab-Repo. Du lernst, wie ArgoCD den gewünschten Zustand aus Git in den Cluster synchronisiert, Drift erkennt und Self-Healing durchführt.

## Lernziele

- ArgoCD im `kind`-Cluster installieren und erreichen
- ArgoCD mit dem GitLab-Repo verbinden
- Anwendungen als ArgoCD Applications definieren
- GitOps-Flow Ende-zu-Ende nachvollziehen (Commit → Sync → Rollout)
- Config-Drift und Self-Healing beobachten

## Voraussetzungen

- Modul 01–04 abgeschlossen
- GitLab-Repo mit GitOps-Struktur vorhanden

## Theorie (Kurzüberblick)

### ArgoCD-Grundkonzepte

[ArgoCD](https://argo-cd.readthedocs.io/en/stable/) ist ein GitOps-Controller für Kubernetes. Wichtige Konzepte:

- **Application**: beschreibt, welche Manifeste (z. B. Helm-Chart) aus welchem Git-Repo und welchem Pfad in welchen Cluster/Namespace deployt werden sollen.
- **Sync**: Abgleich zwischen gewünschtem Zustand (Git) und aktuellem Cluster-Zustand.
- **Health**: Zustand der deployten Ressourcen (z. B. Healthy, Degraded).

Der zentrale Gedanke: „Git ist Source of Truth“. Direktes Ändern von Ressourcen im Cluster gilt als Drift und wird von ArgoCD angezeigt.

## Aufgaben

### Aufgabe 1: ArgoCD im Cluster installieren

**Ziel:** ArgoCD im `kind`-Cluster bereitstellen.

1. Installiere ArgoCD im Cluster (z. B. per offiziellen Manifests oder Helm-Chart). Nutze einen eigenen Namespace (z. B. `argocd`).
2. Prüfe mit `kubectl get pods -n argocd`, ob alle ArgoCD-Komponenten laufen.
3. Richte den Zugriff auf das ArgoCD-Web-UI ein (z. B. per Port-Forwarding oder Ingress, je nach Lab-Setup).
4. Logge dich im UI ein und verschaffe dir einen Überblick über die Ansicht.

Beispiel (Port-Forwarding):

```bash
kubectl get pods -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Danach im Browser: https://localhost:8080
```

Standard-Login (falls nicht angepasst):

```bash
# Benutzername: admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Nutze dieses Passwort für den ersten Login im Web-UI und ändere es danach.

### Aufgabe 2: Erste Application fuer `azubi-portal` anlegen

**Ziel:** Helm-basierte App `azubi-portal` ueber ArgoCD deployen.

1. Lege in ArgoCD eine neue Application an, die auf dein GitLab-Repo zeigt.
2. Waehle den Pfad zu deiner App-Konfiguration (z. B. `gitops/apps/azubi-portal/`) und die passende Helm-Chart/Values-Kombination.
3. Setze Cluster-Ziel und Namespace auf deinen lokalen Cluster und den Namespace `azubi-portal`.
4. Fuehre einen Sync durch und pruefe, ob die Ressourcen im Cluster erstellt werden.

Beispiel für eine ArgoCD-Application (YAML, falls du nicht nur das UI nutzt):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: azubi-portal
  namespace: argocd
spec:
  destination:
    namespace: azubi-portal
    server: https://kubernetes.default.svc
  project: default
  source:
    repoURL: <dein-gitlab-repo-url>
    targetRevision: main
    path: gitops/apps/azubi-portal
    helm:
      valueFiles:
        - values-lab.yaml
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
``` 

Hinweis:

- Wenn dein GitLab-Repo privat ist, musst du in ArgoCD unter "Settings → Repositories" Zugangsdaten (HTTPS-Token oder SSH-Key) hinterlegen.
- Mit `syncPolicy.automated.selfHeal: true` kann ArgoCD Abweichungen vom Git-Zustand automatisch korrigieren, ohne dass du manuell auf "Sync" klicken musst.

### Aufgabe 3: GitOps-Flow fuer `azubi-portal` erleben (Commit → Sync)

**Ziel:** Verstehen, wie Aenderungen in Git im Cluster landen.

1. Aendere in deinem GitLab-Repo eine kleine Konfiguration deiner `azubi-portal`-App (z. B. `replicaCount` oder `welcomeMessage` in `values-lab.yaml`).
2. Committe die Aenderung und pushe sie nach GitLab.
3. Beobachte in ArgoCD, wie die Application „OutOfSync" wird und wie ein automatischer oder manueller Sync den neuen Zustand ausrollt.
4. Verifiziere im Cluster mit `kubectl`, dass die Aenderung angekommen ist.

### Aufgabe 4: Config-Drift und Self-Healing

**Ziel:** Verstehen, wie ArgoCD Abweichungen vom Git-Zustand erkennt und behebt.

1. Aendere eine Ressource deiner `azubi-portal`-App direkt im Cluster per `kubectl` (z. B. setze die Replikas des Deployments manuell hoch oder aendere ein Label).
2. Warte kurz und beobachte im ArgoCD-UI, wie die Application als „OutOfSync" angezeigt wird.
3. Fuehre einen Sync durch (oder aktiviere `selfHeal` in der `syncPolicy`) und beobachte, wie ArgoCD deine manuelle Aenderung zuruecksetzt.
4. Notiere, welche Art von Aenderungen du lieber nie direkt im Cluster machen solltest, wenn GitOps verwendet wird.

### Bonus-Aufgaben (fuer Fortgeschrittene)

- Lege eine zweite ArgoCD-Application an (z. B. fuer einen Monitoring-Stack) und beobachte, wie mehrere Applications parallel verwaltet werden.
- Experimentiere mit unterschiedlichen Sync-Strategien (z. B. automatischer Sync mit `prune` und `selfHeal`) und dokumentiere, welches Verhalten du bevorzugen wuerdest.

## Haeufige Stolperfallen & Tipps

- Privat-Repo in GitLab: ArgoCD braucht gueltige Zugangsdaten (HTTPS-Token oder SSH-Key) unter „Settings → Repositories".
- Falscher Pfad (`spec.source.path`): stelle sicher, dass `gitops/apps/azubi-portal` im Repo existiert und die erwarteten Dateien enthaelt.
- Application muss im Namespace `argocd` angelegt werden (Standard-Setup), sonst sieht der ArgoCD-Controller sie nicht.
- Wenn Health- oder Sync-Status unklar sind, hilft ein Blick in `kubectl describe application azubi-portal -n argocd` sowie die Events im UI.

## Weiterführend

- Schau dir an, wie ArgoCD mit mehreren Applications organisiert werden kann (z. B. App-of-Apps-Muster).
- Experimentiere mit automatischen Sync-Strategien und Health-Checks.
