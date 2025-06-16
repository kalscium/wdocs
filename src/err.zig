//! All functions for dealing with (parsing) errors and reporting them

const std = @import("std");

/// The only true zig 'error' returned for parsing errors, for easy handling
pub const ParsingError = error { ParsingError };

/// Error metadata that is initialized upon parsing error
pub const Metadata = struct {
    /// The start of the context span
    /// 
    /// note: the context span should always contain the error span
    context_span_start: usize = undefined,
    /// THe end of the context span
    context_span_end: usize = undefined,
    /// The start of the error span
    span_start: usize = undefined,
    /// The end of the error span
    span_end: usize = undefined,
    
    /// The main error message (shown at the top `error: foo`)
    error_msg: []const u8 = undefined,
    /// The context for the error
    context: []const u8 = undefined,
};

/// Reports an error to a writer from the page number, metadata, filename and file contents
pub fn report(writer: anytype, page_num: ?usize, metadata: Metadata, filename: []const u8, contents: []const u8) !void {
    // how many characters at the start of the line to include (also applies to the end)
    const line_cutoff = 20; // 16 feels a bit too short, 24 a bit too long

    try std.fmt.format(writer, "\x1B[31;1merror:\x1B[0m {s}\n\x1B[35;1m-->\x1B[0m {s}\n", .{ metadata.error_msg, filename });

    // count the lines
    // note: assumes no span spans more than one line
    // note: also assumes the spans are valid
    var lines: usize = 1;
    var line_start: usize = 0;
    var line_end: usize = undefined;
    for (contents, 0..) |char, i| {
        if (char == '\n') {
            lines += 1;
            line_start = i + 1;
        }
        if (i == metadata.span_start) {
            line_end = i;
            while (line_end < contents.len and contents[line_end] != '\n')
                line_end += 1;
            break;
        }
    }

    // calculate the line num length
    const lines_n_len = @as(usize, @intFromFloat(@log10(@as(f64, @floatFromInt(lines))))) + 1;

    // print the page number
    try writer.writeByteNTimes(' ', lines_n_len + 1);
    try writer.writeAll("\x1B[34;1m--+( \x1B[0m");
    if (page_num) |num|
        try std.fmt.format(writer, "\x1B[32m#page {} \x1B[34;1m)\n", .{num})
    else
        try writer.writeAll("\x1B[30;1munknown page \x1B[34;1m)\n");

    // write the spacer line
    try writer.writeByteNTimes(' ', lines_n_len + 1);
    try writer.writeAll("|\n");

    // write the line number
    try std.fmt.format(writer, "\x1B[0m\x1B[33m{} \x1B[34;1m| \x1B[30;1m...\x1B[0m", .{lines});

    // write the starting contents
    const sc_start = @min(line_cutoff, metadata.context_span_start -| line_start);
    try writer.writeAll(contents[metadata.context_span_start-sc_start..metadata.context_span_start]);

    // write the context contents & error contents
    try std.fmt.format(writer, "\x1B[36m{s}\x1B[31m{s}\x1B[36m{s}\x1B[0m", .{
        contents[metadata.context_span_start..metadata.span_start],
        contents[@min(line_end, metadata.span_start)..@min(line_end, metadata.span_end)],
        contents[@min(line_end, metadata.span_end)..@min(line_end, metadata.context_span_end)],
    });

    // write the ending contents
    const sc_end = @min(line_cutoff, line_end -| metadata.context_span_end);
    try writer.writeAll(contents[@min(contents.len, metadata.context_span_end)..@min(contents.len, metadata.context_span_end+sc_end)]);

    // write more structure stuff & padding
    try writer.writeAll("\x1B[30;1m...\n");
    try writer.writeByteNTimes(' ', lines_n_len + 1);
    try writer.writeAll("\x1B[34;1m:");
    try writer.writeByteNTimes(' ', sc_start + 4);

    // write the context & error arrows
    try writer.writeAll("\x1B[36;1m");
    try writer.writeByteNTimes('~', metadata.span_start-metadata.context_span_start);
    try writer.writeAll("\x1B[31;1m");
    try writer.writeByteNTimes('^', metadata.span_end-metadata.span_start);
    try writer.writeAll("\x1B[36;1m");
    try writer.writeByteNTimes('~', metadata.context_span_end-metadata.span_end);

    // write the context message and the start of the last line
    try std.fmt.format(writer, "\x1B[0m {s}\n\x1B[34;1m+", .{metadata.context});

    // write the last line
    try writer.writeByteNTimes('-', lines_n_len + 1);
    try writer.writeAll("\x1B[0m\n");
}
