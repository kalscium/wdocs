//! Functions for parsing the document's metadata & page number

const std = @import("std");
const wdocs = @import("root.zig");
const err = @import("err.zig");

/// Metadata that must be set for each page
pub const Metadata = struct {
    title: ?[]const u8 = null,
    author: ?[]const u8 = null,
    date: ?Date = null,
    topic: ?[]const u8 = null,

    /// Checks if the metadata is complete (everything set)
    pub fn isComplete(self: Metadata) bool {
        return
            self.title != null and
            self.author != null and
            self.date != null and
            self.topic != null; 
    }

    /// Parses for each of the metadata fields and returns if there are any 
    pub fn parse(self: *Metadata, slice: []const u8, idx: *usize, err_meta: *err.Metadata) err.ParsingError!void {
        // skip all characters until the '#' token is found
        while (idx.* < slice.len) : (idx.* += 1) {
            if (slice[idx.*] == '#') break;
        } else {
            err_meta.* = .{
                .context_span_start = idx.*,
                .span_start = idx.*,
                .span_end = idx.*+1,
                .context_span_end = idx.*+1,
                .error_msg = "incomplete metadata (missing required fields)",
                .context = "EOF was hit before all metadata fields were set",
            };
            return error.ParsingError;
        }

        // skip the '#' character
        const ctxt_span_start = idx.*;
        idx.* += 1;

        // collect the tag and match it
        const terr_span_start = idx.*;
        const tag = wdocs.collectWord(slice, idx);
        inline for (@typeInfo(Metadata).@"struct".fields) |field| {
            if (std.mem.eql(u8, tag, field.name)) {
                // skip whitespace
                while (idx.* < slice.len and (slice[idx.*] == ' ' or slice[idx.*] == '\t'))
                    idx.* += 1;

                // dates require special parsing
                if (comptime std.mem.eql(u8, field.name, "date")) {
                    @field(self, field.name) = Date.parse(slice, idx, err_meta) catch |perr| {
                        err_meta.context_span_start = ctxt_span_start;
                        return perr;
                    };
                    return;
                }

                // read until newline
                const value_span_start = idx.*;
                var value_span_end = idx.*;
                while (idx.* < slice.len and slice[idx.*] != '\n') : (idx.* += 1) {
                    // trim whitespace at the end
                    if (slice[idx.*] != ' ' and slice[idx.*] != '\t')
                        value_span_end = idx.*;
                }

                @field(self, field.name) = slice[value_span_start..value_span_end+1];
                return;
            }
        }

        // if the page tag is hit, then throw incomplete metadata error
        if (std.mem.eql(u8, tag, "page")) {
            if (self.isComplete()) {
                // backtrack to make the #page a different function's problem 
                idx.* = ctxt_span_start;
                return;
            }
            err_meta.* = .{
                .context_span_start = ctxt_span_start,
                .span_start = ctxt_span_start,
                .span_end = idx.*,
                .context_span_end = idx.*,
                .error_msg = "incomplete metadata (missing required fields)",
                .context = "the next page was started before the metadata of the last page was completed",
            };
            return error.ParsingError;
        }

        // if the tag is not recognised, throw error
        err_meta.* = .{
            .context_span_start = ctxt_span_start,
            .span_start = terr_span_start,
            .span_end = idx.*,
            .context_span_end = idx.*,
            .error_msg = "invalid metadata tag",
            .context = "expected one of #title, #author, #date, #topic",
        };
        return error.ParsingError;
    }
};

/// Parses the page number, discarded everything before it.
/// If no page number is found, then it will return null.
pub fn parsePageNum(slice: []const u8, idx: *usize, err_meta: *err.Metadata) err.ParsingError!?usize {
    // skip all characters until the '#' token is found
    while (idx.* < slice.len) : (idx.* += 1) {
        if (slice[idx.*] == '#') break;
    } else return null; // if no # is found

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
}

/// A date in the format yyyy-mm-dd
pub const Date = struct {
    year: u16,
    month: u8,
    day: u8,

    /// Parses the date format yyyy-mm-dd
    pub fn parse(slice: []const u8, idx: *usize, err_meta: *err.Metadata) err.ParsingError!Date {
        // parse for year number
        const ctxt_span_start = idx.*;
        const year = wdocs.collectNumber(slice, idx) orelse {
            err_meta.* = .{
                .context_span_start = ctxt_span_start,
                .span_start = idx.*,
                .span_end = idx.* + 1,
                .context_span_end = idx.* + 1,
                .error_msg = "date missing year value",
                .context = "expected a yyyy year value here",
            };
            return error.ParsingError;
        };

        // check for the separator
        if (slice[idx.*] != '-') {
            err_meta.* = .{
                .context_span_start = ctxt_span_start,
                .span_start = idx.*,
                .span_end = idx.* + 1,
                .context_span_end = idx.* + 1,
                .error_msg = "date missing year month separator",
                .context = "expected `-` here",
            };
            return error.ParsingError;
        }
        idx.* += 1;

        const month = wdocs.collectNumber(slice, idx) orelse {
            err_meta.* = .{
                .context_span_start = ctxt_span_start,
                .span_start = idx.*,
                .span_end = idx.* + 1,
                .context_span_end = idx.* + 1,
                .error_msg = "date missing month value",
                .context = "expected a mm month value here",
            };
            return error.ParsingError;
        };

        if (slice[idx.*] != '-') {
            err_meta.* = .{
                .context_span_start = ctxt_span_start,
                .span_start = idx.*,
                .span_end = idx.* + 1,
                .context_span_end = idx.* + 1,
                .error_msg = "date missing month day separator",
                .context = "expected `-` here",
            };
            return error.ParsingError;
        }
        idx.* += 1;

        const day = wdocs.collectNumber(slice, idx) orelse {
            err_meta.* = .{
                .context_span_start = ctxt_span_start,
                .span_start = idx.*,
                .span_end = idx.* + 1,
                .context_span_end = idx.* + 1,
                .error_msg = "date missing day value",
                .context = "expected a dd day value here",
            };
            return error.ParsingError;
        };

        return .{
            .year = @intCast(year),
            .month = @intCast(month),
            .day = @intCast(day),
        };
    }
};
