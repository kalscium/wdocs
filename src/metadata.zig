//! Functions for parsing the document's metadata & page number

const std = @import("std");
const wdocs = @import("root.zig");
const err = @import("err.zig");

/// Parses the page number, discarded everything before it.
/// If no page number is found, then it will return null.
pub fn parsePageNum(slice: []const u8, idx: *usize, err_meta: *err.Metadata) err.ParsingError!?usize {
    // skip all characters until the '#page' token is found
    while (idx.* < slice.len) {
        // if the '#' character hasn't been found, keep searching
        if (slice[idx.*] != '#') {
            idx.* += 1;
            continue;
        }
        const ctxt_span_start = idx.*;
        idx.* += 1; // skip the '#' character

        // collect the tag, and ensure it's of the right kind
        const terr_span_start = idx.*;
        const tag = wdocs.collectWord(slice, idx);
        if (!std.mem.eql(u8, tag, "page")) {
            err_meta.* = .{
                .context_span_start = ctxt_span_start,
                .context_span_end = idx.*,
                .span_start = terr_span_start,
                .span_end = idx.*,
                .error_msg = "found tag before finding #page",
                .context = "this will be discarded/ignored",
            };
            return error.ParsingError;
        }

        // skip whitespace
        while (idx.* < slice.len and (slice[idx.*] == ' ' or slice[idx.*] == '\t')) : (idx.* += 1)
            continue;

        // try collect a number
        return wdocs.collectNumber(slice, idx) orelse {
            err_meta.* = .{
                .context_span_start = ctxt_span_start,
                .span_start = idx.*,
                .span_end = idx.*+1,
                .context_span_end = idx.*+1,
                .error_msg = "expected page number",
                .context = "found this instead",
            };
            return error.ParsingError;
        };
    } else return null;
}

test parsePageNum {
    // demonstrates the resiliance of the parser
    const slice = "some garbage that's gonna get discarded ## #value 2 #page8; # page 23 #page 12";
    var idx: usize = 0;
    const number = parsePageNum(slice, &idx);
    std.debug.assert(number == 12);
}
