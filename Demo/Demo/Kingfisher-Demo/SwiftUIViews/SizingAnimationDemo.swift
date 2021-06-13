//
//  SizingAnimationDemo.swift
//  Kingfisher
//
//  Created by onevcat on 2021/03/02.
//
//  Copyright (c) 2021 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import SwiftUI
import Kingfisher

@available(iOS 14.0, *)
struct SizingAnimationDemo: View {
    @State var imageSize: CGFloat = 250
    @State var isPlaying = false

    var body: some View {
        VStack {
            KFImage(URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading/kingfisher-1.jpg")!)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: imageSize, height: imageSize)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .frame(width: 350, height: 350)
            Button(action: {
                playButtonAction()
            }) {
                Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 60))
            }
        }

    }
    func playButtonAction() {
        withAnimation(Animation.spring(response: 0.45, dampingFraction: 0.475, blendDuration: 0)) {
            if self.imageSize == 250 {
                self.imageSize = 350
            } else {
                self.imageSize = 250
            }
            self.isPlaying.toggle()
        }
    }
}

@available(iOS 14.0, *)
struct SizingAnimationDemo_Previews: PreviewProvider {
    static var previews: some View {
        SizingAnimationDemo()
    }
}
