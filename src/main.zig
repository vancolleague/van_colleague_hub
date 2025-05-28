const std = @import("std");
const testing = std.testing;

const clap = @import("clap");
const httpz = @import("httpz");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
//const lib = @import("van_colleague_hub_lib");

pub fn main() !void {
    //const allocator = testing.allocator;
    const allocator = std.heap.page_allocator;

    // What parameters do we want to take?
    // Use 'parseParamsComptime' to parse a string into an array of 'Param(Help)'
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                    Display this help and exit.
        \\-c, --node-count <usize>      Number of nodes to expect.
        \\-w, --wait <usize>            Wait time for stuff to respond.
    );

    // Initialize our diagnostics, which can be used for useful errors.
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        //.allocator = gpa.allocator(),
        .allocator = allocator,
    }) catch |err| {
        std.debug.print("--oops\n", .{});
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        std.debug.print("--help\n", .{});

    var server = try httpz.Server(void).init(allocator, .{ .port = 5882 }, {});
    defer {
        server.stop();
        server.deinit();
    }

    var router = try server.router(.{});
    router.get("/api/user:id", getUser, .{});

    try server.listen();
}

fn getUser(req: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    try res.json(.{ .id = req.param("id").?, .name = "Teg" }, .{});
}
