import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

public struct SRDoubleHeaderList<
    StickyHeader: View,
    HeaderContent: View,
    SubHeaderContent: View,
    RowContent: View
>: View {
    
    // MARK: Properties
    
    let headers: [any SRHeaderViewModel]
    let stickyHeader: (_ header: any SRHeaderViewModel, _ subHeader: any SRSubHeaderViewModel) -> StickyHeader
    let headerView: (_ header: any SRHeaderViewModel) -> HeaderContent
    let subHeaderView: (_ subHeader: any SRSubHeaderViewModel) -> SubHeaderContent
    let rowView: (_ row: any SRRowViewModel) -> RowContent
    let onChangeScrollOffset: (CGFloat) -> Void
    @State private var itemPositions: [String: ItemPosition] = [:]
    @State private var currentHeader: any SRHeaderViewModel
    @State private var currentSubHeader: any SRSubHeaderViewModel
    @State private var previousRelativeBottoms: [String: CGFloat] = [:]
    @State private var overlayBottomGlobalY: CGFloat = 0
    @State private var isScrollingDown: Bool = true
    private let detectionTolerance: CGFloat = 2
    private let movementDetectionThreshold: CGFloat = 0.5
    
    // MARK: Init
    
    public init(headers: [any SRHeaderViewModel],
                stickyHeader: @escaping (_: any SRHeaderViewModel, _: any SRSubHeaderViewModel) -> StickyHeader,
                headerView: @escaping (_: any SRHeaderViewModel) -> HeaderContent,
                subHeaderView: @escaping (_: any SRSubHeaderViewModel) -> SubHeaderContent,
                rowView: @escaping (_: any SRRowViewModel) -> RowContent,
                onChangeScrollOffset: @escaping (CGFloat) -> Void) {
        self.headers = headers
        self.stickyHeader = stickyHeader
        self.headerView = headerView
        self.subHeaderView = subHeaderView
        self.rowView = rowView
        self.onChangeScrollOffset = onChangeScrollOffset
        _currentHeader = State(initialValue: headers.first!)
        _currentSubHeader = State(initialValue: headers.first!.subHeaders.first!)
    }
    
    // MARK: Body
    
    public var body: some View {
        GeometryReader { containerGeo in
            List {
                ForEach(headers, id: \.uniqueId) { header in
                    headerView(header)
                        .asListStyleless
                        .trackPosition(id: header.uniqueId)
                    
                    ForEach(header.subHeaders, id: \.uniqueId) { subHeader in
                        subHeaderView(subHeader)
                            .asListStyleless
                            .trackPosition(id: subHeader.uniqueId)
                        
                        ForEach(subHeader.rows, id: \.uniqueId) { row in
                            rowView(row)
                                .asListStyleless
                        }
                    }
                }
            }
            .frame(width: containerGeo.size.width, height: containerGeo.size.height)
            .withoutBounces
            .asListStyleless
            .overlay(alignment: .top, content: overlayView)
            .onScrollGeometryChange(for: CGFloat.self) { proxy in
                proxy.contentOffset.y + proxy.contentInsets.top
            } action: { _, offset in
                onChangeScrollOffset(offset)
            }
            .overlayPreferenceValue(ItemAnchorKey.self) { anchors in
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            updatePositions(from: anchors, geo: geo)
                        }
                        .onChange(of: anchors) { _, _ in
                            updatePositions(from: anchors, geo: geo)
                        }
                }
            }
            .overlayPreferenceValue(StickyHeaderAnchorKey.self) { anchor in
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            updateStickyHeader(from: anchor, geo: geo)
                        }
                        .onChange(of: anchor) { _, _ in
                            updateStickyHeader(from: anchor, geo: geo)
                        }
                }
            }
        }
    }
    
    // MARK: Private func
    
    private func updatePositions(from anchors: [String: Anchor<CGRect>], geo: GeometryProxy) {
        var resolved: [String: ItemPosition] = [:]
        for (id, anchor) in anchors {
            let rect = geo[anchor]
            resolved[id] = ItemPosition(top: rect.minY, bottom: rect.maxY)
        }
        self.itemPositions = resolved
        self.checkPositions()
    }
    
    private func checkPositions() {
        guard overlayBottomGlobalY != 0 else { return }
        let overlayBottom = overlayBottomGlobalY
        previousRelativeBottoms = previousRelativeBottoms.filter { itemPositions[$0.key] != nil }
        for (id, position) in itemPositions {
            guard let (hIndex, sIndex) = findIndexes(subHeaderID: id) else { continue }
            let relativeBottomAtOverlay = position.bottom - overlayBottom
            let previousRelative = previousRelativeBottoms[id]
            let crossedOverlayBoundary: Bool
            var inferredScrollingDown = isScrollingDown
            if let previous = previousRelative {
                let crossedFromAbove = previous > detectionTolerance && relativeBottomAtOverlay <= -detectionTolerance
                let crossedFromBelow = previous < -detectionTolerance && relativeBottomAtOverlay >= detectionTolerance
                crossedOverlayBoundary = crossedFromAbove || crossedFromBelow
                
                let delta = previous - relativeBottomAtOverlay
                if abs(delta) > movementDetectionThreshold {
                    inferredScrollingDown = delta > 0
                }
            } else {
                crossedOverlayBoundary = false
            }
            isScrollingDown = inferredScrollingDown
            if abs(relativeBottomAtOverlay) <= detectionTolerance || crossedOverlayBoundary {
                if inferredScrollingDown {
                    updateOverlayToSubHeader(headerIndex: hIndex, subHeaderIndex: sIndex)
                } else {
                    let previous = findPreviousSubHeader(realHeaderIndex: hIndex, realSubHeaderIndex: sIndex)
                    if let previousHeader = previous.header {
                        let subHeader = previous.subHeader ?? previousHeader.subHeaders.last
                        updateOverlayToHeader(header: previousHeader, subHeader: subHeader)
                    }
                }
            }
            previousRelativeBottoms[id] = relativeBottomAtOverlay
        }
    }
    
    private func findIndexes(subHeaderID: String) -> (headerIndex: Int, subHeaderIndex: Int)? {
        for (h, header) in headers.enumerated() {
            if let s = header.subHeaders.firstIndex(where: { $0.uniqueId == subHeaderID }) {
                return (h, s)
            }
        }
        return nil
    }
    
    private func updateOverlayToSubHeader(headerIndex: Int, subHeaderIndex: Int) {
        guard headers.indices.contains(headerIndex),
              headers[headerIndex].subHeaders.indices.contains(subHeaderIndex) else { return }
        
        let header = headers[headerIndex]
        let subHeader = header.subHeaders[subHeaderIndex]
        updateOverlayToHeader(header: header, subHeader: subHeader)
    }
    
    private func updateOverlayToHeader(header: any SRHeaderViewModel,
                                       subHeader: (any SRSubHeaderViewModel)?) {
        currentHeader = header
        if let subHeader { currentSubHeader = subHeader }
    }
    
    private func findPreviousSubHeader(realHeaderIndex: Int,
                                       realSubHeaderIndex: Int) -> (header: (any SRHeaderViewModel)?,
                                                                    subHeader: (any SRSubHeaderViewModel)?) {
        
        var h = realHeaderIndex
        var s = realSubHeaderIndex - 1
        while h >= 0 {
            let header = headers[h]
            if s >= 0, header.subHeaders.indices.contains(s) {
                return (header, header.subHeaders[s])
            }
            
            h -= 1
            if h >= 0 {
                s = headers[h].subHeaders.count - 1
            }
        }
        return (nil, nil)
    }
    
    private func overlayView() -> some View {
        stickyHeader(currentHeader, currentSubHeader)
            .anchorPreference(key: StickyHeaderAnchorKey.self, value: .bounds) { $0 }
    }
    
    private func updateStickyHeader(from anchor: Anchor<CGRect>?, geo: GeometryProxy) {
        guard let anchor else { return }
        let rect = geo[anchor]
        overlayBottomGlobalY = rect.maxY
        checkPositions()
    }
}

