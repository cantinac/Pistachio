//
//  Adapter.swift
//  Pistachio
//
//  Created by Felix Jendrusch on 2/6/15.
//  Copyright (c) 2015 Felix Jendrusch. All rights reserved.
//

import LlamaKit

public struct Adapter<A, B, E> {
    private let specification: [String: Lens<Result<A, E>, Result<B, E>>]
    private let dictionaryTansformer: ValueTransformer<B, [String: B], E>

    public init(specification: [String: Lens<Result<A, E>, Result<B, E>>], dictionaryTansformer: ValueTransformer<B, [String: B], E>) {
        self.specification = specification
        self.dictionaryTansformer = dictionaryTansformer
    }

    public func encode(a: A) -> Result<B, E> {
        var result: [String: B] = [String: B]()
        for (key, lens) in self.specification {
            switch get(lens, success(a)) {
            case .Success(let value):
                result[key] = value.unbox
            case .Failure(let error):
                return failure(error.unbox)
            }
        }

        return dictionaryTansformer.reverseTransformedValue(result)
    }

    public func decode(a: A, from: B) -> Result<A, E> {
        return dictionaryTansformer.transformedValue(from).flatMap { dictionary in
            var result: Result<A, E> = success(a)
            for (key, lens) in self.specification {
                if let value = dictionary[key] {
                    result = set(lens, result, success(value))
                    if !result.isSuccess { break }
                }
            }

            return result
        }
    }
}
