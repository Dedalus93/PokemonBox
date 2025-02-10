//
//  UIImageView+.swift
//  PokemonBox
//
//  Created by Samith Aturaliyage on 09/02/25.
//

import UIKit

// Estensione per caricare le immagini in modo asincrono
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

