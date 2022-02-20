//
//  BandscopeView.swift
//  Icom7610a
//
//  Created by Mark Erbaugh on 12/6/21.
//

import SwiftUI

struct Panadapter: Shape {
    let data: Data
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height))
        for (x,y) in data.enumerated() {
            p.addLine(to: CGPoint(x:CGFloat(x), y:rect.height - CGFloat(y)))
        }
        p.addLine(to: CGPoint(x:CGFloat(data.count - 1), y: rect.height))
        p.closeSubpath()
        return p
    }
    
    
}

struct BandscopeView: View {
    let data: (Data, Data)
    var body: some View {
        ZStack() {
        Panadapter(data: data.1)
                .foregroundColor(.yellow.opacity(0.2))
            Panadapter(data: data.0)
                .foregroundColor(.yellow)
        }
    }
}

struct BandscopeView_Previews: PreviewProvider {
    static var previews: some View {
        BandscopeView(data: (Data(), Data()))
    }
}
