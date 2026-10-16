# Lösung Modul 08

Das Abschlussprojekt hat keine feste Musterlösung. [root.yaml](./root.yaml) zeigt die Root-Application für das App-of-Apps-Muster.

## Ablauf App-of-Apps

```text
gitops/cluster/root.yaml            einmalig per kubectl apply
        │
        ▼
gitops/cluster/argocd-apps/         ArgoCD legt jede Datei als Application an
        ├── azubi-portal.yaml  ──►  gitops/apps/azubi-portal
        └── <deine-app>.yaml   ──►  gitops/apps/<deine-app>
```

Eine neue App entsteht also allein durch einen Merge Request, der eine Datei in `gitops/cluster/argocd-apps/` hinzufügt.
