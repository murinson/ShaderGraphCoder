//
//  USDA.swift
//  ShaderGraphCoder
//
//  Created by Frank A. Krueger on 2/10/24.
//

import Foundation

public extension SGNode {
    var usdaName: String { "Node\(id)" }
}

public extension SGDataType {
    var usda: String {
        return self.rawValue
    }
}

public extension SIMD2<Float> {
    var usda: String {
        return "(\(self.x), \(self.y))"
    }
}

public extension SIMD3<Float> {
    var usda: String {
        return "(\(self.x), \(self.y), \(self.z))"
    }
}

public extension SIMD4<Float> {
    var usda: String {
        return "(\(self.x), \(self.y), \(self.z), \(self.w))"
    }
}

public extension SGConstantValue {
    var usda: String {
        switch self {
        case .bool(let v):
            return v ? "1" : "0"
        case .color3f(let v, colorSpace: .some(let cs)):
            return "\(v.usda) (colorSpace = \"\(cs.rawValue)\")"
        case .color4f(let v, colorSpace: .some(let cs)):
            return "\(v.usda) (colorSpace = \"\(cs.rawValue)\")"
        case .color3f(let v, colorSpace: .none):
            return v.usda
        case .color4f(let v, colorSpace: .none):
            return v.usda
        case .emptyTexture:
            return "\"\""
        case .float(let v):
            return "\(v)"
        case .half(let v):
            return "\(v)"
        case .int(let v):
            return "\(v)"
        case .string(let v):
            return "\"\(v)\""
        case .texture:
            return "\"\""
        case .token(let v):
            return "\"\(v)\""
        case .vector2f(let v):
            return v.usda
        case .vector3f(let v):
            return v.usda
        case .vector4f(let v):
            return v.usda
        case .vector2h(let v):
            return "(\(v.x), \(v.y))"
        case .vector3h(let v):
            return "(\(v.x), \(v.y), \(v.z))"
        case .vector4h(let v):
            return "(\(v.x), \(v.y), \(v.z), \(v.w))"
        case .vector2i(let v):
            return "(\(v.x), \(v.y))"
        case .vector3i(let v):
            return "(\(v.x), \(v.y), \(v.z))"
        case .vector4i(let v):
            return "(\(v.x), \(v.y), \(v.z), \(v.w))"
        case .matrix2d(let v):
            return "(\(v.columns.0.usda), \(v.columns.1.usda))"
        case .matrix3d(let v):
            return "(\(v.columns.0.usda), \(v.columns.1.usda), \(v.columns.2.usda))"
        case .matrix4d(let v):
            return "(\(v.columns.0.usda), \(v.columns.1.usda), \(v.columns.2.usda), \(v.columns.3.usda))"
        }
    }
}

public extension SGValueSource {
    func getUSDAReference(materialName: String) -> String {
        switch self {
        case .constant(let ivalue):
            return ivalue.usda
        case .nodeOutput(let inode, let inodeOut):
            return "</Root/\(materialName)/\(inode.usdaName).outputs:\(inodeOut)>"
        case .nodeGraphInput(let nodeGraph, let inputName):
            return "</Root/\(nodeGraph.name).inputs:\(inputName)>"
        case .parameter(name: let name, defaultValue: _):
            return "</Root/\(materialName).inputs:\(name)>"
        case .error(let error, _):
            return "\"\(error)\""
        }
    }
}

