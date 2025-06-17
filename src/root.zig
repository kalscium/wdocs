// pub const metadata = @import("metadata.zig");

const std = @import("std");
pub const metadata = @import("metadata.zig");
pub const err = @import("err.zig");
pub const modifier = @import("modifier.zig");
pub const book = @import("book.zig");
pub const xml = @import("xml.zig");

// for tests
comptime {
    _ = metadata;
    _ = err;
    _ = modifier;
    _ = book;
    _ = xml;
}

/// Collects the next word into a slice (a-zA-Z_-), assuming the cursor
/// is on the first character of the word
/// 
/// Returns an empty slice upon no match.
pub fn collectWord(slice: []const u8, idx: *usize) []const u8 {
    const start_idx = idx.*;
    while (idx.* < slice.len) : (idx.* += 1) {
        const char = slice[idx.*];
        if ((char < 'A' or char > 'z') and char != '_' and char != '-' and (char < '0' or char > '9'))
            break;
    }
    return slice[start_idx..idx.*];
}

/// Collects the next word into a slice (a-zA-Z_-), assuming the cursor
/// is on the first character of the word
pub fn collectNumber(slice: []const u8, idx: *usize) ?usize {
    const start_idx = idx.*;
    while (idx.* < slice.len) : (idx.* += 1) {
        const char = slice[idx.*];
        if (char < '0' or char > '9')
            break;
    }
    const raw_num = slice[start_idx..idx.*];

    // if there is no match, just return null
    if (raw_num.len == 0)
        return null;

    // convert string to a number
    var number: usize = 0;
    for (raw_num, 0..) |char, i|
        // the number characters are sequential, so if you subtract the
        // character zero's value, you will find the numerical value of
        // that number.
        // 
        // then the value is also multiplied with it's exponent
        // (like scientific notation) with the largest order of
        // magnitude is the first character
        number += @as(usize, char - '0') * std.math.pow(usize, 10, raw_num.len-i-1);

    return number;
}

test collectNumber {
    const slice = "1234hello-world~ &separator";
    var idx: usize = 0;
    const number = collectNumber(slice, &idx);
    std.debug.assert(number == 1234);
}

test collectWord {
    const slice = "hello-world1234~ &separator";
    var idx: usize = 0;
    const collected = collectWord(slice, &idx);
    std.debug.assert(std.mem.eql(u8, collected, "hello-world1234"));
}
