// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


//
// Code generators.
//
// These insert one or more instructions into a program.
//
public typealias CodeGenerator = (_ b: ProgramBuilder) -> ()

public func IntegerLiteralGenerator(_ b: ProgramBuilder) {
    b.loadInt(b.genInt())
}

public func FloatLiteralGenerator(_ b: ProgramBuilder) {
    b.loadFloat(b.genFloat())
}

public func StringLiteralGenerator(_ b: ProgramBuilder) {
    b.loadString(b.genString())
}

public func BooleanLiteralGenerator(_ b: ProgramBuilder) {
    b.loadBool(Bool.random())
}

public func UndefinedValueGenerator(_ b: ProgramBuilder) {
    b.loadUndefined()
}

public func NullValueGenerator(_ b: ProgramBuilder) {
    b.loadNull()
}

public func ObjectLiteralGenerator(_ b: ProgramBuilder) {
    var initialProperties = [String: Variable]()
    for _ in 0..<Int.random(in: 0..<10) {
        initialProperties[b.genPropertyNameForWrite()] = b.randVar()
    }
    b.createObject(with: initialProperties)
}

public func ArrayLiteralGenerator(_ b: ProgramBuilder) {
    var initialValues = [Variable]()
    for _ in 0..<Int.random(in: 0..<5) {
        initialValues.append(b.randVar())
    }
    b.createArray(with: initialValues)
}

public func ObjectLiteralWithSpreadGenerator(_ b: ProgramBuilder) {
    var initialProperties = [String: Variable]()
    var spreads = [Variable]()
    for _ in 0..<Int.random(in: 0..<10) {
        withProbability(0.5, do: {
            initialProperties[b.genPropertyNameForWrite()] = b.randVar()
        }, else: {
            spreads.append(b.randVar())
        })
    }
    b.createObject(with: initialProperties, andSpreading: spreads)
}

public func ArrayLiteralWithSpreadGenerator(_ b: ProgramBuilder) {
    var initialValues = [Variable]()
    for _ in 0..<Int.random(in: 0..<5) {
        initialValues.append(b.randVar())
    }
    
    // Pick some random inputs to spread.
    let spreads = initialValues.map({ _ in Bool.random() })
    
    b.createArray(with: initialValues, spreading: spreads)
}

public func BuiltinGenerator(_ b: ProgramBuilder) {
    b.loadBuiltin(b.genBuiltinName())
}

public func FunctionDefinitionGenerator(_ b: ProgramBuilder) {
    // For functions, we always generate one random instruction and one return instruction as function body.
    // This ensures that generating one random instruction does not accidentially generate multiple instructions
    // (which increases the likelyhood of runtime exceptions), but also generates somewhat useful functions.
    b.defineFunction(withSignature: FunctionSignature(withParameterCount: Int.random(in: 2...5), hasRestParam: probability(0.1)), isJSStrictMode: probability(0.2)) { _ in
        b.generate()
        b.doReturn(value: b.randVar())
    }
}

public func PropertyRetrievalGenerator(_ b: ProgramBuilder) {
    let object = b.randVar(ofType: .object())
    let propertyName = b.type(of: object).randomProperty() ?? b.genPropertyNameForRead()
    b.loadProperty(propertyName, of: object)
}

public func PropertyAssignmentGenerator(_ b: ProgramBuilder) {
    let object = b.randVar(ofType: .object())
    let propertyName: String
    // Either change an existing property or define a new one
    if probability(0.5) {
        propertyName = b.type(of: object).randomProperty() ?? b.genPropertyNameForWrite()
    } else {
        propertyName = b.genPropertyNameForWrite()
    }
    let value = b.randVar()
    b.storeProperty(value, as: propertyName, on: object)
}

public func PropertyRemovalGenerator(_ b: ProgramBuilder) {
    let object = b.randVar(ofType: .object())
    let propertyName = b.type(of: object).randomProperty() ?? b.genPropertyNameForWrite()
    b.deleteProperty(propertyName, of: object)
}

public func ElementRetrievalGenerator(_ b: ProgramBuilder) {
    let array = b.randVar(ofType: .object())
    let index = b.genIndex()
    b.loadElement(index, of: array)
}

public func ElementAssignmentGenerator(_ b: ProgramBuilder) {
    let array = b.randVar(ofType: .object())
    let index = b.genIndex()
    let value = b.randVar()
    b.storeElement(value, at: index, of: array)
}

