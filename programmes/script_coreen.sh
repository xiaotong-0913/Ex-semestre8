#!/usr/bin/env bash

file=$1 # fichier contenant les URLs
word="개방" # mot avec expression régulière pour les variantes
line_count=1 # compteur de lignes
output_file="../tableaux/tableau_coreen.html"
concordance_file="../concordances/concordancier_coreen.html"

# Vérification des arguments donnés
if [ $# -ne 1 ]; then
    echo "Ce programme demande un argument : un fichier contenant des URLs."
    exit 1
fi

# Création du tableau HTML principal
echo -e "<!DOCTYPE html>
<html>
<head>
    <meta charset=\"UTF-8\" />
    <title>Tableau coréen</title>
    <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bulma@1.0.2/css/versions/bulma-no-dark-mode.min.css\">
</head>
<body>
<section class=\"section\">
    <div class=\"container\">
        <h1 class=\"title\">Tableau pour \"$word\"</h1>
        <table class=\"table is-bordered is-hoverable is-striped\">
        <thead>
            <tr>
                <th>Ligne</th>
                <th>Lien</th>
                <th>Code</th>
                <th>Encodage</th>
                <th>Mots</th>
                <th>Compte</th>
                <th>Contextes</th>
                <th>Concordancier</th>
            </tr>
        </thead>
        <tbody>" > "$output_file"

# Création du tableau HTML du concordancier
echo -e "<!DOCTYPE html>
<html>
<head>
    <meta charset=\"UTF-8\" />
    <title>Concordancier</title>
    <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bulma@1.0.2/css/versions/bulma-no-dark-mode.min.css\">
</head>
<body>
    <section class=\"section\">
        <div class=\"container\">
            <h1 class=\"title\">Concordancier pour \"$word\"</h1>
            <table class=\"table is-bordered is-hoverable is-striped\">
                <thead>
                    <tr>
                        <th>Numéro du fichier</th>
                        <th>Contexte gauche</th>
                        <th>Mot</th>
                        <th>Contexte droit</th>
                    </tr>
                </thead>
                <tbody>" > "$concordance_file"

# Lecture des URLs
while read -r line; do
    # Fichiers intermédiaires
    html_file="../aspirations/coreen-${line_count}.html"
    dump_file="../dumps-text/coreen-${line_count}.txt"
    context_file="../contextes/coreen-${line_count}.txt"

    # Récupération de la page
    response=$(curl -s -L -w "%{content_type}\t%{http_code}" -o "$html_file" "$line")
    http_code=$(echo "$response" | cut -f2)

    # Vérification du code HTTP
    if [[ $http_code != "200" ]]; then
        echo "La page $line renvoie le code d'erreur $http_code et ne sera pas traitée."
        echo -e "<tr><td>Aucune donnée</td><td>Aucune donnée</td><td>Aucune donnée</td><td colspan=\"5\">Aucune donnée</td></tr>" >> "$output_file"
        line_count=$((line_count + 1))
        continue
    fi

    # Extraction de l'encodage
    content_type=$(echo "$response" | cut -f1)
    encoding=$(echo "$content_type" | grep -Po 'charset=\S+' | cut -d "=" -f2 | tail -n 1)

    # Conversion de l'encodage
    if [[ "$encoding" != "UTF-8" ]]; then
        iconv -f "$encoding" -t UTF-8 "$html_file" -o "${html_file}.utf8"
        mv "${html_file}.utf8" "$html_file"
        encoding="UTF-8"
    fi

    # Extraction du texte brut et sauvegarde dans dump-file
    lynx -dump -nolist "$html_file" > "$dump_file"

    # Tokénisation et suppression des lignes vides
    pykos "$dump_file" | grep -v '^[[:space:]]*$' > /tmp/tokens.txt

    # Extraction des contextes pour le concordancier
    awk -v mot="$word" -v mot_variantes="개방성|개방적" -v file_num="$line_count" '
    {
        if (NF == 0) next; # Ignore les lignes vides
        if ($0 ~ mot) {
            if ($0 ~ /개방성/) {
                # Si le mot "개방성" est trouvé
                split($0, arr, "개방성");
                print "<tr><td>" file_num "</td><td>" arr[1] "</td><td>개방성</td><td>" arr[2] "</td></tr>";
            } else if ($0 ~ /개방적/) {
                # Si le mot "개방적" est trouvé
                split($0, arr, "개방적");
                print "<tr><td>" file_num "</td><td>" arr[1] "</td><td>개방적</td><td>" arr[2] "</td></tr>";
            } else {
                # Sinon, le mot "개방" seul
                split($0, arr, "개방");
                print "<tr><td>" file_num "</td><td>" arr[1] "</td><td>개방</td><td>" arr[2] "</td></tr>";
            }
        }
    }' /tmp/tokens.txt >> "$concordance_file"


    # Sauvegarde des contextes dans un fichier texte
    awk -v mot="$word" -v mot_variantes="개방성|개방적" '{
        if (NF == 0) next;  # Ignore les lignes vides
        if ($0 ~ mot) {
            if ($0 ~ /개방성/) {
                # Si "개방성" est trouvé
                split($0, arr, "개방성");
                print arr[1] "개방성" arr[2] "\n--";  # Contexte avec "개방성"
            } else if ($0 ~ /개방적/) {
                # Si "개방적" est trouvé
                split($0, arr, "개방적");
                print arr[1] "개방적" arr[2] "\n--";  # Contexte avec "개방적"
            } else {
                # Sinon, "개방" seul
                split($0, arr, "개방");
                print arr[1] "개방" arr[2] "\n--";  # Contexte avec "개방"
            }
        }
    }' /tmp/tokens.txt > "$context_file"

    # Ajout des liens au tableau principal avec comptage des occurrences du mot
    echo -e "<tr>
                <td>${line_count}</td>
                <td><a href=\"$line\">$line</a></td>
                <td>${http_code}</td>
                <td>${encoding:-Absent}</td>
                <td>$(wc -w < /tmp/tokens.txt)</td>
                <td>$(grep -oE "$word" /tmp/tokens.txt | wc -l)</td>
                <td><a href=\"$context_file\">Contextes</a></td>
                <td><a href=\"$concordance_file\">Concordancier</a></td>
            </tr>" >> "$output_file"

    # Nettoyage des fichiers temporaires
    rm -f /tmp/tokens.txt

    # Incrémentation du compteur
    line_count=$((line_count + 1))
done < "$file"

# Fermeture des tableaux HTML
echo -e "</tbody>
        </table>
    </div>
</section>
</body>
</html>" >> "$output_file"

echo -e "</tbody>
        </table>
    </div>
</section>
</body>
</html>" >> "$concordance_file"
