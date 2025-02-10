//
//  PokemonSearchViewMock.swift
//  PokemonBox
//
//  Created by Samith Aturaliyage on 10/02/25.
//

import XCTest
@testable import PokemonBox

class PokemonSearchViewMock: PokemonSearchView {
    var isLoadingPage = false
    var isAllPagesLoaded = false
    var pageLimit = 20
    var currentOffset = 0
    var paginatedPokemon: [PokemonBasic] = []
    var searchResult: PokemonBasic?
    var pokemonDetailsCache: [String: PokemonDetailModel] = [:]
    
    var dataLoadingStartedCalled = false
    var dataLoadingFinishedCalled = false
    var successStatus: Bool = false
    
    func dataLoadingStarted() {
        dataLoadingStartedCalled = true
    }
    
    func dataLoadingFinished(loadStartTime: Date, success: Bool) {
        dataLoadingFinishedCalled = true
        successStatus = success
    }
}



