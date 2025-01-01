#!/usr/bin/bash

# Vérification du nombre d'arguments
if [ $# -ne 1 ]; then
    echo "Erreur : Ce script nécessite exactement un argument (le fichier des URLs)." >&2
    exit 1
fi

fichier=$1  # Fichier contenant les URLs
aspirations="/home/hxt/Projet-PPE1/aspirations/html_ch"
dumps="/home/hxt/Projet-PPE1/dumps-text/dump_ch"
n=1  # Initialisation du compteur de lignes


# Lecture ligne par ligne du fichier contenant les URLs
while read -r line; do
    # Récupération du code HTTP et du type de contenu
    code=$(curl -s -I -L -w "%{http_code}" -o /dev/null "$line")
    encoding=$(curl -o /dev/null -s -I -L -w "%{content_type}" "$line" | grep -Po "charset=\S+" | cut -d "=" -f2 | tr -d "\r\n")

    # Vérification du code HTTP
    if [ "$code" -eq 200 ]; then
	aspiration_file="$aspirations/page_${n}.html"
	dump_file="$dumps/dump_${n}.txt"

	curl -s -L "$line" -o "$aspiration_file"

	lynx -dump -nolist "$line" > "$dump_file"

        # URL valide, affichage des informations
        echo -e "${n}\t${line}\t${code}\t${encoding:-N/A}\t<a href=\"$dump_file\" target=\"_blank\"text</a>\t<a href=\"$aspiration_file\" target=\"_blank\">html</a>"
    else
        # URL invalide, affichage d'un message d'erreur
        echo "Erreur : $line renvoie un code HTTP $code. Ignorée." >&2
        echo -e "${n}\t${line}\t${code}\tN/A\tN/A\tN/A"
    fi

    n=$((n + 1))  # compteur
done < "$fichier"

