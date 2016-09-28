// MARK: - Frinkiac -
//------------------------------------------------------------------------------
public struct Frinkiac: ServiceHost {
    /// - parameter scheme: `https`.
    public var scheme: String {
        return "https"
    }
    /// - parameter host: `frinkiac.com`.
    public var host: String {
        return "frinkiac.com"
    }
    /// - parameter path: `api`.
    public var path: String? {
        return "api"
    }

    /// - parameter shared: A shared instance.
    fileprivate static let shared = Frinkiac()
}

// MARK: - Extension, Links -
//------------------------------------------------------------------------------
extension Frinkiac {
    /**
     Generates an image link (URL string) for the given `frame`.
     
     - parameter frame: A frame from which the image link will be generated.
     - returns: A link to an image for the given `frame`.
     */
    public static func imageLink(frame: Frame) -> String {
        return "\(shared.scheme)://\(shared.host)/meme/\(frame.episode)/\(frame.timestamp).jpg"
    }

    /**
     Generates a meme link (URL string) for the given `frame`.
     
     - parameter frame: A frame from which the meme link will be generated.
     - parameter caption: The phrase to be used when generating the meme.
     - returns: A link to a meme for the `frame`, with the given `caption`.
     */
    public static func memeLink(frame: Frame, text caption: String) -> String {
        return "\(imageLink(frame: frame))?lines=\(caption.URLEscapedString ?? "")"
    }
}

// MARK: - Extension, API Services -
//------------------------------------------------------------------------------
extension Frinkiac {
    /**
     A wrapper around the singleton's `request` instance function.
     
     - parameter session: The `URLSession` which generates the data task.
     - parameter endpoint: The path endpoint (aka, API route).
     - parameter parameters: An optional set of query parameters.
     - parameter callback: The returning logic invoked when the request is made.
     - returns: A `URLSessionDataTask` which, when started, performs the request.
     */
    private static func request(session: URLSession = URLSession.shared, endpoint: String, parameters: [String:Any]? = nil, callback: @escaping (() throws -> (Any, URLResponse)) -> ()) -> URLSessionDataTask {
        return Frinkiac.shared.request(session: session, endpoint: endpoint, parameters: parameters, callback: callback)
    }

    /**
     Searches for frames containing `quote`.
     
     - parameter quote: The text to be searched for.
     - parameter callback: The returning logic invoked when the request is made.
     - returns: A `URLSessionTask` which, when started, performs the request.
     */
    public static func search(for quote: String, callback: @escaping (() throws -> ([Frame], URLResponse)) -> ()) -> URLSessionTask {
        return request(endpoint: "search", parameters: ["q":quote]) { next in
            callback {
                let result = try next()
                let quotes = (result.0 as? [Any])?.map { Frame(json: $0) } ?? []
                return (quotes, result.1)
            }
        }
    }

    /**
     Fetches the associated `Caption` for `frame`.
     
     - parameter frame: The frame being requested.
     - parameter callback: The returning logic invoked when the request is made.
     - returns: A `URLSessionTask` which, when started, performs the request.
     */
    public static func caption(with frame: Frame, callback: @escaping (() throws -> (Caption, URLResponse)) -> ()) -> URLSessionTask {
        return request(endpoint: "caption", parameters: ["e":frame.episode,"t":frame.timestamp]) { next in
            callback {
                let result = try next()
                let caption = Caption(json: result.0)
                return (caption, result.1)
            }
        }
    }

    /**
     Generates a random caption.
     
     - parameter callback: The returning logic invoked when the request is made.
     - returns: A `URLSessionTask` which, when started, performs the request.
     */
    public static func random(callback: @escaping (() throws -> (Caption, URLResponse)) -> ()) -> URLSessionTask {
        return request(endpoint: "random") { next in
            callback {
                let result = try next()
                let caption = Caption(json: result.0)
                return (caption, result.1)
            }
        }
    }
}

// MARK: - Frame -
//------------------------------------------------------------------------------
public struct Frame {
    // MARK: - Computed -
    //--------------------------------------------------------------------------
    public var episode: String {
        return self["Episode"] as? String ?? ""
    }
    public var id: Int {
        return self["Id"] as? Int ?? 0
    }
    public var timestamp: Int {
        return self["Timestamp"] as? Int ?? 0
    }

    // MARK: - Private -
    //--------------------------------------------------------------------------
    fileprivate let json: Any
    
    // MARK: - Subscript -
    //--------------------------------------------------------------------------
    private subscript(key: String) -> Any? {
        return (json as? [String:AnyObject])?[key]
    }