// MARK: Models

private struct ItemAnchorKey: PreferenceKey {
    
    // MARK: Properties
    
    nonisolated(unsafe) static var defaultValue: [String: Anchor<CGRect>] = [:]
    
    // MARK: Func
    
    static func reduce(value: inout [String : Anchor<CGRect>], nextValue: () -> [String : Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct StickyHeaderAnchorKey: PreferenceKey {
    
    // MARK: Properties
    
    nonisolated(unsafe) static var defaultValue: Anchor<CGRect>? = nil
    
    // MARK: Func
    
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue()
    }
}

private struct ListStylelessModifier: ViewModifier {
    
    // MARK: Func
    
    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets())
            .environment(\.defaultMinListRowHeight, 1)
            .listSectionSpacing(0)
            .listRowSpacing(0)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .listStyle(PlainListStyle())
    }
}

private struct ItemPosition: Equatable {
    
    // MARK: Properties
    
    let top: CGFloat
    let bottom: CGFloat
}

public protocol SRHeaderViewModel {
    
    // MARK: Properties
    
    var uniqueId: String { get }
    var subHeaders: [any SRSubHeaderViewModel] { get }
}

public protocol SRSubHeaderViewModel {
    
    // MARK: Properties
    
    var uniqueId: String { get }
    var rows: [any SRRowViewModel] { get }
}

public protocol SRRowViewModel {
    
    // MARK: Properties
    
    var uniqueId: String { get }
}

// MARK: Extensions

private extension View {
    
    // MARK: Computed properties
    
    var asListStyleless: some View {
        modifier(ListStylelessModifier())
    }
    
    var withoutBounces: some View {
        self.introspect(.list, on: .iOS(.v13, .v14, .v15)) { tableView in
            tableView.bounces = false
            tableView.sectionHeaderHeight = 0
            tableView.sectionFooterHeight = 0
        }
        .introspect(.list, on: .iOS(.v16, .v17, .v18, .v26)) { collectionView in
            collectionView.bounces = false
        }
    }
    
    // MARK: Func
    
    func trackPosition(id: String) -> some View {
        self.anchorPreference(key: ItemAnchorKey.self, value: .bounds) { anchor in
            [id: anchor]
        }
    }
}
