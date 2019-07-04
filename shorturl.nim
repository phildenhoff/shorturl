import jester, asyncdispatch, htmlgen, json, os, strutils, strformat, tables, md5, times
#[ 
    jester: Provides a DSL for quickly creating web applications in Nim.
    asyncdispatch: for async/await
    htmlgen: generate HTML pages
    json: to parse JSON strings into Nim structures, and to dump Nim structures
        into JSON strings
    tables: dictionaries
    md5: generating new ids
    times: routines for realing with the "proleptic Gergorian calendar"
]#

const CONF_PORT = "5000"
const CONF_DOMAIN = "http://localhost"
const CONF_INDEX_HTML = "index.html"
const hostname = CONF_DOMAIN & ":" & CONF_PORT

var urlMapping = initTable[string, string]()

type
    PathFileBackings = enum
        Index = "index.html",
        Err404 = "404.html"

proc newEIO(msg: string): owned(ref IOError) =
    new(result)
    result.msg = msg

proc getPageContent(index: PathFileBackings): string =
    if not existsFile($index):
        raise newEIO("Requested file " & $index & " doesn't exist.")
    let file = open($index)
        
    var html = readAll(file).string
    file.close

    return html


#[ Generates a short ID for use in the domain path as the shortened URL.
]#
proc generateId(url: string): string =
    var time = cpuTime()
    let fullsizeMd5 = getMD5(url & formatFloat(time))
    let id = fullsizeMd5[^5 .. ^1]

    return id


router mainRouter:
    get "/":
        var indexHtml = getPageContent(PathFileBackings.Index)

        indexHtml = indexHtml.replace("%%hostname", hostname)
        resp indexHtml


    post "/shorten":
        let url: string = parseJson(request.body).getOrDefault("url").getStr()

        # Handle malformed requests
        if url.len == 0:
            resp Http400, "Request must include a URL as \"url\"."

        var urlInMapping = false
        var id: string
        for k, v in urlMapping.pairs:
            if url == v:
                id = k
                urlInMapping = true
                break

        if urlInMapping == false:
            # ID:URL mapping not created yet; we'll add it now
            id = generateId(url)
            urlMapping[id]= url 

        var jsonResp = $(%*{"id": id})
        resp Http200, jsonResp
    

    get "/@Id":
        if urlMapping.contains(@"Id") == false:
            try:
                var content404 = getPageContent(Err404)
                resp Http404, content404
            except IOError:
                echo "ERROR: Failed to access file " & $Err404
                resp Http500, "Internal error, something went wrong"

        let url = urlMapping[@"Id"]
        redirect url
    

proc main() =
    let port = CONF_PORT.parseInt().Port
    let settings = newSettings(port=port)
    var jester = initJester(mainRouter, settings=settings)
    jester.serve()

when isMainModule:
    main()
