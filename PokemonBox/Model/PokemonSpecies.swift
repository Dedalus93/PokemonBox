//
//  PokemonSpecies.swift
//  PokemonBox
//
//  Created by Samith Aturaliyage on 10/02/25.
//

/// Modello per la descrizione (ottenuta da /pokemon-species/<name>)
struct PokemonSpecies: Codable {
    let flavor_text_entries: [FlavorTextEntry]
}
