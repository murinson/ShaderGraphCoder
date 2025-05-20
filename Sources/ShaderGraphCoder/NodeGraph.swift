//
//  File.swift
//  ShaderGraphCoder
//
//  Created by MU USA on 13/5/25.
//

import Foundation
import simd

public class SGNodeGraph {
    public let name: String
    public private(set) var inputs: [Input] = []
    public private(set) var outputs: [Output] = []
    
    public init(name: String) {
        self.name = name
    }
    
    @discardableResult
    public func addInput(_ input: Input) -> SGValueSource {
        self.inputs.append(input)
        return SGValueSource.nodeGraphInput(self, input.name)
    }
    
    public func addOutput(_ output: Output) {
        self.outputs.append(output)
    }
    
    public struct Input {
        public let name: String
        public let dataType: SGDataType
        public init(name: String, dataType: SGDataType) {
            self.name = name
            self.dataType = dataType
        }
    }
    
    public struct Output {
        public let name: String
        public let value: SGValue
        public init(name: String, connection: SGValue) {
            self.name = name
            self.value = connection
        }
        public init(connection: SGValue) {
            self.name = "out"
            self.value = connection
        }
    }
    
    public func findInput(name: String) -> Input? {
        inputs.first { $0.name == name }
    }
    
    public func findOutput(name: String) -> Output? {
        outputs.first { $0.name == name }
    }
}

extension SGDataType {
    var defaultValue: SGConstantValue {
        switch self {
        case .asset: .emptyTexture
        case .bool: .bool(false)
        case .color3f: .color3f(.zero)
        case .color4f: .color4f(.zero)
        case .error: .int(0)
        case .half: .half(0)
        case .float: .float(0)
        case .int: .int(0)
        case .matrix2d: .matrix2d(matrix_identity_float2x2)
        case .matrix3d: .matrix3d(matrix_identity_float3x3)
        case .matrix4d: .matrix4d(matrix_identity_float4x4)
        case .string: .string("")
        case .token: .token("")
        case .vector2f: .vector2f(.zero)
        case .vector3f: .vector3f(.zero)
        case .vector4f: .vector4f(.zero)
        case .vector2h: .vector2h(.zero)
        case .vector3h: .vector3h(.zero)
        case .vector4h: .vector4h(.zero)
        case .vector2i: .vector2i(.zero)
        case .vector3i: .vector3i(.zero)
        case .vector4i: .vector4i(.zero)
        }
    }
}

public class SGNodeGraphReference: SGNode {
    public let nodeGraph: SGNodeGraph
    
    public init(nodeGraph: SGNodeGraph, inputs: [Input]) {
        self.nodeGraph = nodeGraph
        
        super.init(nodeType: "NodeGraphReference", inputs: inputs, outputs: [])
    }
}
