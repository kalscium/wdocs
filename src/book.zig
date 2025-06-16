//! Functions for generating the final formatted markdown 'book'

const std = @import("std");
const err = @import("err.zig");
const modifier = @import("modifier.zig");

/// Parses all the contents, converts modifiers and compresses newlines.
/// 
/// Returns the next page number, if there is one
pub fn parseContents(writer: anytype, slice: []const u8, idx: *usize, err_meta: *err.Metadata) !?usize {
    // consume and write all the items
    var newlines: u8 = 0;
    while (idx.* < slice.len) {
        // parse modifiers
        if (slice[idx.*] == '#') {
            if (try modifier.parseModifier(writer, slice, idx, err_meta)) |page|
                return page;
            continue;
        }

        // compress newlines
        if (slice[idx.*] == '\n') {
            newlines += 1;
            if (newlines > 2) {
                idx.* += 1;
                continue; // skip extra newlines
            }
        } else {
            newlines = 0;
        }

        // otherwise just write it to the stream
        try writer.writeByte(slice[idx.*]);
        idx.* += 1;
    }

    return null;
}