    // MARK: - Inferred -
    //--------------------------------------------------------------------------
    public var imageLink: String {
        return Frinkiac.imageLink(frame: self)
    }
}

// MARK: - Episode -
//------------------------------------------------------------------------------
public struct Episode {
    // MARK: - Computed -
    //--------------------------------------------------------------------------
    public var director: String {
        return self["Director"] as? String ?? ""
    }
    public var episodeNumber: Int {
        return self["EpisodeNumber"] as? Int ?? 0
    }
    public var id: Int {
        return self["Id"] as? Int ?? 0
    }
    public var key: String {
        return self["Key"] as? String ?? ""
    }
    public var originalAirDate: String {
        return self["OriginalAirDate"] as? String ?? ""
    }
    public var season: Int {
        return self["Season"] as? Int ?? 0
    }
    public var title: String {
        return self["Title"] as? String ?? ""
    }
    public var wikiLink: String {
        return self["WikiLink"] as? String ?? ""
    }
    public var writer: String {
        return self["Write"] as? String ?? ""
    }

    // MARK: - Private -
    //--------------------------------------------------------------------------
    fileprivate let json: Any
    
    // MARK: - Subscript -
    //--------------------------------------------------------------------------
    private subscript(key: String) -> Any? {
        return (json as? [String:AnyObject])?[key]
    }
}

// MARK: - Subtitle -
//------------------------------------------------------------------------------
public struct Subtitle {
    // MARK: - Computed -
    //--------------------------------------------------------------------------
    public var content: String {
        return self["Content"] as? String ?? ""
    }
    public var endTimestamp: Int {
        return self["EndTimestamp"] as? Int ?? 0
    }
    public var episode: String {
        return self["Episode"] as? String ?? ""
    }
    public var id: Int {
        return self["Id"] as? Int ?? 0
    }
    public var language: String {
        return self["Language"] as? String ?? ""
    }
    public var representatativeTimestamp: Int {
        return self["RepresentativeTimestamp"] as? Int ?? 0
    }
    public var startTimestamp: Int {
        return self["StartTimestamp"] as? Int ?? 0
    }

    // MARK: - Private -
    //--------------------------------------------------------------------------
    fileprivate let json: Any

    // MARK: - Subscript -
    //--------------------------------------------------------------------------
    private subscript(key: String) -> Any? {
        return (json as? [String:AnyObject])?[key]
    }
}

// MARK: - Caption -
//------------------------------------------------------------------------------
public struct Caption {
    // MARK: - Computed -
    //--------------------------------------------------------------------------
    public var episode: Episode {
        return Episode(json: self["Episode"]!)
    }
    public var frame: Frame {
        return Frame(json: self["Frame"]!)
    }
    public var nearby: [Frame] {
        return (self["Nearby"] as? [Any] ?? []).map { Frame(json: $0) }
    }
    public var subtitles: [Subtitle] {
        return (self["Subtitles"] as? [Any] ?? []).map { Subtitle(json: $0) }
    }

    // MARK: - Private -
    //--------------------------------------------------------------------------
    fileprivate let json: Any

    // MARK: - Subscript -
    //--------------------------------------------------------------------------
    private subscript(key: String) -> Any? {
        return (json as? [String:AnyObject])?[key]
    }

    // MARK: - Inferred -
    //--------------------------------------------------------------------------
    public var caption: String {
        return subtitles.caption
    }
    public var imageLink: String {
        return Frinkiac.imageLink(frame: frame)
    }
    public var memeLink: String {
        return Frinkiac.memeLink(frame: frame, text: caption)
    }
}

// MARK: - Extension, Ccaption -
//------------------------------------------------------------------------------
extension Sequence where Iterator.Element == Subtitle {
    fileprivate var caption: String {
        return map { $0.content }
            .joined(separator: " ")
            .lineSplitted
    }
}

// MARK: - Extension, Line Splitted -
//------------------------------------------------------------------------------
extension String {
    /// https://github.com/gausie/slack-frinkiac/blob/master/src/server.js#L38
    fileprivate var lineSplitted: String {
        return components(separatedBy: " ")
            .reduce([[String]]()) { lines, word in
                var nextLines = lines
                let line = nextLines.last ?? []
                
                let lastLineLength = line.joined(separator: " ").characters.count
                let wordLength = word.characters.count + 1
                
                if lastLineLength + wordLength <= 25, lastLineLength > 0 {
                    nextLines[nextLines.index(before: nextLines.endIndex)].append(word)
                } else {
                    nextLines.append([word])
                }
                return nextLines
            }
            .map { $0.joined(separator: " ") }
            .joined(separator: "\n")
    }
}