//
//  BandscopeView.swift
//  Icom7610a
//
//  Created by Mark Erbaugh on 12/6/21.
//

import SwiftUI

struct Panadapter: Shape {
    let data: Data
    let maxY = CGFloat(200)
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        let deltaX = CGFloat(rect.width) / CGFloat(data.count + 1)
        var calcX = rect.minX
        for y in data {
            p.addLine(to: CGPoint(x:calcX, y:rect.height * (1.0 - min(CGFloat(y), maxY) / maxY)))
            calcX += deltaX
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct BGGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRect(rect)
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return p
    }
}

struct BandscopeView: View {
    let data: (Data, Data)
    var body: some View {
        Panadapter(data: data.0)
            .foregroundColor(.yellow.opacity(0.5))
            .background (
                Panadapter(data: data.1)
                    .foregroundColor(.yellow.opacity(0.1))
            )
            .background(BGGrid()
                            .stroke(.gray, lineWidth: 1.0)
                            .background(Color.black))
    }
}

struct BandscopeView_Previews: PreviewProvider {
    static var previews: some View {
        BandscopeView(data: (Data(), Data()))
    }
}
