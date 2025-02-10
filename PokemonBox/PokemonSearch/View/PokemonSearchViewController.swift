//
//  PokemonSearchViewController.swift
//  PokemonBox
//
//  Created by Samith Aturaliyage on 05/02/25.
//

import UIKit

protocol PokemonSearchView : AnyObject {
    // MARK: - Variabili per i dati della view esposte
    var paginatedPokemon: [PokemonBasic] {get set}
    var searchResult: PokemonBasic? {get set}
    var pokemonDetailsCache: [String: PokemonDetailModel] {get set}

    var currentOffset : Int {get set}
    var pageLimit : Int {get}
    var isLoadingPage : Bool {get set}
    var isAllPagesLoaded : Bool {get set}
    
    // MARK: - Funzioni della view esposte
    func dataLoadingStarted()
    func dataLoadingFinished(loadStartTime: Date, success: Bool)
}

class PokemonSearchViewController: UIViewController {
    
    var viewModel : PokemonSearchViewModel?
    
    /// Barra di ricerca per Pokémon tramite il nome
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
    
    /// La table view sottostante
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
    
    /// Variabili per la paginazione
    var currentOffset = 0
    let pageLimit = 20
    var isLoadingPage = false
    var isAllPagesLoaded = false
    
    /// Computed property che restituisce true se la search bar contiene del testo
    private var isSearchMode: Bool {
        return !(searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
    
    // MARK: - Ciclo di vita
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "PokémonBox"
        
        setupUI()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PokemonTableViewCell.self, forCellReuseIdentifier: PokemonTableViewCell.identifier)
        
        viewModel = PokemonSearchViewModel(view: self)
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
    
    
    /// Ferma l'activity indicator e nasconde la loadingContainerView dopo almeno 1 secondo
    private func stopLoadingIndicator(minimumTimeFrom startTime: Date) {
        let elapsed = Date().timeIntervalSince(startTime)
        let delay = max(0, 1.0 - elapsed)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.loadingActivityIndicator.stopAnimating()
            self.loadingContainerView.isHidden = true
        }
    }
}

extension PokemonSearchViewController: PokemonSearchView {
    func dataLoadingStarted() {
        // Blocca lo scrolling della tableView e mostra la loadingContainerView
        DispatchQueue.main.async {
            // Se la tableView sta già decelerando, fermiamo l'inerzia
            self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
            self.tableView.isScrollEnabled = false
            self.tableView.panGestureRecognizer.isEnabled = false
            
            self.loadingContainerView.isHidden = false
            self.loadingActivityIndicator.startAnimating()
        }
    }
    
    func dataLoadingFinished(loadStartTime: Date, success: Bool) {
        DispatchQueue.main.async {
            self.stopLoadingIndicator(minimumTimeFrom: loadStartTime)
            if success {
                self.tableView.reloadData()
            }
            self.tableView.isScrollEnabled = true
            self.tableView.panGestureRecognizer.isEnabled = true
        }
        isLoadingPage = false
    }
}

// MARK: - UISearchBarDelegate

extension PokemonSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchResult = nil
            tableView.reloadData()
        } else {
            viewModel?.searchPokemonWithName(name: searchText) {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
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
            viewModel?.loadMorePokemon()
        }
    }
    
    // Altezza fissa per la cella
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}
