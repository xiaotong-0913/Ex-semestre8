#!/usr/bin/env bash

folder=$1   # Dossier contenant les fichiers texte
language=$2 # Langue des textes

# Vérification des arguments
if [ $# -ne 2 ]; then
    echo "Le script nécessite deux arguments : un nom de dossier et une langue."
    exit 1
fi

# Vérification du dossier et définition du nom du fichier de sortie
if [[ "$folder" == "../dumps-text" ]]; then
    output_file="../pals/dumps-text-$language.txt"
elif [[ "$folder" == "../contextes" ]]; then
    output_file="../pals/contextes-$language.txt"
else
    echo "Le dossier $folder n'est pas reconnu."
    exit 1
fi

# Création du dossier de sortie si inexistant
mkdir -p "$(dirname "$output_file")"

# Initialisation du fichier de sortie
> "$output_file"

# Traitement des fichiers
for file in "$folder"/*"$language"*; do
    # Vérification que le fichier existe
    if [[ ! -f "$file" ]]; then
        echo "Le fichier $file n'existe pas ou n'est pas valide."
        continue
    fi

    echo "Traitement du fichier : $file"

    if [[ "$language" == "coreen" ]]; then
        # Utilisation de pykos pour tokeniser le texte en coréen
        pykos "$file" | sed -E 's/([[:punct:]])/\n\1\n/g; s/([[:space:]])+/\n/g' | tr -s '\n' >> "$output_file"
        echo "Langue coréenne détectée et tokenisation effectuée."
    else
        # Segmentation des mots ou symboles pour les autres langues
        sed -E 's/([[:punct:]])/\n\1\n/g; s/([[:space:]])+/\n/g' "$file" | tr -s '\n' '\n' >> "$output_file"
    fi
done

echo "Tous les fichiers ont été combinés dans : $output_file"
