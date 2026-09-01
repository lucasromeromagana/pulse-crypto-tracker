import Charts
import DesignSystem
import Domain
import SwiftUI

struct PriceChartView: View {
    let points: [PricePoint]
    let tint: Color
    let showsLiveDot: Bool
    let xLabelFormat: Date.FormatStyle
    @Binding var scrubbedPoint: PricePoint?
    @State private var revealProgress: CGFloat = 0
    @State private var isFullyRevealed = false

    var body: some View {
        Chart {
            ForEach(points) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Price", point.price.doubleValue)
                )
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .foregroundStyle(tint)

                // Explicit yStart pins the fill to the visible domain; the
                // default baseline is y = 0, which for a price domain like
                // 66,000...68,000 paints thousands of points below the plot.
                AreaMark(
                    x: .value("Time", point.timestamp),
                    yStart: .value("Baseline", yDomain.lowerBound),
                    yEnd: .value("Price", point.price.doubleValue)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(
                    LinearGradient(
                        colors: [tint.opacity(0.25), tint.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            if let scrubbedPoint {
                RuleMark(x: .value("Scrub", scrubbedPoint.timestamp))
                    .foregroundStyle(Palette.textTertiary.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
            }
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Palette.strokeSubtle)
                AxisValueLabel(format: xLabelFormat)
                    .font(AppTypography.label(11))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Palette.strokeSubtle)
                AxisValueLabel()
                    .font(AppTypography.label(11))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .clipped()
        .mask {
            GeometryReader { geometry in
                Rectangle()
                    .frame(width: geometry.size.width * revealProgress)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                revealProgress = 1
            } completion: {
                isFullyRevealed = true
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    if showsLiveDot, isFullyRevealed, scrubbedPoint == nil, let last = points.last,
                       let position = position(of: last, proxy: proxy, geometry: geometry) {
                        PulsingDot(color: tint)
                            .position(position)
                    }
                    if let scrubbedPoint,
                       let position = position(of: scrubbedPoint, proxy: proxy, geometry: geometry) {
                        Circle()
                            .fill(tint)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .position(position)
                    }
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(scrubGesture(proxy: proxy, geometry: geometry))
                }
            }
        }
        .animation(.smooth(duration: 0.45), value: points)
    }

    private var yDomain: ClosedRange<Double> {
        let values = points.map(\.price.doubleValue)
        guard let minimum = values.min(), let maximum = values.max() else { return 0...1 }
        guard minimum < maximum else {
            return minimum * 0.995...maximum * 1.005 + 0.0001
        }
        let padding = (maximum - minimum) * 0.1
        return (minimum - padding)...(maximum + padding)
    }

    private func position(
        of point: PricePoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) -> CGPoint? {
        guard let plotFrame = proxy.plotFrame else { return nil }
        let frame = geometry[plotFrame]
        guard
            let x = proxy.position(forX: point.timestamp),
            let y = proxy.position(forY: point.price.doubleValue)
        else { return nil }
        return CGPoint(x: frame.origin.x + x, y: frame.origin.y + y)
    }

    private func scrubGesture(proxy: ChartProxy, geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let plotFrame = proxy.plotFrame else { return }
                let frame = geometry[plotFrame]
                let x = value.location.x - frame.origin.x
                guard let date: Date = proxy.value(atX: x) else { return }
                scrubbedPoint = points.min {
                    abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date))
                }
            }
            .onEnded { _ in
                withAnimation(.easeOut(duration: 0.2)) { scrubbedPoint = nil }
            }
    }
}

struct PulsingDot: View {
    let color: Color
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: 30, height: 30)
                .scaleEffect(isPulsing ? 1 : 0.25)
                .opacity(isPulsing ? 0 : 0.8)
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
                .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 1.5))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
        .allowsHitTesting(false)
    }
}