public func ElementRemovalGenerator(_ b: ProgramBuilder) {
    let array = b.randVar(ofType: .object())
    let index = b.genIndex()
    b.deleteElement(index, of: array)
}

public func ComputedPropertyAssignmentGenerator(_ b: ProgramBuilder) {
    let object = b.randVar(ofType: .object())
    
    let propertyName = b.randVar()
    let value = b.randVar()
    b.storeComputedProperty(value, as: propertyName, on: object)
}

public func ComputedPropertyRetrievalGenerator(_ b: ProgramBuilder) {
    let object = b.randVar()
    let propertyName = b.randVar()
    
    b.loadComputedProperty(propertyName, of: object)
}

public func ComputedPropertyRemovalGenerator(_ b: ProgramBuilder) {
    let object = b.randVar()
    let propertyName = b.randVar()
    
    b.deleteComputedProperty(propertyName, of: object)
}

public func TypeTestGenerator(_ b: ProgramBuilder) {
    let v = b.randVar()
    let type = b.doTypeof(v)
    
    // Also generate a comparison here, since that's probably the only interesting thing you can do with the result.
    let rhs = b.loadString(chooseUniform(from: JavaScriptEnvironment.jsTypeNames))
    b.compare(type, rhs, with: .strictEqual)
}

public func InstanceOfGenerator(_ b: ProgramBuilder) {
    let lhs = b.randVar()
    let rhs = b.randVar()
    b.doInstanceOf(lhs, rhs)
}

public func InGenerator(_ b: ProgramBuilder) {
    let lhs = b.randVar()
    let rhs = b.randVar()
    b.doIn(lhs, rhs)
}

public func MethodCallGenerator(_ b: ProgramBuilder) {
    let object = b.randVar(ofType: .object())
    let methodName = b.type(of: object).randomMethod() ?? b.genMethodName()
    let arguments = b.generateCallArguments(forMethod: methodName, on: object)
    
    b.callMethod(methodName, on: object, withArgs: arguments)
}

public func FunctionCallGenerator(_ b: ProgramBuilder) {
    let function = b.randVar(ofType: .function())
    let arguments = b.generateCallArguments(for: function)
    
    b.callFunction(function, withArgs: arguments)
}

public func FunctionReturnGenerator(_ b: ProgramBuilder) {
    if b.isInFunction {
        b.doReturn(value: b.randVar())
    }
}

public func ConstructorCallGenerator(_ b: ProgramBuilder) {
    let constructor = b.randVar(ofType: .constructor())

    let arguments = b.generateCallArguments(for: constructor)
    
    b.construct(constructor, withArgs: arguments)
}

public func FunctionCallWithSpreadGenerator(_ b: ProgramBuilder) {
    let function = b.randVar(ofType: .function())
    // Since we are spreading, the signature doesn't actually help, so ignore it completely
    let arguments = b.generateCallArguments(for: FunctionSignature.forUnknownFunction)
    
    // Pick some random arguments to spread.
    let spreads = arguments.map({ _ in Bool.random() })
    
    b.callFunction(function, withArgs: arguments, spreading: spreads)
}

public func UnaryOperationGenerator(_ b: ProgramBuilder) {
    let input = b.randVar()
    b.unary(chooseUniform(from: allUnaryOperators), input)
}

public func BinaryOperationGenerator(_ b: ProgramBuilder) {
    let lhs = b.randVar()
    let rhs = b.randVar()
    b.binary(lhs, rhs, with: chooseUniform(from: allBinaryOperators))
}

public func PhiGenerator(_ b: ProgramBuilder) {
    b.phi(b.randVar())
}

public func ReassignmentGenerator(_ b: ProgramBuilder) {
    if let output = b.randVar(ofGuaranteedType: .phi(of: .anything)) {
        let input = b.randVar()
        b.copy(input, to: output)
    }
}

public func ComparisonGenerator(_ b: ProgramBuilder) {
    let lhs = b.randVar()
    let rhs = b.randVar()
    b.compare(lhs, rhs, with: chooseUniform(from: allComparators))
}

