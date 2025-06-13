//! Functions for parsing the document's metadata & page number

const std = @import("std");
const wdocs = @import("root.zig");

/// Parses the page number, discarded everything before it.
/// If no page number is found, then it will return null.
pub fn parsePageNum(slice: []const u8, idx: *usize) ?usize {
    // skip all characters until the '#page' token is found
    while (idx.* < slice.len) {
        // if the '#' character hasn't been found, keep searching
        if (slice[idx.*] != '#') {
            idx.* += 1;
            continue;
        }
        idx.* += 1; // skip the '#' character

        // collect the tag, and ensure it's of the right kind
        const tag = wdocs.collectWord(slice, idx);
        if (!std.mem.eql(u8, tag, "page")) continue;

        // skip whitespace
        while (idx.* < slice.len and slice[idx.*] == ' ' or slice[idx.*] == '\t') : (idx.* += 1)
            continue;

        // try collect a number
        if (wdocs.collectNumber(slice, idx)) |number|
            return number;
    } else return null;
}

test parsePageNum {
    // demonstrates the resiliance of the parser
    const slice = "some garbage that's gonna get discarded ## #value 2 #page8; # page 23 #page 12";
    var idx: usize = 0;
    const number = parsePageNum(slice, &idx);
    std.debug.assert(number == 12);
}
