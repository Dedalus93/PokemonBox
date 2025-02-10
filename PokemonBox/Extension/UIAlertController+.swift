//
//  UIAlertController+.swift
//  PokemonBox
//
//  Created by Samith Aturaliyage on 10/02/25.
//

import UIKit

extension UIAlertController {
    /// Crea un alert di errore con un messaggio personalizzato e un pulsante per chiudere l'alert.
    ///
    /// - Parameter message: Il messaggio di errore da visualizzare.
    /// - Returns: Un'istanza di `UIAlertController` configurata come alert d'errore.
    static func presentErrorAlert(with message: String) -> UIAlertController {
        let alert = UIAlertController(title: "Errore", message: message, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Chiudi", style: .default, handler: nil)
        alert.addAction(closeAction)
        return alert
    }
}