public func IfStatementGenerator(_ b: ProgramBuilder) {
    // Optionally create some kind of comparison as well
    withProbability(0.5) {
        b.run(chooseUniform(from: [ComparisonGenerator, ComparisonGenerator, TypeTestGenerator, InstanceOfGenerator]))
    }
    
    let cond = b.randVar(ofType: .boolean)
    let phi = b.phi(b.randVar())
    b.beginIf(cond) {
        b.generate()
        b.copy(b.randVar(), to: phi)
    }
    b.beginElse() {
        b.generate()
        b.copy(b.randVar(), to: phi)
    }
    b.endIf()
}

public func WhileLoopGenerator(_ b: ProgramBuilder) {
    let start = b.loadInt(0)
    let end = b.loadInt(Int.random(in: 0...10))
    let loopVar = b.phi(start)
    b.whileLoop(loopVar, .lessThan, end) {
        b.generate()
        let newLoopVar = b.unary(.Inc, loopVar)
        b.copy(newLoopVar, to: loopVar)
    }
}

public func DoWhileLoopGenerator(_ b: ProgramBuilder) {
    let start = b.loadInt(0)
    let end = b.loadInt(Int.random(in: 0...10))
    let loopVar = b.phi(start)
    b.doWhileLoop(loopVar, .lessThan, end) {
        b.generate()
        let newLoopVar = b.unary(.Inc, loopVar)
        b.copy(newLoopVar, to: loopVar)
    }
}

public func ForLoopGenerator(_ b: ProgramBuilder) {
    let start = b.loadInt(0)
    let end = b.loadInt(Int.random(in: 100...200))
    let step = b.loadInt(1)
    b.forLoop(start, .lessThan, end, .Add, step) { _ in
        b.generate()
    }
}

public func ForInLoopGenerator(_ b: ProgramBuilder) {
    let obj = b.randVar(ofType: .object())
    b.forInLoop(obj) { _ in
        b.generate()
    }
}

public func ForOfLoopGenerator(_ b: ProgramBuilder) {
    let obj = b.randVar(ofType: .object())
    b.forOfLoop(obj) { _ in
        b.generate()
    }
}

public func BreakGenerator(_ b: ProgramBuilder) {
    if b.isInLoop {
        b.doBreak()
    }
}

public func ContinueGenerator(_ b: ProgramBuilder) {
    if b.isInLoop {
        b.doContinue()
    }
}

public func TryCatchGenerator(_ b: ProgramBuilder) {
    let v = b.phi(b.randVar())
    b.beginTry() {
        b.generate()
        b.copy(b.randVar(), to: v)
    }
    b.beginCatch() { _ in
        b.generate()
        b.copy(b.randVar(), to: v)
    }
    b.endTryCatch()
}

public func ThrowGenerator(_ b: ProgramBuilder) {
    let v = b.randVar()
    b.throwException(v)
}

//
// Language-specific Generators
//

public func TypedArrayGenerator(_ b: ProgramBuilder) {
    let size = b.loadInt(Int.random(in: 0...0x10000))
    let constructor = b.loadBuiltin(chooseUniform(from: ["Uint8Array", "Int8Array", "Uint16Array", "Int16Array", "Uint32Array", "Int32Array", "Float32Array", "Float64Array", "Uint8ClampedArray", "DataView"]))
    b.construct(constructor, withArgs: [size])
}

public func FloatArrayGenerator(_ b: ProgramBuilder) {
    let value = b.loadFloat(13.37)
    b.createArray(with: Array(repeating: value, count: Int.random(in: 1...5)))
}

public func IntArrayGenerator(_ b: ProgramBuilder) {
    let value = b.loadInt(1337)
    b.createArray(with: Array(repeating: value, count: Int.random(in: 1...5)))
}

public func ObjectArrayGenerator(_ b: ProgramBuilder) {
    let value = b.createObject(with: [:])
    b.createArray(with: Array(repeating: value, count: Int.random(in: 1...5)))
}

public func WellKnownPropertyLoadGenerator(_ b: ProgramBuilder) {
    let Symbol = b.loadBuiltin("Symbol")
    let name = chooseUniform(from: ["isConcatSpreadable", "iterator", "match", "replace", "search", "species", "split", "toPrimitive", "toStringTag", "unscopables"])
    let pname = b.loadProperty(name, of: Symbol)
    let obj = b.randVar(ofType: .object())
    b.loadComputedProperty(pname, of: obj)
}

