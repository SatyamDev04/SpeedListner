//
//  BarChartView.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 28/08/25.
//


import UIKit

final class BarChartView: UIView {
    struct Bar {
        let value: CGFloat        // e.g., average speed
        let label: String         // x axis label (date / month)
        let highlight: Bool       // to emphasize “today” etc.
    }

    var bars: [Bar] = [] { didSet { setNeedsDisplay(); setNeedsLayout() } }
    var valueFormatter: (CGFloat) -> String = { String(format: "%.2fx", $0) }

    private let labelFont = UIFont.systemFont(ofSize: 10, weight: .regular)
    private let valueFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
    private let axisColor = UIColor.secondaryLabel.withAlphaComponent(0.4)

    override func draw(_ rect: CGRect) {
        guard !bars.isEmpty else { return }
        let ctx = UIGraphicsGetCurrentContext()!
        let inset: CGFloat = 8
        let bottomSpace: CGFloat = 22
        let topSpace: CGFloat = 14

        let plot = rect.inset(by: UIEdgeInsets(top: inset + topSpace, left: inset, bottom: inset + bottomSpace, right: inset))

        // Axis line
        ctx.setStrokeColor(axisColor.cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: plot.minX, y: plot.maxY))
        ctx.addLine(to: CGPoint(x: plot.maxX, y: plot.maxY))
        ctx.strokePath()

        // Max value
        let maxVal = max(bars.map { $0.value }.max() ?? 0, 0.1)

        let barSpacing: CGFloat = 6
        let barWidth = max(2, (plot.width - CGFloat(bars.count - 1) * barSpacing) / CGFloat(bars.count))

        // Draw bars
        for (i, b) in bars.enumerated() {
            let x = plot.minX + CGFloat(i) * (barWidth + barSpacing)
            let h = (CGFloat(b.value) / maxVal) * plot.height
            let barRect = CGRect(x: x, y: plot.maxY - h, width: barWidth, height: h)

            let color = b.highlight ? tintColor : UIColor.label.withAlphaComponent(0.8)
            color?.setFill()
            UIBezierPath(roundedRect: barRect, cornerRadius: min(3, barWidth/2)).fill()

            // Value label (only if enough space)
            if h > 16 {
                let vs = valueFormatter(b.value) as NSString
                let size = vs.size(withAttributes: [.font: valueFont])
                let p = CGPoint(x: x + (barWidth - size.width)/2, y: barRect.minY - size.height - 2)
                vs.draw(at: p, withAttributes: [.font: valueFont, .foregroundColor: UIColor.secondaryLabel])
            }

            // X label
            let ls = (b.label as NSString)
            let lsize = ls.size(withAttributes: [.font: labelFont])
            let lp = CGPoint(x: x + (barWidth - lsize.width)/2, y: plot.maxY + 4)
            ls.draw(at: lp, withAttributes: [.font: labelFont, .foregroundColor: UIColor.secondaryLabel])
        }
    }
}
