//
//  PokemonBoxTests.swift
//  PokemonBoxTests
//
//  Created by Samith Aturaliyage on 08/02/25.
//

import XCTest
@testable import PokemonBox



class PokemonSearchViewModelTests: XCTestCase {
    var viewModel: PokemonSearchViewModel!
    var mockView: PokemonSearchViewMock!
    
    override func setUp() {
        super.setUp()
        mockView = PokemonSearchViewMock()
        viewModel = PokemonSearchViewModel(view: mockView)
    }
    
    override func tearDown() {
        viewModel = nil
        mockView = nil
        super.tearDown()
    }
    
    func testLoadMorePokemon_WhenNotLoading_ShouldStartLoading() {
        mockView.isLoadingPage = false
        mockView.isAllPagesLoaded = false
        
        viewModel.loadMorePokemon()
        
        XCTAssertTrue(mockView.dataLoadingStartedCalled, "dataLoadingStarted() should be called")
    }

    
    func testSearchPokemonWithName_ShouldSetSearchResult() {
        let expectation = self.expectation(description: "Wait for async search")
        
        viewModel.searchPokemonWithName(name: "pikachu") {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertNotNil(self.mockView.searchResult, "searchResult should be set")
    }
    
    func testFetchPokemonDetail_ShouldCacheResult() {
        let expectation = self.expectation(description: "Wait for async fetch detail")
        let pokemon = PokemonBasic(name: "pikachu", url: "https://pokeapi.co/api/v2/pokemon/pikachu")
        
        viewModel.fetchPokemonDetail(for: pokemon) { detail in
            XCTAssertNotNil(detail, "Detail should be fetched")
            XCTAssertNotNil(self.mockView.pokemonDetailsCache[pokemon.name], "Detail should be cached")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
