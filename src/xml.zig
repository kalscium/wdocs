//! Functions for parsing antiword-generated XML documents into markdown

const std = @import("std");
const wdocs = @import("root.zig");

/// Parses the xml and finds and returns the next paragraph (respecting xml tags).
/// 
/// Returns an empty slice if no paragraph is found.
///
/// CANNOT fail unless the XML is invalid.
pub fn parsePara(slice: []const u8, idx: *usize) []const u8 {
    // keep searching until you find the <para> tag
    while (idx.* < slice.len) {
        idx.* += 1;
        if (slice[idx.*-1] != '<') continue;
        const word = wdocs.collectWord(slice, idx);
        if (std.mem.eql(u8, word, "para")) break;
    }

    // skip the rest of the tag & newline
    while (idx.* < slice.len and slice[idx.*] != '\n')
        idx.* += 1;
    idx.* += 1;

    const start = idx.*;

    // collect all the contents whilst respecting sub-tags
    var tags: u8 = 1;
    var last_nl: usize = start+1;
    while (idx.* < slice.len and tags > 0) : (idx.* += 1) {
        if (slice[idx.*] == '\n') {
            last_nl = idx.*;
            continue;
        }

        // if there's another tag (opening or closing)
        if (slice[idx.*] == '<') {
            if (slice[idx.*+1] == '/')
                tags -= 1
            else
                tags += 1;
        }
    }

    // return the collected contents
    // 
    // ends at the last newline to remove the line with the closing tag on it
    return slice[start..last_nl];
}
