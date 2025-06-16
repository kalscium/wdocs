const std = @import("std");
const wdocs = @import("wdocs");

pub fn main() !void {
    const slice = "hello-world, or something else__ + 01234";
    var idx: usize = 0;

    while (idx != slice.len) {
        const word = wdocs.collectWord(slice, &idx);

        // if no match, skip character
        if (word.len == 0) {
            idx += 1;
            continue;
        }
        
        std.debug.print("word: {s}\n", .{word});
    }

    const test_err_meta = wdocs.err.Metadata{
        .error_msg = "this code doesn't work",
        .span_start = 33,
        .context_span_start = 31,
        .context_span_end = 42,
        .span_end = 35,
        .context = "these 'l's are in hello",
    };
    try wdocs.err.report(std.io.getStdErr().writer(), 12, test_err_meta, "foo.bar", "\n123456789012345678901234567890hello world123456789012345678901234567890\n");

    const raw = "#page 12 \n #title a new world. \n #author dave\n#date 2025-06-15  \n#topic everything is here now\nsome #red((prett(y)) red text)\nhi";
    idx = 0;
    var err_meta: wdocs.err.Metadata = .{};
    const page = wdocs.metadata.parsePageNum(raw, &idx, &err_meta) catch |err| {
        if (err == wdocs.err.ParsingError.ParsingError)
            try wdocs.err.report(std.io.getStdErr().writer(), null, err_meta, "example.foo", raw);
        return err;
    };
    std.debug.print("found page: {?}\n", .{page});
    var metadata = wdocs.metadata.Metadata{};
    while (!metadata.isComplete()) {
        metadata.parse(raw, &idx, &err_meta) catch |err| {
            try wdocs.err.report(std.io.getStdErr().writer(), page, err_meta, "example.foo", raw);
            return err;
        };
    }

    // try parse paren
    while (idx < raw.len) : (idx += 1) {
        if (raw[idx] == '(') {
            const paren = wdocs.modifier.parseParen(idx, raw, &idx, &err_meta) catch |err| {
                try wdocs.err.report(std.io.getStdErr().writer(), page, err_meta, "example.foo", raw);
                return err;
            };
            std.debug.print("found inside parentheses: {s}\n", .{paren});
        } 
    }
}
