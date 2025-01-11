# Création du tableau principal
echo "<html lang='en'>
    <head>
    <meta charset='UTF-8'/>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>Tableau URLS</title>
    <link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/bulma@1.0.2/css/bulma.min.css'>
    <style>
    .has-text-uppercase {
        text-transform: uppercase;
    }
    </style>
    </head>
<body>
    <table class='table is-bordered is-hoverable is-striped'>
    <thead>
    <tr>
        <th class='numero_ligne is-primary has-text-uppercase has-text-white has-background-info-dark'>numero_ligne</th>
        <th class='url is-primary has-text-uppercase has-text-white has-background-info-dark'>url</th>
        <th class='code_http is-primary has-text-uppercase has-text-white has-background-info-dark'>code_http</th>
        <th class='encodage is-primary has-text-uppercase has-text-white has-background-info-dark'>encodage</th>
        <th class='aspirations is-primary has-text-uppercase has-text-white has-background-info-dark'>aspirations</th>
        <th class='dumps is-primary has-text-uppercase has-text-white has-background-info-dark'>dumps</th>
        <th class='nombre_mots is-primary has-text-uppercase has-text-white has-background-info-dark'>nombre_mots</th>
        <th class='compte is-primary has-text-uppercase has-text-white has-background-info-dark'>compte</th>
        <th class='contexte is-primary has-text-uppercase has-text-white has-background-info-dark'>contexte</th>
        <th class='concordancier is-primary has-text-uppercase has-text-white has-background-info-dark'>concordancier</th>
    </tr>
    " > ../tableaux/catalan.html


# Création du tableau pour le concordancier
echo "<html lang='en'>
    <head>
    <meta charset='UTF-8'/>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>Tableau URLS</title>
    <link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/bulma@1.0.2/css/bulma.min.css'>
    <style>
    .has-text-uppercase {
        text-transform: uppercase;
    }
    </style>
    </head>
<body>
    <table class='table is-bordered is-hoverable is-striped'>
    <thead>
    <tr>
        <th class='Contexte_gauche is-primary has-text-uppercase has-text-white has-background-info-dark'>Contexte_gauche</th>
        <th class='Mot is-primary has-text-uppercase has-text-white has-background-info-dark'>Mot</th>
        <th class='Contexte_droit is-primary has-text-uppercase has-text-white has-background-info-dark'>Contexte_droit</th>
    </tr>
    </thead>" > ../concordances/concordancier_catalan.html



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
            <td class='has-text-success-light has-background-dark'>$nb_lignes</td>
            <td class='has-text-success-light has-background-dark'><a href=$line>url $nb_lignes</a></td>
            <td class='has-text-success-light has-background-dark'>$http_code</td>
            <td class='has-text-success-light has-background-dark'>$encodage</td>
            <td class='has-text-success-light has-background-dark'><a href=../aspirations/catalan-$nb_lignes.html>aspiration</td>
            <td class='has-text-success-light has-background-dark'><a href=../dumps-text/catalan-$nb_lignes.txt>dump</td>
            <td class='has-text-success-light has-background-dark'>$nbmots</td>
            <td class='has-text-success-light has-background-dark'>$compte</td>
            <td class='has-text-success-light has-background-dark'><a href=../contextes/catalan-$nb_lignes.txt>contexte</a></td>
            <td class='has-text-success-light has-background-dark'><a href=../concordances/concordancier_catalan.html>concordancier</a></td>
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
            <td class='has-text-success-light has-background-dark'>$contexte_gauche</td>
            <td class='has-text-success-light has-background-dark'>obertura</td>
            <td class='has-text-success-light has-background-dark'>$contexte_droit</td>
        </tr>"

done < contextes_temporaires_catalan.txt >> ../concordances/concordancier_catalan.html
echo "</table>
</html>" >> ../concordances/concordancier_catalan.html

# On efface le fichier temporaire
rm -f contextes/contextes_temporaires_catalan.txt

# Ajout de la colonne concordancier au tableau principal
#while read -r line
#do
#sed -i /<\/table>/i\ | echo "<tr><td class='has-text-success-light has-background-dark'><a href=../concordances/concordancier_catalan.html>concordancier</a></td></tr>"
#done < $fichier_urls >> ../tableaux/catalan.html

echo " </body>
    </table>
</html>" >> ../tableaux/catalan.html
