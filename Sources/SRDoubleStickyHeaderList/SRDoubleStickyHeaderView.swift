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
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: ViewHeightKey.self,
                                           value: geo.size.height)
                }
            )
            .onPreferenceChange(ViewHeightKey.self) { height in
                naturalHeight = height
            }
            .frame(maxWidth: .infinity)
            .frame(height: max(naturalHeight - viewModel.offset, 1))
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
