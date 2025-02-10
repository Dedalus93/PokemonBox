//
//  PokemonData.swift
//  PokemonBox
//
//  Created by Samith Aturaliyage on 10/02/25.
//

/// Modello per il dettaglio ottenuto da /pokemon/<name>
struct PokemonData: Codable {
    let name: String
    let sprites: Sprites
    let types: [PokemonTypeSlot]
}