public func WellKnownPropertyStoreGenerator(_ b: ProgramBuilder) {
    let Symbol = b.loadBuiltin("Symbol")
    let name = chooseUniform(from: ["isConcatSpreadable", "iterator", "match", "replace", "search", "species", "split", "toPrimitive", "toStringTag", "unscopables"])
    let pname = b.loadProperty(name, of: Symbol)
    let obj = b.randVar(ofType: .object())
    let val = b.randVar()
    b.storeComputedProperty(val, as: pname, on: obj)
}

public func PrototypeAccessGenerator(_ b: ProgramBuilder) {
    let obj = b.randVar(ofType: .object())
    b.loadProperty("__proto__", of: obj)
}

public func PrototypeOverwriteGenerator(_ b: ProgramBuilder) {
    let obj = b.randVar(ofType: .object())
    let proto = b.randVar(ofType: .object())
    b.storeProperty(proto, as: "__proto__", on: obj)
}

public func CallbackPropertyGenerator(_ b: ProgramBuilder) {
    let obj = b.randVar(ofType: .object())
    let callback = b.randVar(ofType: .function())
    let propertyName = chooseUniform(from: ["valueOf", "toString"])
    b.storeProperty(callback, as: propertyName, on: obj)
}

public func PropertyAccessorGenerator(_ b: ProgramBuilder) {
    let receiver = b.randVar(ofType: .object())
    let propertyName = probability(0.5) ? b.loadString(b.genPropertyNameForWrite()) : b.loadInt(b.genIndex())
    
    var initialProperties = [String: Variable]()
    withEqualProbability({
        initialProperties = ["get": b.randVar(ofType: .function())]
    }, {
        initialProperties = ["set": b.randVar(ofType: .function())]
    }, {
        initialProperties = ["get": b.randVar(ofType: .function()), "set": b.randVar(ofType: .function())]
    })
    let descriptor = b.createObject(with: initialProperties)
    
    let Object = b.loadBuiltin("Object")
    b.callMethod("defineProperty", on: Object, withArgs: [receiver, propertyName, descriptor])
}



public func ProxyGenerator(_ b: ProgramBuilder) {
    let target = b.randVar()
    
    var candidates = Set(["getPrototypeOf", "setPrototypeOf", "isExtensible", "preventExtensions", "getOwnPropertyDescriptor", "defineProperty", "has", "get", "set", "deleteProperty", "ownKeys", "apply", "call", "construct"])
    
    var handlerProperties = [String: Variable]()
    for _ in 0..<Int.random(in: 0..<candidates.count) {
        let hook = chooseUniform(from: candidates)
        candidates.remove(hook)
        handlerProperties[hook] = b.randVar(ofType: .function())
    }
    let handler = b.createObject(with: handlerProperties)
    
    let Proxy = b.loadBuiltin("Proxy")
    
    b.construct(Proxy, withArgs: [target, handler])
}

// Tries to change the length property of some object
public func LengthChangeGenerator(_ b: ProgramBuilder) {
    let target = b.randVar(ofType: .object())
    let newLength: Variable
    if probability(0.5) {
        newLength = b.loadInt(Int.random(in: 0..<3))
    } else {
        newLength = b.loadInt(b.genIndex())
    }
    b.storeProperty(newLength, as: "length", on: target)
}

// Tries to change the element kind of an array
public func ElementKindChangeGenerator(_ b: ProgramBuilder) {
    let target = b.randVar(ofType: .object())
    let value = b.randVar()
    b.storeElement(value, at: Int.random(in: 0..<3), of: target)
}

// Generates a JavaScript 'with' statement
public func WithStatementGenerator(_ b: ProgramBuilder) {
    let obj = b.randVar(ofType: .object())
    b.with(obj) {
        withProbability(0.5, do: { () -> Void in
            b.loadFromScope(id: b.genPropertyNameForRead())
        }, else: { () -> Void in
            let value = b.randVar()
            b.storeToScope(value, as: b.genPropertyNameForWrite())
        })
        b.generate()
    }
}

public func LoadFromScopeGenerator(_ b: ProgramBuilder) {
    guard b.isInWithStatement else {
        return
    }
    b.loadFromScope(id: b.genPropertyNameForRead())
}

public func StoreToScopeGenerator(_ b: ProgramBuilder) {
    guard b.isInWithStatement else {
        return
    }
    let value = b.randVar()
    b.storeToScope(value, as: b.genPropertyNameForWrite())
}


