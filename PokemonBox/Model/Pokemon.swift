//
//  Pokemon.swift
//  PokemonBox
//
//  Created by Samith Aturaliyage on 05/02/25.
//

// Modello per il risultato della chiamata paginata (e per il download della lista completa)
struct PokemonBasic: Codable {
    let name: String
    let url: String
}

struct PokemonListResponse: Codable {
    let results: [PokemonBasic]
}

/// Modello per il dettaglio ottenuto da /pokemon/<name>
struct PokemonData: Codable {
    let name: String
    let sprites: Sprites
    let types: [PokemonTypeSlot]
}

struct Sprites: Codable {
    let front_default: String?
}

struct PokemonTypeSlot: Codable {
    let slot: Int
    let type: PokemonType
}

struct PokemonType: Codable {
    let name: String
    let url: String
}

/// Modello per la descrizione (ottenuta da /pokemon-species/<name>)
struct PokemonSpecies: Codable {
    let flavor_text_entries: [FlavorTextEntry]
}

struct FlavorTextEntry: Codable {
    let flavor_text: String
    let language: NamedAPIResource
}

struct NamedAPIResource: Codable {
    let name: String
    let url: String
}

/// Modello composito usato per mostrare il contenuto della cella
struct PokemonDetailModel {
    let name: String
    let imageUrl: String?
    let types: [String]
    let description: String?
}
