//
//  PokemonTableViewCell.swift
//  PokemonBox
//
//  Created by Samith Aturaliyage on 09/02/25.
//
import UIKit

class PokemonTableViewCell: UITableViewCell {
    static let identifier = "PokemonTableViewCell"
    
    // Immagine a sinistra
    let pokemonImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // Nome in alto a destra
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Stack view orizzontale che conterrà i vari tipi (ognuno in una label)
    let typesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.setContentHuggingPriority(.required, for: .vertical)
        stack.setContentCompressionResistancePriority(.required, for: .vertical)
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Descrizione breve in basso
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    // Inizializzazione e layout
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(pokemonImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(typesStackView)
        contentView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            // Immagine a sinistra
            pokemonImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            pokemonImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            pokemonImageView.widthAnchor.constraint(equalToConstant: 80),
            pokemonImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Nome in alto a destra
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: pokemonImageView.trailingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            
            // Stack view per i tipi subito sotto il nome
            typesStackView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            typesStackView.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            typesStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: 0),
            
            // Descrizione sotto la stack view
            descriptionLabel.topAnchor.constraint(equalTo: typesStackView.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: 0)
            
            
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) non implementato")
    }
    
    /// Configura la cella con il modello dettagliato
    func configure(with detail: PokemonDetailModel) {
        nameLabel.text = detail.name.capitalized
        
        // Puliamo eventuali label già aggiunte nel typesStackView
        typesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for type in detail.types {
            let typeLabel = PaddingLabel()
            typeLabel.font = UIFont.boldSystemFont(ofSize: 15)
            typeLabel.textInsets = UIEdgeInsets(top: 5, left: 7, bottom: 5, right: 7)
            typeLabel.translatesAutoresizingMaskIntoConstraints = false
            typeLabel.textColor = .darkGray
            typeLabel.text = type.capitalized
            
            typeLabel.backgroundColor = .lightGray.withAlphaComponent(0.25)
            typeLabel.layer.borderColor = UIColor.blue.cgColor
            typeLabel.layer.cornerRadius = 5
            typeLabel.clipsToBounds = true
            typeLabel.textAlignment = .center
            // Aggiungiamo la label allo stack
            typesStackView.addArrangedSubview(typeLabel)
        }
        
        descriptionLabel.text = detail.description?.replacingOccurrences(of: "\n", with: " ") ?? "No description available."
        
        if let imageUrlString = detail.imageUrl, let url = URL(string: imageUrlString) {
            pokemonImageView.load(url: url)
        } else {
            pokemonImageView.image = nil
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Resetta i contenuti al loro stato predefinito
        self.pokemonImageView.image = nil
        self.nameLabel.text = nil
        self.descriptionLabel.text = nil
    }
}