// wasm support
public func BufferSourceGenerator(_ b: ProgramBuilder) {
    
    let buffer = b.fuzzer.bufferSource.randomElement()
    var initialValues = [Variable]()
    for index in 0..<buffer.count {
        initialValues.append(b.loadInt(buffer[index]))
    }
    let AlterableArray = b.createArray(with: initialValues)
    let constructor = b.loadBuiltin("Uint8Array")
    b.construct(constructor, withArgs: [AlterableArray])
    
}

public func GlobalDescriptorFloatGenerator(_ b: ProgramBuilder) {
    var initialProperties = [String: String]()
    initialProperties = ["value": Bool.random() ? "\"f32\"" : "\"f64\"", "mutable": Bool.random() ? "true": "false"]
    let GlobalDescriptorFloat = b.createObjectWithValue(with: initialProperties)
    b.alter(GlobalDescriptorFloat, "GlobalDescriptorFloat")
}

public func GlobalDescriptorIntGenerator(_ b: ProgramBuilder) {
    
   var initialProperties = [String: String]()
     initialProperties = ["value": Bool.random() ? "\"i32\"" : "\"i64\"", "mutable": Bool.random() ? "true": "false"]
     let GlobalDescriptorInt = b.createObjectWithValue(with: initialProperties)
     b.alter(GlobalDescriptorInt, "GlobalDescriptorInt")
}

public func TableDescriptor(_ b: ProgramBuilder) {
    var initialProperties = [String: String]()
    withEqualProbability({
       initialProperties = ["element": "\"anyfunc\"", "initial": String(CInt.random(in: 0...42))]
    }, {
       initialProperties = ["element": "\"anyfunc\"", "initial": String(CInt.random(in: 0...42)), "maximum": String(CInt.random(in: 43...99))]
    })

    let TableDescriptor = b.createObjectWithValue(with: initialProperties)
    b.alter(TableDescriptor, "TableDescriptor")
    
}

public func MemoryDescriptor(_ b: ProgramBuilder) {
    var initialProperties = [String: String]()
    withEqualProbability({
        initialProperties = ["initial": String(Int.random(in: 0...9))]
    }, {
        initialProperties = ["initial": String(Int.random(in: 0...9)), "maximum": String(Int.random(in: 9...999))]
    })
    
    let MemoryDescriptor = b.createObjectWithValue(with: initialProperties)
    b.alter(MemoryDescriptor, "MemoryDescriptor")
    
}


public func ImportObjectGenerator(_ b: ProgramBuilder) {
    
    // need to optimize
    
    var initialProperties = [String: Variable]()
    withEqualProbability({
        initialProperties = [:]
    }, {
        let MemoryWasmObject = b.generalWasmObject(.MemoryWasmObject)
        initialProperties = ["mem": MemoryWasmObject]
        initialProperties = ["js": b.createObject(with: initialProperties)]
    }, {
        let TableWasmObject = b.generalWasmObject(.TableWasmObject)
        initialProperties = ["tbl": TableWasmObject]
        initialProperties = ["js": b.createObject(with: initialProperties)]
    })
    
    let o = b.createObject(with: initialProperties)
    b.alter(o, "ImportObject")

}



public func GlobalWasmObjectGenerator(_ b: ProgramBuilder) {
    var arguments = [Variable]()
    withEqualProbability({
        arguments = [b.generalWasmObject(.GlobalDescriptorFloat), b.loadFloat(b.genFloat())]
    }, {
        arguments = [b.generalWasmObject(.GlobalDescriptorInt), b.loadNumber(b.genInt())]
    })

    let constructor = b.loadBuiltin("WebAssembly.Global") //type: GlobalWasmConstructor
    b.construct(constructor, withArgs: arguments)
}


public func TableWasmObjectGenerator(_ b: ProgramBuilder) {

    let TableDescriptor = b.generalWasmObject(.TableDescriptor)
    let constructor = b.loadBuiltin("WebAssembly.Table")
    b.construct(constructor, withArgs: [TableDescriptor])
}



public func MemoryWasmObjectGenerator(_ b: ProgramBuilder) {
    
    let MemoryDescriptor = b.generalWasmObject(.MemoryDescriptor)
    let constructor = b.loadBuiltin("WebAssembly.Memory")
    b.construct(constructor, withArgs: [MemoryDescriptor])
}


