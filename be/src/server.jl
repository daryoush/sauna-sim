println("server starting!")
using Joseki
println("Joseki imported!")
using JSON
println("JSON imported!")
using HTTP
println("HTTP imported")
import HTTP.IOExtras.bytes
using SaunaModel:json_api
println("SaunaModel imported!")
### Create some endpoints

# This function takes two numbers x and y from the query string and returns x^y
# In this case they need to be identified by name and it should be called with
# something like 'http://localhost:8000/pow/?x=2&y=3'
function pow(req::HTTP.Request)
    j = HTTP.queryparams(HTTP.URI(req.target))
    has_all_required_keys(["x", "y"], j) || return error_responder(req, "You need to specify values for x and y!")
    # Try to parse the values as numbers.  If there's an error here the generic
    # error handler will deal with it.
    x = parse(Float32, j["x"])
    y = parse(Float32, j["y"])
    json_responder(req, x^y)
end

# This function takes two numbers n and k from a JSON-encoded request
# body and returns binomial(n, k)
function bin(req::HTTP.Request)
    j = try
        body_as_dict(req)
    catch err
        return error_responder(req, "I was expecting a json request body!")
    end
    has_all_required_keys(["n", "k"], j) || return error_responder(req, "You need to specify values for n and k!")
    json_responder(req, binomial(j["n"],j["k"]))
end

function simulate(req::HTTP.Request)
    b = json_api("{}")
    req.response.body = bytes(b)
    return req.response
end

### Create and run the server

# Make a router and add routes for our endpoints.
endpoints = [
    (pow, "GET", "/pow"),
    (bin, "POST", "/bin"),
    (simulate, "GET", "/simulate")
]
r = Joseki.router(endpoints)

# If there is a PORT environment variable defined us it, otherwise use 8000
haskey(ENV, "PORT") ? port = parse(Int32, ENV["PORT"]) : port = 8000
# Fire up the server, binding to all ips

Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    HTTP.serve(r, "0.0.0.0", port; verbose=false)
end