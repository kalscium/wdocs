//! Functions for parsing modifiers (`#red(this is red)`)

const std = @import("std");
const err = @import("err.zig");
const wdocs = @import("root.zig");

/// Parses, converts and writes the formatted markdown versions of modifiers to a writer, assuming the idx is on `#`.
/// 
/// Returns the new page number, if the modifier is a `#page`
pub fn parseModifier(writer: anytype, slice: []const u8, idx: *usize, err_meta: *err.Metadata) !?usize {
    const ctxt_span_start = idx.*;
    idx.* += 1; // skip `#`

    // parse the next word
    const modifier = wdocs.collectWord(slice, idx);
    if (modifier.len == 0) {
        err_meta.* = .{
            .context_span_start = ctxt_span_start,
            .span_start = idx.*,
            .span_end = idx.*+1,
            .context_span_end = idx.*+1,
            .error_msg = "expected tag identifier",
            .context = "found this instead",
        };
        return error.ParsingError;
    }
    const merr_span_end = idx.*;

    // check for #pages
    if (std.mem.eql(u8, modifier, "page")) {
        // skip whitespace
        while (idx.* < slice.len and (slice[idx.*] == ' ' or slice[idx.*] == '\t')) : (idx.* += 1)
            continue;
        // parse number
        const number = wdocs.collectNumber(slice, idx) orelse {
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
        return number;
    }

    // parse the parentheses
    if (slice[idx.*] != '(') {
        err_meta.* = .{
            .context_span_start = ctxt_span_start,
            .span_start = idx.*,
            .span_end = idx.*+1,
            .context_span_end = idx.*+1,
            .error_msg = "modifier missing parentheses",
            .context = "expected `(` here",
        };
        return error.ParsingError;
    }
    const paren = try parseParen(ctxt_span_start, slice, idx, err_meta);

    if (std.mem.eql(u8, modifier, "title")) {
        try std.fmt.format(writer, "\n## {s}\n", .{paren});
    } else if (std.mem.eql(u8, modifier, "red")) {
        try std.fmt.format(writer, "<span style=\"color: #CC241D;\">{s}</span>", .{paren});
    } else if (std.mem.eql(u8, modifier, "blue")) {
        try std.fmt.format(writer, "<span style=\"color: #458588;\">{s}</span>", .{paren});
    } else if (std.mem.eql(u8, modifier, "greeen")) {
        try std.fmt.format(writer, "<span style=\"color: #98971A;\">{s}</span>", .{paren});
    } else if (std.mem.eql(u8, modifier, "yellow")) {
        try std.fmt.format(writer, "<span style=\"color: #D79921;\">{s}</span>", .{paren});
    } else {
        err_meta.* = .{
            .context_span_start = ctxt_span_start,
            .span_start = ctxt_span_start+1,
            .span_end = merr_span_end,
            .context_span_end = idx.*,
            .error_msg = "invalid modifier",
            .context = "expected one of #title, #red, #blue, #green, #yellow",
        };
        return error.ParsingError;
    }

    return null;
}

/// Parses the contents within parentheses (respecting escaped parentheses)
pub fn parseParen(ctxt_start_span: usize, slice: []const u8, idx: *usize, err_meta: *err.Metadata) err.ParsingError![]const u8 {
    // how many open parentheses there are
    var parens: u8 = 1;

    idx.* += 1; // skip `(`
    const start_span = idx.*;

    // collect everything with speical cases for parentheses
    while (idx.* < slice.len and parens > 0 and slice[idx.*] != '\n') : (idx.* += 1) {
        if (slice[idx.*] == '(') parens += 1;
        if (slice[idx.*] == ')') parens -= 1;
    }

    // if there are still open parentheses, throw an error
    if (parens > 0) {
        err_meta.* = .{
            .context_span_start = ctxt_start_span,
            .span_start = idx.*,
            .span_end = idx.* + 1,
            .context_span_end = idx.* + 1,
            .error_msg = "unclosed modifier parentheses",
            .context = "expected `)` here",
        };
        return error.ParsingError;
    }

    // return the contents
    return slice[start_span..idx.*-1];
}