public func ModuleWasmObjectGenerator(_ b: ProgramBuilder) {

    let BufferSource = b.generalWasmObject(.jsTypedArray("Uint8Array"))
    
    let constructor = b.loadBuiltin("WebAssembly.Module")
    b.construct(constructor, withArgs: [BufferSource])
}


public func InstanceWasmObjectGenerator(_ b: ProgramBuilder) {
    let constructor = b.loadBuiltin("WebAssembly.Instance")
    let ModuleWasmObject = b.generalWasmObject(.ModuleWasmObject)
    let ImportObject = b.generalWasmObject(.ImportObject)
    b.construct(constructor, withArgs: [ModuleWasmObject, ImportObject])

}



public func GlobalWasmObjectCallGenerator(_ b: ProgramBuilder) {
    // find one globalwasm object
    let GlobalWasmObject = b.generalWasmObject(.GlobalWasmObject)
    let methodName = b.type(of: GlobalWasmObject).randomMethod() ?? b.genMethodName()
    b.callMethod(methodName, on: GlobalWasmObject, withArgs: [])
}


public func TableWasmObjectCallGenerator(_ b: ProgramBuilder) {
    let TableWasmObject = b.generalWasmObject(.TableWasmObject)
    let methodName = b.type(of: TableWasmObject).randomMethod() ?? b.genMethodName()
    let arguments:[Variable]
    switch methodName {
    case "get":
        arguments = [b.loadNumber(Int.random(in: 0...42))]
    case "grow":
        arguments = [b.loadNumber(Int.random(in: 0...42))]
    default:
        arguments = b.generateCallArguments(forMethod: methodName, on: TableWasmObject)
    }
    
    b.callMethod(methodName, on: TableWasmObject, withArgs: arguments)
}


public func MemoryWasmObjectCallGenerator(_ b: ProgramBuilder) {
    let MemoryWasmObject = b.generalWasmObject(.MemoryWasmObject)
    let methodName = b.type(of: MemoryWasmObject).randomMethod() ?? b.genMethodName()
    let arguments = b.generateCallArguments(forMethod: methodName, on: MemoryWasmObject)
    b.callMethod(methodName, on: MemoryWasmObject, withArgs: arguments)
}


public func ModuleWasmObjectCallGenerator(_ b: ProgramBuilder) {
    let ModuleWasmObject = b.generalWasmObject(.ModuleWasmObject)
    let methodName = b.type(of: ModuleWasmObject).randomMethod() ?? b.genMethodName()
    let function = b.loadBuiltin(methodName)
    let arguments:[Variable]
    

    switch methodName {
    case "WebAssembly.Module.customSections":
        arguments = [ModuleWasmObject, b.loadString(chooseUniform(from: JavaScriptEnvironment.sectionName))]
    case "WebAssembly.Module.exports":
        arguments = [ModuleWasmObject]
    case "WebAssembly.Module.imports":
        arguments = [ModuleWasmObject]
    default:
        fatalError("No such method for Module")
    }
    
    b.callFunction(function, withArgs: arguments)
    
}

public func InstanceWasmObjectCallGenerator(_ b: ProgramBuilder) {
    
    let InstanceWasmObject = b.generalWasmObject(.InstanceWasmObject)
    let methodName = b.type(of: InstanceWasmObject).randomMethod() ?? b.genMethodName()
    let arguments = b.generateCallArguments(forMethod: methodName, on: InstanceWasmObject)
    b.callMethod(methodName, on: InstanceWasmObject, withArgs: arguments)
}

public func WasmMethodCallGenerator(_ b: ProgramBuilder) {
    let BufferSource = b.generalWasmObject(.jsTypedArray("Uint8Array"))
    let function = b.loadBuiltin(chooseUniform(from: ["WebAssembly.validate", "WebAssembly.compile"]))
    let arguments:[Variable]
    
    arguments = [BufferSource]
    b.callFunction(function, withArgs: arguments)
    
}

public func SpecialWasmObjectCallGenerator(_ b: ProgramBuilder, _ type: Type, _ methodName: String, _ arguments: [Variable]){
    
    let WasmObject = b.generalWasmObject(type)
    b.callMethod(methodName, on: WasmObject, withArgs: arguments)
}


