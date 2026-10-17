import json
import sys

# Language-specific translations for the new keys
translations = {
    "fr": {
        "languageExample": "Français, English, etc.",
        "noneOption": "Aucun",
        "play": "Lire",
        "newAnd4K": "Films à la demande",
        "seasonsAndEpisodes": "Séries à la demande",
    },
    "en": {
        "languageExample": "English, French, etc.",
        "noneOption": "None",
        "play": "Play",
        "newAnd4K": "Movies on Demand",
        "seasonsAndEpisodes": "Series on Demand",
    },
    "es": {
        "languageExample": "Español, English, etc.",
        "noneOption": "Ninguno",
        "play": "Reproducir",
        "newAnd4K": "Películas a la carta",
        "seasonsAndEpisodes": "Series a la carta",
    },
    "de": {
        "languageExample": "Deutsch, English, etc.",
        "noneOption": "Keine",
        "play": "Abspielen",
        "newAnd4K": "Filme auf Abruf",
        "seasonsAndEpisodes": "Serien auf Abruf",
    },
    "it": {
        "languageExample": "Italiano, English, etc.",
        "noneOption": "Nessuno",
        "play": "Riprodurre",
        "newAnd4K": "Film on Demand",
        "seasonsAndEpisodes": "Serie on Demand",
    },
    "ar": {
        "languageExample": "العربية, English, etc.",
        "noneOption": "لا شيء",
        "play": "تشغيل",
        "newAnd4K": "أفلام عند الطلب",
        "seasonsAndEpisodes": "مسلسلات عند الطلب",
    },
}

# Language example translations
lang_examples = {
    "fr": "Français, English, etc.",
    "en": "English, French, etc.",
    "es": "Español, English, etc.",
    "de": "Deutsch, English, etc.",
    "it": "Italiano, English, etc.",
    "ar": "العربية, English, etc.",
}

for lang, trans in translations.items():
    filepath = f"lib/l10n/app_{lang}.arb"
    
    # Read the file
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Parse as JSON
    data = json.loads(content)
    
    # Update languageExample
    data["languageExample"] = lang_examples[lang]
    
    # Add new keys after languageExample (we'll insert them in the right position)
    # For simplicity, just add them - order doesn't matter for JSON
    data["noneOption"] = trans["noneOption"]
    data["play"] = trans["play"]
    data["newAnd4K"] = trans["newAnd4K"]
    data["seasonsAndEpisodes"] = trans["seasonsAndEpisodes"]
    
    # Write back with pretty formatting
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"Updated {filepath}")

print("All done!")