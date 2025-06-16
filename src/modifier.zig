//! Functions for parsing modifiers (`#red(this is red)`)

const err = @import("err.zig");

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