public func WasmPropertyRetrievalGenerator(_ b: ProgramBuilder) {

    let candidates:[Type] = [.GlobalWasmObject, .TableWasmObject, .MemoryWasmObject, .ModuleWasmObject, .InstanceWasmObject]
    let object = b.randVar(ofType: chooseUniform(from: candidates))
    let propertyName = b.type(of: object).randomProperty() ?? b.genPropertyNameForRead()
    b.loadProperty(propertyName, of: object)
}

public func WasmPropertyAssignmentGenerator(_ b: ProgramBuilder) {
    
    let candidates:[Type] = [.GlobalWasmObject, .TableWasmObject, .MemoryWasmObject, .ModuleWasmObject, .InstanceWasmObject]
    let object = b.randVar(ofType: chooseUniform(from: candidates))
    let propertyName: String
    // Either change an existing property or define a new one
    propertyName = b.type(of: object).randomProperty() ?? b.genPropertyNameForWrite()
    let value = b.randVar()
    b.storeProperty(value, as: propertyName, on: object)
}

public func WasmPropertyRemovalGenerator(_ b: ProgramBuilder) {
    
    let candidates:[Type] = [.GlobalWasmObject, .TableWasmObject, .MemoryWasmObject, .ModuleWasmObject, .InstanceWasmObject]
    let object = b.randVar(ofType: chooseUniform(from: candidates))
    let propertyName = b.type(of: object).randomProperty() ?? b.genPropertyNameForWrite()
    b.deleteProperty(propertyName, of: object)
}




public func CVE_2020_0768(_ b: ProgramBuilder){
//    const v2 = undefined;
//    let v4 = 0;
//    while (v4 === v4) {
//        if (v2) {
//            const v9 = [1337];
//            [v9];
//        }
//        const v11 = v4 + 1;
//        v4 = v11;
//    }
    let v2 = b.const(b.loadUndefined())
    let v4 = b.phi(b.loadInt(0))
    b.whileLoop(v4, .strictEqual, v4) {
        b.beginIf(v2) {
            let v9 = b.createArray(with: [b.loadInt(1337)])
            b.createArray(with: [v9])

        }
        b.beginElse {
            b.beginIf(v2) {}
            b.endIf()
            
        }
        
        b.endIf()
        
        let v11 = b.binary(v4, b.loadInt(1), with: .Add)
        b.copy(v11, to: v4)
    }

}




//public func GeneralWasmObjectGenerator(_ b: ProgramBuilder, _ t: Type) -> Variable {
//    var GeneralWasmObject : Variable?
//    switch t {
//    case .GlobalWasmObject:
//        GeneralWasmObject = b.randVar(ofGuaranteedType: .GlobalWasmObject)
//        if GeneralWasmObject == nil {
//            GlobalWasmObjectGenerator(b)
//            GeneralWasmObject = b.randVar(ofGuaranteedType: .GlobalWasmObject)
//        }
//
//    case .TableWasmObject:
//        GeneralWasmObject = b.randVar(ofGuaranteedType: .TableWasmObject)
//        if GeneralWasmObject == nil {
//            TableWasmObjectGenerator(b)
//            GeneralWasmObject = b.randVar(ofGuaranteedType: .TableWasmObject)
//        }
//
//    case .MemoryWasmObject:
//        GeneralWasmObject = b.randVar(ofGuaranteedType: .MemoryWasmObject)
//        if GeneralWasmObject == nil {
//            MemoryWasmObjectGenerator(b)
//            GeneralWasmObject = b.randVar(ofGuaranteedType: .MemoryWasmObject)
//        }
//
//    case .ModuleWasmObject:
//        GeneralWasmObject = b.randVar(ofGuaranteedType: .ModuleWasmObject)
//        if GeneralWasmObject == nil {
//            ModuleWasmObjectGenerator(b)
//            GeneralWasmObject = b.randVar(ofGuaranteedType: .ModuleWasmObject)
//        }
//
//    case .ImportObject:
//        GeneralWasmObject = b.randVar(ofGuaranteedType: .ImportObject)
//        if GeneralWasmObject == nil {
//            ImportObjectGenerator(b)
//            GeneralWasmObject = b.randVar(ofGuaranteedType: .ImportObject)
//        }
//    default:
//        fatalError("Object Type \(n) is not supported")
//    }
//
//    return GeneralWasmObject!
//}

