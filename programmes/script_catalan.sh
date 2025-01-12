# Création du tableau principal
echo -e "<!DOCTYPE html>
<html>
<head>
    <meta charset=\"UTF-8\" />
    <title>Tableau catalan</title>
    <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bulma@1.0.2/css/versions/bulma-no-dark-mode.min.css\">
</head>
<body>
<section class=\"section\">
    <div class=\"container\">
        <h1 class=\"title\">Tableau pour 'obertura'</h1>
        <table class=\"table is-bordered is-hoverable is-striped\">
        <thead>
            <tr>
                <th>NUMERO_LIGNE</th>
                <th>URL</th>
                <th>CODE_HTTP</th>
                <th>ENCODAGE</th>
                <th>ASPIRATIONS</th>
                <th>DUMPS</th>
                <th>NOMBRE_MOTS</th>
                <th>COMPTE</th>
                <th>CONTEXTE</th>
                <th>CONCORDANCIER</th>
            </tr>
        </thead>
        <tbody>" > ../tableaux/catalan.html


# Création du tableau pour le concordancier
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
            <h1 class=\"title\">Concordancier pour 'obertura'</h1>
            <table class=\"table is-bordered is-hoverable is-striped\">
                <thead>
                    <tr>
                        <th>CONTEXTE_GAUCHE</th>
                        <th>MOT</th>
                        <th>CONTEXTE_DROIT</th>
                    </tr>
                    </thead>
                    <tbody>" > ../concordances/concordancier_catalan.html



# Remplissage du tableau principal
if [ $# -ne 1 ]
then
	echo "le script prend exactement 1 argument"
	exit
fi

fichier_urls=$1

nb_lignes=1

while read -r line
do
    curl -o ../aspirations/catalan-$nb_lignes.html $line
    lynx -dump -nolist $line >> ../dumps-text/catalan-$nb_lignes.txt
    grep -A 1 -B 1 "obertura" ../dumps-text/catalan-$nb_lignes.txt >>../contextes/catalan-$nb_lignes.txt
    http_code=$(curl -s -I -L -w "%{http_code}" -o /dev/null $line)
    encodage=$(curl -s -I -L -w "%{content_type}" -o /dev/null $line | grep -P -o "charset=\S+" | cut -d "=" -f2)
    nbmots=$(lynx -dump -nolist $line | wc -w)
    compte=$(grep -i -o "obertura" ../dumps-text/catalan-$nb_lignes.txt | wc -w)

    # Conversion de l'encodage
    if [[ "$encodage" != "UTF-8" ]]; then
        iconv -f "$encodage" -t UTF-8 "$html_file" -o "${html_file}.utf8"
        mv "${html_file}.utf8" "$html_file"
        $encodage="UTF-8"
    fi

    echo "
        <tr>
            <td>$nb_lignes</td>
            <td><a href=$line>url $nb_lignes</a></td>
            <td>$http_code</td>
            <td>$encodage</td>
            <td><a href=../aspirations/catalan-$nb_lignes.html>aspiration</td>
            <td><a href=../dumps-text/catalan-$nb_lignes.txt>dump</td>
            <td>$nbmots</td>
            <td>$compte</td>
            <td><a href=../contextes/catalan-$nb_lignes.txt>contexte</a></td>
            <td><a href=../concordances/concordancier_catalan.html>concordancier</a></td>
        </tr>"

    nb_lignes=$(expr $nb_lignes + 1)
done < $fichier_urls >> ../tableaux/catalan.html


# Remplissage du concordancier
for numero in {1..48}
do
    grep -B 1 -A 1 '\bobertura\b' ../dumps-text/catalan-$numero.txt >> contextes_temporaires_catalan.txt
done

while read -r line
do
    contexte_gauche=$(echo $line | sed 's/\(.*\)\bobertura\b.*/\1/' | sed 's/[^a-zA-Z ]//g')
    contexte_droit=$(echo $line | sed 's/.*\bobertura\b\(.*\)/\1/' | sed 's/[^a-zA-Z ]//g' | sed 's/\([.!?]\).*/\1/')

    echo "
        <tr>
            <td>$contexte_gauche</td>
            <td>obertura</td>
            <td>$contexte_droit</td>
        </tr>"

done < contextes_temporaires_catalan.txt >> ../concordances/concordancier_catalan.html
echo -e "</tbody>
        </table>
    </div>
</section>
</body>
</html>" >> ../concordances/concordancier_catalan.html

# On efface le fichier temporaire
rm -f contextes/contextes_temporaires_catalan.txt

# Ajout de la colonne concordancier au tableau principal
#while read -r line
#do
#sed -i /<\/table>/i\ | echo "<tr><td class='has-text-success-light has-background-dark'><a href=../concordances/concordancier_catalan.html>concordancier</a></td></tr>"
#done < $fichier_urls >> ../tableaux/catalan.html

echo -e "</tbody>
        </table>
    </div>
</section>
</body>
</html>" >> ../tableaux/catalan.html
