//
//  ShaderGraphPreview.swift
//  HoloVids
//
//  Created by Frank A. Krueger on 6/5/24.
//

#if os(visionOS)

import SwiftUI
import RealityKit

struct ShaderGraphPreview: View {
    let surface: SGToken?
    let geometryModifier: SGToken? = nil
    @State private var error: String? = nil
    var body: some View {
        VStack {
            if let e = error {
                Text(e)
                    .font(.title)
                    .padding()
                    .background(.red)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 600)
            }
            RealityView { content in
                do {
                    let mat = try await ShaderGraphMaterial(surface: surface, geometryModifier: geometryModifier, nodeGraphs: [])
                    let entity0 = ModelEntity(mesh: .generateBox(size: 0.16), materials: [mat])
                    entity0.transform.translation = [-0.1, 0.0, 0.0]
                    let entity1 = ModelEntity(mesh: .generateSphere(radius: 0.1), materials: [mat])
                    entity1.transform.translation = [0.1, 0.0, 0.0]
                    content.add(entity0)
                    content.add(entity1)
                    self.error = nil
                }
                catch {
                    if case ShaderGraphCoderError.graphContainsErrors(errors: let es) = error {
                        self.error = es.joined(separator: "\n")
                    }
                    else {
                        self.error = error.localizedDescription
                    }
                }
            }
        }
    }
}

#Preview {
    // let data = try? Data(contentsOf: URL(string: "https://praeclarum.org/assets/me.jpg")!)
    // let image = UIImage(data: data!)!.cgImage!
    // let texture: SGTexture = .texture(from: image, options: TextureResource.CreateOptions(semantic: .color))
    // let textureSurface = texture.sampleColor3f().pbrSurface()
    let blueSurface = SGValue.color3f([0, 0, 1]).pbrSurface()
    return ShaderGraphPreview(surface: blueSurface)
}

#endif