public func getUSDA(materialName: String, surface: SGToken?, geometryModifier: SGToken?, nodeGraphs: [SGNodeGraph]) -> (String, [String: SGTextureSource], [String]) {
    var lines: [String] = []
    func line(_ text: String) {
        lines.append(text)
    }
    line("#usda 1.0")
    line("(")
    line("    defaultPrim = \"Root\"")
    line("    metersPerUnit = 1")
    line("    upAxis = \"Y\"")
    line(")")
    line("")
    line("def Xform \"Root\"")
    line("{")
    line("    reorder nameChildren = [\"\(materialName)\"]")
    line("    def Material \"\(materialName)\"")
    line("    {")
    
    let outputValues = [surface, geometryModifier]
    let outputNodes = [surface?.node, geometryModifier?.node].compactMap { $0 }
    let parameters = collectParameters(nodes: outputNodes)
    let errors = collectErrors(values: outputValues)
    var textureSources: [String: SGTextureSource] = [:]
    for p in parameters {
        let (name, defaultValue) = p
        line("        \(defaultValue.dataType.usda) inputs:\(name) = \(defaultValue.usda)")
        if case SGConstantValue.texture(let source) = defaultValue {
            textureSources[name] = source
        }
    }
    
    if let s = surface?.node {
        let v = s.getOutputValue(name: "out").getUSDAReference(materialName: materialName)
        line("        token outputs:mtlx:surface.connect = \(v)")
    }
    else {
        line("        token outputs:mtlx:surface")
    }
    if let g = geometryModifier?.node {
        let v = g.getOutputValue(name: "out").getUSDAReference(materialName: materialName)
        line("        token outputs:realitykit:vertex.connect = \(v)")
    }
    else {
        line("        token outputs:realitykit:vertex")
    }
    
    writeShaders(for: materialName, outputNodes: outputNodes, line: line)
    
    line("    }") // Material
    
    for ng in nodeGraphs {
        line("    def NodeGraph \"\(ng.name)\" (")
        line("        active = true")
        line("    )")
        line("    {")
        for i in ng.inputs {
            line("        \(i.dataType.usda) inputs:\(i.name) = \(i.dataType.defaultValue.usda)")
        }
        for o in ng.outputs {
            line("        \(o.value.dataType.usda) outputs:\(o.name)")
            line("        \(o.value.dataType.usda) outputs:\(o.name).connect = \(o.value.source.getUSDAReference(materialName: ng.name))")
        }
        
        writeShaders(for: ng.name, outputNodes: ng.outputs.compactMap { $0.value.node }, line: line)
        
        line("    }") // NodeGraph
    }
    
    line("}") // Xform
    
    return (lines.joined(separator: "\n"), textureSources, errors)
}

fileprivate func writeShaders(for entityName: String, outputNodes: [SGNode], line: (String) -> ()) {
    var nodesToWrite: [SGNode] = outputNodes
    var nodesWritten: Set<SGNode> = []
    while nodesToWrite.count > 0 {
        let node = nodesToWrite[0]
        nodesToWrite.remove(at: 0)
        nodesWritten.insert(node)
        line("")
        
        if let referenceNode = node as? SGNodeGraphReference {
            line("        def \"\(referenceNode.usdaName)\" (")
            line("            active = true")
            line("            instanceable = true")
            line("            references = </Root/\(referenceNode.nodeGraph.name)>")
            line("        )")
            line("        {")
        } else {
            line("        def Shader \"\(node.usdaName)\"")
            line("        {")
            line("            uniform token info:id = \"\(node.nodeType)\"")
        }
        
        for i in node.inputs {
            var decl = "\(i.dataType.usda) inputs:\(i.name)"
            if let c = i.value?.source {
                switch c {
                case .nodeOutput, .parameter, .nodeGraphInput: decl += ".connect"
                default: break
                }
            }
            if let value = i.value?.source.getUSDAReference(materialName: entityName) {
                line("            \(decl) = \(value)")
            }
            else {
                line("            \(decl)")
            }
        }
        for o in node.outputs {
            let decl = "\(o.dataType.usda) outputs:\(o.name)"
            line("            \(decl)")
        }
        line("        }")
        for i in node.inputs {
            if case .nodeOutput(let inode, _) = i.value?.source {
                if !(nodesWritten.contains(inode) || nodesToWrite.contains(inode)) {
                    nodesToWrite.append(inode)
                }
            }
        }
    }
}
