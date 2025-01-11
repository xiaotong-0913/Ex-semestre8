#!/usr/bin/env bash

file=$1 # fichier contenant les URLs
word="(o|O)uvertures?" # mot avec expression régulière pour les variantes
line_count=1 # compteur de lignes
output_file="../tableaux/tableau_francais.html"
concordance_file="../concordances/concordancier_francais.html"

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
    <title>Tableau français</title>
    <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bulma@1.0.2/css/versions/bulma-no-dark-mode.min.css\">
</head>
<body>
<section class=\"section\">
    <div class=\"container\">
        <h1 class=\"title\">Tableau pour \"ouverture\"</h1>
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
            <h1 class=\"title\">Concordancier pour \"ouverture\"</h1>
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
    html_file="../aspirations/francais-${line_count}.html"
    dump_file="../dumps-text/francais-${line_count}.txt"
    context_file="../contextes/francais-${line_count}.txt"

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
    cat "$dump_file" sed -E 's/([^[:space:][:punct:]]+|[[:punct:]])/\1\n/g' | grep -v '^[[:space:]]*$' > /tmp/tokens.txt

    # Sauvegarde des contextes dans un fichier texte (2 lignes précédentes et 2 lignes suivantes)
    grep -E "$word" "$dump_file" -C 2 > "$context_file"

    # Extraction des contextes gauche et droit pour le concordancier (5 mots pour chaque contexte)
    grep -oE "(\b(\w+\s+){0,5}\b$word\b((\s+\w+){0,5}" "$dump_file" | while read -r line; do
            left=$(echo "$line" | sed -E "s/(.*)$word(.*)//")
            right=$(echo "$line" | sed -E "s/(.*)($mot)(.*)//")
            echo "<tr><td class=\"has-text-right\">$left</td><td class=\"has-text-centered\"><strong>$mot</strong></td><td class=\"has-text-left\">$right</td></tr>" >> "$concordance_file"
        done

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