//
// SRDoubleHeaderView.swift
//
// Copyright (c) 2025 Sportradat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import SwiftUI

public struct SRDoubleHeaderView<
    AboveView: View,
    StickyHeader: View,
    HeaderContent: View,
    SubHeaderContent: View,
    RowContent: View
>: View {
    
    // MARK: Properties
    
    let aboveView: AboveView
    let headers: [any SRHeaderViewModel]
    let stickyHeader: (_ header: any SRHeaderViewModel,
                       _ subHeader: any SRSubHeaderViewModel) -> StickyHeader
    let headerView: (_ header: any SRHeaderViewModel) -> HeaderContent
    let subHeaderView: (_ subHeader: any SRSubHeaderViewModel) -> SubHeaderContent
    let rowView: (_ row: any SRRowViewModel) -> RowContent
    @State private var aboveViewModel = AboveViewModel()
    
    public init( aboveView: AboveView,
                 headers: [any SRHeaderViewModel],
                 stickyHeader: @escaping (_ header: any SRHeaderViewModel,
                                          _ subHeader: any SRSubHeaderViewModel) -> StickyHeader,
                 headerView: @escaping (_ header: any SRHeaderViewModel) -> HeaderContent,
                 subHeaderView: @escaping (_ subHeader: any SRSubHeaderViewModel) -> SubHeaderContent,
                 rowView: @escaping (_ row: any SRRowViewModel) -> RowContent) {
        self.aboveView = aboveView
        self.headers = headers
        self.stickyHeader = stickyHeader
        self.headerView = headerView
        self.subHeaderView = subHeaderView
        self.rowView = rowView
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            AboveViewContainer(viewModel: aboveViewModel, aboveView: aboveView)
            SRDoubleHeaderList(headers: headers,
                               stickyHeader: stickyHeader,
                               headerView: headerView,
                               subHeaderView: subHeaderView,
                               rowView: rowView) { scrollOffset in
                aboveViewModel.offset = scrollOffset
            }
        }
    }
}

fileprivate struct AboveViewContainer<AboveView: View>: View {
    
    // MARK: Properties
    
    fileprivate let viewModel: AboveViewModel
    let aboveView: AboveView
    @State private var naturalHeight: CGFloat = 0
    
    // MARK: Computed properties
    
    var body: some View {
        aboveView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: ViewHeightKey2.self,
                                           value: geo.size.height)
                }
            )
            .onPreferenceChange(ViewHeightKey2.self) { height in
                naturalHeight = height
            }
            .frame(height: max(naturalHeight - viewModel.offset, 0))
            .clipped()
    }
}

fileprivate struct ViewHeightKey: PreferenceKey {
    
    // MARK: Properties
    
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    
    // MARK: Func
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

@Observable
fileprivate class AboveViewModel {
    
    // MARK: Properties
    
    var offset: CGFloat = 0
}
