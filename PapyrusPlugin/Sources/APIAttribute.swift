import SwiftSyntax

enum APIAttribute {
    /// Type or Function attributes
    case json(encoder: String, decoder: String)
    case urlForm(encoder: String)
    case multipart(encoder: String)
    case converter(encoder: String, decoder: String)
    case keyMapping(value: String)
    case headers(value: String)
    case authorization(value: String)

    /// Function attributes
    case http(method: String, path: String)

    /// Parameter attributes
    case body
    case field(key: String?)
    case query(key: String?)
    case header(key: String?)
    case path(key: String?)

    init?(syntax: AttributeSyntax) {
        var firstArgument: String?
        var secondArgument: String?
        var labeledArguments: [String: String] = [:]
        if case let .argumentList(list) = syntax.arguments {
            for argument in list {
                if let label = argument.label {
                    labeledArguments[label.description] = argument.expression.description
                }
            }

            firstArgument = list.first?.expression.description
            secondArgument = list.dropFirst().first?.expression.description
        }

        let name = syntax.attributeName.trimmedDescription
        switch name {
        case "GET", "DELETE", "PATCH", "POST", "PUT", "OPTIONS", "HEAD", "TRACE", "CONNECT":
            guard let firstArgument else {
                return nil
            }

            self = .http(method: name, path: firstArgument)
        case "HTTP":
            guard let firstArgument, let secondArgument else {
                return nil
            }

            self = .http(method: secondArgument.withoutQuotes, path: firstArgument)
        case "Body":
            self = .body
        case "Field":
            self = .field(key: firstArgument?.withoutQuotes)
        case "Query":
            self = .query(key: firstArgument?.withoutQuotes)
        case "Header":
            self = .header(key: firstArgument?.withoutQuotes)
        case "Path":
            self = .path(key: firstArgument?.withoutQuotes)
        case "Headers":
            guard let firstArgument else {
                return nil
            }

            self = .headers(value: firstArgument)
        case "JSON":
            let encoder = labeledArguments["encoder"] ?? "JSONEncoder()"
            let decoder = labeledArguments["decoder"] ?? "JSONDecoder()"
            self = .json(encoder: encoder, decoder: decoder)
        case "URLForm":
            self = .urlForm(encoder: firstArgument ?? "URLEncodedFormEncoder()")
        case "Multipart":
            self = .multipart(encoder: firstArgument ?? "MultipartEncoder()")
        case "Converter":
            guard let firstArgument, let secondArgument else {
                return nil
            }

            self = .converter(encoder: firstArgument, decoder: secondArgument)
        case "KeyMapping":
            guard let firstArgument else {
                return nil
            }

            self = .keyMapping(value: firstArgument)
        case "Authorization":
            guard let firstArgument else {
                return nil
            }

            self = .authorization(value: firstArgument)
        default:
            return nil
        }
    }

    func apiBuilderStatement(input: String? = nil) -> String? {
        switch self {
        case .body:
            guard let input else {
                return "Input Required!"
            }

            return """
            req.setBody(\(input))
            """
        case let .query(key):
            guard let input else {
                return "Input Required!"
            }

            let mapParameter = key == nil ? "" : ", mapKey: false"
            return """
            req.addQuery("\(key ?? input)", value: \(input)\(mapParameter))
            """
        case let .header(key):
            guard let input else {
                return "Input Required!"
            }

            let hasCustomKey = key == nil
            let convertParameter = hasCustomKey ? "" : ", convertToHeaderCase: true"
            return """
            req.addHeader("\(key ?? input)", value: \(input)\(convertParameter))
            """
        case let .path(key):
            guard let input else {
                return "Input Required!"
            }

            return """
            req.addParameter("\(key ?? input)", value: \(input))
            """
        case let .field(key):
            guard let input else {
                return "Input Required!"
            }

            let mapParameter = key == nil ? "" : ", mapKey: false"
            return """
            req.addField("\(key ?? input)", value: \(input)\(mapParameter))
            """
        case .json(let encoder, let decoder):
            return """
            req.requestEncoder = .json(\(encoder))
            req.responseDecoder = .json(\(decoder))
            """
        case .urlForm(let encoder):
            return """
            req.requestEncoder = .urlForm(\(encoder))
            """
        case .multipart(let encoder):
            return """
            req.requestEncoder = .multipart(\(encoder))
            """
        case .converter(let encoder, let decoder):
            return """
            req.requestEncoder = \(encoder)
            req.responseDecoder = \(decoder)
            """
        case .headers(let value):
            return """
            req.addHeaders(\(value))
            """
        case .keyMapping(let value):
            return """
            req.keyMapping = \(value)
            """
        case .authorization(value: let value):
            return """
            req.addAuthorization(\(value))
            """
        case .http:
            return nil
        }
    }
}
