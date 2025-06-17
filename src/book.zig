//! Functions for generating the final formatted markdown 'book'

const std = @import("std");
const err = @import("err.zig");
const modifier = @import("modifier.zig");
const wdocs = @import("root.zig");

/// Parses all the contents, converts modifiers and compresses newlines.
/// 
/// Returns the next page number, if there is one
pub fn parseContents(writer: anytype, slice: []const u8, idx: *usize, err_meta: *err.Metadata) !?usize {
    // consume and write all the items
    var newlines: u8 = 0;
    while (idx.* < slice.len) : (idx.* += 1) {
        // parse modifiers
        if (slice[idx.*] == '#') {
            if (try modifier.parseModifier(writer, slice, idx, err_meta)) |page|
                return page;
            idx.* -= 1; // as continuing increments idx again
            continue;
        }

        // compress newlines
        if (slice[idx.*] == '\n') {
            newlines += 1;
            if (newlines > 2)
                continue; // skip extra newlines
        } else {
            newlines = 0;
        }

        // parse &foos (from antiword)
        if (slice[idx.*] == '&') {
            idx.* += 1;
            const word = wdocs.collectWord(slice, idx);
            // skip the `;` after the word aswell
            if (std.mem.eql(u8, word, "amp")) {
                try writer.writeByte('&');
                continue;
            } else if (std.mem.eql(u8, word, "lt")) {
                try writer.writeByte('<');
                continue;
            } else if (std.mem.eql(u8, word, "gt")) {
                try writer.writeByte('>');
                continue;
            } else {
                idx.* -= 1;
            }
        }

        // otherwise just write it to the stream
        try writer.writeByte(slice[idx.*]);
    }

    return null;
}
