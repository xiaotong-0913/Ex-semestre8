#!/usr/bin/env bash

# Vérification du nombre d'arguments
if [ $# -ne 1 ]; then
    echo "Erreur : Ce script nécessite exactement un argument (le fichier des URLs)." >&2
    exit 1
fi

fichier=$1  # Fichier contenant les URLs
base_dir=$(dirname "$0") # Répertoire du script
aspirations="$base_dir/../aspirations"
dumps="$base_dir/../dumps-text"
contexte="$base_dir/../contextes"
concordance="$base_dir/../concordances"
output_html="$base_dir/../tableaux/tableau_chinois.html"
concordance_file="$concordance/concordancier_chinois.html"
mot="开放"
n=1  # Initialisation du compteur de lignes

# Création des dossiers si inexistants
mkdir -p "$aspirations" "$dumps" "$contexte" "$concordance" || {
    echo "Erreur : Impossible de créer les répertoires nécessaires." >&2
    exit 1
}

# Initialisation du fichier HTML principal
echo "<!DOCTYPE html>" > "$output_html"
echo "<html>" >> "$output_html"
echo "<head><meta charset=\"UTF-8\"><title>Résultats des URLs</title>" >> "$output_html"
echo "<link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bulma@0.9.3/css/bulma.min.css\">" >> "$output_html"
echo "</head><body><div class=\"container\">" >> "$output_html"
echo "<h1 class=\"title\">Tableau chinois pour \"开放\"</h1>" >> "$output_html"
echo "<table class=\"table is-bordered is-striped is-fullwidth\">" >> "$output_html"
echo "<thead><tr><th>Ligne</th><th>Lien</th><th>Code</th><th>Encodage</th><th>DumpText</th><th>HTML</th><th>Compte</th><th>Contextes</th><th>Concordancier</th></tr></thead>" >> "$output_html"
echo "<tbody>" >> "$output_html"

# Initialisation du fichier de concordance
echo "<!DOCTYPE html>" > "$concordance_file"
echo "<html><head><meta charset=\"UTF-8\"><title>Concordancier Chinois</title>" >> "$concordance_file"
echo "<link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bulma@1.0.2/css/bulma-no-dark-mode.min.css\">" >> "$concordance_file"
echo "</head><body><div class=\"container\">" >> "$concordance_file"
echo "<h1 class=\"title\">Concordancier Complet pour \"开放\"</h1>" >> "$concordance_file"
echo "<table class=\"table is-bordered is-hoverable is-striped\">" >> "$concordance_file"
echo "<thead><tr><th>Numéro du fichier</th><th>Contexte gauche</th><th>Mot</th><th>Contexte droit</th></tr></thead>" >> "$concordance_file"
echo "<tbody>" >> "$concordance_file"

# Lecture ligne par ligne du fichier contenant les URLs
while read -r line; do
    # Récupération du code HTTP et du type de contenu
    response=$(curl -s -I -L -w "%{http_code}\t%{content_type}" -o /dev/null "$line")
    code=$(echo "$response" | cut -f1)
    encoding=$(echo "$response" | grep -Po "charset=\\S+" | cut -d "=" -f2 | tr -d "\r\n")

    if [ "$code" -eq 200 ]; then
        # Définition des fichiers de sortie
        aspiration_file="$aspirations/chinois_${n}.html"
        dump_file="$dumps/chinois_${n}.txt"
        context_file="$contexte/chinois_${n}.txt"

        # Téléchargement et création des fichiers nécessaires
        curl -s -L "$line" -o "$aspiration_file"

        # Conversion en UTF-8 si nécessaire
        if [[ "$encoding" != "UTF-8" && -n "$encoding" ]]; then
            iconv -f "$encoding" -t UTF-8 "$aspiration_file" -o "${aspiration_file}.utf8"
            mv "${aspiration_file}.utf8" "$aspiration_file"
            encoding="UTF-8"
        fi

        lynx -dump -nolist "$aspiration_file" > "$dump_file"

        compte=$(grep -o "$mot" "$dump_file" | wc -l)
        grep -A2 -B2 "$mot" "$dump_file" > "$context_file" # Isoler les occurrences de mot avec 2 lignes

        # Génération des concordances
        grep -oP ".{0,30}$mot.{0,30}" "$dump_file" | while read -r inner_line; do
            left=$(echo "$inner_line" | sed -E "s/(.*)($mot)(.*)/\1/")
            right=$(echo "$inner_line" | sed -E "s/(.*)($mot)(.*)/\3/")
            echo "<tr><td class=\"has-text-right\">$left</td><td class=\"has-text-centered\"><strong>$mot</strong></td><td class=\"has-text-left\">$right</td></tr>" >> "$concordance_file"
        done

        # Ajouter une ligne au tableau HTML principal
        echo "<tr><td>$n</td><td><a href=\"$line\" target=\"_blank\">$line</a></td><td>$code</td><td>${encoding:-N/A}</td>" >> "$output_html"
        echo "<td><a href=\"aspirations/chinois_${n}.html\" target=\"_blank\">html</a></td><td><a href=\"dumps-text/chinois_${n}.txt\" target=\"_blank\">text</a></td>" >> "$output_html"
        echo "<td>$compte</td><td><a href=\"contextes/chinois_${n}.txt\" target=\"_blank\">context</a></td><td><a href=\"concordances/concordancier_chinois.html\" target=\"_blank\">concordance</a></td></tr>" >> "$output_html"
    else
        # URL invalide
        echo "Erreur : $line renvoie un code HTTP $code. Ignorée." >&2
        echo "<tr><td>$n</td><td><a href=\"$line\" target=\"_blank\">$line</a></td><td>$code</td><td>N/A</td><td>N/A</td><td>N/A</td><td>0</td><td>N/A</td><td>N/A</td></tr>" >> "$output_html"
    fi

    n=$((n + 1))  # compteur

done < "$fichier"

# Finalisation des fichiers HTML
echo "</tbody></table></div></body></html>" >> "$output_html"
echo "</tbody></table></div></body></html>" >> "$concordance_file"

echo "Résultats enregistrés dans $output_html et $concordance_file."
