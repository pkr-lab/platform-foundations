# Hinweise für Autoren und KI-Assistenten

Dieses Repository ist ein Lern-Lab für Auszubildende. Änderungen sollen das Lab verständlich, konsistent und lauffähig halten.

## Sprache und Stil

- Alle Texte auf Deutsch, mit echten Umlauten (ä, ö, ü, ß) – keine Umschreibungen wie „ae“.
- Azubis werden mit „du“ angesprochen.
- Fachbegriffe (Pod, Deployment, Merge Request, …) bleiben englisch.
- Keine Kommentare in Code- und YAML-Dateien; Erklärungen gehören in die Module oder nach `docs/`.

## Aufbau eines Moduls

Jedes Modul `NN-thema.md` im Repo-Root enthält in dieser Reihenfolge:

1. Kurzbeschreibung
2. Lernziele
3. Voraussetzungen
4. Theorie (Kurzüberblick)
5. Aufgaben mit **Ziel**, nummerierten Schritten und Beispielbefehlen
6. Bonus-Aufgaben
7. Du bist fertig, wenn … (Checkliste)
8. Verständnisfragen
9. Häufige Stolperfallen & Tipps
10. Aufräumen
11. Weiterführend
12. Verweis auf `solutions/modul-NN/`

Ausnahme: Das Abschlussprojekt (Modul 09) hat statt Aufgaben, Bonus, Checkliste und Verständnisfragen eine Projektbeschreibung, Projektphasen und eine Bewertungs-Checkliste.

## Konventionen

- Durchgängige Beispiel-App: `azubi-portal` im Namespace `azubi-portal`.
- Ports gemäß [docs/Ports.md](./docs/Ports.md); 8080/8443 sind für den kind-Ingress reserviert.
- GitOps-Struktur gemäß Modul 06: `gitops/apps/<app>/` (Chart direkt im Ordner) und `gitops/cluster/argocd-apps/`.
- Images und Helm-Charts kommen ausschließlich über das JFrog Artifactory (siehe [docs/Artifactory.md](./docs/Artifactory.md)). In eigenen Manifesten und Values-Dateien steht die vollständige Artifactory-Adresse; fremde Charts nutzen den Registry-Mirror aus Modul 01.
- Images immer mit festem Tag, nie `latest` oder `stable`. Helm-Charts immer mit `--version` bzw. fester `targetRevision`.
- Podman läuft rootless: kein `sudo` vor `podman` oder `kind`.
- Platzhalter in spitzen Klammern, Artifactory-Platzhalter gemäß [docs/Artifactory.md](./docs/Artifactory.md#platzhalter): `<artifactory-host>`, `<docker-remote-repo>`, `<docker-local-repo>`, `<helm-repo>`, `<helm-oci-repo>`, außerdem `<dein-gitlab-repo-url>`, `<chart-version>`.
- Das Repository ist öffentlich: keine echten Hostnamen, Firmennamen, Benutzer oder Tokens.
- Aufgaben geben Ziel und Hinweise; vollständige Lösungen stehen nur unter `solutions/`.

## Bei Änderungen

- Neue oder geänderte Dateien in `docs/` dokumentieren.
- Chart-Änderungen: `version` in `Chart.yaml` erhöhen und `docs/azubi-portal-chart.md` anpassen.
- Wird ein Modul eingefügt oder umbenannt: `README.md`, `docs/Repository-Struktur.md`, `solutions/README.md` und Querverweise („Modul NN“) in allen Modulen anpassen.
- Vor dem Commit die Prüfungen aus [docs/Repository-Struktur.md](./docs/Repository-Struktur.md#ci-prüfungen) ausführen.
