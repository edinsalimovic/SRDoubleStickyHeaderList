//
//  ContentView.swift
//  Example
//
//  Created by Edin Salimovic on 8. 12. 2025..
//

import SwiftUI
import SRDoubleStickyHeaderList

struct ContentView: View {
    
    var body: some View {
        SRDoubleStickyHeaderList(
            aboveView: viewAboveList,
            headers: headers,
            stickyHeader: stickyHeader,
            headerView: headerView,
            subHeaderView: subHeaderView,
            rowView: rowView,
            loadMoreView: loadMoreView,
            emptyStateView: AnyView(Text("No data")))
    }
    
    private var viewAboveList: some View {
        VStack {
            Text("Some view above the list")
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 150)
        .background(.green)
    }
    
    private func stickyHeader(header: any SRHeaderViewModel, subHeader: any SRSubHeaderViewModel) -> some View {
        VStack(spacing: 0) {
            headerView(header: header)
            subHeaderView(subHeader: subHeader)
        }
    }
    
    @ViewBuilder
    private func headerView(header: any SRHeaderViewModel) -> some View {
        if let sport = header as? Sport {
            Text(sport.name)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 50)
                .background(.red)
        }
    }
    
    @ViewBuilder
    private func subHeaderView(subHeader: any SRSubHeaderViewModel) -> some View {
        if let tournament = subHeader as? Tournament {
            Text(tournament.name)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 50)
                .background(.blue)
        }
    }
    
    @ViewBuilder
    private func rowView(row: any SRRowViewModel) -> some View {
        if let event = row as? Event {
            Text(event.name)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 50)
                .background(.gray)
        }
    }
    
    private var loadMoreView: AnyView {
        AnyView(ProgressView()
            .onAppear {
                print("Reached end....")
            })
    }
}
