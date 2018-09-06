/**
    Stratum protocol is based on JSON-RPC 2.0.
    (although it doesn't include "jsonrpc" information in every message).
    Each message has to end with a line end character (n).
*/
module rpc.protocol.stratum;

import rpc.core;
import rpc.protocol.json;
import vibe.data.json;
import std.typecons: Nullable, nullable;


class StratumRPCRequest : JsonRPCRequest!int
{
public:
    static StratumRPCRequest make(T)(int id, string method, T params)
    {
        import vibe.data.json : serializeToJson;

        auto request = new StratumRPCRequest();
        request.id = id;
        request.method = method;
        request.params = serializeToJson!T(params);

        return request;
    }

    static StratumRPCRequest make(int id, string method)
    {
        auto request = new StratumRPCRequest();
        request.id = id;
        request.method = method;

        return request;
    }

    /** Strip the "jsonrpc" field.
    */
    override Json toJson() const @safe
    {
        Json json = Json.emptyObject;
        json["method"] = method;
        json["id"] = id;
        if (!params.isNull)
            json["params"] = params.get;
        return json;
    }

    /** Strip the "jsonrpc" field.
    */
    static StratumRPCRequest fromJson(Json src) @safe
    {
        StratumRPCRequest request = new StratumRPCRequest();
        request.method = src["method"].to!string;
        if (src["id"].type != Json.Type.undefined)
            request.id = src["id"].to!int;
        if (src["params"].type != Json.Type.undefined)
            request.params = src["params"].nullable;
        return request;
    }
}

class StratumRPCResponse : JsonRPCResponse!int
{
public:
    /** Strip the "jsonrpc" field.
    */
    override Json toJson() const @safe
    {
        Json json = Json.emptyObject;
        // the id must be 'null' in case of parse error
        if (!id.isNull)
            json["id"] = id.get;
        else
            json["id"] = null;
        if (!result.isNull)
            json["result"] = result.get;
        if (!error.isNull)
            json["error"] = serializeToJson!(const(JsonRPCError))(error.get);
        return json;
    }

    /** Strip the "jsonrpc" field.
    */
    static StratumRPCResponse fromJson(Json src) @safe
    {
        StratumRPCResponse request = new StratumRPCResponse();
        if (src["id"].type != Json.Type.undefined)
        {
            if (src["id"].type == Json.Type.null_)
                request.id.nullify;
            else
                request.id = src["id"].to!int;
        }
        if (src["result"].type != Json.Type.undefined)
            request.result = src["result"].nullable;
        if (src["error"].type != Json.Type.undefined)
            request.error = deserializeJson!JsonRPCError(src["error"]).nullable;
        return request;
    }
}

class RawStratumRPCServer : RawJsonRPCServer!(int, StratumRPCRequest, StratumRPCResponse)
{
    import vibe.core.stream: InputStream, OutputStream;

public:
    this(OutputStream ostream, InputStream istream) @safe
    {
        super(ostream, istream);
    }
}

class HTTPStratumRPCServer : HTTPJsonRPCServer!(int, StratumRPCRequest, StratumRPCResponse)
{
    import vibe.http.router: URLRouter;

public:
    this(URLRouter router, string path)
    {
        super(router, path);
    }
}

class TCPStratumRPCServer : TCPJsonRPCServer!(int, StratumRPCRequest, StratumRPCResponse)
{
public:
    this(ushort port, RPCInterfaceSettings settings = null)
    {
        super(port, settings);
    }
}

class RawStratumRPCAutoClient(I) : JsonRPCAutoClient!(I, int, StratumRPCRequest, StratumRPCResponse)
{
    import vibe.core.stream: InputStream, OutputStream;
    import autointf;

public:
    this(OutputStream ostream, InputStream istream) @safe
    {
        _client = new RawJsonRPCClient!(int, StratumRPCRequest, StratumRPCResponse)(ostream, istream);
        _settings = new RPCInterfaceSettings();
    }

    mixin(autoImplementMethods!I());
}

class HTTPStratumRPCAutoClient(I) : JsonRPCAutoClient!(I, int, StratumRPCRequest, StratumRPCResponse)
{
    import autointf;

public:
    this(string host) @safe
    {
        _client = new HTTPJsonRPCClient!(int, StratumRPCRequest, StratumRPCResponse)(host);
        _settings = new RPCInterfaceSettings();
    }

    mixin(autoImplementMethods!I());
}

class TCPStratumRPCAutoClient(I) : JsonRPCAutoClient!(I, int, StratumRPCRequest, StratumRPCResponse)
{
    import autointf;

public:
    this(string host, ushort port) @safe
    {
        _client = new TCPJsonRPCClient!(int, StratumRPCRequest, StratumRPCResponse)(host, port);
        _settings = new RPCInterfaceSettings();
    }

    mixin(autoImplementMethods!I());
}