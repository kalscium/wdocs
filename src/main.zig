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

    // const raw = "#cover\n#title The cover page\nhere is the cover page #page 12 \n #title a new world. \n #author dave\n#date 2025-06-15  \n#topic everything is here now\n#title(a grand title)\nsome #red((prett(y)) red text)\n\n\nhi there #itallic(nerd)\n#bold(bold of you)\ncheese &amp;wine\n#page 13 this belongs to another page";
    const raw =
        \\#cover
        \\#title The cover page
        \\#author The Robotics Team
        \\#date 2024-06-17
        \\#topic Cover Page
        \\Here is the cover page!
        \\#page 12
        \\#title a new world.
        \\#author dave
        \\#date 2025-06-15
        \\#topic everything is here now
        \\#title(a grand title)
        \\some #red((prett(y)) red text)
        \\hi there #itallic(nerd)
        \\#bold(bold of you)
        \\cheese &amp;wine
        \\#page 13 this belongs to another page
        ;
    idx = 0;
    var err_meta: wdocs.err.Metadata = .{};
    var page = wdocs.metadata.parsePageNum(raw, &idx, &err_meta) catch |err| {
        if (err == wdocs.err.ParsingError.ParsingError)
            try wdocs.err.report(std.io.getStdErr().writer(), null, err_meta, "example.foo", raw);
        return err;
    } orelse return;

    while (idx < raw.len) {
        std.debug.print("\n<<< found page: {?}>>>\n", .{page});

        var metadata = wdocs.metadata.Metadata{};
        while (!metadata.isComplete()) {
            metadata.parse(raw, &idx, &err_meta) catch |err| {
                try wdocs.err.report(std.io.getStdErr().writer(), page, err_meta, "example.foo", raw);
                return err;
            };
        }

        // print contents
        page = wdocs.book.parseContents(std.io.getStdOut().writer(),  raw, &idx, &err_meta) catch |err| {
            try wdocs.err.report(std.io.getStdErr().writer(), page, err_meta, "example.foo", raw);
            return err;
        } orelse page;
    }
}
