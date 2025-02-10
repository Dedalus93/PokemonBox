//
//  PokemonSearchViewModel.swift
//  PokemonBox
//
//  Created by Samith Aturaliyage on 05/02/25.
//

import Foundation

protocol PokemonSearchViewModelProtocol {
    
}

class PokemonSearchViewModel: PokemonSearchViewModelProtocol {
    
    weak var view: PokemonSearchView?
    
    init(view: PokemonSearchView? = nil) {
        self.view = view
        self.loadMorePokemon()
    }
    
    // MARK: - Caricamento dati paginato
        private func loadMorePokemon() {
            guard !(view?.isLoadingPage ?? true), !(view?.isAllPagesLoaded ?? true) else { return }
            view?.isLoadingPage = true
            
            // Registra il tempo d'inizio per garantire che la view rimanga visibile almeno 1 secondo
            let loadStartTime = Date()
            
            // Blocca lo scrolling della tableView e mostra la loadingContainerView
            DispatchQueue.main.async {
                // Se la tableView sta già decelerando, fermiamo l'inerzia
                self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
                self.tableView.isScrollEnabled = false
                self.tableView.panGestureRecognizer.isEnabled = false
                
                self.loadingContainerView.isHidden = false
                self.loadingActivityIndicator.startAnimating()
            }
            
            let urlString = "https://pokeapi.co/api/v2/pokemon?limit=\(pageLimit)&offset=\(currentOffset)"
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async {
                    self.stopLoadingIndicator(minimumTimeFrom: loadStartTime)
                    self.tableView.isScrollEnabled = true
                    self.tableView.panGestureRecognizer.isEnabled = true
                }
                isLoadingPage = false
                return
            }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self else { return }
                if let error = error {
                    print("Errore nel caricamento: \(error)")
                    DispatchQueue.main.async {
                        self.stopLoadingIndicator(minimumTimeFrom: loadStartTime)
                        self.tableView.isScrollEnabled = true
                        self.tableView.panGestureRecognizer.isEnabled = true
                    }
                    self.isLoadingPage = false
                    return
                }
                guard let data = data else {
                    DispatchQueue.main.async {
                        self.stopLoadingIndicator(minimumTimeFrom: loadStartTime)
                        self.tableView.isScrollEnabled = true
                        self.tableView.panGestureRecognizer.isEnabled = true
                    }
                    self.isLoadingPage = false
                    return
                }
                do {
                    let response = try JSONDecoder().decode(PokemonListResponse.self, from: data)
                    let newPokemon = response.results
                    if newPokemon.count < self.pageLimit {
                        self.isAllPagesLoaded = true
                    }
                    self.paginatedPokemon.append(contentsOf: newPokemon)
                    self.currentOffset += self.pageLimit
                    
                    var counter = 0
                    for pokemon in newPokemon {
                        fetchPokemonDetail(for: pokemon) { detail in
                            if detail != nil {
                                counter += 1
                                if counter == newPokemon.count {
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                        self.stopLoadingIndicator(minimumTimeFrom: loadStartTime)
                                        self.tableView.isScrollEnabled = true
                                        self.tableView.panGestureRecognizer.isEnabled = true
                                    }
                                    self.isLoadingPage = false
                                }
                            }
                        }
                    }

                } catch {
                    print("Errore di decodifica: \(error)")
                    DispatchQueue.main.async {
                        self.stopLoadingIndicator(minimumTimeFrom: loadStartTime)
                        self.tableView.isScrollEnabled = true
                        self.tableView.panGestureRecognizer.isEnabled = true
                    }
                    self.isLoadingPage = false
                }
            }.resume()
        }
    
    /// Per la modalità ricerca: carica la lista completa dei Pokémon (se non già scaricata)
    private func searchPokemonWithName(name: String, completion: @escaping () -> Void) {

        SVProgressHUD.show()
        let urlString = "https://pokeapi.co/api/v2/pokemon/\(name.lowercased())"
        guard let url = URL(string: urlString) else {
            SVProgressHUD.dismiss()
            completion()
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async { SVProgressHUD.dismiss() }
            guard let self = self else { return }
            if let error = error {
                print("Errore nella ricerca del Pokemon digitato dall'utente: \(error)")
                completion()
                return
            }
            guard let data = data else {
                completion()
                return
            }
            
            do {
                if let dictionary =
                    try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let formsString = (dictionary["forms"] as? [[String:Any]]),
                   let forms = formsString.first,
                   let formsData = try? JSONSerialization.data(withJSONObject: forms, options: []),
                   let pokemonBasicData = try? JSONDecoder().decode(PokemonBasic.self, from: formsData){
                    searchResult = pokemonBasicData
                    fetchPokemonDetail(for: pokemonBasicData) { detailModel in
                        completion()
                    }
                } else {
                    searchResult = nil
                }
            } catch {
                print("Errore di decodifica: \(error)")
                searchResult = nil
                completion()
                return
            }
            
            completion()
        }.resume()
    }
    
    /// Carica i dettagli di un Pokémon (immagine, tipi e descrizione)
    private func fetchPokemonDetail(for pokemon: PokemonBasic, completion: @escaping (PokemonDetailModel?) -> Void) {
        // 1. Chiamata a /pokemon/<name> per ottenere sprites e tipi
        guard let url = URL(string: pokemon.url) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Errore nel fetch di dettagli per \(pokemon.name): \(error)")
                completion(nil)
                return
            }
            guard let data = data else {
                completion(nil)
                return
            }
            do {
                let pokemonData = try JSONDecoder().decode(PokemonData.self, from: data)
                // 2. Chiamata a /pokemon-species/<name> per ottenere la descrizione
                let speciesUrlString = "https://pokeapi.co/api/v2/pokemon-species/\(pokemon.name)"
                guard let speciesUrl = URL(string: speciesUrlString) else {
                    completion(nil)
                    return
                }
                URLSession.shared.dataTask(with: speciesUrl) { dataSpecies, responseSpecies, errorSpecies in
                    if let errorSpecies = errorSpecies {
                        print("Errore nel fetch di specie per \(pokemon.name): \(errorSpecies)")
                        completion(nil)
                        return
                    }
                    guard let dataSpecies = dataSpecies else {
                        completion(nil)
                        return
                    }
                    do {
                        let speciesData = try JSONDecoder().decode(PokemonSpecies.self, from: dataSpecies)
                        // Prendiamo la prima descrizione in inglese (rimuovendo eventuali interruzioni di linea)
                        let flavorEntry = speciesData.flavor_text_entries.first { $0.language.name == "en" }
                        let flavorText = flavorEntry?.flavor_text
                            .replacingOccurrences(of: "\n", with: " ")
                            .replacingOccurrences(of: "\u{000c}", with: " ")
                        let detail = PokemonDetailModel(
                            name: pokemonData.name,
                            imageUrl: pokemonData.sprites.front_default,
                            types: pokemonData.types.map { $0.type.name },
                            description: flavorText
                        )
                        // Cache: memorizziamo il risultato
                        DispatchQueue.main.async {
                            self?.pokemonDetailsCache[pokemon.name] = detail
                        }
                        completion(detail)
                    } catch {
                        print("Errore di decodifica specie: \(error)")
                        completion(nil)
                    }
                }.resume()
            } catch {
                print("Errore di decodifica dei dettagli: \(error)")
                completion(nil)
            }
        }.resume()
    }
}
