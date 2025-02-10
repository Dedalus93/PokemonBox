//
//  PokemonListViewController.swift
//  PokemonBox
//
//  Created by Samith Aturaliyage on 05/02/25.
//

import UIKit
import SVProgressHUD



// Estensione per caricare le immagini in modo asincrono (molto semplice)
extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
        }
    }
}

// MARK: - ViewController

class PokemonSearchViewController: UIViewController {
    
    
    // La search bar in alto
    let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search Pokémon by name"
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()
    
    /// View contenente l'activity indicator e la label "Loading data"
    private let loadingContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.isHidden = true // Nascondiamo la view per default
        return view
    }()
    
    /// Activity indicator da mostrare all'interno della loadingContainerView
    private let loadingActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    /// Label con il testo "Loading data"
    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Loading data"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    // La table view sottostante
    let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    // MARK: - Variabili per i dati
    
    /// Modalità paginata: array dei Pokémon scaricati a blocchi
    var paginatedPokemon: [PokemonBasic] = []
    
    /// Risultato dalla modalità ricerca
    var searchResult: PokemonBasic?
    
    /// Cache per i dettagli (che includono immagine, tipi e descrizione)
    var pokemonDetailsCache: [String: PokemonDetailModel] = [:]
    
    // Variabili per la paginazione
    var currentOffset = 0
    let pageLimit = 20
    var isLoadingPage = false
    var isAllPagesLoaded = false
    
    // Computed property che restituisce true se la search bar contiene del testo
    private var isSearchMode: Bool {
        return !(searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
    
    // MARK: - Ciclo di vita
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "PokémonBox"
        
        SVProgressHUD.setDefaultMaskType(.none)
        setupUI()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PokemonTableViewCell.self, forCellReuseIdentifier: PokemonTableViewCell.identifier)
        
        // Inizialmente, se la search bar è vuota, carichiamo il primo batch (20 Pokémon)
        if !isSearchMode {
            loadMorePokemon()
        }
    }
    
    private func setupUI() {
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(loadingContainerView)
        
        // Aggiungiamo l'activity indicator e la label alla loadingContainerView
        loadingContainerView.addSubview(loadingActivityIndicator)
        loadingContainerView.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            // Posizionamento della searchBar in alto (safe area)
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // La tableView occupa il resto dello schermo
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Posizionamento della loadingContainerView: centrata con dimensioni fisse
            loadingContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingContainerView.widthAnchor.constraint(equalToConstant: 120),
            loadingContainerView.heightAnchor.constraint(equalToConstant: 120),
            
            // Posizionamento dell'activity indicator all'interno della loadingContainerView
            loadingActivityIndicator.topAnchor.constraint(equalTo: loadingContainerView.topAnchor, constant: 16),
            loadingActivityIndicator.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor),
            
            // La label "Loading data" sotto l'indicatore
            loadingLabel.topAnchor.constraint(equalTo: loadingActivityIndicator.bottomAnchor, constant: 8),
            loadingLabel.leadingAnchor.constraint(equalTo: loadingContainerView.leadingAnchor, constant: 8),
            loadingLabel.trailingAnchor.constraint(equalTo: loadingContainerView.trailingAnchor, constant: -8),
            loadingLabel.bottomAnchor.constraint(equalTo: loadingContainerView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Caricamento dati
    
    /// Modalità paginata: carica il prossimo batch di 20 Pokémon
    // MARK: - Caricamento dati paginato
        private func loadMorePokemon() {
            guard !isLoadingPage, !isAllPagesLoaded else { return }
            isLoadingPage = true
            
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
    
    /// Ferma l'activity indicator e nasconde la loadingContainerView dopo almeno 1 secondo
    private func stopLoadingIndicator(minimumTimeFrom startTime: Date) {
        let elapsed = Date().timeIntervalSince(startTime)
        let delay = max(0, 1.0 - elapsed)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.loadingActivityIndicator.stopAnimating()
            self.loadingContainerView.isHidden = true
        }
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
                print("Errore nel caricamento della lista completa: \(error)")
                completion()
                return
            }
            guard let data = data else {
                completion()
                return
            }
            do {
                
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
                    }
                } catch {
                    completion()
                    return
                }
                
                completion()
            } catch {
                print("Errore di decodifica: \(error)")
                completion()
            }
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
                        // Prendiamo la prima flavor text in inglese (rimuovendo eventuali interruzioni di linea)
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

// MARK: - UISearchBarDelegate

extension PokemonSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchResult = nil
            tableView.reloadData()
        } else {
            
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        let searchText = searchBar.text ?? ""
        searchPokemonWithName(name: searchText) {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension PokemonSearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchMode ? searchResult == nil ? 0 : 1 : paginatedPokemon.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PokemonTableViewCell.identifier, for: indexPath) as? PokemonTableViewCell else {
            return UITableViewCell()
        }
        
        var pokemon: PokemonBasic
        
        if isSearchMode {
            guard let result = searchResult else {
                return UITableViewCell()
            }
            pokemon = result
            
        } else {
            pokemon = paginatedPokemon[indexPath.row]
        }

        
        if let detail = pokemonDetailsCache[pokemon.name] {
            cell.configure(with: detail)
        }
        
        return cell
    }

    
    // Quando lo scrolling raggiunge quasi il fondo, se in modalità paginata, carichiamo altri 20 Pokémon
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isSearchMode else { return }
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height - 140 {
            loadMorePokemon()
        }
    }
    
    // Altezza fissa per la cella
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}
