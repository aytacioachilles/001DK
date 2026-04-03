//
//  DannebrogView.swift
//  001DK
//
 
import SwiftUI
 
// MARK: - Dannebrog (Danish flag) drawn in SwiftUI
struct DannebrogView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let crossV: CGFloat  = w * 0.38
            let crossVW: CGFloat = w * 0.13
            let crossH: CGFloat  = h * 0.13
 
            ZStack {
                Color(red: 0.78, green: 0.08, blue: 0.12)
 
                Rectangle()
                    .fill(.white)
                    .frame(width: w, height: crossH * 2)
                    .position(x: w / 2, y: h / 2)
 
                Rectangle()
                    .fill(.white)
                    .frame(width: crossVW, height: h)
                    .position(x: crossV + crossVW / 2, y: h / 2)
            }
        }
    }
}
